extends PanelContainer
class_name InventorySlotUI

signal slot_clicked(inventory: Inventory, slot_index: int)

var inventory: Inventory
var slot_index: int = -1

@onready var icon = $MarginContainer/Icon
@onready var count_lbl = $MarginContainer/CountLabel

var hover_timer: SceneTreeTimer = null
var name_tooltip: Label

func _ready():
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_setup_internal_name_label()

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

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Handle simple click if needed, but mainly Drag handled by _get_drag_data
			slot_clicked.emit(inventory, slot_index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# 右键一键丢弃
			if GameState.inventory.has_method("drop_item_from_slot"):
				GameState.inventory.drop_item_from_slot(inventory, slot_index)

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
	
	var preview = TextureRect.new()
	preview.texture = item.icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(40, 40)
	set_drag_preview(preview)
	
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
