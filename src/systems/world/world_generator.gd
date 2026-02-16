extends Node2D
class_name WorldGenerator

@export var world_width: int = 1000
@export var world_height: int = 500
@export var seed_value: int = 0

@export var gatherable_scene: PackedScene = preload("res://scenes/world/gatherable.tscn")
@export var layer_door_scene: PackedScene = preload("res://scenes/world/layer_door.tscn")
@export var npc_scene: PackedScene = preload("res://NPC.tscn")

@export_group("Building Presets")
@export var house_scene: PackedScene # = preload("res://scenes/world/buildings/house_small.tscn")
@export var workshop_scene: PackedScene = preload("res://scenes/world/buildings/workshop.tscn")
@export var ruins_scene: PackedScene = preload("res://scenes/world/buildings/ruins_stone.tscn")
@export var chest_scene: PackedScene = preload("res://scenes/world/chest.tscn")

@export_group("Tile Settings")
## 瓦片源 ID (Minimalist Palette uses ID 0)
@export var tile_source_id: int = 0
## 泥土草方块源 ID (Minimalist Palette uses ID 0)
@export var grass_dirt_source_id: int = 0
## 泥土草方块瓦片的 Atlas 坐标 (Grass 1,0)
@export var grass_tile: Vector2i = Vector2i(1, 0)
## 泥土瓦片的 Atlas 坐标 (Dirt 0,0)
@export var dirt_tile: Vector2i = Vector2i(0, 0)
## 岩石瓦片的 Atlas 坐标 (Stone 2,0)
@export var stone_tile: Vector2i = Vector2i(2, 0)
## 深层硬岩的 Atlas 坐标 (HardRock 1,3)
@export var hard_rock_tile: Vector2i = Vector2i(1, 3)

@export_group("Mineral Settings")
## 铁矿石 Atlas 坐标 (0, 4)
@export var iron_tile: Vector2i = Vector2i(0, 4)
## 铜矿石 Atlas 坐标 (1, 4)
@export var copper_tile: Vector2i = Vector2i(1, 4)
## 金矿石 Atlas 坐标 (4, 4)
@export var gold_tile: Vector2i = Vector2i(4, 4)
## 钻石矿石 Atlas 坐标 (5, 4)
@export var diamond_tile: Vector2i = Vector2i(5, 4)
## 魔力水晶 Atlas 坐标 (2, 4)
@export var magic_crystal_tile: Vector2i = Vector2i(2, 4)
## 法杖核心 Atlas 坐标 (3, 4)
@export var staff_core_tile: Vector2i = Vector2i(3, 4)
## 魔法加速石 Atlas 坐标 (0, 5)
@export var magic_speed_stone_tile: Vector2i = Vector2i(0, 5)

## 基础矿物噪声频率
@export var mineral_noise_freq: float = 0.08

@export_group("Tree Settings")
## 树木瓦片源 ID
@export var tree_source_id: int = 0
## 树根瓦片
@export var tree_root_left: Vector2i = Vector2i(0, 2)
@export var tree_root_mid: Vector2i = Vector2i(1, 2)
@export var tree_root_right: Vector2i = Vector2i(2, 2)
## 树干瓦片 (Fixed position (1,2) for wood)
@export var tree_trunk_tile: Vector2i = Vector2i(1, 2)
## 树冠瓦片
@export var tree_canopy_tile: Vector2i = Vector2i(1, 0)
## 树木生成概率
@export var tree_chance: float = 0.05
## 树木最小间距
@export var min_tree_distance: int = 6

# 职业与动画资源的映射表
@export var role_animations: Dictionary = {
	"Merchant": "res://assets/character/animations/merchant.tres",
	"Farmer": "res://assets/character/animations/farmer.tres",
	"Blacksmith": "res://assets/character/animations/blacksmith.tres",
	"Guard": "res://assets/character/animations/guard.tres",
	"Villager": "res://assets/character/animations/villager.tres"
}

@onready var layer_0: TileMapLayer = $Layer0 # Surface
@onready var layer_1: TileMapLayer = _find_layer_node(["Layer1", "TileMapLayer", "Layer_Background"])
@onready var layer_2: TileMapLayer = _find_layer_node(["Layer2", "Layer_Deep"])

func _find_layer_node(possible_names: Array) -> TileMapLayer:
	for n_name in possible_names:
		if has_node(n_name):
			return get_node(n_name) as TileMapLayer
	# 如果找不到，动态创建一个，防止报错
	var new_layer = TileMapLayer.new()
	new_layer.name = possible_names[0]
	add_child(new_layer)
	return new_layer

@onready var tree_layer_0: TileMapLayer = $TreeLayer0
@onready var tree_layer_1: TileMapLayer = $TreeLayer1
@onready var tree_layer_2: TileMapLayer = $TreeLayer2

# --- 层级噪声系统 ---
var noise_continental: FastNoiseLite = FastNoiseLite.new()
var noise_temperature: FastNoiseLite = FastNoiseLite.new()
var noise_moisture: FastNoiseLite = FastNoiseLite.new()
var noise_cave: FastNoiseLite = FastNoiseLite.new()
var noise_tunnel: FastNoiseLite = FastNoiseLite.new()
var noise_tree_cluster: FastNoiseLite = FastNoiseLite.new() # 树木聚簇噪声
var noise_tree_density: FastNoiseLite = FastNoiseLite.new() # 树木密度噪声

# --- 矿物噪声 ---
var noise_mineral_common: FastNoiseLite = FastNoiseLite.new()
var noise_mineral_rare: FastNoiseLite = FastNoiseLite.new()
var noise_mineral_legendary: FastNoiseLite = FastNoiseLite.new()

# --- 生态系统 (Biomes) ---
enum BiomeType { 
	FOREST,     # 森林
	PLAINS,     # 平原
	DESERT,     # 沙漠
	TUNDRA,     # 苔原
	SWAMP,      # 沼泽
	
	# --- 地下变体 ---
	The_UNDERGROUND,    # 普通地下 (森林/平原地下)
	UNDERGROUND_DESERT, # 沙漠地下 (化石、沙岩)
	UNDERGROUND_TUNDRA, # 冻土层 (冰窟)
	UNDERGROUND_SWAMP,  # 淤泥层 (毒气穴)
}

# 2D 噪声缩放因子 (1.0 表示直接使用噪声频率)
@export var biome_noise_scale: float = 1.0 

var biome_params = {
	BiomeType.FOREST: {
		"color": Color(0.2, 0.6, 0.3), "amp": 60,
		"surface_block": Vector2i(2, 1),    # Grass
		"sub_block": Vector2i(0, 0),      # Dirt
		"stone_block": Vector2i(2, 0),    # Stone
		"underground_biome": BiomeType.The_UNDERGROUND,
		"source_id": 0
	},
	BiomeType.PLAINS: {
		"color": Color(0.4, 0.6, 0.2), "amp": 40,
		"surface_block": Vector2i(2, 1),    # Grass
		"sub_block": Vector2i(0, 0),      # Dirt
		"stone_block": Vector2i(2, 0),    # Stone
		"underground_biome": BiomeType.The_UNDERGROUND,
		"source_id": 0
	},
	BiomeType.DESERT: {
		"color": Color(0.8, 0.7, 0.3), "amp": 20,
		"surface_block": Vector2i(3, 0),  # Sand
		"sub_block": Vector2i(3, 0),      # Sand
		"stone_block": Vector2i(3, 0),    # Sandstone
		"underground_biome": BiomeType.UNDERGROUND_DESERT,
		"source_id": 0
	},
	BiomeType.TUNDRA: {
		"color": Color(0.7, 0.8, 0.9), "amp": 80,
		"surface_block": Vector2i(3, 1),  # Snow
		"sub_block": Vector2i(0, 0),      # Dirt
		"stone_block": Vector2i(2, 3),    # Ice
		"underground_biome": BiomeType.UNDERGROUND_TUNDRA,
		"source_id": 0
	},
	BiomeType.SWAMP: {
		"color": Color(0.3, 0.4, 0.25), "amp": 10,
		"surface_block": Vector2i(3, 2),  # Mud
		"sub_block": Vector2i(3, 2),      # Mud
		"stone_block": Vector2i(3, 2),    # MudStone
		"underground_biome": BiomeType.UNDERGROUND_SWAMP,
		"source_id": 0
	},
	# --- 地下变体定义 ---
	BiomeType.The_UNDERGROUND: {
		"amp": 0, "sub_block": Vector2i(0, 0), "stone_block": Vector2i(2, 0),
		"surface_block": Vector2i(0, 0), "source_id": 0
	},
	BiomeType.UNDERGROUND_DESERT: {
		"amp": 0, "sub_block": Vector2i(3, 0), "stone_block": Vector2i(3, 0),
		"surface_block": Vector2i(3, 0), "source_id": 0
	},
	BiomeType.UNDERGROUND_TUNDRA: {
		"amp": 0, "sub_block": Vector2i(3, 1), "stone_block": Vector2i(2, 3),
		"surface_block": Vector2i(3, 1), "source_id": 0
	},
	BiomeType.UNDERGROUND_SWAMP: {
		"amp": 0, "sub_block": Vector2i(3, 2), "stone_block": Vector2i(3, 2),
		"surface_block": Vector2i(3, 2), "source_id": 0
	}
}

var pois: Dictionary = {} # {Vector2i: String}

func _ready() -> void:
	add_to_group("world_generator")
	# 确保每一局启动时都有真正的随机底色
	randomize()
	if seed_value == 0:
		seed_value = randi()
	
	_setup_noises()
	
	# 确保所有图层强制共享同一个 TileSet 资源
	if layer_0.tile_set:
		for l in [layer_1, layer_2, tree_layer_0, tree_layer_1, tree_layer_2]:
			if l:
				l.tile_set = layer_0.tile_set
				
	# 注册图层
	if LayerManager:
		LayerManager.register_layer(0, layer_0)
		LayerManager.register_layer(1, layer_1)
		LayerManager.register_layer(2, layer_2)
		
		# 注册树木图层 (使用 meta 标记所属的主图层)
		if tree_layer_0: 
			tree_layer_0.set_meta("layer_index", 0)
			tree_layer_0.add_to_group("map_layers")
		if tree_layer_1: 
			tree_layer_1.set_meta("layer_index", 1)
			tree_layer_1.add_to_group("map_layers")
		if tree_layer_2: 
			tree_layer_2.set_meta("layer_index", 2)
			tree_layer_2.add_to_group("map_layers")
	
	layer_0.add_to_group("world_tiles")
	
	check_tileset_ids()

func _setup_noises() -> void:
	# 1. 大陆骨架 (极低频) - 决定基础海拔与陆地分布
	noise_continental.seed = seed_value
	noise_continental.frequency = 0.001
	noise_continental.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# 2. 气候噪声 - 决定生物群系
	noise_temperature.seed = seed_value + 123
	noise_temperature.frequency = 0.0015 # 调整频率，使生态区大小适中（约 600-1000 瓦片）
	noise_temperature.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_temperature.fractal_octaves = 2
	
	noise_moisture.seed = seed_value + 456
	noise_moisture.frequency = 0.0015
	noise_moisture.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_moisture.fractal_octaves = 2
	
	# 3. 洞穴与细节噪声 (高频)
	noise_cave.seed = seed_value + 789
	noise_cave.frequency = 0.02
	noise_cave.fractal_octaves = 3

	# 树木噪声配置
	noise_tree_cluster.seed = seed_value + 2024
	noise_tree_cluster.frequency = 0.005 # 决定树林簇的大小
	noise_tree_cluster.noise_type = FastNoiseLite.TYPE_PERLIN
	
	noise_tree_density.seed = seed_value + 999
	noise_tree_density.frequency = 0.05 # 决定单棵树的随机性
	noise_tree_density.noise_type = FastNoiseLite.TYPE_VALUE

	# 4. 矿道噪声 (Ridged Multifractal 模拟 Perlin Worms 效果)
	noise_tunnel.seed = seed_value + 1011
	noise_tunnel.frequency = 0.012
	noise_tunnel.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_tunnel.fractal_type = FastNoiseLite.FRACTAL_RIDGED 
	noise_tunnel.fractal_octaves = 2

	# 5. 矿物生成噪声
	noise_mineral_common.seed = seed_value + 3001
	noise_mineral_common.frequency = mineral_noise_freq
	noise_mineral_common.noise_type = FastNoiseLite.TYPE_SIMPLEX # Simplex 更适合有机形状
	
	noise_mineral_rare.seed = seed_value + 3002
	noise_mineral_rare.frequency = mineral_noise_freq * 1.5 # 稀有矿物分布更散
	noise_mineral_rare.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	noise_mineral_legendary.seed = seed_value + 3003
	noise_mineral_legendary.frequency = mineral_noise_freq * 2.0
	noise_mineral_legendary.noise_type = FastNoiseLite.TYPE_CELLULAR # 晶体/核心使用 Cellular 更有几何感
	noise_mineral_legendary.cellular_jitter = 1.0

func _get_mineral_at(gx: int, gy: int, depth: float) -> Vector2i:
	# 负一表示无矿物
	var no_mineral = Vector2i(-1, -1)
	
	# 阈值定义 (噪声值通常在 -1 到 1 之间)
	# 值越高越稀有
	
	# Layer 0 (Shallow): Y < 100 relative to surface
	# Layer 1 (Underground): 100 < Y < 300
	# Layer 2 (Deep): Y > 300
	
	# 使用 3D 噪声采样 (Y轴缩放以产生扁平矿脉) 或 2D 采样
	# 这里使用 2D 采样 (gx, gy)
	
	var n_common = noise_mineral_common.get_noise_2d(gx, gy * 1.2)
	var n_rare = noise_mineral_rare.get_noise_2d(gx, gy * 1.5)
	var n_legend = noise_mineral_legendary.get_noise_2d(gx, gy * 2.0)
	
	# --- Deep Layer (Y > 300) ---
	if depth > 300:
		# 钻石 (Legendary) - 最深层特有
		if n_legend > 0.88: return diamond_tile
		# 魔法加速石 (Very Rare)
		if n_legend > 0.82: return magic_speed_stone_tile
		# 金矿 (Rare)
		if n_rare > 0.6: return gold_tile
		# 法杖核心 (Rare)
		if n_rare > 0.75: return staff_core_tile # Note: logic overlap, order matters. rare > 0.75 is subset of > 0.6? No, wait. 0.75 is scarcer. 
		# If I put > 0.6 first, > 0.75 will never hit if I return immediately.
		# So put rarer things first.
		
		# Re-ordering for rarity:
		if n_rare > 0.8: return staff_core_tile
		if n_rare > 0.6: return gold_tile # Gold is more common than Staff Core in deep
		
		# 丰富的矿脉
		if n_common > 0.4: return iron_tile
		if n_common < -0.4: return magic_crystal_tile

	# --- Underground Layer (100 < Y < 300) ---
	elif depth > 100:
		# 钻石 (Extremely Rare here)
		if n_legend > 0.95: return diamond_tile
		# 法杖核心 (Very Rare here)
		if n_rare > 0.85: return staff_core_tile
		# 金矿 (Rare)
		if n_rare > 0.7: return gold_tile
		# 魔力水晶 (Uncommon)
		if n_rare > 0.5: return magic_crystal_tile
		# 铁矿
		if n_common > 0.5: return iron_tile
		# 铜矿
		if n_common < -0.5: return copper_tile

	# --- Surface/Shallow Layer (10 < Y < 100) ---
	elif depth > 10:
		# 金矿 (Very Rare near surface)
		if n_rare > 0.85: return gold_tile
		# 铜矿 (Common)
		if n_common > 0.6: return copper_tile
		# 铁矿 (Sparse)
		if n_common < -0.7: return iron_tile
		
	return no_mineral

## 核心树木分布逻辑：结合噪声与生物群系
func should_spawn_tree_at(gx: int, gy: int) -> bool:
	# 1. 结构避让 (预测是否有房屋)
	if _is_in_structure_forbidden_zone(gx, gy):
		return false
		
	# 2. 局部最优检查：确保 min_tree_distance 的最小间距
	# 我们只在局部噪声最小（优先级最高）的点生成树，从而实现完美间距且确定性
	if not _is_tree_priority_candidate(gx):
		return false
		
	# 3. 噪声局部最优判定
	var my_density = noise_tree_density.get_noise_2d(gx, 0)
	for ox in range(-min_tree_distance, min_tree_distance + 1):
		if ox == 0: continue
		var nx = gx + ox
		if _is_tree_priority_candidate(nx):
			var n_density = noise_tree_density.get_noise_2d(nx, 0)
			if n_density < my_density: # 发现周边有更高优先级（值更小）的点
				return false
			elif n_density == my_density and nx < gx: # 处理可能的平局
				return false

	return true

## 内部：仅进行噪声和生态概率判定（不含间距和结构避让）
func _is_tree_priority_candidate(gx: int) -> bool:
	var biome = get_biome_at(gx, 0)
	
	if biome == BiomeType.DESERT: return false
	
	var cluster_val = (noise_tree_cluster.get_noise_2d(gx, 0) + 1.0) / 2.0
	var density_val = (noise_tree_density.get_noise_2d(gx, 0) + 1.0) / 2.0
	
	var base_chance = tree_chance * 2.0
	if biome == BiomeType.FOREST: 
		base_chance = tree_chance * 8.0
	elif biome == BiomeType.PLAINS: 
		base_chance = tree_chance * 2.5
	
	if cluster_val < 0.15: return false
	
	var final_prob = base_chance * (0.3 + cluster_val * 1.7)
	return density_val < final_prob

## 预测该位置是否处于建筑禁止区 (建筑本身 + 左右隔离带)
func _is_in_structure_forbidden_zone(gx: int, gy: int) -> bool:
	var chunk_x = floor(gx / 64.0)
	
	# 同步 InfiniteChunkManager 的哈希逻辑
	if not InfiniteChunkManager: return false
	
	# 检查当前及相邻 Chunk (因为建筑可能跨越边界或在边缘)
	for ox in range(-2, 3): # 对应 manager 的检测范围
		var cx = int(chunk_x + ox)
		# 房屋目前只在 y=4~7 产生 (对应 InfiniteChunkManager 逻辑)
		for cy in range(4, 8):
			var hash_val = InfiniteChunkManager.get_chunk_hash(Vector2i(cx, cy))
			if hash_val % 12 == 0: # 对应 manager 的房子概率
				# 预测房子位置
				var center_x_local = hash_val % 30 + 15
				var b_x_global = cx * 64 + center_x_local
				
				# 房屋宽度约 35
				var house_w = 35 
				var margin = 2 # 房外延伸 2 格隔离带
				
				if gx >= b_x_global - margin and gx < b_x_global + house_w + margin:
					return true
	return false

## 获取指定位置的生物群系 (2D 噪声 + 深度分层)
func get_biome_at(global_x: int, global_y: int) -> BiomeType:
	# 1. 采样 2D 气候噪声 (温度与湿度)
	# 使用较低的 Y 轴权重，使生态区在垂直方向拉伸，更像地层
	var temp = noise_temperature.get_noise_2d(global_x, global_y * 0.5)
	var moist = noise_moisture.get_noise_2d(global_x, global_y * 0.5)
	
	# 2. 采样深度专用噪声 (决定地下区域的物性变化)
	var depth_val = noise_continental.get_noise_2d(global_x * 2.0, global_y * 2.0)
	
	# 3. 基础地表生态判定
	var surface_biome = BiomeType.FOREST
	
	if temp < -0.2:
		surface_biome = BiomeType.TUNDRA
	elif temp > 0.3:
		if moist < -0.1:
			surface_biome = BiomeType.DESERT
		elif moist > 0.2:
			surface_biome = BiomeType.SWAMP
		else:
			surface_biome = BiomeType.PLAINS
	else:
		if moist < 0.0:
			surface_biome = BiomeType.PLAINS
		else:
			surface_biome = BiomeType.FOREST
	
	# 4. 深度分层判定
	var surface_base = 300.0
	var layer_noise = noise_continental.get_noise_1d(global_x) * 50.0
	var underground_threshold = surface_base + 100.0 + layer_noise
	
	if global_y > underground_threshold:
		# --- 核心修改：真正的 2D 地下分层逻辑 ---
		# 如果是 Tundra，且深度极深或深度噪声触发，切换到特定的地下形态
		var current_b_data = biome_params[surface_biome]
		var ug_biome = current_b_data.underground_biome
		
		# 额外的垂直微扰：如果 moist 极高，即使是在地下也能形成局部的地下沼泽/洞窟
		if moist > 0.4 and global_y > underground_threshold + 200:
			return BiomeType.UNDERGROUND_SWAMP
			
		return ug_biome
	else:
		return surface_biome

## 为了兼容旧接口，这里保留一个简化版 (处理像素坐标到瓦片坐标的转换)
func get_biome_weights_at_pos(global_pos: Vector2) -> Dictionary:
	# 将像素坐标 (Pixels) 转换为瓦片坐标 (Tiles)
	# 假设 TILE_SIZE = 16
	var tile_x = int(global_pos.x / 16.0)
	var tile_y = int(global_pos.y / 16.0)
	
	var biome = get_biome_at(tile_x, tile_y)
	var weights = {}
	for b in BiomeType.values(): weights[b] = 0.0
	weights[biome] = 1.0 # 2D 模式下简化为硬切换
	return weights

## 新增：获取指定 X 轴位置的地表高度（瓦片单位）
func get_surface_height_at(global_x: int) -> float:
	var spawn_x = 0
	var dist_to_spawn_x = abs(global_x - spawn_x)
	var spawn_flat_weight = clamp(dist_to_spawn_x / 64.0, 0.0, 1.0)
	
	var surface_biome_type = get_biome_at(global_x, 0)
	var b_params = biome_params.get(surface_biome_type, biome_params[BiomeType.FOREST])
	var biome_amp = b_params["amp"]
	
	var cont_val = noise_continental.get_noise_1d(global_x)
	var blended_cont_val = lerp(0.0, cont_val, spawn_flat_weight)
	
	return 300.0 + (blended_cont_val * biome_amp)

func generate_chunk_cells(coord: Vector2i) -> Dictionary:
	var result = { 0: {}, 1: {}, 2: {} }
	var chunk_origin = coord * 64
	
	for x in range(64):
		var global_x = chunk_origin.x + x
		
		# --- 强制平坦化与重生点保护 ---
		var spawn_x = 0
		var dist_to_spawn_x = abs(global_x - spawn_x)
		var spawn_flat_weight = clamp(dist_to_spawn_x / 64.0, 0.0, 1.0)
		
		# 1. 基础海拔 (Surface Biome Only)
		var surface_biome_type = get_biome_at(global_x, 0)
		var b_params = biome_params[surface_biome_type]
		var biome_amp = b_params["amp"]
		
		var cont_val = noise_continental.get_noise_1d(global_x)
		var blended_cont_val = lerp(0.0, cont_val, spawn_flat_weight)
		
		var surface_base = 300.0 + (blended_cont_val * biome_amp)
		
		for y in range(64):
			var global_y = chunk_origin.y + y
			var local_pos = Vector2i(x, y)
			
			# 2. 垂直填充逻辑
			var is_solid = global_y > surface_base
			
			# 3. 深度洞穴
			if is_solid:
				var dist_from_surf = global_y - surface_base
				var is_spawn_protected = dist_to_spawn_x < 20 and dist_from_surf < 40.0
				
				if dist_from_surf > 15.0 and not is_spawn_protected:
					var c_val = noise_cave.get_noise_2d(global_x, global_y)
					var t_val = noise_tunnel.get_noise_2d(global_x, global_y)
					
					# 调高阈值以减少大坑，增加实心面积
					var cave_thresh = 0.55 if dist_from_surf < 80 else 0.48
					var tunnel_thresh = 0.85
					
					if c_val > cave_thresh or t_val > tunnel_thresh:
						is_solid = false
					
			if is_solid:
				# --- 核心修改：基于位置的生态判定 ---
				var current_biome = get_biome_at(global_x, global_y)
				var current_b_data = biome_params.get(current_biome, biome_params[BiomeType.FOREST])
				
				var depth = global_y - surface_base
				
				# 决定瓦片材质
				var custom_source_id = current_b_data.get("source_id", tile_source_id)
				var tile_data = {"source": custom_source_id, "atlas": current_b_data["sub_block"]} 
				
				if depth < 1.0:
					# 地表
					tile_data["atlas"] = current_b_data["surface_block"] 
					if current_b_data["surface_block"] == Vector2i(2, 0):
						tile_data["source"] = grass_dirt_source_id
				elif depth > 10.0:
					# 石头 (基础)
					tile_data["atlas"] = current_b_data["stone_block"]
					
					# 尝试生成矿物 (仅在基础层为石头时)
					# 注意：我们允许在沙石(Sandstone)或冰(Ice)中生成矿物，但通常矿物嵌在石头里
					# 为了通用性，只要是"地下深处"的默认方块，都尝试替换为矿物
					var mineral_tile = _get_mineral_at(global_x, global_y, depth)
					if mineral_tile != Vector2i(-1, -1):
						tile_data["atlas"] = mineral_tile
				
				# 强制将所有实心方块放在 Layer 0，确保玩家始终有物理碰撞
				result[0][local_pos] = tile_data
				
			# --- 背景墙逻辑：防止地下出现虚空 ---
			# 只要是在地表以下，就在 Layer 1 (背景) 放置背景墙
			if global_y > surface_base + 2.0:
				var bg_biome = get_biome_at(global_x, global_y)
				var bg_data = biome_params.get(bg_biome, biome_params[BiomeType.FOREST])
				
				# 背景墙使用 sub_block 坐标，但通常我们会调暗它或使用特定纹理
				# 目前我们将其放在 Layer 1，LayerManager 会自动处理它的半透明/暗化
				result[1][local_pos] = {
					"source": bg_data.get("source_id", tile_source_id),
					"atlas": bg_data["sub_block"]
				}
				
				# 深层背景可以使用岩石
				if global_y > surface_base + 40.0:
					result[1][local_pos]["atlas"] = bg_data["stone_block"]
						
	return result

func check_tileset_ids() -> void:
	# 检查 TileSet 是否包含指定的 Source ID
	if layer_0.tile_set:
		if not layer_0.tile_set.has_source(tile_source_id):
			var sources = layer_0.tile_set.get_source_count()
			if sources > 0:
				var first_source = layer_0.tile_set.get_source_id(0)
				print("WorldGenerator: 警告！tile_source_id (", tile_source_id, ") 不存在。切换到: ", first_source)
				tile_source_id = first_source
		
		# 同时检查树木源
		if not layer_0.tile_set.has_source(tree_source_id):
			print("WorldGenerator: 错误！tree_source_id (", tree_source_id, ") 不存在于 TileSet 中！")

func start_generation() -> void:
	# 确保初始图层物理生效
	if LayerManager:
		LayerManager.switch_to_layer(0)
	
	# 重置无限区块管理器
	if InfiniteChunkManager:
		InfiniteChunkManager.restart()
		
	# 彻底清空当前所有图层
	if layer_0: layer_0.clear()
	if layer_1: layer_1.clear()
	if layer_2: layer_2.clear()
	if tree_layer_0: tree_layer_0.clear()
	if tree_layer_1: tree_layer_1.clear()
	if tree_layer_2: tree_layer_2.clear()

	# 重新配置所有噪声，确保新的种子被应用到所有噪声类型
	_setup_noises()

	# 清理旧的实体 (NPC, 资源点等)
	for child in get_children():
		if child is CharacterBody2D or child is Area2D:
			child.queue_free()
	
	pois.clear()
	
	# 在无限地图模式下，我们不再调用全局生成函数
	#generate_layer(0, layer_0)
	#generate_layer(1, layer_1)
	#generate_layer(2, layer_2)
	#_spawn_villages()
	#_spawn_ruins()
	
	# 只保留必要的初始化
	_update_camera_limits()
	
	print("WorldGenerator: 初始化完成 (无限地图模式)")

func _update_camera_limits() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var camera = player.get_node_or_null("Camera2D")
	if not camera or not camera is Camera2D: return
	
	# 移除边界限制以实现无限大世界
	# 使用大的整数值表示无限
	camera.limit_left = -10000000
	camera.limit_top = -10000000
	camera.limit_right = 10000000
	camera.limit_bottom = 10000000

func surface_base_calc(x: int, biome: String) -> float:
	var cont_val = noise_continental.get_noise_1d(x)
	var base = 300.0 + (cont_val * 120.0)
	if biome == "MOUNTAIN": base -= 40.0
	elif biome == "DESERT": base += 10.0
	return base

func generate_layer(layer_id: int, tile_layer: TileMapLayer) -> void:
	if not tile_layer: return
	
	tile_layer.clear()
	var cells_set = 0
	var last_tree_x = -min_tree_distance 
	
	for x in range(world_width):
		var cont_val = noise_continental.get_noise_1d(x)
		
		# 1. 气候与生物群系决策
		# 这里简化处理，仅依赖 x 以保持 generate_layer 这种逐层生成模式的效率
		var temp = noise_temperature.get_noise_2d(x, 0)
		var moist = noise_moisture.get_noise_2d(x, 0)
		var biome = "PLAINS"
		if cont_val > 0.4: biome = "MOUNTAIN"
		elif temp > 0.2: biome = "DESERT" if moist < -0.1 else "FOREST"
		
		var surface_y = surface_base_calc(x, biome)
		
		for y in range(world_height):
			var is_solid = y > surface_y
			
			# 4. 深度洞穴与连通矿道系统 (同 generate_chunk_cells)
			if is_solid:
				var dist_from_surf = y - surface_y
				if dist_from_surf > 15.0:
					var cave_val = noise_cave.get_noise_2d(x, y)
					var tunnel_val = noise_tunnel.get_noise_2d(x, y)
					
					var cave_thresh = 0.45 if dist_from_surf < 50 else 0.38
					var tunnel_thresh = 0.82
					
					if cave_val > cave_thresh or tunnel_val > tunnel_thresh:
						is_solid = false
					
			if is_solid:
				var depth = y - surface_y
				var target_layer_idx = 0
				if depth > 80: target_layer_idx = 1
				if depth > 200: target_layer_idx = 2

				if target_layer_idx == layer_id:
					var source = tile_source_id
					var atlas = dirt_tile
					
					if depth < 2.0:
						source = grass_dirt_source_id
						atlas = Vector2i(1, 0) if biome == "DESERT" else grass_tile
					elif depth > 15:
						atlas = stone_tile
					
					if target_layer_idx == 2:
						atlas = hard_rock_tile
						
					tile_layer.set_cell(Vector2i(x, y), source, atlas)
					cells_set += 1

	print("WorldGenerator: 图层 ", layer_id, " 生成完成，共放置 ", cells_set, " 个瓦片")

func _find_flat_areas(layer_id: int, min_width: int) -> Array[int]:
	var flat_areas: Array[int] = []
	var current_layer = layer_0 if layer_id == 0 else (layer_1 if layer_id == 1 else layer_2)
	
	var current_flat_start = -1
	var current_flat_width = 0
	var last_y = -1
	
	for x in range(50, world_width - 50):
		# 寻找该 X 坐标的地面高度
		var ground_y = -1
		for y in range(world_height):
			if current_layer.get_cell_source_id(Vector2i(x, y)) != -1:
				ground_y = y
				break
		
		if ground_y != -1:
			if last_y == -1:
				current_flat_start = x
				current_flat_width = 1
				last_y = ground_y
			elif ground_y == last_y:
				current_flat_width += 1
			else:
				if current_flat_width >= min_width:
					flat_areas.append(current_flat_start + floori(current_flat_width / 2.0))
				current_flat_start = x
				current_flat_width = 1
				last_y = ground_y
		else:
			if current_flat_width >= min_width:
				flat_areas.append(current_flat_start + floori(current_flat_width / 2.0))
			current_flat_start = -1
			current_flat_width = 0
			last_y = -1
			
	return flat_areas

func _spawn_villages() -> void:
	var flat_spots = _find_flat_areas(0, 20)
	if flat_spots.is_empty(): return
	
	flat_spots.shuffle()
	var village_count = min(3, flat_spots.size())
	
	for i in range(village_count):
		var center_x = flat_spots[i]
		_create_village(center_x)

func _create_village(center_x: int) -> void:
	var building_types = []
	if house_scene: building_types.append(house_scene)
	if workshop_scene: building_types.append(workshop_scene)
	
	if building_types.is_empty(): return
	
	var num_buildings = randi_range(2, 4)
	var current_x = center_x - (num_buildings * 10)
	
	for i in range(num_buildings):
		current_x = clampi(current_x, 10, world_width - 10)
		var scene = building_types.pick_random()
		if not scene: continue
		
		# 寻找地面
		var ground_y = -1
		for y in range(world_height):
			if layer_0.get_cell_source_id(Vector2i(current_x, y)) != -1:
				ground_y = y
				break
		
		if ground_y != -1:
			var building = scene.instantiate()
			add_child(building)
			building.position = layer_0.map_to_local(Vector2i(current_x, ground_y - 1))
			
			# 处理建筑内的标记点
			_process_building_markers(building)
			
			pois[Vector2i(current_x, ground_y)] = "村庄建筑"
		
		current_x += randi_range(15, 25)

func _spawn_ruins() -> void:
	var flat_spots = _find_flat_areas(1, 15) # 在地下层寻找平地
	if flat_spots.is_empty(): return
	
	flat_spots.shuffle()
	var ruin_count = min(5, flat_spots.size())
	
	for i in range(ruin_count):
		var rx = flat_spots[i]
		# 寻找地下层的地面
		var ground_y = -1
		for y in range(world_height):
			if layer_1.get_cell_source_id(Vector2i(rx, y)) != -1:
				ground_y = y
				break
		
		if ground_y != -1 and ruins_scene:
			var ruin = ruins_scene.instantiate()
			add_child(ruin)
			ruin.position = layer_1.map_to_local(Vector2i(rx, ground_y - 1))
			_process_building_markers(ruin)
			pois[Vector2i(rx, ground_y)] = "遗迹"

func _process_building_markers(building: Node2D) -> void:
	for child in building.get_children():
		if child is Marker2D:
			if child.name.begins_with("NPC"):
				var role = ""
				if "Merchant" in child.name: role = "Merchant"
				elif "Blacksmith" in child.name: role = "Blacksmith"
				_spawn_npc_at_pos(child.global_position, role)
			elif child.name.begins_with("Chest"):
				_spawn_chest_at_pos(child.global_position)

func _spawn_npc_at_pos(global_pos: Vector2, forced_role: String = "") -> void:
	if not npc_scene: return
	var npc = npc_scene.instantiate()
	add_child(npc)
	npc.global_position = global_pos
	
	if npc.npc_data:
		var roles = ["Merchant", "Farmer", "Blacksmith", "Villager", "Guard"]
		var selected_role = forced_role if forced_role != "" else roles.pick_random()
		npc.npc_data.role = selected_role
		npc.npc_data.display_name = _get_random_name_for_role(selected_role)
		npc.npc_data.alignment = "Friendly"
		
		if role_animations.has(selected_role):
			var anim_path = role_animations[selected_role]
			if ResourceLoader.exists(anim_path):
				npc.custom_sprite_frames = load(anim_path)
		
		_initialize_npc_inventory(npc, selected_role)

func _spawn_chest_at_pos(global_pos: Vector2) -> void:
	if not chest_scene: return
	var chest = chest_scene.instantiate()
	add_child(chest)
	chest.global_position = global_pos

func _spawn_pois() -> void:
	pass # 已被 _spawn_villages 和 _spawn_ruins 替代

func _create_camp(pos: Vector2i) -> void:
	pass # 已被 _create_village 替代

func get_poi_at(pos: Vector2i) -> String:
	# 检查周围一小块区域，因为玩家可能没踩到精确的中心点
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var check_pos = pos + Vector2i(dx, dy)
			if check_pos in pois:
				return pois[check_pos]
	return ""

func _spawn_npc_on_ground(x: int, alignment: String, forced_role: String = "") -> void:
	# 寻找该 X 坐标下的地面
	for y in range(world_height):
		if layer_0.get_cell_source_id(Vector2i(x, y)) != -1:
			_spawn_npc(0, Vector2i(x, y - 1), alignment, forced_role)
			return

func _spawn_npc(layer_id: int, pos: Vector2i, alignment: String, forced_role: String = "") -> void:
	if not npc_scene: return
	
	var npc = npc_scene.instantiate()
	add_child(npc)
	
	# 稍微调高生成位置（向上偏移 8 像素），防止插在地里
	var spawn_pos = layer_0.map_to_local(pos)
	spawn_pos.y -= 8 
	npc.position = spawn_pos
	
	# 初始化 NPC 数据
	if npc.npc_data:
		var roles = ["Merchant", "Farmer", "Blacksmith", "Villager", "Guard"]
		var selected_role = forced_role
		
		if selected_role == "":
			var role_weights = [0.1, 0.3, 0.1, 0.4, 0.1] # 权重分配
			var r = randf()
			selected_role = "Villager"
			var cumulative_weight = 0.0
			for i in range(roles.size()):
				cumulative_weight += role_weights[i]
				if r <= cumulative_weight:
					selected_role = roles[i]
					break
		
		npc.npc_data.role = selected_role
		npc.npc_data.display_name = _get_random_name_for_role(selected_role)
		npc.npc_data.alignment = alignment
		npc.npc_data.attributes["money"] = randi_range(10, 500)
		
		# 设置职业对应的动画
		if role_animations.has(selected_role):
			var anim_path = role_animations[selected_role]
			if ResourceLoader.exists(anim_path):
				npc.custom_sprite_frames = load(anim_path)
		
		# 根据职业初始化库存
		_initialize_npc_inventory(npc, selected_role)
	
	# 随机分配任务
	if randf() < 0.3 and get_node_or_null("/root/QuestManager"):
		npc.quest_template = get_node("/root/QuestManager").create_random_quest()
	
	# 设置物理位面隔离
	if LayerManager:
		LayerManager.move_entity_to_layer(npc, layer_id)
	else:
		# 退化方案
		npc.collision_layer = 1 << 5 # NPC Bit
		npc.collision_mask = 1 << layer_id

func _get_random_name_for_role(role: String) -> String:
	var first_names = ["张", "李", "王", "赵", "孙", "周", "吴", "郑"]
	var last_names = ["大", "二", "三", "四", "五", "六", "七", "八", "九"]
	var npc_name = first_names.pick_random() + last_names.pick_random()
	
	match role:
		"Merchant": return npc_name + "(商人)"
		"Farmer": return npc_name + "(农民)"
		"Blacksmith": return npc_name + "(铁匠)"
		"Guard": return npc_name + "(守卫)"
		"Villager": return npc_name
	return npc_name

func _initialize_npc_inventory(npc: Node, role: String) -> void:
	if not npc.has_method("get_inventory"): return
	var inv = npc.inventory # 直接访问 BaseNPC 的 inventory 数组
	
	match role:
		"Merchant":
			# 商人出售多种基础资源
			_add_item_to_npc(inv, "wood", randi_range(5, 15))
			_add_item_to_npc(inv, "stone", randi_range(5, 15))
			_add_item_to_npc(inv, "iron", randi_range(2, 5))
		"Farmer":
			# 农民出售木材
			_add_item_to_npc(inv, "wood", randi_range(10, 20))
		"Blacksmith":
			# 铁匠出售铁矿和工具
			_add_item_to_npc(inv, "iron", randi_range(10, 20))
			_add_item_to_npc(inv, "pickaxe", 1)
		"Guard":
			# 守卫通常不卖东西
			pass
		"Villager":
			# 普通村民可能有一点杂物
			if randf() < 0.5:
				_add_item_to_npc(inv, "stone", randi_range(1, 5))

func _add_item_to_npc(inv: Array, item_id: String, amount: int) -> void:
	var item_data = GameState.item_db.get(item_id)
	if item_data:
		for i in range(amount):
			inv.append(item_data)

func _spawn_resource(layer_id: int, pos: Vector2i) -> void:
	var res = gatherable_scene.instantiate()
	add_child(res)
	res.position = layer_0.map_to_local(pos)
	
	# 根据层级分配资源类型
	match layer_id:
		0: res.item_data = GameState.item_db.get("wood")
		1: res.item_data = GameState.item_db.get("iron")
		2: res.item_data = GameState.item_db.get("iron") # 暂时用铁矿代替稀有矿
	
	# 设置碰撞层以匹配当前位面
	# 资源点设为第 4 位 (Bit 4) 以便玩家交互
	res.collision_layer = 1 << 3

func _spawn_tree(layer_id: int, pos: Vector2i) -> void:
	var tree_layer = null
	match layer_id:
		0: tree_layer = tree_layer_0
		1: tree_layer = tree_layer_1
		2: tree_layer = tree_layer_2
	
	if not tree_layer: return

	# 1. 放置树根 (3 宽，手动放置 3 个瓦片以防 TileSet 未配置为大瓦片)
	# pos 是草方块位置。树根在草方块上方一格 (y-1)，且水平居中
	var root_y = pos.y - 1
	var root_tiles = [tree_root_left, tree_root_mid, tree_root_right]
	for dx in range(-1, 2):
		var root_pos = Vector2i(pos.x + dx, root_y)
		tree_layer.set_cell(root_pos, tree_source_id, root_tiles[dx + 1])
	
	# 2. 放置随机长度的树干 (2-4 节)
	# 树干从树根中心上方开始向上生长
	var trunk_height = randi_range(2, 4)
	for i in range(1, trunk_height + 1):
		tree_layer.set_cell(pos + Vector2i(0, -1 - i), tree_source_id, tree_trunk_tile)
	
	# 3. 放置树冠 (在树干顶部周围生成一个 3x3 的结构)
	var canopy_center = pos + Vector2i(0, -(trunk_height + 2))
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			# 放置瓦片 (统一使用 tree_canopy_tile)
			tree_layer.set_cell(canopy_center + Vector2i(dx, dy), tree_source_id, tree_canopy_tile)

func _spawn_door(layer_id: int, pos: Vector2i) -> void:
	var door = layer_door_scene.instantiate()
	add_child(door)
	door.position = layer_0.map_to_local(pos)
	
	# 设置目标层
	if layer_id < 2:
		door.target_layer = layer_id + 1
		door.door_name = "进入更深层"
	else:
		door.target_layer = 0
		door.door_name = "回到地表"
	
	# 设置碰撞层以匹配当前位面
	# 传送门设为第 4 位 (Bit 4) 以便玩家交互
	door.collision_layer = 1 << 3

func get_spawn_position() -> Vector2:
	# 针对无限地图模式，固定在 0 附近生成
	var spawn_x = 0
	var global_x = spawn_x
	
	# 下面的混合逻辑必须与 generate_chunk_cells 中的一致
	var dist_to_spawn_x = abs(global_x - spawn_x)
	var spawn_flat_weight = clamp(dist_to_spawn_x / 64.0, 0.0, 1.0)
	var cont_val = noise_continental.get_noise_1d(global_x)
	var blended_cont_val = lerp(0.0, cont_val, spawn_flat_weight)
	
	var surface_limit = 300.0 + (blended_cont_val * 120.0)
	# 第一块实心砖块的索引
	var first_solid_y = ceil(surface_limit) 
	
	# 计算地表的绝对像素高度
	var surface_y_px = first_solid_y * 16
	
	# 根据 player.tscn 的碰撞体积偏移 (CollisionShape2D2 at y=15.15, size_y=55.68)
	var player_spawn_y = surface_y_px - 46
	
	# 计算 X 轴像素位置。同样要进行 Collision 偏移补偿 (-5.5)
	var player_spawn_x = global_x * 16 - 5.5
	
	return Vector2(player_spawn_x, player_spawn_y)
