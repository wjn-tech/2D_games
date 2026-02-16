extends Control

@onready var npc_list: VBoxContainer = $NPCPanel/VBoxContainer/ScrollContainer/NPCList
@onready var world_overlay: Control = $WorldOverlay

var indicator_scene: PackedScene = load("res://src/ui/housing/housing_indicator.tscn")
var dragging_npc: String = ""

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
	
	# 获取所有已招募的 NPC 数据对象
	var npc_data_list = SettlementManager.recruited_npcs
	
	if npc_data_list.size() == 0:
		var label = Label.new()
		label.text = "没有已招募的 NPC\n(前往野外招募)"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		npc_list.add_child(label)
		
	for npc_data in npc_data_list:
		var btn = Button.new()
		btn.text = npc_data.display_name
		btn.custom_minimum_size = Vector2(100, 40)
		btn.set_meta("npc_name", npc_data.display_name)
		btn.gui_input.connect(_on_npc_gui_input.bind(npc_data.display_name))
		npc_list.add_child(btn)

func _load_houses() -> void:
	if not SettlementManager: return

	var houses = SettlementManager.scan_all_housing()
	for rid in houses.keys():
		var info = houses[rid]
		var indicator = indicator_scene.instantiate()
		world_overlay.add_child(indicator)

		# 计算房屋中心（世界坐标）
		var center_map_pos = info.interior[0] 
		var world_pos = Vector2(center_map_pos) * 16.0
		
		indicator.set_meta("world_pos", world_pos)
		indicator.setup(info)
		
		# 初始位置
		indicator.position = world_pos

func _update_indicator_positions() -> void:
	var camera = get_viewport().get_camera_2d()
	if not camera: return
	
	for indicator in world_overlay.get_children():
		if not indicator.has_meta("world_pos"): continue
		
		var world_pos = indicator.get_meta("world_pos")
		# 将世界坐标转换为屏幕 Canvas 坐标
		# 注意：CanvasLayer 节点下的 UI 需要根据 Camera 的 transform 进行转换
		var screen_pos = (world_pos - camera.get_screen_center_position()) * camera.zoom + get_viewport_rect().size / 2.0
		indicator.position = screen_pos

func _on_npc_gui_input(event: InputEvent, npc_name: String) -> void:
	if event is InputEventMouseButton and event.pressed:
		dragging_npc = npc_name
		print("开始分配 NPC: ", npc_name)

func _on_house_clicked(house_id: String) -> void:
	if dragging_npc != "":
		SettlementManager.assign_npc_to_house(dragging_npc, house_id)
		dragging_npc = ""
		refresh_all()
