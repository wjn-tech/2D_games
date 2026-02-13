extends Control
class_name InventoryUI

## InventoryUI
## 绑定 InventoryManager 并渲染网格化背包。

@export var slot_scene: PackedScene # 拖入 ItemSlot.tscn
@export var grid_container_path: NodePath

@onready var grid_container: GridContainer = get_node(grid_container_path)

var _is_ready: bool = false
var _item_name_label: Label

func _ready() -> void:
	# 强制设置布局为左上角，并增加美化边距
	_setup_layout()
	
	# 创建物品名称显示标签 (右下角)
	_setup_item_name_label()
	
	# 监听背包变化信号
	GameState.inventory.inventory_changed.connect(refresh_ui)
	
	# 监听转生信号，如果 GameState.inventory 重新实例化了，这里需要重新连接
	if EventBus:
		EventBus.player_data_refreshed.connect(_on_player_refreshed)
		
	refresh_ui()
	# 延迟一帧标记为就绪，防止打开瞬间又被关闭
	get_tree().process_frame.connect(func(): _is_ready = true)

func _setup_item_name_label() -> void:
	# 彻底移除全局标签逻辑，改为格子自管理
	pass

func show_item_name(_text: String, _pos: Vector2 = Vector2.ZERO) -> void:
	pass

func hide_item_name() -> void:
	pass

func _on_player_refreshed() -> void:
	# 断开旧连接（如果存在）
	if GameState.inventory.inventory_changed.is_connected(refresh_ui):
		GameState.inventory.inventory_changed.disconnect(refresh_ui)
	
	# 连接新背包
	GameState.inventory.inventory_changed.connect(refresh_ui)
	refresh_ui()

func _setup_layout() -> void:
	# 确保根节点正确设置
	# 如果该节点在 CharacterPanel 中作为子节点，父节点会控制大小
	# 只要 MainSplit 设置了 anchors_preset = 15，它就会自动填充 InventoryWindow
	pass

## 刷新整个背包界面
func refresh_ui() -> void:
	if not grid_container: return
	
	# 清除旧格子
	for child in grid_container.get_children():
		child.queue_free()
	
	# 获取背包数据 (InventoryManager -> Inventory)
	var inv_manager = GameState.inventory
	if not inv_manager or not inv_manager.backpack: return
	
	var inv = inv_manager.backpack
	var slots_data = inv.slots
	var max_slots = inv.capacity
	
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
