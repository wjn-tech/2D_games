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

func setup(index: int, slot_data: Dictionary) -> void:
	slot_index = index
	
	if not icon_rect: return
	
	if slot_data.is_empty() or not slot_data.has("item_data"):
		icon_rect.texture = null
		if count_label: count_label.text = ""
	else:
		var item: BaseItem = slot_data["item_data"]
		icon_rect.texture = item.icon
		if count_label:
			count_label.text = str(slot_data["amount"]) if slot_data["amount"] > 1 else ""

## 鼠标点击处理（示例：右键使用）
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# 调用 InventoryManager 使用物品
			if GameState.inventory.has_method("use_item"):
				GameState.inventory.use_item(slot_index)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# 这里可以扩展拖拽逻辑
			pass

## 鼠标悬停显示 Tooltip
func _get_tooltip(_at_position: Vector2) -> String:
	var slot_data = GameState.inventory.slots[slot_index]
	if slot_data.is_empty():
		return ""
	
	var item: BaseItem = slot_data["item_data"]
	return "%s\n%s" % [item.display_name, item.description]
