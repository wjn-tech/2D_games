extends Control

@onready var npc_list: VBoxContainer = $NPCPanel/VBoxContainer/ScrollContainer/NPCList
@onready var world_overlay: Control = $WorldOverlay

var indicator_scene: PackedScene = load("res://src/ui/housing/housing_indicator.tscn")

func _ready() -> void:
	refresh_all()

func _process(_delta: float) -> void:
	# 保持 Overlay 里的图标位置与世界坐标同步
	_update_indicator_positions()

func refresh_all() -> void:
	_clear_ui()
	_load_npcs()
	_load_houses()

func _clear_ui() -> void:
	for child in npc_list.get_children():
		child.queue_free()
	for child in world_overlay.get_children():
		child.queue_free()

func _load_npcs() -> void:
	if not SettlementManager: return
	
	# 获取所有已招募的模板或实例
	# 为了演示，直接获取场景里的 town_npcs
	var npcs = get_tree().get_nodes_in_group("town_npcs")
	for npc in npcs:
		var btn = Button.new()
		btn.text = npc.name
		btn.custom_minimum_size = Vector2(100, 40)
		btn.set_meta("npc_name", npc.name)
		btn.gui_input.connect(_on_npc_gui_input.bind(npc.name))
		npc_list.add_child(btn)

func _load_houses() -> void:
	if not SettlementManager: return
	
	var houses = SettlementManager.scan_all_housing()
	for rid in houses.keys():
		var info = houses[rid]
		var indicator = indicator_scene.instantiate()
		world_overlay.add_child(indicator)
		
		# 计算房屋中心（世界坐标）
		var center_map_pos = info.interior[0] # 简化：取第一个点
		var world_pos = Vector2(center_map_pos) * 16.0
		
		indicator.set_meta("house_id", rid)
		indicator.set_meta("world_pos", world_pos)
		indicator.setup(info)
		
		# 房屋图标被点击时，如果当前正在拖拽 NPC，则进行分配
		indicator.clicked.connect(_on_house_clicked.bind(rid))

func _update_indicator_positions() -> void:
	var camera = get_viewport().get_camera_2d()
	if not camera: return
	
	for indicator in world_overlay.get_children():
		var world_pos = indicator.get_meta("world_pos")
		# 这是一个 UI 叠加层，所以我们需要将世界坐标转换为屏幕/Canvas 坐标
		var screen_pos = (world_pos - camera.get_screen_center_position()) * camera.zoom + get_viewport_rect().size / 2.0
		indicator.position = screen_pos

var dragging_npc: String = ""

func _on_npc_gui_input(event: InputEvent, npc_name: String) -> void:
	if event is InputEventMouseButton and event.pressed:
		dragging_npc = npc_name
		print("开始分配 NPC: ", npc_name)

func _on_house_clicked(house_id: String) -> void:
	if dragging_npc != "":
		SettlementManager.assign_npc_to_house(dragging_npc, house_id)
		dragging_npc = ""
		refresh_all()
