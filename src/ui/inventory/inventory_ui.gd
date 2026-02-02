extends Control
class_name InventoryUI

## InventoryUI
## 绑定 InventoryManager 并渲染网格化背包。

@export var slot_scene: PackedScene # 拖入 ItemSlot.tscn
@export var grid_container_path: NodePath

@onready var grid_container: GridContainer = get_node(grid_container_path)

var _is_ready: bool = false

func _ready() -> void:
	# 强制设置布局为左上角，并增加美化边距
	_setup_layout()
	
	# 监听背包变化信号
	GameState.inventory.inventory_changed.connect(refresh_ui)
	
	# 监听转生信号，如果 GameState.inventory 重新实例化了，这里需要重新连接
	if EventBus:
		EventBus.player_data_refreshed.connect(_on_player_refreshed)
		
	refresh_ui()
	# 延迟一帧标记为就绪，防止打开瞬间又被关闭
	get_tree().process_frame.connect(func(): _is_ready = true)

func _on_player_refreshed() -> void:
	# 断开旧连接（如果存在）
	if GameState.inventory.inventory_changed.is_connected(refresh_ui):
		GameState.inventory.inventory_changed.disconnect(refresh_ui)
	
	# 连接新背包
	GameState.inventory.inventory_changed.connect(refresh_ui)
	refresh_ui()

func _setup_layout() -> void:
	# 如果该节点在 CharacterPanel 中作为子节点，则跳过全屏布局设置
	if get_parent() and get_parent().name == "InventorySection":
		mouse_filter = Control.MOUSE_FILTER_PASS
		# 隐藏不需要的装饰
		if has_node("InventoryPanel"):
			get_node("InventoryPanel").visible = false
		return

	# 确保根节点是全屏的
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 隐藏所有在编辑器中误设的、不在面板内的杂乱节点
	for child in get_children():
		if child is Control and child.name != "InventoryPanel":
			child.visible = false
	
	# 寻找或创建一个美观的面板容器
	var panel = get_node_or_null("InventoryPanel")
	if not panel:
		panel = PanelContainer.new()
		panel.name = "InventoryPanel"
		add_child(panel)
		
		# 给面板添加背景
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
		panel_style.border_width_left = 2
		panel_style.border_width_top = 2
		panel_style.border_width_right = 2
		panel_style.border_width_bottom = 2
		panel_style.border_color = Color(0.3, 0.3, 0.3, 1.0)
		panel_style.set_corner_radius_all(8)
		panel.add_theme_stylebox_override("panel", panel_style)
		
		var vbox = VBoxContainer.new()
		panel.add_child(vbox)
		
		# 添加标题栏
		var header = HBoxContainer.new()
		vbox.add_child(header)
		
		var title_label = Label.new()
		title_label.text = " 物品栏 (B)"
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_label.add_theme_font_size_override("font_size", 14)
		title_label.add_theme_color_override("font_color", Color.GOLD)
		header.add_child(title_label)
		
		var close_btn = Button.new()
		close_btn.text = " X "
		close_btn.flat = true
		close_btn.pressed.connect(func(): UIManager.close_window("Inventory"))
		header.add_child(close_btn)
		
		# 将 GridContainer 移入 VBox 并重置其布局属性
		if grid_container:
			grid_container.get_parent().remove_child(grid_container)
			vbox.add_child(grid_container)
			# 确保它是可见的
			grid_container.visible = true
			# 重置位置和大小，让容器自动排版
			grid_container.position = Vector2.ZERO
			grid_container.custom_minimum_size = Vector2.ZERO
			grid_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# 设置面板样式与位置
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(20, 120) # 稍微往下移一点，避开 HUD
	panel.custom_minimum_size = Vector2(300, 0)
	
	# 设置内边距
	var margin = 12
	if panel.has_theme_stylebox_override("panel"):
		var style = panel.get_theme_stylebox("panel").duplicate()
		style.content_margin_left = margin
		style.content_margin_right = margin
		style.content_margin_top = margin
		style.content_margin_bottom = margin
		panel.add_theme_stylebox_override("panel", style)
	
	# 调整网格间距
	if grid_container:
		grid_container.columns = 5
		grid_container.add_theme_constant_override("h_separation", 8)
		grid_container.add_theme_constant_override("v_separation", 8)

## 刷新整个背包界面
func refresh_ui() -> void:
	if not grid_container: return
	
	# 清除旧格子
	for child in grid_container.get_children():
		child.queue_free()
	
	# 获取背包数据
	var inventory = GameState.inventory
	var slots_data = inventory.slots
	var max_slots = inventory.max_slots
	
	# 始终生成 max_slots 个格子，即使是空的
	for i in range(max_slots):
		var slot_ui = slot_scene.instantiate()
		grid_container.add_child(slot_ui)
		
		# 如果该索引有数据，则传入数据；否则传入空字典
		var data = slots_data[i] if i < slots_data.size() else {}
		if slot_ui.has_method("setup"):
			slot_ui.setup(i, data)

func _input(event: InputEvent) -> void:
	if not _is_ready: return
	
	# 仅处理 ESC 关闭，B 键由 GameManager.toggle_window 统一处理，防止冲突导致一闪而逝
	if event.is_action_pressed("ui_cancel"):
		UIManager.close_window("Inventory")
		get_viewport().set_input_as_handled()
