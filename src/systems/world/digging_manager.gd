extends Node2D
class_name DiggingManager

## DiggingManager
## 处理 TileMap 的挖掘逻辑、稿力检查与资源再生。

signal tile_mined(coords: Vector2i, tile_data: Dictionary)

@export var tile_map: Node # 改为 Node 以兼容 TileMap 和 TileMapLayer
@export var mining_layer: int = 0

@onready var loot_scene = preload("res://scenes/world/loot_item.tscn")
var cracking_layer: TileMapLayer
var dust_particles: CPUParticles2D

# 碎裂 Atlas 坐标映射 (0-9 帧)
var cracking_atlas_coords = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1)
]

# 存储正在再生的资源: { coords: { "id": int, "source_id": int, "atlas_coords": Vector2i, "respawn_time": float } }
var respawn_queue: Dictionary = {}

# 挖掘进度: { coords: float }
var mining_progress_map: Dictionary = {}

func _ready() -> void:
	# 初始化碎裂渲染层 (使用一个新的 TileMapLayer)
	cracking_layer = TileMapLayer.new()
	cracking_layer.name = "CrackingLayer"
	cracking_layer.z_index = 10 
	cracking_layer.collision_enabled = false
	add_child(cracking_layer)
	
	# 程序化创建碎裂贴图源
	_setup_cracking_tileset()
	
	# 初始化尘土粒子池
	_setup_dust_particles()
	
	# 如果没有手动指定 TileMap，尝试在场景中寻找
	if not tile_map:
		var tree = get_tree()
		if tree:
			var nodes = tree.get_nodes_in_group("main_tilemap")
			if nodes.size() > 0:
				tile_map = nodes[0]
			else:
				# 备选方案：寻找第一个 TileMap 或 TileMapLayer
				var root = tree.current_scene
				if root:
					tile_map = _find_tilemap_recursive(root)

func _find_tilemap_recursive(node: Node) -> Node:
	if node.has_method("get_cell_source_id"):
		return node
	for child in node.get_children():
		var found = _find_tilemap_recursive(child)
		if found:
			return found
	return null

func _process(delta: float) -> void:
	_handle_respawn(delta)

## 持续挖掘逻辑
func mine_tile_step(coords: Vector2i, delta: float, pickaxe_power: int) -> bool:
	var ground_layer = _get_current_tile_map()
	if not ground_layer: 
		# print("DiggingManager: 未找到 TileMap!")
		return false
	
	var target_layer = ground_layer
	var tree_layer = _get_tree_layer(ground_layer)
	
	# 优先检查树木层
	if tree_layer:
		var tree_s_id = -1
		if tree_layer.has_method("get_layers_count"):
			tree_s_id = tree_layer.get_cell_source_id(mining_layer, coords)
		else:
			tree_s_id = tree_layer.get_cell_source_id(coords)
		
		if tree_s_id != -1:
			target_layer = tree_layer
	
	var s_id = -1
	if target_layer.has_method("get_layers_count"):
		s_id = target_layer.get_cell_source_id(mining_layer, coords)
	else:
		s_id = target_layer.get_cell_source_id(coords)
	
	if s_id == -1:
		reset_mining_progress(coords)
		return false
		
	var tile_data = _get_tile_data(target_layer, coords)
	
	var required_power = _get_custom_data(tile_data, target_layer, coords, "required_power", 0, Vector2i(-1,-1), s_id)
	var hardness = _get_custom_data(tile_data, target_layer, coords, "hardness", 1.0, Vector2i(-1,-1), s_id)
	
	# print("DiggingManager: 正在挖掘 ", coords, " 进度: ", mining_progress_map.get(coords, 0.0), "/", hardness)
	
	if pickaxe_power < required_power:
		# 可以在这里显示“稿力不足”的漂浮文字
		return false
		
	if not mining_progress_map.has(coords):
		mining_progress_map[coords] = 0.0
		
	mining_progress_map[coords] += delta
	
	# --- 视觉与粒子更新 ---
	var progress_ratio = mining_progress_map[coords] / hardness
	_update_cracking_visual(coords, progress_ratio, target_layer)
	_emit_dust_at(coords, target_layer)
	
	if mining_progress_map[coords] >= hardness:
		# 挖掘成功前清理视觉效果
		reset_mining_progress(coords)
		
		mining_progress_map.erase(coords)
		return try_mine_tile(coords, pickaxe_power)
		
	return false

func reset_mining_progress(coords: Vector2i):
	if mining_progress_map.has(coords):
		var ground_layer = _get_current_tile_map()
		if ground_layer:
			# 将瓦片坐标转换为全局层坐标以清除裂纹
			var target_coords = _get_global_layer_coords(coords, ground_layer)
			cracking_layer.set_cell(target_coords, -1)
		mining_progress_map.erase(coords)
	dust_particles.emitting = false

func _get_global_layer_coords(local_coords: Vector2i, from_layer: Node) -> Vector2i:
	# 将局部瓦片坐标映射回统一的 CrackingLayer 坐标系
	var world_pos = from_layer.to_global(from_layer.map_to_local(local_coords))
	return cracking_layer.to_local(world_pos) / 16 # 假设 16 像素瓦片

func _emit_dust_at(coords: Vector2i, target_layer: Node):
	dust_particles.global_position = target_layer.to_global(target_layer.map_to_local(coords))
	dust_particles.emitting = true
	
	# 根据材质动态调整粒子颜色
	var s_id = -1
	if target_layer.has_method("get_layers_count"):
		s_id = target_layer.get_cell_source_id(mining_layer, coords)
	else:
		s_id = target_layer.get_cell_source_id(coords)
		
	var particle_color = Color.BROWN
	if s_id == 3: particle_color = Color.FOREST_GREEN # Grass
	elif s_id == 1: particle_color = Color.GRAY # Stone
	
	dust_particles.modulate = particle_color

func _update_cracking_visual(coords: Vector2i, progress_ratio: float, target_layer: Node = null):
	var current_tile_map = target_layer
	if not current_tile_map:
		current_tile_map = _get_current_tile_map()
	if not current_tile_map: return
	
	var frame = clampi(floori(progress_ratio * 10), 0, 9)
	var atlas_pos = Vector2i(frame % 5, frame / 5)
	
	# 这里需要对齐两个 TileMapLayer 的坐标系
	# 统一使用 world 坐标作为基准转换
	var map_pos = _get_global_layer_coords(coords, current_tile_map)
	cracking_layer.set_cell(map_pos, 0, atlas_pos)

func _get_current_tile_map() -> Node:
	if LayerManager and LayerManager.get_current_layer():
		return LayerManager.get_current_layer()
	return tile_map

func _get_tile_data(current_tile_map: Node, coords: Vector2i) -> TileData:
	if current_tile_map.has_method("get_layers_count"):
		return current_tile_map.get_cell_tile_data(mining_layer, coords)
	else:
		return current_tile_map.get_cell_tile_data(coords)

func _get_custom_data(tile_data: TileData, current_tile_map: Node, coords: Vector2i, key: String, default_val: Variant, provided_atlas: Vector2i = Vector2i(-1, -1), provided_source: int = -2) -> Variant:
	if tile_data and tile_data.has_custom_data(key):
		var val = tile_data.get_custom_data(key)
		if val != null and val != "" and val != 0:
			return val
	
	# 硬编码默认值，以防 TileSet 未配置
	var atlas_coords = provided_atlas
	var source_id = provided_source
	
	if current_tile_map:
		if current_tile_map.has_method("get_layers_count"):
			if atlas_coords == Vector2i(-1, -1):
				atlas_coords = current_tile_map.get_cell_atlas_coords(mining_layer, coords)
			if source_id == -2:
				source_id = current_tile_map.get_cell_source_id(mining_layer, coords)
		else:
			if atlas_coords == Vector2i(-1, -1):
				atlas_coords = current_tile_map.get_cell_atlas_coords(coords)
			if source_id == -2:
				source_id = current_tile_map.get_cell_source_id(coords)
		
	var world_gen = get_tree().get_first_node_in_group("world_generator")
	
	if key == "hardness":
		if world_gen:
			if source_id == world_gen.tree_source_id:
				# 检查是否属于 1x3 树根区域
				var r_origin = world_gen.tree_root_origin
				if atlas_coords.y == r_origin.y and atlas_coords.x >= r_origin.x and atlas_coords.x < r_origin.x + 3:
					return 1.2
				if atlas_coords == world_gen.tree_trunk_tile: return 1.0
				# 检查是否属于 3x3 树冠区域
				var c_origin = world_gen.tree_canopy_origin
				if atlas_coords.x >= c_origin.x and atlas_coords.x < c_origin.x + 3 and \
				   atlas_coords.y >= c_origin.y and atlas_coords.y < c_origin.y + 3:
					return 0.3
			
			if source_id == world_gen.grass_dirt_source_id: return 0.6
			
			# 检查生态系统专属块 (地表与深层)
			for b_key in world_gen.biome_params:
				var b_data = world_gen.biome_params[b_key]
				if atlas_coords == b_data["sub_block"]:
					return 0.8
				if atlas_coords == b_data["surface_block"]:
					return 0.6
				if atlas_coords == b_data["stone_block"]:
					return 1.5
					
			if atlas_coords == world_gen.dirt_tile: return 0.8
			if atlas_coords == world_gen.stone_tile: return 1.5
			if atlas_coords == world_gen.hard_rock_tile: return 3.0
			
			# 放置的木块
			if source_id == world_gen.tile_source_id and atlas_coords == Vector2i(3, 4): return 1.0
		
		# 强制保底硬度匹配
		if source_id == 3: return 0.6 # Grass
		if source_id == 1 and atlas_coords == Vector2i(0, 0): return 0.8 # Dirt
		if source_id == 1 and atlas_coords == Vector2i(1, 0): return 1.5 # Stone
		
		return 1.0
	
	if key == "drop_item":
		if world_gen:
			if source_id == world_gen.tree_source_id:
				return "res://data/items/wood.tres"
				
			if source_id == world_gen.grass_dirt_source_id: 
				return "res://data/items/dirt.tres"
			if source_id == world_gen.tile_source_id:
				# 检查生态系统专属块掉落
				for b_key in world_gen.biome_params:
					var b_data = world_gen.biome_params[b_key]
					if atlas_coords == b_data["sub_block"] or atlas_coords == b_data["surface_block"]:
						return "res://data/items/dirt.tres"
					if atlas_coords == b_data["stone_block"]:
						return "res://data/items/stone.tres"
						
				if atlas_coords == world_gen.dirt_tile: return "res://data/items/dirt.tres"
				if atlas_coords == world_gen.stone_tile: return "res://data/items/stone.tres"
				if atlas_coords == world_gen.hard_rock_tile: return "res://data/items/stone.tres"
				if atlas_coords == Vector2i(3, 4): return "res://data/items/wood.tres"
		
		# 强制保底匹配 (针对 TileSet 未能正确连接 WorldGenerator 的情况)
		if source_id == 3: return "res://data/items/dirt.tres" # Grass Source
		if source_id == 1 and atlas_coords == Vector2i(0, 0): return "res://data/items/dirt.tres" # Dirt Tile
		if source_id == 1 and atlas_coords == Vector2i(1, 0): return "res://data/items/stone.tres" # Stone Tile
		
	return default_val

## 尝试挖掘指定坐标的 Tile
func try_mine_tile(coords: Vector2i, pickaxe_power: int) -> bool:
	# 优先使用 LayerManager 的活跃层
	var ground_layer = _get_current_tile_map()
	if not ground_layer: return false
	
	# 寻找对应的树木图层
	var tree_layer = _get_tree_layer(ground_layer)
	
	# 优先检查树木图层
	if tree_layer and _do_mine_at_layer(tree_layer, coords, pickaxe_power):
		return true
		
	# 其次检查地面图层
	return _do_mine_at_layer(ground_layer, coords, pickaxe_power)

func _get_tree_layer(ground_layer: Node) -> Node:
	var idx = ground_layer.get_meta("layer_index", -1)
	if idx == -1: return null
	var layers = get_tree().get_nodes_in_group("map_layers")
	for l in layers:
		if l != ground_layer and l.get_meta("layer_index", -1) == idx:
			return l
	return null

func _do_mine_at_layer(current_tile_map: Node, coords: Vector2i, pickaxe_power: int) -> bool:
	var source_id = -1
	var tile_data: TileData = null
	
	# 首先清除裂纹显示，防止切换层时残留
	if cracking_layer:
		var map_pos = _get_global_layer_coords(coords, current_tile_map)
		cracking_layer.set_cell(map_pos, -1)
		
	# 兼容性处理：判断是 TileMap 还是 TileMapLayer
	if current_tile_map.has_method("get_layers_count"):
		source_id = current_tile_map.get_cell_source_id(mining_layer, coords)
		if source_id != -1:
			tile_data = current_tile_map.get_cell_tile_data(mining_layer, coords)
	else:
		source_id = current_tile_map.get_cell_source_id(coords)
		if source_id != -1:
			tile_data = current_tile_map.get_cell_tile_data(coords)
			
	if source_id == -1 or not tile_data:
		return false
		
	# 获取自定义属性
	var required_power = _get_custom_data(tile_data, current_tile_map, coords, "required_power", 0)
	var respawn_time = _get_custom_data(tile_data, current_tile_map, coords, "respawn_time", 0.0)
	
	if pickaxe_power < required_power:
		print("DiggingManager: 稿力不足! 需要: ", required_power)
		return false
		
	# 记录再生信息
	var atlas_coords = Vector2i(-1, -1)
	var alt_tile = 0
	if current_tile_map.has_method("get_layers_count"):
		atlas_coords = current_tile_map.get_cell_atlas_coords(mining_layer, coords)
		alt_tile = current_tile_map.get_cell_alternative_tile(mining_layer, coords)
	else:
		atlas_coords = current_tile_map.get_cell_atlas_coords(coords)
		alt_tile = current_tile_map.get_cell_alternative_tile(coords)

	if respawn_time > 0:
		respawn_queue[coords] = {
			"source_id": source_id,
			"atlas_coords": atlas_coords,
			"alternative_tile": alt_tile,
			"time_left": respawn_time
		}
	
	# --- 获取掉落物路径 (在移除之前或传递参数) ---
	var drop_path = _get_custom_data(tile_data, current_tile_map, coords, "drop_item", "", atlas_coords, source_id)
	
	# 移除 Tile
	if current_tile_map.has_method("get_layers_count"):
		current_tile_map.set_cell(mining_layer, coords, -1)
	else:
		current_tile_map.set_cell(coords, -1)
	
	# --- 生成掉落物 ---
	if drop_path != "":
		var drop_item = load(drop_path)
		if drop_item:
			var loot = loot_scene.instantiate()
			get_tree().current_scene.add_child(loot)
			loot.global_position = current_tile_map.to_global(current_tile_map.map_to_local(coords))
			# 使用 setup 而不是直接赋值
			if loot.has_method("setup"):
				loot.setup(drop_item, 1)
			else:
				loot.item_data = drop_item

	# --- 无限地图 Delta 记录与粒子反馈 ---
	var world_pos = current_tile_map.map_to_local(coords)
	if InfiniteChunkManager:
		var layer_idx = current_tile_map.get_meta("layer_index", 0)
		InfiniteChunkManager.record_delta(world_pos, layer_idx, -1)
		
		# 生成 Noita 风格碎片粒子
		var color = Color.BROWN
		if tile_data:
			# 尝试根据材质决定颜色，这里简单根据 Tile ID 判断
			if source_id == 3: color = Color.DARK_GREEN # Grass
			elif source_id == 1: color = Color.GRAY   # Stone
		InfiniteChunkManager.spawn_impact_particles(world_pos, color)
		
	# 特殊逻辑：如果是树根，自动砍倒整棵树
	var world_gen = get_tree().get_first_node_in_group("world_generator")
	if world_gen and source_id == world_gen.tree_source_id:
		var r_origin = world_gen.tree_root_origin
		# 检查是否属于 1x3 树根区域 (兼容大瓦片和独立瓦片)
		var is_root = false
		var offset = 0
		
		if atlas_coords == r_origin:
			# 大瓦片逻辑：通过向左探测找到起始位置 (水平 3x1)
			is_root = true
			var start_pos = coords
			while true:
				var prev = start_pos - Vector2i(1, 0)
				var s_id = -1
				var a_coords = Vector2i(-1, -1)
				if current_tile_map.has_method("get_layers_count"):
					s_id = current_tile_map.get_cell_source_id(mining_layer, prev)
					a_coords = current_tile_map.get_cell_atlas_coords(mining_layer, prev)
				else:
					s_id = current_tile_map.get_cell_source_id(prev)
					a_coords = current_tile_map.get_cell_atlas_coords(prev)
				
				if s_id == source_id and a_coords == r_origin:
					start_pos = prev
				else:
					break
			offset = coords.x - start_pos.x
		elif atlas_coords.y == r_origin.y and atlas_coords.x >= r_origin.x and atlas_coords.x < r_origin.x + 3:
			# 独立瓦片逻辑 (水平)
			is_root = true
			offset = atlas_coords.x - r_origin.x
			
		if is_root:
			_fell_tree(coords, current_tile_map, world_gen, offset)
		
	tile_mined.emit(coords, {"source_id": source_id})
	_spawn_loot(coords, tile_data, current_tile_map, atlas_coords)
	return true

func _fell_tree(mined_coords: Vector2i, target_map: Node, world_gen: WorldGenerator, root_offset: int) -> void:
	# 1. 清理剩下的树根部分 (水平 3x1)
	var root_start = mined_coords - Vector2i(root_offset, 0)
	for dx in range(3):
		var r_pos = root_start + Vector2i(dx, 0)
		if r_pos == mined_coords: continue # 已经被 try_mine_tile 移除了
		
		if target_map.has_method("get_layers_count"):
			target_map.set_cell(mining_layer, r_pos, -1)
		else:
			target_map.set_cell(r_pos, -1)

	# 2. 向上清理树干 (树干在树根中心上方，即 root_start + (1, -1))
	var trunk_count = 0
	var trunk_base_pos = root_start + Vector2i(1, -1)
	var current_pos = trunk_base_pos
	
	while true:
		var atlas = Vector2i(-1, -1)
		var s_id = -1
		if target_map.has_method("get_layers_count"):
			atlas = target_map.get_cell_atlas_coords(mining_layer, current_pos)
			s_id = target_map.get_cell_source_id(mining_layer, current_pos)
		else:
			atlas = target_map.get_cell_atlas_coords(current_pos)
			s_id = target_map.get_cell_source_id(current_pos)
			
		if s_id == world_gen.tree_source_id and atlas == world_gen.tree_trunk_tile:
			trunk_count += 1
			if target_map.has_method("get_layers_count"):
				target_map.set_cell(mining_layer, current_pos, -1)
			else:
				target_map.set_cell(current_pos, -1)
			current_pos += Vector2i(0, -1)
		else:
			break
	
	# 3. 清理树冠 (在最后一个树干位置上方)
	var canopy_center = current_pos
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var c_pos = canopy_center + Vector2i(dx, dy)
			var atlas = Vector2i(-1, -1)
			var s_id = -1
			if target_map.has_method("get_layers_count"):
				atlas = target_map.get_cell_atlas_coords(mining_layer, c_pos)
				s_id = target_map.get_cell_source_id(mining_layer, c_pos)
			else:
				atlas = target_map.get_cell_atlas_coords(c_pos)
				s_id = target_map.get_cell_source_id(c_pos)
				
			if s_id == world_gen.tree_source_id:
				var c_origin = world_gen.tree_canopy_origin
				if atlas.x >= c_origin.x and atlas.x < c_origin.x + 3 and \
				   atlas.y >= c_origin.y and atlas.y < c_origin.y + 3:
					if target_map.has_method("get_layers_count"):
						target_map.set_cell(mining_layer, c_pos, -1)
					else:
						target_map.set_cell(c_pos, -1)
	
	# 4. 额外掉落木材 (等同于树干数量 + 1 根部)
	var total_wood = trunk_count + 1
	var wood_res = load("res://data/items/wood.tres")
	if wood_res:
		for i in range(total_wood):
			var loot = loot_scene.instantiate()
			tile_map.get_parent().add_child(loot)
			# 在树根位置稍微偏移生成
			loot.global_position = tile_map.to_global(tile_map.map_to_local(mined_coords)) + Vector2(randf_range(-10, 10), randf_range(-10, 10))
			loot.setup(wood_res)

func _spawn_loot(coords: Vector2i, tile_data: TileData, current_tile_map: Node, atlas_coords: Vector2i) -> void:
	# 使用 map_to_local 获取中心点，然后转为全局坐标
	var local_pos = current_tile_map.map_to_local(coords)
	var world_pos = current_tile_map.to_global(local_pos)
	
	# 尝试从 TileData 获取掉落物资源路径
	var item_path = _get_custom_data(tile_data, current_tile_map, coords, "drop_item", "", atlas_coords)
	
	# print("DiggingManager: 尝试生成掉落物, 路径: ", item_path, " atlas: ", atlas_coords)
	
	if item_path != "":
		var item_res = load(item_path)
		if item_res and item_res is BaseItem:
			# 实例化物理掉落物
			var loot = loot_scene.instantiate()
			# 将掉落物添加到与 TileMap 相同的父节点下，确保坐标系一致
			current_tile_map.get_parent().add_child(loot)
			loot.global_position = world_pos
			loot.setup(item_res)
			print("DiggingManager: 挖掘成功，生成掉落物: ", item_res.display_name, " 位置: ", world_pos)
		else:
			push_warning("DiggingManager: 无法加载物品资源: " + item_path)
	else:
		print("DiggingManager: 挖掘成功，但该 Tile 未配置 drop_item 属性。")

func _setup_cracking_tileset():
	# 创建一个包含 10 帧裂纹效果的动态 TileSet
	var ts = TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	
	# 画布生成：2列 5行 的裂纹纹理 (5*2=10帧)
	var img = Image.create(80, 32, false, Image.FORMAT_RGBA8)
	for f in range(10):
		var ox = (f % 5) * 16
		var oy = (f / 5) * 16
		# 每一帧增加裂纹密度
		var crack_count = (f + 1) * 3
		for i in range(crack_count):
			var rx = randi() % 14 + 1
			var ry = randi() % 14 + 1
			img.set_pixel(ox + rx, oy + ry, Color(0, 0, 0, 0.8)) # 深色裂痕
			if f > 5: # 严重碎裂阶段增加边缘
				img.set_pixel(ox + rx + 1, oy + ry, Color(0, 0, 0, 0.4))
	
	var tex = ImageTexture.create_from_image(img)
	var source = TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(16, 16)
	for f in range(10):
		source.create_tile(Vector2i(f % 5, f / 5))
	
	ts.add_source(source, 0)
	cracking_layer.tile_set = ts

func _setup_dust_particles():
	dust_particles = CPUParticles2D.new()
	dust_particles.name = "DiggingDust"
	dust_particles.emitting = false
	dust_particles.amount = 15
	dust_particles.lifetime = 0.4
	dust_particles.one_shot = false
	dust_particles.explosiveness = 0.2
	dust_particles.spread = 180.0
	dust_particles.gravity = Vector2(0, 400)
	dust_particles.initial_velocity_min = 40.0
	dust_particles.initial_velocity_max = 80.0
	dust_particles.scale_amount_min = 1.0
	dust_particles.scale_amount_max = 3.0
	dust_particles.direction = Vector2(0, -1)
	add_child(dust_particles)

func _handle_respawn(delta: float) -> void:
	var to_remove = []
	for coords in respawn_queue:
		respawn_queue[coords]["time_left"] -= delta
		if respawn_queue[coords]["time_left"] <= 0:
			var data = respawn_queue[coords]
			if tile_map.has_method("get_layers_count"):
				tile_map.set_cell(mining_layer, coords, data["source_id"], data["atlas_coords"], data["alternative_tile"])
			else:
				tile_map.set_cell(coords, data["source_id"], data["atlas_coords"], data["alternative_tile"])
			to_remove.append(coords)
			print("DiggingManager: 资源已再生: ", coords)
			
	for coords in to_remove:
		respawn_queue.erase(coords)
