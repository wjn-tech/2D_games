extends PanelContainer
class_name InventorySlotUI

signal slot_clicked(inventory: Inventory, slot_index: int)

var inventory: Inventory
var slot_index: int = -1
var is_active: bool = false # For Hotbar

@onready var icon = $MarginContainer/Icon
@onready var count_lbl = $MarginContainer/CountLabel

var hover_timer: SceneTreeTimer = null
var name_tooltip: Label

func _ready():
	# Apply Pixel Art Panel Style
	add_theme_stylebox_override("panel", HUDStyles.get_panel_style())
	
	gui_input.connect(_on_gui_input)
	
	# Using _notification instead for more robust hover detection across all speeds
	# if not mouse_entered.is_connected(_on_mouse_entered_slot):
	# 	mouse_entered.connect(_on_mouse_entered_slot)
	# if not mouse_exited.is_connected(_on_mouse_exited_slot):
	# 	mouse_exited.connect(_on_mouse_exited_slot)
		
	_setup_internal_name_label()
	
	# Initial style
	_update_style()
	
	# Forced Pivot to center for better scale animation consistency
	pivot_offset = size / 2
	
	# But WE (the slot itself) must stop/catch the mouse
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Initial child sweep
	_set_mouse_filter_recursive(self, Control.MOUSE_FILTER_IGNORE)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _set_mouse_filter_recursive(node: Node, filter: int) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = filter
		_set_mouse_filter_recursive(child, filter)

func set_active(active: bool) -> void:
	is_active = active
	# If active, trigger a small bump animation
	if is_active and is_inside_tree():
		var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.3)
	else:
		if is_inside_tree():
			var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "scale", Vector2.ONE, 0.2)
			
	_update_style()

func _update_style() -> void:
	if not is_inside_tree(): return
	
	var style: StyleBoxFlat
	if is_active:
		style = HUDStyles.get_slot_style_active()
	else:
		style = HUDStyles.get_slot_style_normal()
		
	add_theme_stylebox_override("panel", style)

func get_slot_data() -> Dictionary:
	if inventory:
		return inventory.get_slot(slot_index)
	return { "item": null, "count": 0 }

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		# 强制子节点穿透，特别是动态生成的图标或标签
		for child in get_children():
			if child is Control:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_on_mouse_entered_slot()
	elif what == NOTIFICATION_MOUSE_EXIT:
		_on_mouse_exited_slot()

func _on_mouse_entered_slot() -> void:
	# Audio Feedback
	# if has_node("/root/AudioManager"):
	# 	print("InventorySlot: Hovered -> Playing 'hover'")
	# 	get_node("/root/AudioManager").play_ui_sfx("hover")
	# else:
	# 	print("InventorySlot: Hovered -> No AudioManager found!")

	_on_mouse_entered() # Call existing logic
	
	# Scale animation
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	pivot_offset = size / 2

func _on_mouse_exited_slot() -> void:
	_on_mouse_exited() # Call existing logic
	
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# if has_node("/root/AudioManager"):
			# 	get_node("/root/AudioManager").play_ui_sfx("click")
			
			slot_clicked.emit(inventory, slot_index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Context menu or split?
			pass

func _process(_delta: float) -> void:
	# Removed: Aggressive mouse filter enforcement in _process is unnecessary and costly.
	# The filters are now correctly handled in _ready and _update_visual.
	pass

func _setup_internal_name_label():
	name_tooltip = Label.new()
	name_tooltip.name = "HoverNameLabel"
	name_tooltip.top_level = true
	add_child(name_tooltip)
	
	name_tooltip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	name_tooltip.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	name_tooltip.add_theme_font_size_override("font_size", 10)
	name_tooltip.add_theme_color_override("font_outline_color", Color.BLACK)
	name_tooltip.add_theme_constant_override("outline_size", 2)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	name_tooltip.add_theme_stylebox_override("normal", style)
	
	name_tooltip.visible = false
	name_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_tooltip.z_index = 100

func setup(inv: Inventory, idx: int):
	inventory = inv
	slot_index = idx
	inventory.content_changed.connect(_on_inventory_changed)
	
	# Listen for visual update signal if InventoryManager exposes it, 
	# but tricky since we only have 'inventory' here (which is just data).
	# Simple hack: rely on player calling refresh or re-setting item.
	
	# However, we can listen to the item's `changed` signal if it's a Resource?
	# Or the User asked for Inventory Icon update.
	# We updated player.gd to emit `inventory.item_visual_updated`.
	# But InventoryContainer/Slot usually doesn't know about Manager.
	# Let's check parentage or global bus.
	# For now, Player.gd calls hotbar_ui.refresh() which rebuilds/updates.
	
	_update_visual()

func _on_inventory_changed(idx: int):
	if idx == slot_index:
		_update_visual()

func _update_visual():
	var slot = inventory.get_slot(slot_index)
	var item = slot.get("item")
	
	# Aggressively ensure children do NOT block input
	# This avoids the "slow hover silent" issue by using STOP on the slot
	# and IGNORE on all internal visuals (Icon, Label, etc.)
	if icon: 
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if count_lbl: 
		count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin = get_node_or_null("MarginContainer")
	if margin: 
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for child in margin.get_children():
			if child is Control:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Also check generic child elements that might be added dynamically
	for child in get_children():
		if child is Control and child != self:
			if child.name != "HoverNameLabel": # Keep tooltip logic separate
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if item:
		icon.texture = item.icon
		icon.visible = true
		var count = slot.get("count", 0)
		if count > 1:
			count_lbl.text = str(count)
			count_lbl.visible = true
		else:
			count_lbl.visible = false
	else:
		icon.texture = null
		icon.visible = false
		count_lbl.visible = false

# Renamed or removed duplicate _on_gui_input to avoid conflict
# The correct one is above.

func _on_mouse_entered():
	var slot = inventory.get_slot(slot_index)
	var item = slot.get("item")
	if item:
		if name_tooltip:
			name_tooltip.text = item.display_name
			name_tooltip.visible = true
			name_tooltip.reset_size()
			
			var target_pos = global_position + (size * get_global_transform().get_scale())
			name_tooltip.global_position = target_pos - name_tooltip.size

func _on_mouse_exited():
	if name_tooltip:
		name_tooltip.visible = false

func _get_drag_data(at_position):
	var slot = inventory.get_slot(slot_index)
	var item = slot.get("item")
	if not item: return null
	
	# 首先通过 UI 层级尝试强制关闭高亮 (此时槽位数据还未彻底变更)
	# 这样在拖拽预览生成的同一帧，高亮就消失
	if UIManager:
		UIManager.clear_highlight()
	
	var preview = TextureRect.new()
	preview.texture = item.icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(40, 40)
	preview.modulate.a = 0.8
	set_drag_preview(preview)
	
	# 显式关闭教程箭头 (使用 UIManager.highlight_overlay 自动清理逻辑辅助)
	var tutorial = get_tree().get_first_node_in_group("tutorial_manager")
	if tutorial:
		# 强制触发一次清除操作
		if tutorial.has_method("_check_step"):
			# 如果当前正在做这个步骤，我们不直接 check，而是让 UI 层清空
			pass
		
		# 寻找箭头所在的 CanvasLayer 孩子并隐藏 (TutorialOverlay)
		for child in tutorial.get_children():
			if child is CanvasLayer and child.name == "TutorialOverlay":
				for sub_child in child.get_children():
					if sub_child is Control: # This is the arrow
						sub_child.visible = false
	
	return { "inventory": inventory, "index": slot_index, "item": item }

func _can_drop_data(at_position, data):
	return data is Dictionary and data.has("inventory") and data.has("index")

func _drop_data(at_position, data):
	var from_inv = data.inventory
	var from_idx = data.index
	
	# Prefer Global Singleton
	var manager = GameState.inventory
	if manager:
		manager.swap_items(from_inv, from_idx, inventory, slot_index)
	else:
		# Fallback
		manager = get_tree().get_first_node_in_group("inventory_manager")
		if manager:
			manager.swap_items(from_inv, from_idx, inventory, slot_index)
			
	# Notify UI Manager to clear tutorial highlights if this was the tutorial item
	if UIManager and UIManager.has_method("clear_highlight"):
		UIManager.clear_highlight()
