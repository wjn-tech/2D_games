extends PanelContainer
class_name ItemSlotUI

## ItemSlotUI
## 处理单个物品格子的显示、悬停与点击。

@export var icon_rect_path: NodePath
@export var count_label_path: NodePath

@onready var icon_rect: TextureRect = get_node(icon_rect_path)
@onready var count_label: Label = get_node(count_label_path)

var slot_index: int = -1
var current_item: Resource = null # 缓存当前格子的物品数据
var name_tooltip: Label # 新增：格子自带的名称标签

func _ready() -> void:
	# 确保接收鼠标事件
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	_setup_internal_name_label()
	
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
	
	# 确保图标居中且不超出，并让鼠标事件穿透到父容器 (ItemSlotUI)
	if icon_rect:
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(40, 40)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# 确保数量标签在右下角，且鼠标穿透
	if count_label:
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_label.add_theme_color_override("font_outline_color", Color.BLACK)
		count_label.add_theme_constant_override("outline_size", 4)
		count_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		count_label.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# 隐藏调试用的 ColorRect
	var debug_rect = find_child("ColorRect")
	if debug_rect:
		debug_rect.visible = false
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _setup_internal_name_label() -> void:
	# 方案：将标签作为格子的子节点，但开启 top_level 以实现绝对定位
	# 这样它不会被 PanelContainer 的自动布局干扰
	name_tooltip = Label.new()
	name_tooltip.name = "HoverNameLabel"
	add_child(name_tooltip)
	
	# 关键：开启 top_level 允许我们直接在全局坐标系操作它
	name_tooltip.top_level = true
	
	# 样式调整
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
	name_tooltip.z_index = 100 # 确保在最上层

func _on_mouse_entered() -> void:
	if current_item:
		var item_name = current_item.display_name if "display_name" in current_item else "Unknown Item"
		
		if name_tooltip:
			name_tooltip.text = item_name
			name_tooltip.visible = true
			name_tooltip.reset_size() # 确保尺寸根据文字更新
			
			# 实时计算：将标签右下角贴合到格子右下角
			# global_position 是格子的左上角，size 是格子大小
			# 我们的目标位置是 (格子左上角 + 格子大小) - 标签大小
			var target_pos = global_position + (size * get_global_transform().get_scale())
			name_tooltip.global_position = target_pos - name_tooltip.size

		# 高亮效果
		_set_highlight(true)

func _set_highlight(enabled: bool) -> void:
	var style = get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		var highlight_style = style.duplicate()
		if enabled:
			highlight_style.border_color = Color(1.0, 1.0, 1.0, 1.0)
			highlight_style.bg_color = Color(0.25, 0.25, 0.25, 0.9)
		add_theme_stylebox_override("panel", highlight_style)

func _on_mouse_exited() -> void:
	# 隐藏内部标签
	if name_tooltip:
		name_tooltip.visible = false
		
	# 恢复外观 (移除 Override)
	remove_theme_stylebox_override("panel")

func _find_parent_inventory_ui() -> Control:
	var p = get_parent()
	while p:
		# 即使 class_name 判定失败，也可以通过检查方法来确认身份
		if p.has_method("show_item_name"):
			return p
		p = p.get_parent()
	return null

func has_item() -> bool:
	if slot_index < 0: return false
	return GameState.inventory.get_item_at(slot_index) != null


func setup(index: int, slot_data: Dictionary) -> void:
	slot_index = index
	current_item = slot_data.get("item") # 缓存物品
	
	if not icon_rect: return
	
	if not current_item:
		icon_rect.texture = null
		if count_label:
			count_label.text = ""
		return
	
	var count = slot_data.get("count", 0)
	
	# 设置图标
	if current_item.get("icon"):
		icon_rect.texture = current_item.icon
	
	# 设置数量
	if count_label:
		count_label.text = str(count) if count > 1 else ""

## 鼠标点击处理（右键丢弃）
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# 调用 InventoryManager 丢弃物品
			if GameState.inventory.has_method("drop_item_from_slot"):
				# 注意：InventoryUI 固定对应 backpack
				GameState.inventory.drop_item_from_slot(GameState.inventory.backpack, slot_index)
				
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# 点击逻辑（目前暂无）
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
