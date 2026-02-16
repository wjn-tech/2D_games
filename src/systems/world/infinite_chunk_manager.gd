extends Node

## InfiniteChunkManager (Autoload)
## 负责地图区块的生命周期管理、坐标转换和异步加载。

const CHUNK_SIZE = 64
const TILE_SIZE = 16
const LOAD_RADIUS = 2 # 加载半径（区块单位）

var active_save_root: String = "user://saves/world_deltas/"

# 内存中的区块缓存: { Vector2i: WorldChunk }
var loaded_chunks: Dictionary = {}
# 当前区块内已实例化的节点容器: { Vector2i: Node2D }
var chunk_entity_containers: Dictionary = {}
# 所有的 Delta 数据（即使区块被卸载也保留）: { Vector2i: WorldChunk }
var world_delta_data: Dictionary = {}

var current_session_id: int = 0
const TransformHelper = preload("res://src/utils/transform_helper.gd")

signal chunk_loaded(coord: Vector2i)
signal chunk_unloaded(coord: Vector2i)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 默认路径初始化，实际应由 SaveManager 设置
	_ensure_save_dir()
	
func restart() -> void:
	print("InfiniteChunkManager: Restarting world state...")
	current_session_id += 1 # 增加 Session ID 以使旧的异步任务失效
	loaded_chunks.clear()
	_loading_queue.clear()
	
	# Fix: Explicitly destroy old entity containers (since they are on Main scene, not WorldGenerator)
	for container in chunk_entity_containers.values():
		if is_instance_valid(container):
			container.queue_free()
	chunk_entity_containers.clear()
	
	# 如果是新游戏，我们必须清空之前保存的所有区块 Delta
	world_delta_data.clear()
	
	_wipe_save_data_debug() # 彻底清理磁盘上的旧区块文件
	
	# 重置最后玩家位置，强制立刻更新
	update_player_vicinity(Vector2(0, -999999)) # Force update on next frame

func set_save_root(path_root: String) -> void:
	# e.g. "user://saves/slot_1/world/"
	active_save_root = path_root
	_ensure_save_dir()
	print("InfiniteChunkManager: 存档路径已切换至 ", active_save_root)
	
	# 切换存档时清空缓存（注意：这应该在游戏重新开始时调用，而不是运行时热切换）
	world_delta_data.clear()
	loaded_chunks.clear()

func save_all_deltas() -> void:
	for coord in world_delta_data:
		var chunk = world_delta_data[coord]
		var path = _get_save_path(coord)
		ResourceSaver.save(chunk, path)
	print("InfiniteChunkManager: 所有区块修改已保存。")

func _wipe_save_data_debug() -> void:
	# 简单暴力的清理
	var dir = DirAccess.open(active_save_root)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		print("InfiniteChunkManager: 已强制清理旧区块存档。")

func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(active_save_root):
		DirAccess.make_dir_recursive_absolute(active_save_root)

func _get_save_path(coord: Vector2i) -> String:
	return active_save_root + "chunk_%d_%d.tres" % [coord.x, coord.y]

## 获取世界坐标所属的区块坐标
func get_chunk_coord(world_pos: Vector2) -> Vector2i:
	var tile_pos = Vector2i((world_pos / TILE_SIZE).floor())
	return Vector2i((Vector2(tile_pos) / CHUNK_SIZE).floor())

## 获取区块内局部坐标
func get_local_tile_pos(world_pos: Vector2) -> Vector2i:
	var tile_pos = Vector2i((world_pos / TILE_SIZE).floor())
	return Vector2i(
		posmod(tile_pos.x, CHUNK_SIZE),
		posmod(tile_pos.y, CHUNK_SIZE)
	)

## 记录玩家修改
func record_delta(world_pos: Vector2, layer_idx: int, source_id: int, atlas_coords: Vector2i = Vector2i.ZERO) -> void:
	var c_coord = get_chunk_coord(world_pos)
	var l_pos = get_local_tile_pos(world_pos)
	
	if not world_delta_data.has(c_coord):
		# 尝试从磁盘加载
		var path = _get_save_path(c_coord)
		if FileAccess.file_exists(path):
			world_delta_data[c_coord] = ResourceLoader.load(path)
		else:
			world_delta_data[c_coord] = WorldChunk.new()
			world_delta_data[c_coord].coord = c_coord
	
	world_delta_data[c_coord].add_delta(layer_idx, l_pos, source_id, atlas_coords)
	
	# 同步更新小地图
	if MinimapManager and MinimapManager.has_method("update_tile_at_pos"):
		MinimapManager.update_tile_at_pos(world_pos, source_id, atlas_coords)

## 更新玩家周边的区块加载状态
func update_player_vicinity(player_pos: Vector2) -> void:
	var needed_chunks = []
	
	# 增加对 0 点附近的检查，并确保玩家位置发生显著变化再更新
	var center_chunk = get_chunk_coord(player_pos)
	
	for x in range(center_chunk.x - LOAD_RADIUS, center_chunk.x + LOAD_RADIUS + 1):
		for y in range(center_chunk.y - LOAD_RADIUS, center_chunk.y + LOAD_RADIUS + 1):
			needed_chunks.append(Vector2i(x, y))
	
	# 卸载不再需要的区块
	var to_unload = []
	for coord in loaded_chunks.keys():
		if not coord in needed_chunks:
			to_unload.append(coord)
	
	for coord in to_unload:
		_unload_chunk(coord)
		
	# 加载新区块
	for coord in needed_chunks:
		if not loaded_chunks.has(coord) and not _loading_queue.has(coord):
			_request_chunk_load(coord)

var _loading_queue: Dictionary = {}

func _request_chunk_load(coord: Vector2i) -> void:
	_loading_queue[coord] = true
	WorkerThreadPool.add_task(_async_load_task.bind(coord, current_session_id))

func _async_load_task(coord: Vector2i, session_id: int) -> void:
	# 如果 Session ID 不匹配，说明是上一局残留的任务，直接退出
	if session_id != current_session_id:
		return
		
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not is_instance_valid(generator): 
		_loading_queue.erase(coord)
		return
		
	var cells = generator.generate_chunk_cells(coord)
	var spawned_entities = []
	
	# 记录原始地表高度（用于树木生成避开建筑遮挡）
	var natural_ground_y = []
	for x in range(64):
		natural_ground_y.append(_get_top_tile_y(cells, x))
	
	# --- 插入特定结构 (Wang Tile / POI) ---
	_apply_structures(coord, cells, spawned_entities)
	
	# --- 插入树木 (仅地表 Chunk) ---
	_apply_trees(coord, cells, natural_ground_y)
	
	# 回到主线程应用结果 (TileMap 修改必须在主线程)
	call_deferred("_finalize_chunk_load", coord, cells, spawned_entities)

func _get_top_tile_y(cells: Dictionary, local_x: int) -> int:
	# 在 Layer 0 中寻找该 X 坐标的“真正的”地面 (非空且上方为空)
	if not cells.has(0): return -1
	for y in range(1, 64):
		var pos = Vector2i(local_x, y)
		var pos_above = Vector2i(local_x, y - 1)
		
		# 规则：当前格有瓦片，且上方格没有瓦片 (或者是空气)
		if cells[0].has(pos) and not cells[0].has(pos_above):
			return y
	# 边界情况：如果第 0 行就是地面
	if cells[0].has(Vector2i(local_x, 0)): return 0
	return -1

func get_chunk_hash(c_coord: Vector2i) -> int:
	# 引入世界种子作为额外的盐值，确保每局游戏的结构位置都不同
	var seed_salt = 0
	var gen = get_tree().get_first_node_in_group("world_generator")
	if gen and "seed_value" in gen:
		seed_salt = gen.seed_value
	
	var x = c_coord.x + 12345 + (seed_salt % 9999)
	var y = c_coord.y + 67890 + (seed_salt / 9999)
	return abs((x * 73856093) ^ (y * 19349663) ^ 5381 ^ seed_salt)

func _get_chunk_world_origin(c_coord: Vector2i) -> Vector2:
	return Vector2(c_coord.x * CHUNK_SIZE * TILE_SIZE, c_coord.y * CHUNK_SIZE * TILE_SIZE)

func _apply_structures(coord: Vector2i, chunk_data: Dictionary, entities_out: Array) -> void:
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not generator: return

	chunk_data["_coord"] = coord
	var is_surface_chunk = coord.y >= 4 and coord.y <= 7
	
	for dx in range(-2, 3): # 扩大检测范围，确保较宽的房屋能完整跨区块
		var check_coord = coord + Vector2i(dx, 0)
		var hash_val = get_chunk_hash(check_coord)
		
		if is_surface_chunk and hash_val % 12 == 0:
			var center_x_local = hash_val % 30 + 15
			# 严格使用整数像素偏差
			var global_house_x_tiles = check_coord.x * 64 + center_x_local
			
			# 安全保护：在世界原点附近 (Spawn Point) ±120 格范围内禁止生成结构，防止出生点被房子卡住
			if abs(global_house_x_tiles) < 120:
				continue
			
			# 高度扫描：扫描房子宽度的地面高度，取全宽度内的最高点（Y值最小）作为基准
			# 防止房子门口被埋在地下
			var house_half_width = 18 # 约 35/2
			var min_y_in_range = 99999
			for scan_x in range(global_house_x_tiles - house_half_width, global_house_x_tiles + house_half_width):
				var gy = _get_stable_ground_y(scan_x)
				if gy < min_y_in_range:
					min_y_in_range = gy
			
			# 稍微抬高一格，确保不切土
			var global_base_y = min_y_in_range
			
			var local_x = global_house_x_tiles - (coord.x * 64)
			var local_y = global_base_y - (coord.y * 64)
			
			# 只要房屋的一部分可能在该区块内，就调用生成逻辑
			# 房屋宽度约 35，高度约 20
			if local_x > -40 and local_x < 100 and local_y > -40 and local_y < 100:
				_generate_tile_house(chunk_data, Vector2i(local_x, local_y), entities_out)

		# 彻底移除随机矿井生成，防止地平线出现垂直空洞大坑
		# if dx == 0 and hash_val % 100 == 0:
		# 	_apply_shaft(chunk_data, hash_val)

	# 情况 3: 埋没遗迹
	if coord.y > 6 and get_chunk_hash(coord) % 15 == 0:
		_apply_ruins(coord, chunk_data, get_chunk_hash(coord))

func _get_stable_ground_y(global_x: int) -> int:
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not generator: return 300
	
	# 重复生成器中的平坦化逻辑
	var spawn_x = 0
	var dist_to_spawn_x = abs(global_x - spawn_x)
	var spawn_flat_weight = clamp(float(dist_to_spawn_x) / 64.0, 0.0, 1.0)
	
	var biome_amp = 0.0
	var primary_biome = generator.get_biome_at(global_x, 0) # 传入 0 获取地表生态
	
	# 简化：直接使用主要生态的参数 (既然现在是 2D 自然切分，不需要线性混合高度)
	if generator.biome_params.has(primary_biome):
		biome_amp = generator.biome_params[primary_biome]["amp"]
	else:
		biome_amp = 60.0
	
	var cont_val = generator.noise_continental.get_noise_1d(global_x)
	var blended_cont_val = lerp(0.0, cont_val, spawn_flat_weight)
	
	# 严格同步 generator.gd: var surface_base = 300.0 + (blended_cont_val * biome_amp)
	# 瓦片 Y 是 global_y > surface_base。
	# 例如 surface_base = 300.0，则 301 为第一个实心。
	# 我们返回 301 作为房屋底座所在高度
	var surface_base = 300.0 + (blended_cont_val * biome_amp)
	return int(floor(surface_base)) + 1

func _apply_shaft(chunk_data: Dictionary, hash_val: int) -> void:
	var start_x = hash_val % 40 + 10
	for y in range(64):
		for x in range(start_x, start_x + 6):
			var p = Vector2i(x,y)
			for l in [0,1,2]:
				if chunk_data.has(l): chunk_data[l][p] = {"source": -1, "atlas": Vector2i(-1,-1)}

# --- 建筑设计师模式：在此定义您的精美房屋蓝图 ---
# 您可以使用任何字符，并在下方的 _generate_tile_house 中定义它们的含义
const MY_CUSTOM_HOUSE_DESIGN = [
	"             AAAAAAAAA             ",
	"     AAAAAAAAAAAAAAAAAAAAAAAAA     ",
	"      A   AAAAA     AAAAA   A      ",
	"       A AAAA         AAAA A       ",
	"        ###################        ",
	"        #.................#        ",
	"        #.................#        ",
	"        #.................#        ",
	"        #.................#        ",
	"        #.................#        ",
	"        #.................#        ",
	"        #.................#        ",
	"        #.................#        ",
	"        #.................#        ",
	"        D.................D        ",
	"        D.................D        ",
	"        D.................D        ",
	"        D...........CCC...D        ",
	"        D.......M...CCC...D        ",
	"        ###################        ",
	"        ###################        "
]

func _generate_tile_house(chunk_data: Dictionary, base_pos: Vector2i, entities_out: Array) -> void:
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not generator: return
	
	var s_id = generator.tile_source_id
	var palette = {
		"#": {"type": "tile", "layer": 0, "source": s_id, "atlas": generator.stone_tile},
		"A": {"type": "tile", "layer": 0, "source": s_id, "atlas": generator.hard_rock_tile}, # 屋顶
		".": {"type": "tile", "layer": 1, "source": s_id, "atlas": generator.dirt_tile},      # 室内背景
		"+": {"type": "tile", "layer": 0, "source": s_id, "atlas": generator.hard_rock_tile}, # 梁柱 (有碰撞)
		"D": {"type": "special", "tag": "door", "bg": generator.dirt_tile},                  # 门及其背景
		"C": {"type": "special", "tag": "chest", "bg": generator.dirt_tile},                 # 箱子及其背景
		"M": {"type": "special", "tag": "merchant", "bg": generator.dirt_tile},              # 商人
		" ": {"type": "air"}
	}
	
	var design = MY_CUSTOM_HOUSE_DESIGN
	var house_height = design.size()
	var house_width = design[0].length()
	var processed_positions = {}
	
	var my_coord = chunk_data.get("_coord", Vector2i.ZERO)
	
	for row_idx in range(house_height):
		var y_offset = house_height - 1 - row_idx
		for x_idx in range(house_width):
			if processed_positions.has(Vector2i(x_idx, row_idx)): continue
			
			var char = design[row_idx][x_idx]
			# base_pos 现在被视为房屋底座所在 Tile
			var p = base_pos + Vector2i(x_idx, -y_offset)
			
			var item = palette.get(char, {"type": "air"})
			if item.get("type") == "air": continue
			
			# 严格计算全局坐标（Tile单位）
			var global_tile_x = my_coord.x * 64 + p.x
			var global_tile_y = my_coord.y * 64 + p.y
			
			var is_in_this_chunk = (
				global_tile_x >= my_coord.x * 64 and global_tile_x < (my_coord.x + 1) * 64 and
				global_tile_y >= my_coord.y * 64 and global_tile_y < (my_coord.y + 1) * 64
			)
			
			var local_p = Vector2i(
				global_tile_x - my_coord.x * 64,
				global_tile_y - my_coord.y * 64
			)
			
			if is_in_this_chunk:
				if not chunk_data.has(0): chunk_data[0] = {}
				if not chunk_data.has(1): chunk_data[1] = {}
				
				# 仅在非空气位置进行挖掘。如果 design 是 ' '，保留原地形。
				if item["type"] != "air":
					# 基础挖掘
					chunk_data[0][local_p] = {"source": -1, "atlas": Vector2i(-1,-1)}
					chunk_data[1][local_p] = {"source": -1, "atlas": Vector2i(-1,-1)}
					
					if item["type"] == "tile":
						chunk_data[item["layer"]][local_p] = {"source": item["source"], "atlas": item["atlas"]}
					elif item["type"] == "special":
						# 特殊实体通常需要一个背景方块，否则看起来是空洞
						if item.has("bg"):
							chunk_data[1][local_p] = {"source": s_id, "atlas": item["bg"]}

			# 实体判定逻辑
			if item["type"] == "special":
				var is_owner = false
				var entity_data = {}
				
				if item["tag"] == "door":
					var door_h = 0
					var cr = row_idx
					while cr < house_height and design[cr][x_idx] == "D":
						processed_positions[Vector2i(x_idx, cr)] = true
						cr += 1
						door_h += 1
					
					var bottom_tile_y = global_tile_y + door_h - 1
					var owner_x = int(floor(float(global_tile_x) / 64.0))
					var owner_y = int(floor(float(bottom_tile_y) / 64.0))
					
					if owner_x == my_coord.x and owner_y == my_coord.y:
						is_owner = true
						entity_data = {
							"scene_path": "res://scenes/world/interactive_door.tscn",
							"pos": Vector2(global_tile_x * TILE_SIZE, (bottom_tile_y + 1) * TILE_SIZE),
							"data": {"height": door_h}
						}
				elif item["tag"] == "chest":
					var owner_x = int(floor(float(global_tile_x) / 64.0))
					var owner_y = int(floor(float(global_tile_y) / 64.0))
					if owner_x == my_coord.x and owner_y == my_coord.y:
						is_owner = true
						entity_data = {
							"scene_path": generator.chest_scene.resource_path,
							"pos": Vector2(global_tile_x * TILE_SIZE, global_tile_y * TILE_SIZE),
							"data": {}
						}
					processed_positions[Vector2i(x_idx, row_idx)] = true
				
				elif item["tag"] == "merchant":
					var owner_x = int(floor(float(global_tile_x) / 64.0))
					var owner_y = int(floor(float(global_tile_y) / 64.0))
					if owner_x == my_coord.x and owner_y == my_coord.y:
						is_owner = true
						# 尝试查找已配置的 merchant 场景或使用通用 NPC
						var merch_scene = "res://scenes/npc/merchant.tscn"
						entity_data = {
							"scene_path": merch_scene,
							"pos": Vector2(global_tile_x * TILE_SIZE + 8, (global_tile_y + 1) * TILE_SIZE - 2), # 稍微对齐到地面
							"data": {"npc_name": "Merchant", "role": "Merchant"}
						}
					processed_positions[Vector2i(x_idx, row_idx)] = true

				if is_owner:
					entities_out.append(entity_data)

	# --- 自动地基填充：防止房子悬空 ---
	for x_idx in range(house_width):
		# 检查设计图的最底层是否为实体（非空气）
		var bottom_char = design[house_height - 1][x_idx]
		if bottom_char == " ": continue
		
		var global_tile_x = my_coord.x * 64 + base_pos.x + x_idx
		var real_ground_index = _get_stable_ground_y(global_tile_x) # 地面其实是这个值-1，但这个值是首个实心块，正好对接
		var global_base_y = my_coord.y * 64 + base_pos.y
		
		# 如果房子底部 (BaseY) 高于 真实地面 (RealGroundY)，中间需要填充
		# 填充范围：(BaseY + 1) -> RealGroundIndex
		if real_ground_index > global_base_y:
			for f_y in range(global_base_y + 1, real_ground_index + 1):
				# 检查该高度是否在本 Chunk 范围内
				if f_y >= my_coord.y * 64 and f_y < (my_coord.y + 1) * 64:
					var g_x = global_tile_x
					
					# 检查 X 是否在本 Chunk 范围内
					if g_x >= my_coord.x * 64 and g_x < (my_coord.x + 1) * 64:
						var local_p = Vector2i(g_x - my_coord.x * 64, f_y - my_coord.y * 64)
						
						if not chunk_data.has(0): chunk_data[0] = {}
						if not chunk_data.has(1): chunk_data[1] = {}
						
						# 地基填充石块
						chunk_data[0][local_p] = {"source": s_id, "atlas": generator.stone_tile}
						# 必须填充背景，防止露出天空
						chunk_data[1][local_p] = {"source": s_id, "atlas": generator.dirt_tile}

func _apply_ruins(coord: Vector2i, chunk_data: Dictionary, hash_val: int) -> void:
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not generator: return
	
	# 情况 3: 埋没遗迹 (Layer 1)
	if coord.y > 6 and hash_val % 15 == 0:
		var rx = hash_val % 30 + 15
		var ry = hash_val % 30 + 15
		for ox in range(-5, 6):
			for oy in range(-4, 5):
				var p = Vector2i(rx + ox, ry + oy)
				if p.x >=0 and p.x < 64 and p.y >=0 and p.y < 64:
					if not chunk_data.has(1):
						chunk_data[1] = {}
					
					if abs(ox) == 5 or abs(oy) == 4:
						# 使用动态 Source ID (根据 WorldGenerator 设置)，确认为有效贴图且有碰撞
						chunk_data[1][p] = {"source": generator.tile_source_id, "atlas": generator.stone_tile}
					else:
						# 遗迹内部掏空
						chunk_data[1][p] = {"source": -1, "atlas": Vector2i(-1,-1)}

func _apply_trees(coord: Vector2i, cells: Dictionary, ground_y_list: Array) -> void:
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not generator: return
	
	# 树木目前只在地表层附近生成
	if coord.y < 4 or coord.y > 6: return
	
	# 使用专门的生成器以确保线程安全且确定性
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(str(generator.seed_value) + "_" + str(coord.x) + "_" + str(coord.y) + "_trees")
	
	for x in range(2, 62): # 留出边缘
		var gx = coord.x * 64 + x
		var ly = ground_y_list[x]
		if ly == -1 or ly < 5 or ly > 60: continue 
		
		# --- 垂直空间安全检测 ---
		# 检查树木上方是否有岩石或地形阻挡 (避免树冠插进天花板)
		var is_obstructed = false
		for check_y in range(1, 10):
			# 树冠宽 3 格 (x-1, x, x+1)，都要检查
			for offset_x in range(-1, 2):
				var check_pos = Vector2i(x + offset_x, ly - check_y)
				if cells.has(0) and cells[0].has(check_pos) and cells[0][check_pos]["source"] != -1:
					is_obstructed = true
					break
			if is_obstructed: break
		
		if is_obstructed: continue

		var gy = coord.y * 64 + ly
		
		if generator.should_spawn_tree_at(gx, gy):
			_generate_tree_at(cells, Vector2i(x, ly), rng)

func _generate_tree_at(cells: Dictionary, local_pos: Vector2i, rng: RandomNumberGenerator) -> void:
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not generator: return
	
	var tree_layer_idx = 10 # 地表树木层
	if not cells.has(tree_layer_idx): cells[tree_layer_idx] = {}
	
	var sid = generator.tree_source_id
	
	# 1. 树根 (3x1)
	var root_y = local_pos.y - 1
	var root_tiles = [generator.tree_root_left, generator.tree_root_mid, generator.tree_root_right]
	for dx in range(-1, 2):
		var p = Vector2i(local_pos.x + dx, root_y)
		cells[tree_layer_idx][p] = {"source": sid, "atlas": root_tiles[dx + 1]}
			
	# 2. 树干 (随机 3-5 节)
	var trunk_h = rng.randi_range(3, 5)
	# Explicitly check for wood tile at (1,2)
	var trunk_atlas = generator.tree_trunk_tile
	for i in range(1, trunk_h + 1):
		var p = Vector2i(local_pos.x, root_y - i)
		cells[tree_layer_idx][p] = {"source": sid, "atlas": trunk_atlas}
			
	# 3. 树冠 (3x3)
	var canopy_center_y = root_y - trunk_h - 1
	var canopy_tile = generator.tree_canopy_tile
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var p = Vector2i(local_pos.x + dx, canopy_center_y + dy)
			# Minimalist: Reuse single leaf tile for entire canopy
			cells[tree_layer_idx][p] = {"source": sid, "atlas": canopy_tile}

func _finalize_chunk_load(coord: Vector2i, cells: Dictionary, new_entities: Array = []) -> void:
	# 如果是异步任务触发的，清理队列。如果是强制同步加载的，可能不在队列中
	if _loading_queue.has(coord):
		_loading_queue.erase(coord)
	
	# 双重加载检查：如果此时已经有其他地方加载了该区块，直接返回
	if loaded_chunks.has(coord) or chunk_entity_containers.has(coord):
		return

	var chunk: WorldChunk
	var path = _get_save_path(coord)
	
	if world_delta_data.has(coord):
		chunk = world_delta_data[coord]
	elif FileAccess.file_exists(path):
		chunk = ResourceLoader.load(path)
		world_delta_data[coord] = chunk
	else:
		chunk = WorldChunk.new()
		chunk.coord = coord
		
		# 严格去重：如果多个结构种子在同一坐标产生了相同的实体，仅保留一个
		var unique_entities = []
		var seen_keys = {}
		for ent in new_entities:
			# 使用四舍五入后的整数坐标作为键，防止微小浮点误差导致去重失效
			var key = "%s_%d_%d" % [ent.scene_path, int(round(ent.pos.x)), int(round(ent.pos.y))]
			if not seen_keys.has(key):
				unique_entities.append(ent)
				seen_keys[key] = true
		
		# 将去重后的新生成的实体加入 Chunk
		chunk.entities.append_array(unique_entities)
	
	loaded_chunks[coord] = chunk
	
	_apply_cells_to_layers(coord, cells, chunk)
	_spawn_chunk_entities(coord, chunk) 
	
	# 显式刷新 TileMapLayer 属性 (根据图层类型决定碰撞)
	var gen = get_tree().get_first_node_in_group("world_generator")
	if gen:
		if gen.layer_0: gen.layer_0.collision_enabled = true
		if gen.layer_1: gen.layer_1.collision_enabled = true
		# Layer 2 是背景墙图层，不应开启物理碰撞
		if gen.layer_2: gen.layer_2.collision_enabled = false
	
	_spawn_chunk_particles(coord, cells) 
	
	if MinimapManager:
		MinimapManager.update_from_chunk(coord, cells, chunk)
		
	chunk_loaded.emit(coord)

## 强制同步加载指定位置的区块 (用于传送等紧急情况)
func force_load_at_world_pos(world_pos: Vector2) -> void:
	var coord = get_chunk_coord(world_pos)
	if loaded_chunks.has(coord): return
	
	print("InfiniteChunkManager: SYNC forcing load for chunk ", coord)
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not generator: return
	
	var cells = generator.generate_chunk_cells(coord)
	var spawned_entities = []
	
	var natural_ground_y = []
	for x in range(64):
		natural_ground_y.append(_get_top_tile_y(cells, x))
		
	_apply_structures(coord, cells, spawned_entities)
	_apply_trees(coord, cells, natural_ground_y)
	
	# 同步调用最终应用
	_finalize_chunk_load(coord, cells, spawned_entities)

## 寻找安全的地面位置 (用于防止掉入虚空)
## 返回有效的 Global Position (Vector2) 或 null (未找到)
func find_safe_ground(start_pos: Vector2, max_depth: float = 1200.0) -> Variant:
	# 1. 确保该区域已加载 (数据层)
	force_load_at_world_pos(start_pos)
	
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not generator: return null
	
	# 这里假设 generator.layer_0 是主要的参照层
	var layer_0 = generator.layer_0
	if not layer_0: return null
	
	var map_pos = layer_0.local_to_map(start_pos)
	var max_y_offset = int(max_depth / float(TILE_SIZE))
	
	# 检查当前是否在墙里
	if _is_solid_at_map(generator, map_pos):
		# 如果卡在墙里，向上寻找空气
		for i in range(1, 20): # 向上找20格
			if not _is_solid_at_map(generator, map_pos + Vector2i(0, -i)):
				# 找到空气
				return layer_0.map_to_local(map_pos + Vector2i(0, -i))
		return start_pos # 放弃治疗，交给物理引擎挤出
		
	# 检查下方是否有地面 (防止虚空)
	for y_off in range(0, max_y_offset):
		var check_pos = map_pos + Vector2i(0, y_off)
		if _is_solid_at_map(generator, check_pos):
			# 找到地面！
			var ground_center = layer_0.map_to_local(check_pos)
			# 返回地面上方一格的位置 (防止脚嵌入地面)
			return ground_center + Vector2(0, -TILE_SIZE)
			
	return null # 下方全是虚空

func _is_solid_at_map(gen, coord: Vector2i) -> bool:
	if gen.layer_0.get_cell_source_id(coord) != -1: return true
	if gen.layer_1 and gen.layer_1.get_cell_source_id(coord) != -1: return true
	if gen.layer_2 and gen.layer_2.get_cell_source_id(coord) != -1: return true
	return false

func _spawn_chunk_entities(coord: Vector2i, chunk: WorldChunk) -> void:
	if chunk.entities.is_empty(): return
	
	var container = Node2D.new()
	container.name = "Entities_%d_%d" % [coord.x, coord.y]
	get_tree().current_scene.add_child(container)
	chunk_entity_containers[coord] = container
	
	for entity_data in chunk.entities:
		_instantiate_entity(container, entity_data)

func _instantiate_entity(parent: Node, data: Dictionary) -> void:
	var path = data.scene_path
	# 简单修正路径（如果必要）
	if "workshop.tscn" in path and not "buildings/" in path:
		path = "res://scenes/world/buildings/workshop.tscn"
	if "ruins_stone.tscn" in path and not "buildings/" in path:
		path = "res://scenes/world/buildings/ruins_stone.tscn"
		
	var scene = load(path)
	if scene:
		var inst = scene.instantiate()
		parent.add_child(inst)
		inst.global_position = data.pos
		
		# 处理自定义数据
		if inst.has_method("load_custom_data"):
			inst.load_custom_data(data.get("data", {}))
			
		# 处理建筑内部的生成点 (ChestSpawn, NPCSpawn)
		_process_structure_spawns(inst, parent)

func _process_structure_spawns(structure: Node, container: Node) -> void:
	# 在建筑树中寻找 Marker2D
	for child in structure.get_children():
		if child is Marker2D:
			if "ChestSpawn" in child.name:
				_spawn_chest_at(child.global_position, container)
			elif "NPCSpawn" in child.name:
				_spawn_npc_at(child.global_position, container)

func _spawn_chest_at(pos: Vector2, parent: Node) -> void:
	var chest_path = "res://scenes/world/chest.tscn"
	var scene = load(chest_path)
	if scene:
		var chest = scene.instantiate()
		parent.add_child(chest)
		chest.global_position = pos

func _spawn_npc_at(pos: Vector2, parent: Node) -> void:
	# 获取 generator 以获取资源
	var generator = get_tree().get_first_node_in_group("world_generator")
	if generator and generator.npc_scene:
		# --- 数据层安全检测 (比物理检测更快更准) ---
		var tile_layer = get_tree().get_first_node_in_group("world_tiles")
		if tile_layer:
			# NPC 偏移修正：NPC 场景的原点并不是脚底，而是靠近头部，脚底大约在 Origin + 43px 处
			# 我们需要确保 脚底 (Feet) 不在墙里，且站在地上
			var npc_feet_offset = 43.0 
			
			# 将标记点的全局坐标转换为 TileMap 坐标
			# 我们关注的是 "脚底" 所在的瓦片
			var target_feet_pos_global = pos + Vector2(0, npc_feet_offset)
			var tile_pos = tile_layer.local_to_map(TransformHelper.safe_to_local(tile_layer, target_feet_pos_global))
			
			# 1. 如果脚底在实心瓦片里 -> 向上寻找空地 (卡墙修复)
			if tile_layer.get_cell_source_id(tile_pos) != -1:
				var found_air = false
				# 向上最多找 6 格 (约 96px)
				for y_up in range(1, 7):
					var check_tile = tile_pos - Vector2i(0, y_up)
					# 检查脚底是否为空 (Air) 且 头部空间也为空 (Air)
					# 假设 NPC 高 3 格 (48px)
					if tile_layer.get_cell_source_id(check_tile) == -1 and \
					   tile_layer.get_cell_source_id(check_tile - Vector2i(0, 1)) == -1 and \
					   tile_layer.get_cell_source_id(check_tile - Vector2i(0, 2)) == -1:
						
						# 找到了！新的脚底 Tile 是 coords check_tile
						# 但此时 check_tile 是空气，NPC 会掉下去？
						# 我们希望脚底踩在实心块上。
						# 刚才循环是 "如果脚底是实心，往上找"。
						# 所以我们应该找：上方是空气，下方是实心 的分界线。
						pass
				
				# 简单策略：直接从当前卡住的位置向上遍历，直到找到 "脚底是空气" 的点
				# 然后回退一格，或者就在那里 (如地面)
				for y_up in range(1, 10):
					var current_feet_tile = tile_pos - Vector2i(0, y_up)
					if tile_layer.get_cell_source_id(current_feet_tile) == -1:
						# 脚底出来了！
						# 修正 Pos: 新的 Origin = Feet_Global - Offset
						var new_feet_global = tile_layer.to_global(tile_layer.map_to_local(current_feet_tile))
						# map_to_local 返回中心点。如果 feet 是底部，因该 +8? No, usually center is fine for snap.
						# 对齐只要不穿模即可。
						pos = new_feet_global - Vector2(0, npc_feet_offset)
						found_air = true
						break
				
				if not found_air:
					print("InfiniteChunkManager: NPC 深埋无法解脱，取消: ", pos)
					return
			
			# 2. 如果脚底是悬空的 -> 向下寻找地面 (悬空修复)
			# (防止 Marker 放太高)
			elif tile_layer.get_cell_source_id(tile_pos) == -1:
				for y_down in range(1, 10):
					var check_tile = tile_pos + Vector2i(0, y_down)
					if tile_layer.get_cell_source_id(check_tile) != -1:
						# 找到地面了！地面在 check_tile
						# 脚底应该在 check_tile 的上方 -> check_tile - (0,1)
						var valid_feet_tile = check_tile - Vector2i(0, 1)
						var new_feet_global = tile_layer.to_global(tile_layer.map_to_local(valid_feet_tile))
						# 微调：贴合地面通常需要 +8 (半个Tile) ?
						# map_to_local 是中心。为了站在 tile 上，脚底应该在 tile top?
						# Tile Top = Center - 8.
						pos = new_feet_global + Vector2(0, 8) - Vector2(0, npc_feet_offset)
						break

		var npc = generator.npc_scene.instantiate()
		parent.add_child(npc)
		npc.global_position = pos
		if npc.has_method("load_custom_data"):
			npc.load_custom_data({"role": "Villager", "alignment": "Friendly"})

## 注册新实体到无限地图系统
func register_placed_entity(world_pos: Vector2, scene_path: String, custom_data: Dictionary = {}) -> void:
	var c_coord = get_chunk_coord(world_pos)
	
	# 确保数据加载
	if not world_delta_data.has(c_coord):
		var path = _get_save_path(c_coord)
		if FileAccess.file_exists(path):
			world_delta_data[c_coord] = ResourceLoader.load(path)
		else:
			world_delta_data[c_coord] = WorldChunk.new()
			world_delta_data[c_coord].coord = c_coord
			
	var entity_info = {
		"scene_path": scene_path,
		"pos": world_pos,
		"data": custom_data
	}
	world_delta_data[c_coord].entities.append(entity_info)
	
	# 如果当前区块已加载，立即实例化（通过容器）
	if chunk_entity_containers.has(c_coord):
		_instantiate_entity(chunk_entity_containers[c_coord], entity_info)

## 在 Tile 被破坏时生成大量碎片粒子
func spawn_impact_particles(world_pos: Vector2, color: Color) -> void:
	var particles = CPUParticles2D.new()
	get_tree().current_scene.add_child(particles)
	particles.global_position = world_pos
	
	particles.amount = 30
	particles.lifetime = 0.6
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.gravity = Vector2(0, 800)
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 150.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 3.0
	particles.color = color
	
	particles.emitting = true
	particles.one_shot = true
	# 自动销毁容器
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)

func _spawn_chunk_particles(_coord: Vector2i, _cells: Dictionary) -> void:
	# 此处可扩展新区块加载时的烟雾或微尘效果
	pass

func _load_chunk(_coord: Vector2i) -> void:
	# 弃用同步加载版本
	pass

func _apply_cells_to_layers(chunk_coord: Vector2i, cells: Dictionary, chunk: WorldChunk) -> void:
	var generator = get_tree().get_first_node_in_group("world_generator")
	var layers = {
		0: get_tree().get_first_node_in_group("world_tiles"), 
		1: LayerManager.get_layer(1) if LayerManager else null,
		2: LayerManager.get_layer(2) if LayerManager else null,
		10: generator.tree_layer_0 if generator else null,
		11: generator.tree_layer_1 if generator else null,
		12: generator.tree_layer_2 if generator else null
	}
	
	var origin = chunk_coord * CHUNK_SIZE
	
	# 修改：不仅遍历 cells.keys()，还要确保遍历所有可能的逻辑图层，以便应用玩家 Delta
	var all_relevant_layers = cells.keys()
	for l_idx in [0, 1, 2]: # 核心物理/背景层
		if not l_idx in all_relevant_layers:
			all_relevant_layers.append(l_idx)
	
	for layer_idx in all_relevant_layers:
		# 严格过滤：仅处理整数图层索引，忽略元数据 (如 _coord)
		if not layer_idx is int: continue
		
		var layer = layers.get(layer_idx)
		if not layer: continue
		
		# 获取该层原始数据，并确保其为字典
		var layer_cells = cells.get(layer_idx)
		if not (layer_cells is Dictionary): continue
		
		# 我们需要处理该层中所有可能的位置：包括生成的和 Delta 记录的
		# 首先处理 Delta（玩家修改）
		var chunk_deltas = chunk.deltas.get(layer_idx, {})
		if not (chunk_deltas is Dictionary): chunk_deltas = {}
		
		# 1. 应用生成的瓦片 (如果没有 Delta 覆盖)
		for local_pos in layer_cells:
			if chunk_deltas.has(local_pos): continue # 跳过，由 Delta 处理
			
			var data = layer_cells[local_pos]
			if not (data is Dictionary): continue
			
			var map_pos = origin + local_pos
			layer.set_cell(map_pos, data.get("source", -1), data.get("atlas", Vector2i(-1, -1)))
			
		# 2. 应用玩家修改 (Delta)
		for local_pos in chunk_deltas:
			var map_pos = origin + local_pos
			var delta = chunk_deltas[local_pos]
			if not (delta is Dictionary): continue
			
			if delta.get("source", -1) == -1:
				layer.set_cell(map_pos, -1)
			else:
				layer.set_cell(map_pos, delta.get("source", -1), delta.get("atlas", Vector2i(-1, -1)))
	
	# --- 强制物理重刷 ---
	# 在传送后的同步加载中，此举至关重要，它强制本帧生成物理形状
	for layer_idx in layers:
		var layer = layers[layer_idx]
		if layer is TileMapLayer:
			layer.update_internals() # 触发 Godot 内部重绘与物理刷新

func _unload_chunk(coord: Vector2i) -> void:
	# 1. 如果有修改，保存到磁盘并释放内存
	if world_delta_data.has(coord):
		var chunk = world_delta_data[coord]
		var has_changes = false
		for l in [0,1,2]:
			if not chunk.deltas.get(l, {}).is_empty():
				has_changes = true
				break
		
		if has_changes:
			ResourceSaver.save(chunk, _get_save_path(coord))
		
		world_delta_data.erase(coord)

	# 1.5 清理实体容器
	if chunk_entity_containers.has(coord):
		var container = chunk_entity_containers[coord]
		if is_instance_valid(container):
			container.queue_free()
		chunk_entity_containers.erase(coord)

	# 1.8 从已加载列表移除
	loaded_chunks.erase(coord)

	# 2. 清除 TileMapLayer 上的对应区域以释放渲染资源
	var generator = get_tree().get_first_node_in_group("world_generator")
	var layers = [
		get_tree().get_first_node_in_group("world_tiles"),
		LayerManager.get_layer(1) if LayerManager else null,
		LayerManager.get_layer(2) if LayerManager else null
	]
	
	if generator:
		layers.append(generator.tree_layer_0)
		layers.append(generator.tree_layer_1)
		layers.append(generator.tree_layer_2)
	
	var origin = coord * CHUNK_SIZE
	for layer in layers:
		if not layer: continue
		# 极速清理：由于 Godot 4 TileMapLayer.set_cell 是内部哈希操作，手动循环是标准做法
		# 未来如果 TileMapLayer 增加 clear_region 将更优
		for x in range(CHUNK_SIZE):
			for y in range(CHUNK_SIZE):
				layer.set_cell(origin + Vector2i(x, y), -1)
				
	loaded_chunks.erase(coord)
	chunk_unloaded.emit(coord)
