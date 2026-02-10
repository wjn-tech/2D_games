extends VBoxContainer

@onready var time_label: Label = $TimeLabel
@onready var weather_label: Label = $WeatherLabel
@onready var biome_label: Label = $BiomeLabel
@onready var tile_label: Label = $TileLabel

func _ready() -> void:
	# 初始显示
	_update_display()
	
	# 绑定信号
	if Chronometer:
		Chronometer.minute_passed.connect(_on_time_updated)
	
	if WeatherManager:
		WeatherManager.weather_changed.connect(_on_weather_updated)

func _process(_delta: float) -> void:
	# 每帧或间隔更新生态显示 (根据玩家位置)
	_update_biome_display()
	_update_tile_info()

func _update_tile_info() -> void:
	if not tile_label: return
	
	# 1. 优先检查鼠标下的实体 (建筑组件、宝箱等)
	var space_state = get_tree().root.get_world_2d().direct_space_state
	var mouse_pos = get_global_mouse_position()
	
	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_viewport().get_mouse_position() # UI 坐标
	# 将屏幕坐标转为世界坐标进行物理查询
	var camera = get_viewport().get_camera_2d()
	if camera:
		query.position = camera.get_screen_center_position() + (get_viewport().get_mouse_position() - get_viewport_rect().size / 2) / camera.zoom
	else:
		query.position = mouse_pos

	var results = space_state.intersect_point(query)
	for result in results:
		var target = result.collider
		if target.has_method("get") and target.get("building_name"):
			tile_label.text = "物体: " + target.building_name
			tile_label.visible = true
			return
		elif target.is_in_group("interactable"):
			tile_label.text = "Object: Interactable"
			tile_label.visible = true
			return

	# 2. 如果没有实体，检查 TileMap
	var layer_mgr = get_tree().get_first_node_in_group("layer_manager") if has_node("/root/LayerManager") else null
	
	# 关键修复：获取正确的视角空间中的鼠标位置
	var active_layer: TileMapLayer = null
	if LayerManager and LayerManager.get("current_layer_instance"):
		active_layer = LayerManager.current_layer_instance
	else:
		active_layer = get_tree().get_first_node_in_group("world_tiles")
		
	if not active_layer:
		tile_label.text = ""
		return

	# 使用 active_layer 的坐标系来获取鼠标的全局位置
	var mouse_world_pos = active_layer.get_global_mouse_position()
	var map_pos = active_layer.local_to_map(active_layer.to_local(mouse_world_pos))
	var tile_data = active_layer.get_cell_tile_data(map_pos)
	
	if tile_data:
		# 优先使用 DiggingManager 的逻辑
		var tile_name = "Unknown Tile"
		var digging_mgr = get_tree().get_first_node_in_group("digging_manager")
		
		# 尝试从 DiggingManager 实例或全局名称查找
		if not digging_mgr and has_node("/root/DiggingManager"):
			digging_mgr = get_node("/root/DiggingManager")
		elif not digging_mgr:
			# 尝试在场景中查找
			digging_mgr = get_tree().root.find_child("DiggingManager", true, false)
			
		if digging_mgr and digging_mgr.has_method("get_tile_display_name"):
			tile_name = digging_mgr.get_tile_display_name(active_layer, map_pos)
		else:
			# 回退逻辑 (如果找不到 DiggingManager)
			var atlas_coords = active_layer.get_cell_atlas_coords(map_pos)
			var source_id = active_layer.get_cell_source_id(map_pos)
			
			if source_id == 3: tile_name = "Grass"
			elif source_id == 1:
				if atlas_coords == Vector2i(36, 35): tile_name = "Dirt"
				elif atlas_coords == Vector2i(52, 52): tile_name = "Stone"
		
		tile_label.text = "Tile: " + tile_name
		tile_label.visible = true
	else:
		tile_label.visible = false

func _update_biome_display() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var world_gen = get_tree().get_first_node_in_group("world_generator")
	
	if player and world_gen and biome_label:
		var weights = world_gen.get_biome_weights_at_pos(player.global_position)
		var main_biome = 0
		var max_w = -1.0
		for b in weights:
			if weights[b] > max_w:
				max_w = weights[b]
				main_biome = b
		
		# 映射枚举到名称
		var names = ["Forest", "Plains", "Desert", "Tundra", "Swamp", "Underground", "Und. Desert", "Und. Tundra", "Und. Swamp"]
		if main_biome < names.size():
			biome_label.text = "Biome: " + names[main_biome]
		else:
			biome_label.text = "Biome: Unknown"

func _on_time_updated(_m, _h) -> void:
	_update_display()

func _on_weather_updated(_type) -> void:
	_update_display()

func _update_display() -> void:
	if Chronometer:
		var time_str = Chronometer.get_time_string()
		var phase = Chronometer.get_time_phase()
		var phase_icon = ""
		match phase:
			"Dawn": phase_icon = "🌅 "
			"Day": phase_icon = "☀️ "
			"Dusk": phase_icon = "🌇 "
			"Night": phase_icon = "🌙 "
		
		time_label.text = phase_icon + time_str
	
	if WeatherManager:
		var w_name = "Sunny"
		match WeatherManager.current_weather:
			0: w_name = "Sunny"
			1: w_name = "Rainy"
			2: w_name = "Snowy"
			3: w_name = "Thunderstorm"
		weather_label.text = "Weather: " + w_name
