extends PanelContainer
class_name ItemSlotUI

## ItemSlotUI
## 处理单个物品格子的显示、悬停与点击。

@export var icon_rect_path: NodePath
@export var count_label_path: NodePath

@onready var icon_rect: TextureRect = get_node(icon_rect_path)
@onready var count_label: Label = get_node(count_label_path)

var slot_index: int = -1

func _ready() -> void:
	# 重置布局属性，防止在编辑器中误设的巨大偏移影响显示
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	
	# 美化格子外观
	custom_minimum_size = Vector2(52, 52)
	
	# 给格子添加一个半透明背景，使其看起来像“方块”
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.8) # 更深一点的背景
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.5, 0.5, 0.9) # 更亮的边框
	style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", style)
	
	# 确保图标居中且不超出
	if icon_rect:
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(40, 40)
	
	# 确保数量标签在右下角
	if count_label:
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_label.add_theme_color_override("font_outline_color", Color.BLACK)
		count_label.add_theme_constant_override("outline_size", 4)
		count_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	
	# 隐藏调试用的 ColorRect
	var debug_rect = find_child("ColorRect")
	if debug_rect:
		debug_rect.visible = false
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	if has_item():
		# 向上寻找 InventoryUI 并通知显示名称
		var inventory_ui = _find_parent_inventory_ui()
		if inventory_ui:
			var item_name = GameState.inventory.get_item_at(slot_index).display_name
			inventory_ui.show_item_name(item_name)
			
		# 高亮效果
		var style = get_theme_stylebox("panel")
		if style is StyleBoxFlat:
			style.border_color = Color(1.0, 1.0, 1.0, 1.0)
			style.bg_color = Color(0.25, 0.25, 0.25, 0.9)

func _on_mouse_exited() -> void:
	# 向上寻找 InventoryUI 并通知隐藏名称
	var inventory_ui = _find_parent_inventory_ui()
	if inventory_ui:
		inventory_ui.hide_item_name()
		
	# 恢复外观
	var style = get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		style.border_color = Color(0.5, 0.5, 0.5, 0.9)
		style.bg_color = Color(0.15, 0.15, 0.15, 0.8)

func _find_parent_inventory_ui() -> InventoryUI:
	var p = get_parent()
	while p:
		if p is InventoryUI:
			return p
		p = p.get_parent()
	return null

func has_item() -> bool:
	if slot_index < 0: return false
	return GameState.inventory.get_item_at(slot_index) != null


func setup(index: int, slot_data: Dictionary) -> void:
	slot_index = index
	
	if not icon_rect: return
	
	# Fix: Use "item" key instead of "item_data" to match Inventory resource
	if slot_data.is_empty() or not slot_data.has("item") or slot_data["item"] == null:
		icon_rect.texture = null
		if count_label:
			count_label.text = ""
		return
	
	var item = slot_data["item"]
	var count = slot_data.get("count", 0)
	
	# 设置图标
	if item.get("icon"):
		icon_rect.texture = item.icon
	
	# 设置数量
	if count_label:
		count_label.text = str(count) if count > 1 else ""

## 鼠标点击处理（示例：右键使用）
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# 调用 InventoryManager 使用物品
			if GameState.inventory.has_method("use_item"):
				GameState.inventory.use_item(slot_index) # Be careful with index if use_item distinguishes hotbar/backpack
				
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# Tap to click/select?
			pass

## Drag & Drop Implementation
func _get_drag_data(_at_position: Vector2):
	if slot_index < 0: return null
	
	# Determine which inventory we represent.
	# InventoryUI is specifically Backpack.
	var my_inv = GameState.inventory.backpack
	var slot = my_inv.get_slot(slot_index)
	var item = slot.get("item")
	
	if not item: return null
	
	# Create Preview
	var preview_Icon = TextureRect.new()
	preview_Icon.texture = item.icon
	preview_Icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_Icon.custom_minimum_size = Vector2(40, 40)
	preview_Icon.size = Vector2(40, 40)
	
	var preview = Control.new()
	preview.add_child(preview_Icon)
	preview_Icon.position = -0.5 * preview_Icon.size # Center it
	set_drag_preview(preview)
	
	return { 
		"inventory": my_inv, 
		"index": slot_index, 
		"item": item 
	}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("inventory") and data.has("index")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	print("ItemSlotUI: Drop received from ", data.get("index"), " to ", slot_index)
	var from_inv = data.inventory
	var from_idx = data.index
	var my_inv = GameState.inventory.backpack
	
	# Call Manager to Swap
	GameState.inventory.swap_items(from_inv, from_idx, my_inv, slot_index)
	# UI refresh should be triggered by InventoryManager signals

## 鼠标悬停显示 Tooltip
func _get_tooltip(_at_position: Vector2) -> String:
	var slot_data = GameState.inventory.slots[slot_index]
	if slot_data.is_empty():
		return ""
	
	var item: BaseItem = slot_data["item_data"]
	return "%s\n%s" % [item.display_name, item.description]
