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
var noise_cave_region: FastNoiseLite = FastNoiseLite.new()
var noise_surface_feature: FastNoiseLite = FastNoiseLite.new()
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

const CAVE_REGION_SURFACE := "Surface"
const CAVE_REGION_TUNNEL := "Tunnel"
const CAVE_REGION_CHAMBER := "Chamber"
const CAVE_REGION_OPEN_CAVERN := "OpenCavern"
const CAVE_REGION_POCKET := "Pocket"
const CAVE_REGION_CONNECTOR := "Connector"
const CAVE_REGION_SOLID := "Solid"

const SURFACE_FEATURE_NONE := "None"
const SURFACE_FEATURE_STONE_OUTCROP := "StoneOutcrop"
const SURFACE_FEATURE_DESERT_SPIRE := "DesertSpire"
const SURFACE_FEATURE_FROST_SPIRE := "FrostSpire"
const SURFACE_FEATURE_MUD_MOUND := "MudMound"
const SURFACE_FEATURE_GRASS_KNOLL := "GrassKnoll"

const SURFACE_ENTRANCE_NONE := "none"
const SURFACE_ENTRANCE_GENTLE_MOUTH := "gentle_mouth"
const SURFACE_ENTRANCE_RAVINE_CUT := "ravine_cut"
const SURFACE_ENTRANCE_PIT_FUNNEL := "pit_funnel"
const SURFACE_ENTRANCE_HILLSIDE_CUT := "hillside_cut"

const RELIEF_PROFILE_STARTER_FLAT := "starter_flat"
const RELIEF_PROFILE_ROLLING := "rolling"
const RELIEF_PROFILE_RIDGE := "ridge"
const RELIEF_PROFILE_BASIN := "basin"
const RELIEF_PROFILE_MOUNTAIN := "mountain"

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
var _surface_biome_cache: Dictionary = {}
var _surface_height_cache: Dictionary = {}
var _surface_relief_profile_cache: Dictionary = {}
var _surface_transition_context_cache: Dictionary = {}
var _surface_column_context_cache: Dictionary = {}
var _mountain_breach_zone_cache: Dictionary = {}

func _clear_generation_caches() -> void:
	_surface_biome_cache.clear()
	_surface_height_cache.clear()
	_surface_relief_profile_cache.clear()
	_surface_transition_context_cache.clear()
	_surface_column_context_cache.clear()
	_mountain_breach_zone_cache.clear()

func _ready() -> void:
	add_to_group("world_generator")
	add_to_group("world_generators")
	# 确保每一局启动时都有真正的随机底色
	randomize()
	if seed_value == 0:
		seed_value = randi()

	_clear_generation_caches()
	_setup_noises()
	
	# 确保所有图层强制共享同一个 TileSet 资源
	if layer_0.tile_set:
		for l in [layer_1, layer_2, tree_layer_0, tree_layer_1, tree_layer_2]:
			if l:
				l.tile_set = layer_0.tile_set
				
	# 标记只用于视觉填充的背景层，避免被当作实体墙参与物理。
	if layer_1:
		layer_1.set_meta("background_only", true)
		layer_1.collision_enabled = false
	if layer_2:
		layer_2.collision_enabled = false

	# 注册图层
	if LayerManager:
		LayerManager.register_layer(0, layer_0)
		LayerManager.register_layer(1, layer_1)
		LayerManager.register_layer(2, layer_2)
		
		# 强制初始化图层属性，防止 LayerManager 注册因时序问题失效
		# 背景墙 (Layer 1) 应在玩家图层 (Layer 0) 之后
		if layer_1:
			layer_1.z_index = -20
			layer_1.modulate = Color(0.7, 0.7, 0.7, 0.8) # 80% 可见度
		
		# 深层地底 (Layer 2)
		if layer_2:
			layer_2.z_index = -40
			layer_2.modulate = Color(0.5, 0.5, 0.5, 0.6)
		
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
	add_to_group("world_generator")
	add_to_group("world_generators")
	
	check_tileset_ids()

func _setup_noises() -> void:
	_clear_generation_caches()

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

	# 4.5 洞穴区域与地表地貌特征噪声
	noise_cave_region.seed = seed_value + 1601
	noise_cave_region.frequency = 0.022
	noise_cave_region.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_cave_region.fractal_octaves = 2

	noise_surface_feature.seed = seed_value + 2201
	noise_surface_feature.frequency = 0.03
	noise_surface_feature.noise_type = FastNoiseLite.TYPE_VALUE

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
		# 深层稀有矿物先判定，避免被更宽的金矿阈值吞掉。
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
	var surface_biome := _get_surface_biome_from_climate(global_x, global_y)
	var surface_base := 300.0 + noise_continental.get_noise_1d(global_x) * 42.0
	var transition_context := _build_surface_transition_context(global_x, surface_biome)
	return _get_column_biome_at_depth(global_x, global_y, surface_base, surface_biome, transition_context)

func _classify_surface_biome_from_climate(temp: float, moist: float) -> BiomeType:
	if temp < -0.28:
		return BiomeType.TUNDRA
	if temp > 0.36:
		if moist < -0.16:
			return BiomeType.DESERT
		if moist > 0.24:
			return BiomeType.SWAMP
		return BiomeType.PLAINS
	if moist < -0.08:
		return BiomeType.PLAINS
	if moist > 0.34 and temp > 0.05:
		return BiomeType.SWAMP
	return BiomeType.FOREST

func _sample_smoothed_surface_climate(global_x: int, global_y: int) -> Dictionary:
	var offsets := [-160, -96, -48, 0, 48, 96, 160]
	var weights := [0.06, 0.12, 0.18, 0.28, 0.18, 0.12, 0.06]
	var temp_acc := 0.0
	var moist_acc := 0.0
	for i in range(offsets.size()):
		var sample_x := global_x + int(offsets[i])
		var w := float(weights[i])
		temp_acc += noise_temperature.get_noise_2d(sample_x, global_y * 0.35) * w
		moist_acc += noise_moisture.get_noise_2d(sample_x, global_y * 0.35) * w

	# 低频偏置让生态带更连续，不会短距离来回跳。
	temp_acc += noise_surface_feature.get_noise_1d(global_x * 0.014 + 27.0) * 0.07
	moist_acc += noise_cave_region.get_noise_1d(global_x * 0.012 - 41.0) * 0.08
	return {
		"temp": temp_acc,
		"moist": moist_acc,
	}

func _get_surface_band_biome(band_index: int, global_y: int) -> BiomeType:
	var band_size := 160
	var center_x := band_index * band_size + int(band_size * 0.5)
	var climate := _sample_smoothed_surface_climate(center_x, global_y)
	return _classify_surface_biome_from_climate(float(climate.get("temp", 0.0)), float(climate.get("moist", 0.0)))

func _get_surface_biome_from_climate(global_x: int, global_y: int) -> BiomeType:
	var cache_key := Vector2i(global_x, global_y)
	if _surface_biome_cache.has(cache_key):
		return int(_surface_biome_cache[cache_key])

	var band_size := 160
	var band_index := int(floor(float(global_x) / float(band_size)))
	var primary := _get_surface_band_biome(band_index, global_y)
	var left_biome := _get_surface_band_biome(band_index - 1, global_y)
	var right_biome := _get_surface_band_biome(band_index + 1, global_y)

	var local_x := float(global_x - band_index * band_size)
	var boundary_warp := noise_surface_feature.get_noise_1d(global_x * 0.052 + 31.0) * 14.0
	var left_zone := 34.0 + boundary_warp * 0.25
	var right_zone := float(band_size) - 34.0 + boundary_warp * 0.25

	if left_biome != primary and local_x < left_zone:
		var left_t := clampf((left_zone - local_x) / maxf(left_zone, 1.0), 0.0, 1.0)
		var left_gate := (noise_tunnel.get_noise_2d(global_x * 0.083 + 17.0, global_y * 0.061 - 13.0) + 1.0) * 0.5
		if left_gate < left_t:
			_surface_biome_cache[cache_key] = left_biome
			return left_biome

	if right_biome != primary and local_x > right_zone:
		var right_t := clampf((local_x - right_zone) / maxf(float(band_size) - right_zone, 1.0), 0.0, 1.0)
		var right_gate := (noise_tunnel.get_noise_2d(global_x * 0.079 - 29.0, global_y * 0.059 + 23.0) + 1.0) * 0.5
		if right_gate < right_t:
			_surface_biome_cache[cache_key] = right_biome
			return right_biome

	_surface_biome_cache[cache_key] = primary
	return primary

func _get_world_topology() -> Node:
	return get_node_or_null("/root/WorldTopology")

func _is_spawn_safe_tile_x(global_x: int) -> bool:
	var world_topology = _get_world_topology()
	if world_topology and world_topology.has_method("is_spawn_safe_tile_x"):
		return world_topology.is_spawn_safe_tile_x(global_x)
	return absi(global_x) < 20

func _get_surface_biome_name(surface_biome: BiomeType) -> String:
	match surface_biome:
		BiomeType.PLAINS:
			return "plains"
		BiomeType.DESERT:
			return "desert"
		BiomeType.TUNDRA:
			return "tundra"
		BiomeType.SWAMP:
			return "swamp"
		_:
			return "forest"

func _select_surface_relief_profile(global_x: int, surface_biome: BiomeType) -> String:
	var cache_key := Vector2i(global_x, int(surface_biome))
	if _surface_relief_profile_cache.has(cache_key):
		return String(_surface_relief_profile_cache[cache_key])

	if _is_spawn_safe_tile_x(global_x):
		_surface_relief_profile_cache[cache_key] = RELIEF_PROFILE_STARTER_FLAT
		return RELIEF_PROFILE_STARTER_FLAT
	var band_index := int(floor(float(global_x) / 192.0))

	var world_topology = _get_world_topology()
	var biome_name := _get_surface_biome_name(surface_biome)
	var region_type := "major"
	if world_topology and world_topology.has_method("get_surface_region_for_tile_x"):
		var region: Dictionary = world_topology.get_surface_region_for_tile_x(global_x)
		if not region.is_empty():
			if bool(region.get("spawn_safe", false)):
				_surface_relief_profile_cache[cache_key] = RELIEF_PROFILE_STARTER_FLAT
				return RELIEF_PROFILE_STARTER_FLAT
			biome_name = String(region.get("biome", biome_name))
			region_type = String(region.get("region_type", "major"))

	if region_type == "transition":
		_surface_relief_profile_cache[cache_key] = RELIEF_PROFILE_ROLLING
		return RELIEF_PROFILE_ROLLING

	# 使用更大的宏观区段进行 profile 选择，确保玩家长距离探索能明显遇到不同地形。
	var band_hash := _hash01(band_index, 1913)
	var band_temp := (noise_temperature.get_noise_1d(float(band_index) * 0.41 + 37.0) + 1.0) * 0.5
	var band_moist := (noise_moisture.get_noise_1d(float(band_index) * 0.33 - 61.0) + 1.0) * 0.5
	var selector := band_hash * 0.46 + band_temp * 0.36 + band_moist * 0.18

	var selected_profile := RELIEF_PROFILE_ROLLING
	if biome_name != "swamp" and selector > 0.64:
		selected_profile = RELIEF_PROFILE_MOUNTAIN
	elif selector < 0.20:
		selected_profile = RELIEF_PROFILE_BASIN
	else:
		match biome_name:
			"swamp":
				selected_profile = RELIEF_PROFILE_BASIN if selector > 0.2 else RELIEF_PROFILE_ROLLING
			"tundra":
				selected_profile = RELIEF_PROFILE_RIDGE if selector > 0.38 else RELIEF_PROFILE_ROLLING
			"desert":
				selected_profile = RELIEF_PROFILE_ROLLING if selector > 0.44 else RELIEF_PROFILE_BASIN
			"plains":
				selected_profile = RELIEF_PROFILE_RIDGE if selector > 0.56 else RELIEF_PROFILE_ROLLING
			_:
				selected_profile = RELIEF_PROFILE_RIDGE if selector > 0.48 else RELIEF_PROFILE_ROLLING

	_surface_relief_profile_cache[cache_key] = selected_profile
	return selected_profile

func _compute_macro_relief_delta(global_x: int, profile: String, biome_amp: float) -> float:
	var continental := noise_continental.get_noise_1d(global_x)
	var tunnel_ridge := absf(noise_tunnel.get_noise_1d(global_x))
	match profile:
		RELIEF_PROFILE_STARTER_FLAT:
			return continental * biome_amp * 0.12
		RELIEF_PROFILE_MOUNTAIN:
			var massif_gate := clampf((noise_temperature.get_noise_1d(global_x * 0.015 + 311.0) + 1.0) * 0.5, 0.0, 1.0)
			var massif := pow(massif_gate, 1.62) * (biome_amp * 1.32 + 42.0)
			var shoulder_gate := clampf((noise_moisture.get_noise_1d(global_x * 0.022 - 211.0) + 1.0) * 0.5, 0.0, 1.0)
			var shoulder := pow(shoulder_gate, 1.34) * 26.0
			var ridge_variation := continental * biome_amp * 0.32
			var crown_breakup := noise_surface_feature.get_noise_1d(global_x * 0.08 + 211.0) * 4.5
			return -massif - shoulder + ridge_variation + crown_breakup + 14.0
		RELIEF_PROFILE_RIDGE:
			var ridge_shape := signf(continental) * pow(absf(continental), 0.65)
			return ridge_shape * biome_amp * 0.95 + tunnel_ridge * 18.0 - 8.0
		RELIEF_PROFILE_BASIN:
			return -absf(continental) * biome_amp * 0.65 + 6.0
		_:
			return continental * biome_amp * 0.55

func _compute_biome_relief_delta(global_x: int, profile: String, surface_biome: BiomeType, biome_amp: float) -> float:
	var climate_wave := noise_moisture.get_noise_1d(global_x)
	var biome_scale := 1.0
	match surface_biome:
		BiomeType.DESERT:
			biome_scale = 0.72
		BiomeType.TUNDRA:
			biome_scale = 1.12
		BiomeType.SWAMP:
			biome_scale = 0.58
		BiomeType.PLAINS:
			biome_scale = 0.86
		_:
			biome_scale = 1.0

	var profile_scale := 0.16
	if profile == RELIEF_PROFILE_RIDGE:
		profile_scale = 0.22
	elif profile == RELIEF_PROFILE_MOUNTAIN:
		profile_scale = 0.28
	elif profile == RELIEF_PROFILE_BASIN:
		profile_scale = 0.12
	return climate_wave * biome_amp * biome_scale * profile_scale

func _compute_local_relief_delta(global_x: int, profile: String) -> float:
	var detail := noise_surface_feature.get_noise_1d(global_x)
	var breakup := noise_cave_region.get_noise_1d(global_x * 2)
	var detail_amp := 4.0
	if profile == RELIEF_PROFILE_STARTER_FLAT:
		detail_amp = 2.0
	elif profile == RELIEF_PROFILE_MOUNTAIN:
		detail_amp = 2.6
	elif profile == RELIEF_PROFILE_RIDGE:
		detail_amp = 5.5
	return detail * detail_amp + breakup * 2.0

func _get_surface_height_raw_for_biome(global_x: int, surface_biome: BiomeType) -> float:
	var b_params = biome_params.get(surface_biome, biome_params[BiomeType.FOREST])
	var biome_amp := float(b_params["amp"])
	var profile := _select_surface_relief_profile(global_x, surface_biome)
	var macro_delta := _compute_macro_relief_delta(global_x, profile, biome_amp)
	var biome_delta := _compute_biome_relief_delta(global_x, profile, surface_biome, biome_amp)
	var local_delta := _compute_local_relief_delta(global_x, profile)
	var shaped_height := 300.0 + macro_delta + biome_delta + local_delta
	return _apply_spawn_relief_clamp(global_x, shaped_height)

func _build_surface_shape_metrics(global_x: int) -> Dictionary:
	var left_x := global_x - 8
	var right_x := global_x + 8
	var left_biome := _get_surface_biome_from_climate(left_x, 0)
	var center_biome := _get_surface_biome_from_climate(global_x, 0)
	var right_biome := _get_surface_biome_from_climate(right_x, 0)
	var left_h := _get_surface_height_for_biome(left_x, left_biome)
	var center_h := _get_surface_height_for_biome(global_x, center_biome)
	var right_h := _get_surface_height_for_biome(right_x, right_biome)
	var left_near_h := _get_surface_height_for_biome(global_x - 4, _get_surface_biome_from_climate(global_x - 4, 0))
	var right_near_h := _get_surface_height_for_biome(global_x + 4, _get_surface_biome_from_climate(global_x + 4, 0))
	var slope := (right_h - left_h) / 16.0
	var relief_span := maxf(absf(center_h - left_h), absf(center_h - right_h))
	var ruggedness := absf(right_h - center_h) + absf(center_h - left_h)
	var slope_left := (center_h - left_near_h) / 4.0
	var slope_right := (right_near_h - center_h) / 4.0
	var crestness := center_h - (left_h + right_h) * 0.5
	var same_direction_slope := signf(slope_left) == signf(slope_right) and absf(slope_left) > 0.08 and absf(slope_right) > 0.08
	return {
		"slope": slope,
		"relief_span": relief_span,
		"ruggedness": ruggedness,
		"left_h": left_h,
		"center_h": center_h,
		"right_h": right_h,
		"slope_left": slope_left,
		"slope_right": slope_right,
		"crestness": crestness,
		"same_direction_slope": same_direction_slope,
	}

func _apply_spawn_relief_clamp(global_x: int, shaped_height: float) -> float:
	var world_topology = _get_world_topology()
	var spawn_anchor_tile := 0
	var clamp_radius := 96.0
	var dist := float(absi(global_x - spawn_anchor_tile))

	if world_topology:
		if world_topology.has_method("get_spawn_anchor_tile"):
			spawn_anchor_tile = int(world_topology.get_spawn_anchor_tile())
		if world_topology.has_method("get_spawn_safe_radius_chunks"):
			clamp_radius = maxf(clamp_radius, float(world_topology.get_spawn_safe_radius_chunks() * 64 + 64))
		if world_topology.has_method("shortest_wrapped_tile_distance"):
			dist = float(world_topology.shortest_wrapped_tile_distance(global_x, spawn_anchor_tile))
		else:
			dist = float(absi(global_x - spawn_anchor_tile))

	var flat_weight := clampf(dist / clamp_radius, 0.0, 1.0)
	var flat_target := 300.0 + noise_continental.get_noise_1d(global_x) * 8.0
	return lerpf(flat_target, shaped_height, flat_weight)

func _get_surface_height_for_biome(global_x: int, surface_biome: BiomeType) -> float:
	var cache_key := Vector2i(global_x, int(surface_biome))
	if _surface_height_cache.has(cache_key):
		return float(_surface_height_cache[cache_key])

	var raw_h := _get_surface_height_raw_for_biome(global_x, surface_biome)
	var left_x1 := global_x - 2
	var right_x1 := global_x + 2
	var left_x2 := global_x - 6
	var right_x2 := global_x + 6
	var left_h1 := _get_surface_height_raw_for_biome(left_x1, _get_surface_biome_from_climate(left_x1, 0))
	var right_h1 := _get_surface_height_raw_for_biome(right_x1, _get_surface_biome_from_climate(right_x1, 0))
	var left_h2 := _get_surface_height_raw_for_biome(left_x2, _get_surface_biome_from_climate(left_x2, 0))
	var right_h2 := _get_surface_height_raw_for_biome(right_x2, _get_surface_biome_from_climate(right_x2, 0))
	var profile := _select_surface_relief_profile(global_x, surface_biome)
	var smooth := raw_h * 0.56 + (left_h1 + right_h1) * 0.18 + (left_h2 + right_h2) * 0.04
	var neighborhood := (left_h1 + right_h1) * 0.5
	var blend := 0.06 if profile == RELIEF_PROFILE_MOUNTAIN else 0.20
	var smoothed_height := lerpf(smooth, neighborhood, blend)
	_surface_height_cache[cache_key] = smoothed_height
	return smoothed_height

func _build_surface_transition_context(global_x: int, surface_biome: BiomeType) -> Dictionary:
	var cache_key := Vector2i(global_x, int(surface_biome))
	if _surface_transition_context_cache.has(cache_key):
		return _surface_transition_context_cache[cache_key]

	var max_probe := 96
	var nearest_dist := max_probe + 1
	var secondary := surface_biome
	var nearest_dir := 0
	for offset in range(8, max_probe + 1, 8):
		var left_biome := _get_surface_biome_from_climate(global_x - offset, 0)
		if left_biome != surface_biome and offset < nearest_dist:
			nearest_dist = offset
			secondary = left_biome
			nearest_dir = -1
		var right_biome := _get_surface_biome_from_climate(global_x + offset, 0)
		if right_biome != surface_biome and offset < nearest_dist:
			nearest_dist = offset
			secondary = right_biome
			nearest_dir = 1

	if secondary == surface_biome:
		var no_transition := {
			"has_transition": false,
			"secondary_surface_biome": surface_biome,
			"blend": 0.0,
			"nearest_dist": float(max_probe),
			"nearest_dir": 0,
		}
		_surface_transition_context_cache[cache_key] = no_transition
		return no_transition

	var dist_weight := clampf(1.0 - float(nearest_dist) / float(max_probe), 0.0, 1.0)
	var wobble := (noise_surface_feature.get_noise_1d(global_x * 0.43 + 211.0) + 1.0) * 0.5
	var blend := clampf(dist_weight * 0.66 + wobble * 0.34, 0.0, 1.0)
	var transition := {
		"has_transition": true,
		"secondary_surface_biome": secondary,
		"blend": blend,
		"nearest_dist": float(nearest_dist),
		"nearest_dir": nearest_dir,
	}
	_surface_transition_context_cache[cache_key] = transition
	return transition

func _get_column_biome_at_depth(global_x: int, global_y: int, surface_base: float, surface_biome: BiomeType, transition_context: Dictionary = {}) -> BiomeType:
	var depth_noise := noise_continental.get_noise_1d(global_x + 71) * 18.0
	var underground_threshold := surface_base + 100.0 + depth_noise
	if global_y <= underground_threshold:
		if bool(transition_context.get("has_transition", false)):
			var transition_blend := float(transition_context.get("blend", 0.0))
			var proximity := clampf(1.0 - float(transition_context.get("nearest_dist", 96.0)) / 96.0, 0.0, 1.0)
			var surface_mix := clampf(transition_blend * 0.36 + proximity * 0.25, 0.0, 0.58)
			if surface_mix > 0.0:
				var seam_warp := noise_tunnel.get_noise_2d(global_x * 0.041 + 23.0, global_y * 0.037 - 19.0) * 7.0
				var warped_x := global_x + seam_warp
				var surface_gate := (noise_temperature.get_noise_2d(warped_x * 0.14 + 91.0, global_y * 0.19 - 73.0) + 1.0) * 0.5
				if surface_gate < surface_mix:
					return int(transition_context.get("secondary_surface_biome", surface_biome))
		return surface_biome

	var moist = noise_moisture.get_noise_2d(global_x, global_y * 0.5)
	var current_b_data = biome_params[surface_biome]
	var ug_biome: BiomeType = current_b_data.underground_biome

	if bool(transition_context.get("has_transition", false)):
		var secondary_surface: BiomeType = int(transition_context.get("secondary_surface_biome", surface_biome))
		var secondary_b_data = biome_params.get(secondary_surface, current_b_data)
		var secondary_ug_biome: BiomeType = secondary_b_data.underground_biome
		if secondary_ug_biome != ug_biome:
			var transition_blend := float(transition_context.get("blend", 0.0))
			var proximity := clampf(1.0 - float(transition_context.get("nearest_dist", 96.0)) / 96.0, 0.0, 1.0)
			var transition_mix := clampf(transition_blend * 0.74 + proximity * 0.24, 0.0, 0.94)
			var seam_warp := noise_tunnel.get_noise_2d(global_x * 0.033 - 17.0, global_y * 0.021 + 29.0) * 9.0
			var warped_x := global_x + seam_warp
			var boundary_noise := (noise_cave_region.get_noise_2d(warped_x * 0.19 + 151.0, global_y * 0.11 - 89.0) + 1.0) * 0.5
			if boundary_noise < transition_mix:
				ug_biome = secondary_ug_biome

	if moist > 0.4 and global_y > underground_threshold + 200.0:
		return BiomeType.UNDERGROUND_SWAMP
	return ug_biome

func _make_surface_entrance_none() -> Dictionary:
	return {
		"type": SURFACE_ENTRANCE_NONE,
		"center_x": 0.0,
		"lip_y": 0.0,
		"width": 0.0,
		"depth": 0.0,
		"flare": 0.0,
	}

func _select_surface_entrance_type(relief_profile: String, biome_name: String, selector: float, is_spawn_safe: bool) -> String:
	if is_spawn_safe:
		return SURFACE_ENTRANCE_NONE
	if relief_profile == RELIEF_PROFILE_BASIN or biome_name == "swamp":
		return SURFACE_ENTRANCE_NONE

	if relief_profile == RELIEF_PROFILE_MOUNTAIN:
		if selector > 0.78:
			return SURFACE_ENTRANCE_HILLSIDE_CUT
		if selector > 0.70:
			return SURFACE_ENTRANCE_RAVINE_CUT
		return SURFACE_ENTRANCE_NONE

	if relief_profile == RELIEF_PROFILE_RIDGE:
		if selector > 0.82:
			return SURFACE_ENTRANCE_HILLSIDE_CUT
		if selector > 0.76:
			return SURFACE_ENTRANCE_RAVINE_CUT
		return SURFACE_ENTRANCE_NONE

	if biome_name == "desert":
		return SURFACE_ENTRANCE_RAVINE_CUT if selector > 0.86 else SURFACE_ENTRANCE_NONE

	# 平原/滚动丘陵优先给“可读的小入口”，而不是满地漏斗坑。
	if selector > 0.86:
		return SURFACE_ENTRANCE_RAVINE_CUT
	if selector > 0.72:
		return SURFACE_ENTRANCE_GENTLE_MOUTH
	return SURFACE_ENTRANCE_NONE

func _get_surface_entrance_info(global_x: int, surface_base: float, relief_profile: String, surface_biome: BiomeType, is_spawn_safe: bool, lane_y: float, shape_metrics: Dictionary) -> Dictionary:
	var biome_name := _get_surface_biome_name(surface_biome)
	var best := _make_surface_entrance_none()
	var best_dist := 1000000.0
	var slope_mag := absf(float(shape_metrics.get("slope", 0.0)))
	var ruggedness := float(shape_metrics.get("ruggedness", 0.0))
	var relief_span := float(shape_metrics.get("relief_span", 0.0))
	var crestness := float(shape_metrics.get("crestness", 0.0))
	var slope_left := float(shape_metrics.get("slope_left", 0.0))
	var slope_right := float(shape_metrics.get("slope_right", 0.0))
	var left_h_metric := float(shape_metrics.get("left_h", surface_base))
	var right_h_metric := float(shape_metrics.get("right_h", surface_base))
	var same_direction_slope := bool(shape_metrics.get("same_direction_slope", false))
	var is_peak_top := crestness < -3.2 and signf(slope_left) != signf(slope_right)
	var slope_balance := absf(absf(slope_left) - absf(slope_right))
	var can_hillside_cut := same_direction_slope and slope_mag > 0.22 and ruggedness > 4.8 and slope_balance > 0.08 and not is_peak_top
	var allow_any_entrance := not is_spawn_safe and (relief_span > 2.0 or ruggedness > 3.0 or slope_mag > 0.10)
	if not allow_any_entrance:
		return best
	var families := [
		{"spacing": 196, "selector_salt": 701, "center_salt": 709, "warp_scale": 0.31, "jitter_scale": 0.34},
		{"spacing": 288, "selector_salt": 811, "center_salt": 823, "warp_scale": 0.23, "jitter_scale": 0.30},
	]

	for family in families:
		var spacing := int(family.get("spacing", 168))
		var selector_salt := int(family.get("selector_salt", 701))
		var center_salt := int(family.get("center_salt", 709))
		var warp_scale := float(family.get("warp_scale", 0.33))
		var jitter_scale := float(family.get("jitter_scale", 0.45))
		var band_index := int(floor(float(global_x) / float(spacing)))

		for offset in range(-2, 3):
			var idx := band_index + offset
			var idx_f := float(idx)
			var selector_hash := _hash01(idx, selector_salt)
			var selector_noise := (noise_temperature.get_noise_1d(idx_f * 0.53 + float(selector_salt) * 0.11) + 1.0) * 0.5
			var selector := selector_hash * 0.58 + selector_noise * 0.42
			var entrance_type := _select_surface_entrance_type(relief_profile, biome_name, selector, is_spawn_safe)
			if entrance_type == SURFACE_ENTRANCE_NONE:
				continue
			if entrance_type == SURFACE_ENTRANCE_HILLSIDE_CUT and not can_hillside_cut:
				continue
			if entrance_type == SURFACE_ENTRANCE_GENTLE_MOUTH and (slope_mag < 0.10 and relief_span < 2.8):
				continue
			if entrance_type == SURFACE_ENTRANCE_RAVINE_CUT and slope_mag < 0.12 and ruggedness < 4.2:
				continue
			if not is_spawn_safe and is_peak_top:
				continue

			var base_center := float(idx * spacing) + float(spacing) * 0.5
			var center_warp := noise_surface_feature.get_noise_1d(idx_f * warp_scale + float(selector_salt) * 0.17) * float(spacing) * 0.28
			var center_jitter := (_hash01(idx, center_salt) - 0.5) * float(spacing) * jitter_scale
			var center_x := base_center + center_warp + center_jitter
			var cadence_break := (noise_moisture.get_noise_1d(center_x * 0.021 + float(selector_salt)) + 1.0) * 0.5
			if cadence_break < 0.34:
				continue

			var width := 0.0
			var depth := 0.0
			var flare := 0.0
			match entrance_type:
				SURFACE_ENTRANCE_GENTLE_MOUTH:
					width = 6.0 + _hash01(idx, center_salt + 10) * 2.2
					depth = 9.0 + _hash01(idx, center_salt + 18) * 6.0
					flare = 2.4
				SURFACE_ENTRANCE_RAVINE_CUT:
					width = 5.6 + _hash01(idx, center_salt + 24) * 2.4
					depth = 15.0 + _hash01(idx, center_salt + 31) * 11.0
					flare = 2.3
				SURFACE_ENTRANCE_HILLSIDE_CUT:
					width = 3.7 + _hash01(idx, center_salt + 52) * 1.8
					depth = 12.0 + _hash01(idx, center_salt + 59) * 8.0
					flare = 1.1
				SURFACE_ENTRANCE_PIT_FUNNEL:
					width = 5.0 + _hash01(idx, center_salt + 37) * 3.0
					depth = 18.0 + _hash01(idx, center_salt + 44) * 10.0
					flare = 6.0

			var dist := absf(float(global_x) - center_x)
			if dist <= width + flare and dist < best_dist:
				var side_bias := _hash01(idx, center_salt + 61) * 2.0 - 1.0
				if entrance_type == SURFACE_ENTRANCE_HILLSIDE_CUT:
					side_bias = -1.0 if left_h_metric < right_h_metric else 1.0
				var route_entry_x := center_x
				var route_exit_x := center_x
				var route_lane_y := lane_y + _hash01(idx, center_salt + 67) * 2.2
				var route_floor := maxf(
					route_lane_y - 2.0,
					surface_base + depth + 10.0 + _hash01(idx, center_salt + 51) * 12.0
				)
				route_floor = minf(route_floor, route_lane_y + 4.0)
				route_floor = maxf(route_floor, surface_base + depth + 8.0)
				var route_width := maxf(2.6, width * 0.34)
				match entrance_type:
					SURFACE_ENTRANCE_GENTLE_MOUTH:
						route_entry_x = center_x + side_bias * (width * 0.42 + 0.8)
						route_exit_x = route_entry_x + side_bias * (width * 0.56 + 1.4)
						route_width = maxf(2.45, width * 0.27)
					SURFACE_ENTRANCE_RAVINE_CUT:
						route_entry_x = center_x + side_bias * (width * 0.51 + 1.0)
						route_exit_x = center_x + side_bias * (width * 1.34 + 2.2)
						route_width = maxf(2.35, width * 0.24)
					SURFACE_ENTRANCE_HILLSIDE_CUT:
						route_entry_x = center_x + side_bias * (width * 0.94 + 1.9)
						route_exit_x = center_x + side_bias * (width * 1.92 + 3.4)
						route_width = maxf(1.85, width * 0.18)
					SURFACE_ENTRANCE_PIT_FUNNEL:
						route_entry_x = center_x + side_bias * (width * 0.16)
						route_exit_x = center_x + side_bias * (width * 0.42 + 1.5)
						route_width = maxf(2.4, width * 0.26)
				best = {
					"type": entrance_type,
					"center_x": center_x,
					"lip_y": floor(surface_base),
					"width": width,
					"depth": depth,
					"flare": flare,
					"side_bias": side_bias,
					"route_entry_x": route_entry_x,
					"route_exit_x": route_exit_x,
					"route_floor": route_floor,
					"route_lane_y": route_lane_y,
					"route_width": route_width,
					"route_seed": idx * 997 + center_salt,
				}
				best_dist = dist
	return best

func _should_carve_surface_entrance(global_x: int, global_y: int, entrance_info: Dictionary) -> bool:
	if entrance_info.is_empty() or String(entrance_info.get("type", SURFACE_ENTRANCE_NONE)) == SURFACE_ENTRANCE_NONE:
		return false
	var center_x := float(entrance_info.get("center_x", 0.0))
	var dx := absf(float(global_x) - center_x)
	var lip_y := float(entrance_info.get("lip_y", 0.0))
	var width := float(entrance_info.get("width", 0.0))
	var depth := float(entrance_info.get("depth", 0.0))
	var flare := float(entrance_info.get("flare", 0.0))
	var side_bias := float(entrance_info.get("side_bias", 0.0))
	var route_entry_x := float(entrance_info.get("route_entry_x", center_x))
	var route_width := float(entrance_info.get("route_width", 2.8))
	var entrance_type := String(entrance_info.get("type", SURFACE_ENTRANCE_NONE))
	var carve_floor := -INF
	var signed_dx := float(global_x) - center_x

	match entrance_type:
		SURFACE_ENTRANCE_GENTLE_MOUTH:
			if float(global_y) < lip_y - 1.0 or float(global_y) > lip_y + depth:
				return false
			var progress := clampf((float(global_y) - lip_y) / maxf(depth, 1.0), 0.0, 1.0)
			var mouth_center := lerpf(route_entry_x, center_x, pow(progress, 0.76))
			var open_side_scale := 1.06 if signf(signed_dx) == signf(side_bias) else 0.6
			var half_width := lerpf(maxf(1.8, width * 0.34 + flare * 0.26 * open_side_scale), route_width + 0.95, progress)
			var local_dx := absf(float(global_x) - mouth_center)
			if local_dx <= half_width:
				return true
			var edge_noise := (noise_surface_feature.get_noise_2d(float(global_x) * 0.19, float(global_y) * 0.11 + 37.0) + 1.0) * 0.5
			return local_dx <= half_width + 0.75 and edge_noise > 0.7
		SURFACE_ENTRANCE_RAVINE_CUT:
			if float(global_y) < lip_y - 1.0 or float(global_y) > lip_y + depth:
				return false
			var progress := clampf((float(global_y) - lip_y) / maxf(depth, 1.0), 0.0, 1.0)
			var ravine_center := lerpf(route_entry_x, center_x + side_bias * 0.8, pow(progress, 0.58))
			var wall_noise := noise_surface_feature.get_noise_2d(float(global_x) * 0.43, float(global_y) * 0.19 + 71.0) * 1.1
			var half_width := lerpf(maxf(1.7, width * 0.29 + flare * 0.45), route_width + 0.9, progress) + wall_noise
			var local_dx := absf(float(global_x) - ravine_center)
			if local_dx <= half_width:
				return true
			return local_dx <= half_width + 0.55 and progress < 0.82
		SURFACE_ENTRANCE_HILLSIDE_CUT:
			if float(global_y) < lip_y - 1.0 or float(global_y) > lip_y + depth:
				return false
			var progress := clampf((float(global_y) - lip_y) / maxf(depth, 1.0), 0.0, 1.0)
			var ledge_shift := side_bias * (width * 1.82 + 2.2)
			var cut_center := lerpf(route_entry_x + ledge_shift, route_entry_x, pow(progress, 0.72))
			var wall_bias := side_bias * (1.0 - progress) * 0.38
			var local_dx := float(global_x) - (cut_center + wall_bias)
			var half_width := lerpf(maxf(1.05, width * 0.18), route_width + 0.64, progress)
			if progress < 0.24 and local_dx * side_bias > 0.0:
				return false
			if absf(local_dx) <= half_width:
				return true
			var edge_noise := (noise_cave_region.get_noise_2d(float(global_x) * 0.24 + 13.0, float(global_y) * 0.13 - 17.0) + 1.0) * 0.5
			return absf(local_dx) <= half_width + 0.32 and edge_noise > 0.77
		SURFACE_ENTRANCE_PIT_FUNNEL:
			if dx > width + flare:
				return false
			var funnel_width := maxf(width * (0.35 + clampf((global_y - lip_y) / maxf(depth, 1.0), 0.0, 1.0) * 0.75), 1.0)
			if dx > funnel_width:
				return false
			carve_floor = lip_y + depth - (dx / funnel_width) * 4.0
		_:
			return false

	return float(global_y) <= carve_floor and float(global_y) >= lip_y - 1.0

func _should_carve_entrance_route(global_x: int, global_y: int, entrance_info: Dictionary) -> bool:
	if entrance_info.is_empty() or String(entrance_info.get("type", SURFACE_ENTRANCE_NONE)) == SURFACE_ENTRANCE_NONE:
		return false

	var lip_y := float(entrance_info.get("lip_y", 0.0))
	var depth := float(entrance_info.get("depth", 0.0))
	var route_floor := float(entrance_info.get("route_floor", lip_y))
	if route_floor <= lip_y + 2.0:
		return false
	var route_start_y := lip_y + maxf(depth * 0.58, 6.0)
	if float(global_y) <= route_start_y or float(global_y) > route_floor:
		return false

	var center_x := float(entrance_info.get("center_x", 0.0))
	var route_entry_x := float(entrance_info.get("route_entry_x", center_x))
	var route_exit_x := float(entrance_info.get("route_exit_x", center_x))
	var route_seed := float(int(entrance_info.get("route_seed", 0)))
	var route_width := float(entrance_info.get("route_width", 2.8))
	var route_lane_y := float(entrance_info.get("route_lane_y", route_floor + 4.0))
	var progress := clampf((float(global_y) - route_start_y) / maxf(route_floor - route_start_y, 1.0), 0.0, 1.0)
	var eased := pow(progress, 0.82)
	var meander := noise_cave_region.get_noise_2d(route_seed * 0.013 + progress * 2.7, progress * 6.1) * (0.8 + progress * 1.2)
	var drift := noise_tunnel.get_noise_2d(route_seed * 0.007 - 17.0, progress * 4.3) * (0.5 + progress * 1.0)
	var center := lerpf(route_entry_x, route_exit_x, eased) + meander + drift
	var corridor_half := lerpf(route_width + 0.45, route_width + 0.18, progress)
	var dx := absf(float(global_x) - center)
	if dx <= corridor_half:
		return true

	# 为连接段添加柔化边缘，避免出现规则竖直井筒。
	var edge_noise := (noise_surface_feature.get_noise_2d(float(global_x) * 0.22, float(global_y) * 0.17 + route_seed * 0.009) + 1.0) * 0.5
	if dx <= corridor_half + 0.75 and edge_noise > 0.63:
		return true

	# 入口末段强制接驳主矿道，避免“通道挖下去但断开”。
	if route_lane_y > route_floor + 1.0 and float(global_y) > route_floor and float(global_y) <= route_lane_y + 1.0:
		var link_progress := clampf((float(global_y) - route_floor) / maxf(route_lane_y - route_floor, 1.0), 0.0, 1.0)
		var link_center := route_exit_x + noise_tunnel.get_noise_2d(route_seed * 0.017 + link_progress * 3.1, link_progress * 4.7) * 0.85
		var link_half := lerpf(maxf(1.9, route_width * 0.86), maxf(2.8, route_width + 0.8), link_progress)
		if absf(float(global_x) - link_center) <= link_half:
			return true

	return false

func _make_mountain_breach_none() -> Dictionary:
	return {
		"enabled": false,
	}

func _point_to_segment_distance(px: float, py: float, ax: float, ay: float, bx: float, by: float) -> Dictionary:
	var abx := bx - ax
	var aby := by - ay
	var len_sq := maxf(abx * abx + aby * aby, 0.0001)
	var apx := px - ax
	var apy := py - ay
	var t := clampf((apx * abx + apy * aby) / len_sq, 0.0, 1.0)
	var qx := ax + abx * t
	var qy := ay + aby * t
	var dx := px - qx
	var dy := py - qy
	return {
		"dist": sqrt(dx * dx + dy * dy),
		"t": t,
		"qx": qx,
		"qy": qy,
	}

func _get_mountain_worm_breach_info(global_x: int, surface_base: float, relief_profile: String, _shape_metrics: Dictionary, lane_y: float, is_spawn_safe: bool) -> Dictionary:
	if is_spawn_safe:
		return _make_mountain_breach_none()
	if relief_profile != RELIEF_PROFILE_MOUNTAIN and relief_profile != RELIEF_PROFILE_RIDGE:
		return _make_mountain_breach_none()

	# 每个 96 格山体区段共享同一条破口蠕虫，避免列级不一致导致“入口消失”。
	var zone_index := int(floor(float(global_x) / 96.0))
	var zone_key := "%s:%d" % [relief_profile, zone_index]
	if _mountain_breach_zone_cache.has(zone_key):
		return _mountain_breach_zone_cache[zone_key]

	var zone_presence := _hash01(zone_index, 3721)
	if relief_profile == RELIEF_PROFILE_MOUNTAIN and zone_presence < 0.78:
		var no_mountain := _make_mountain_breach_none()
		_mountain_breach_zone_cache[zone_key] = no_mountain
		return no_mountain
	if relief_profile == RELIEF_PROFILE_RIDGE and zone_presence < 0.90:
		var no_ridge := _make_mountain_breach_none()
		_mountain_breach_zone_cache[zone_key] = no_ridge
		return no_ridge

	var zone_start := zone_index * 96
	var zone_end := zone_start + 95
	var zone_low := 999999.0
	var zone_high := -999999.0
	for scan_x in range(zone_start + 6, zone_end - 6, 4):
		var sb := _get_surface_biome_from_climate(scan_x, 0)
		var sy := _get_surface_height_for_biome(scan_x, sb)
		zone_low = minf(zone_low, sy)
		zone_high = maxf(zone_high, sy)

	var best_x := zone_start + 48
	var best_slope := 0.0
	var best_score := -1.0
	for scan_x in range(zone_start + 8, zone_end - 8, 2):
		var sb := _get_surface_biome_from_climate(scan_x, 0)
		var sy := _get_surface_height_for_biome(scan_x, sb)
		var l_biome := _get_surface_biome_from_climate(scan_x - 3, 0)
		var r_biome := _get_surface_biome_from_climate(scan_x + 3, 0)
		var left_y := _get_surface_height_for_biome(scan_x - 3, l_biome)
		var right_y := _get_surface_height_for_biome(scan_x + 3, r_biome)
		var slope := (right_y - left_y) / 6.0
		var elev := sy - zone_low
		var elev_norm := elev / maxf(zone_high - zone_low, 1.0)
		var score := absf(slope) * 0.72 + elev_norm * 0.28
		if score > best_score:
			best_score = score
			best_slope = slope
			best_x = scan_x

	if best_score < 0.28 or absf(best_slope) < 0.26:
		var no_breach := _make_mountain_breach_none()
		_mountain_breach_zone_cache[zone_key] = no_breach
		return no_breach

	var outside_dir := -signf(best_slope)
	if outside_dir == 0.0:
		outside_dir = -1.0 if _hash01(zone_index, 3917) < 0.5 else 1.0
	var inward_dir := -outside_dir

	var mouth_x := float(best_x) + outside_dir * (0.5 + _hash01(zone_index, 3743) * 0.9)
	var mouth_tile_x := int(round(mouth_x))
	var mouth_biome := _get_surface_biome_from_climate(mouth_tile_x, 0)
	var mouth_y := _get_surface_height_for_biome(mouth_tile_x, mouth_biome)

	# 蠕虫从山体内部向地表侧坡破口，再继续向主洞道收敛。
	var turn_x := mouth_x + inward_dir * (3.4 + _hash01(zone_index, 3779) * 2.8)
	var turn_y := mouth_y + 5.8 + _hash01(zone_index, 3787) * 3.2
	var join_x := turn_x + inward_dir * (8.0 + _hash01(zone_index, 3793) * 6.0)
	var mouth_lane_y := _get_cave_lane_y(mouth_tile_x, mouth_y)
	var join_y := clampf(mouth_lane_y + _hash01(zone_index, 3811) * 3.2, mouth_y + 14.0, mouth_y + 42.0)
	var route_floor := maxf(join_y + 2.0, mouth_lane_y + 1.0)

	var mouth_radius := 1.45 + _hash01(zone_index, 3809) * 0.4
	var neck_radius := 1.25 + _hash01(zone_index, 3821) * 0.3
	var body_radius := 1.95 + _hash01(zone_index, 3851) * 0.7
	var join_radius := 2.25 + _hash01(zone_index, 3863) * 0.7

	var breach_info := {
		"enabled": true,
		"mouth_x": mouth_x,
		"mouth_y": mouth_y,
		"mouth_radius": mouth_radius,
		"turn_x": turn_x,
		"turn_y": turn_y,
		"join_x": join_x,
		"join_y": join_y,
		"route_floor": route_floor,
		"lane_y": mouth_lane_y,
		"neck_radius": neck_radius,
		"body_radius": body_radius,
		"join_radius": join_radius,
		"outside_dir": outside_dir,
		"inward_dir": inward_dir,
		"seed": zone_index * 901 + 383,
	}
	_mountain_breach_zone_cache[zone_key] = breach_info
	return breach_info

func _should_carve_mountain_worm_breach(global_x: int, global_y: int, breach_info: Dictionary) -> bool:
	if breach_info.is_empty() or not bool(breach_info.get("enabled", false)):
		return false

	var mouth_y := float(breach_info.get("mouth_y", 0.0))
	var route_floor := float(breach_info.get("route_floor", mouth_y))
	if route_floor <= mouth_y + 4.0:
		return false
	if float(global_y) < mouth_y - 1.0 or float(global_y) > route_floor:
		return false

	var mouth_x := float(breach_info.get("mouth_x", 0.0))
	var turn_x := float(breach_info.get("turn_x", mouth_x))
	var turn_y := float(breach_info.get("turn_y", mouth_y + 5.0))
	var join_x := float(breach_info.get("join_x", turn_x))
	var join_y := float(breach_info.get("join_y", route_floor))
	var lane_y := float(breach_info.get("lane_y", route_floor))
	var mouth_radius := float(breach_info.get("mouth_radius", 1.8))
	var join_radius := float(breach_info.get("join_radius", 2.2))
	var inward_dir := float(breach_info.get("inward_dir", -1.0))
	var seed_probe := float(int(breach_info.get("seed", 0)))

	# 保证山体侧面至少有一个可见开口，不会被后续扰动完全抹掉。
	if absf(float(global_y) - mouth_y) <= 1.6 and absf(float(global_x) - mouth_x) <= mouth_radius:
		return true

	var progress := clampf((float(global_y) - mouth_y + 1.0) / maxf(route_floor - mouth_y + 1.0, 1.0), 0.0, 1.0)
	var seg1 := _point_to_segment_distance(float(global_x), float(global_y), mouth_x, mouth_y, turn_x, turn_y)
	var seg2 := _point_to_segment_distance(float(global_x), float(global_y), turn_x, turn_y, join_x, join_y)

	var neck_radius := float(breach_info.get("neck_radius", 1.15))
	var body_radius := float(breach_info.get("body_radius", 2.2))
	var seg1_radius := lerpf(mouth_radius * 0.82, neck_radius, float(seg1.get("t", 0.0)))
	var seg2_radius := lerpf(neck_radius, body_radius, float(seg2.get("t", 0.0)))
	var route_t := pow(progress, 0.78)
	var edge_noise := noise_surface_feature.get_noise_2d(float(global_x) * 0.24 + 41.0, float(global_y) * 0.16 - 13.0 + seed_probe * 0.001)
	var radius_noise := noise_cave_region.get_noise_2d(seed_probe * 0.009 + route_t * 3.1, float(global_y) * 0.12 - 17.0)
	var detail := edge_noise * 0.16 + radius_noise * 0.22

	# 入口上段保持向山体内侧单向推进，禁止沿地表横插。
	if float(global_y) <= turn_y and (float(global_x) - mouth_x) * inward_dir < -0.08:
		return false
	if progress < 0.35:
		if (float(global_x) - mouth_x) * inward_dir < -0.22:
			return false
		if float(global_y) < mouth_y + 1.0 and absf(float(global_x) - mouth_x) > mouth_radius:
			return false

	if float(seg1.get("dist", 999.0)) <= seg1_radius + detail:
		return true
	if float(seg2.get("dist", 999.0)) <= seg2_radius + detail:
		return true

	# 在主洞道深度提供联通保底空腔，避免“入口成了孤立羊肠道”。
	if absf(float(global_y) - lane_y) <= join_radius and absf(float(global_x) - join_x) <= join_radius + 0.9:
		return true
	return false

func _build_surface_column_context(global_x: int) -> Dictionary:
	if _surface_column_context_cache.has(global_x):
		return _surface_column_context_cache[global_x]

	var surface_biome := _get_surface_biome_from_climate(global_x, 0)
	var transition_context := _build_surface_transition_context(global_x, surface_biome)
	var relief_profile := _select_surface_relief_profile(global_x, surface_biome)
	var surface_base := _get_surface_height_for_biome(global_x, surface_biome)
	var is_spawn_safe := _is_spawn_safe_tile_x(global_x)
	var lane_y := _get_cave_lane_y(global_x, surface_base)
	var shape_metrics := _build_surface_shape_metrics(global_x)
	var entrance_info := _get_surface_entrance_info(global_x, surface_base, relief_profile, surface_biome, is_spawn_safe, lane_y, shape_metrics)
	var mountain_breach_info := _get_mountain_worm_breach_info(global_x, surface_base, relief_profile, shape_metrics, lane_y, is_spawn_safe)
	var context := {
		"surface_biome": surface_biome,
		"transition_context": transition_context,
		"relief_profile": relief_profile,
		"surface_base": surface_base,
		"is_spawn_safe": is_spawn_safe,
		"shape_metrics": shape_metrics,
		"lane_y": lane_y,
		"entrance_info": entrance_info,
		"mountain_breach_info": mountain_breach_info,
	}
	_surface_column_context_cache[global_x] = context
	return context

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
	var surface_biome := _get_surface_biome_from_climate(global_x, 0)
	return _get_surface_height_for_biome(global_x, surface_biome)

func get_surface_relief_profile_at_tile(global_x: int) -> String:
	var surface_biome := _get_surface_biome_from_climate(global_x, 0)
	return _select_surface_relief_profile(global_x, surface_biome)

func get_surface_relief_profile_at_pos(global_pos: Vector2) -> String:
	var tile_x = int(global_pos.x / 16.0)
	return get_surface_relief_profile_at_tile(tile_x)

func _hash01(index: int, salt: int) -> float:
	var n := index * 1103515245 + salt * 12345 + seed_value * 265443576
	n = n ^ (n >> 13)
	n = n * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0x7fffffff) / 2147483647.0

func _get_vertical_connector_distance(global_x: int) -> float:
	var anchor_a := (noise_cave_region.get_noise_1d(global_x * 0.19 + 33.0) + 1.0) * 0.5
	var anchor_b := (noise_tunnel.get_noise_1d(global_x * 0.11 - 57.0) + 1.0) * 0.5
	var anchor_c := (noise_surface_feature.get_noise_1d(global_x * 0.07 + 101.0) + 1.0) * 0.5
	var anchor_strength := anchor_a * 0.50 + anchor_b * 0.32 + anchor_c * 0.18
	return clampf((0.84 - anchor_strength) * 28.0, 0.0, 28.0)

func _get_vertical_connector_depth_distance(global_x: int, depth: float) -> float:
	var depth_a := 44.0 + (noise_cave_region.get_noise_1d(global_x * 0.043 + 91.0) + 1.0) * 0.5 * 96.0
	var depth_b := 128.0 + (noise_tunnel.get_noise_1d(global_x * 0.031 - 47.0) + 1.0) * 0.5 * 102.0
	var depth_c := 198.0 + (noise_surface_feature.get_noise_1d(global_x * 0.027 + 19.0) + 1.0) * 0.5 * 56.0
	var nearest := minf(absf(depth - depth_a), absf(depth - depth_b))
	return minf(nearest, absf(depth - depth_c))

func _should_place_vertical_connector(global_x: int, depth: float) -> bool:
	# Keep sparse X anchors but remove strict Y-periodic repetition.
	if depth <= 36.0 or depth >= 240.0:
		return false
	if _get_vertical_connector_distance(global_x) >= 4.0:
		return false
	if _get_vertical_connector_depth_distance(global_x, depth) >= 16.0:
		return false

	var depth_gate_primary := (noise_cave_region.get_noise_2d(global_x * 0.021 + 77.0, depth * 0.018) + 1.0) * 0.5
	var depth_gate_secondary := (noise_tunnel.get_noise_2d(global_x * 0.015 - 41.0, depth * 0.026) + 1.0) * 0.5
	var anti_stripe_gate := (noise_surface_feature.get_noise_2d(global_x * 0.041 + 19.0, depth * 0.017 - 23.0) + 1.0) * 0.5
	return depth_gate_primary > 0.64 and depth_gate_secondary > 0.52 and anti_stripe_gate > 0.47

func _get_cave_anchor_depth_at_x(global_x: int) -> float:
	var base_depth := 58.0
	var anchor_variation := noise_cave_region.get_noise_1d(global_x * 2) * 22.0
	var branch_bias := noise_tunnel.get_noise_1d(global_x + 37) * 10.0
	return base_depth + anchor_variation + branch_bias

func _get_cave_lane_y(global_x: int, surface_base: float) -> float:
	var seed_phase := float(seed_value % 8192) * 0.0009
	var macro := noise_cave_region.get_noise_1d(global_x * 0.63 + seed_phase) * 24.0
	var mid := noise_tunnel.get_noise_1d(global_x * 1.27 - 41.0) * 11.5
	var drift := noise_moisture.get_noise_1d(global_x * 0.29 + 173.0) * 8.0
	var local_sway := noise_cave.get_noise_1d(global_x + 133) * 4.5
	var lane_depth := 60.0 + macro + mid + drift + local_sway
	var lane_y := surface_base + lane_depth
	return clampf(lane_y, surface_base + 30.0, surface_base + 240.0)

func _get_cave_region_info_from_context(global_x: int, global_y: int, surface_base: float, relief_profile: String, lane_y: float) -> Dictionary:
	var depth = global_y - surface_base
	var info = {
		"region": CAVE_REGION_SURFACE,
		"reachable": true,
		"openness": 1.0,
		"depth": depth,
		"relief_profile": relief_profile,
	}

	if depth < 28.0:
		return info

	var lane_dist = abs(global_y - lane_y)
	var connector_dist = _get_vertical_connector_distance(global_x)
	var chamber_val = noise_cave_region.get_noise_2d(global_x * 0.025, global_y * 0.025)
	var pocket_val = noise_cave_region.get_noise_2d(global_x * 0.055 + 120.0, global_y * 0.055 - 87.0)

	info["region"] = CAVE_REGION_SOLID
	info["reachable"] = false
	info["openness"] = 0.0

	if _should_place_vertical_connector(global_x, depth):
		info["region"] = CAVE_REGION_CONNECTOR
		info["reachable"] = true
		info["openness"] = 0.55
	elif depth > 48.0 and chamber_val > 0.78:
		info["region"] = CAVE_REGION_OPEN_CAVERN
		info["reachable"] = true
		info["openness"] = 0.9
	elif depth > 40.0 and chamber_val > 0.62:
		info["region"] = CAVE_REGION_CHAMBER
		info["reachable"] = true
		info["openness"] = 0.72
	elif depth > 24.0 and lane_dist < 5.0:
		info["region"] = CAVE_REGION_TUNNEL
		info["reachable"] = true
		info["openness"] = 0.35
	elif depth > 54.0 and pocket_val > 0.76:
		info["region"] = CAVE_REGION_POCKET
		info["reachable"] = lane_dist < 16.0 or chamber_val > 0.5 or connector_dist < 7.0
		info["openness"] = 0.18

	return info

func get_cave_region_info_at_tile(global_x: int, global_y: int) -> Dictionary:
	var surface_base = get_surface_height_at(global_x)
	var relief_profile := get_surface_relief_profile_at_tile(global_x)
	var lane_y = _get_cave_lane_y(global_x, surface_base)
	return _get_cave_region_info_from_context(global_x, global_y, surface_base, relief_profile, lane_y)

func get_cave_region_info_at_pos(global_pos: Vector2) -> Dictionary:
	var tile_x = int(global_pos.x / 16.0)
	var tile_y = int(global_pos.y / 16.0)
	return get_cave_region_info_at_tile(tile_x, tile_y)

func get_surface_feature_tag_at_tile(global_x: int, global_y: int) -> String:
	var surface_y = int(floor(get_surface_height_at(global_x)))
	if abs(global_y - surface_y) > 8:
		return SURFACE_FEATURE_NONE

	var biome = get_biome_at(global_x, 0)
	var feature_val = (noise_surface_feature.get_noise_2d(global_x, 0) + 1.0) * 0.5
	match biome:
		BiomeType.DESERT:
			return SURFACE_FEATURE_DESERT_SPIRE if feature_val > 0.82 else SURFACE_FEATURE_NONE
		BiomeType.TUNDRA:
			return SURFACE_FEATURE_FROST_SPIRE if feature_val > 0.78 else SURFACE_FEATURE_NONE
		BiomeType.SWAMP:
			return SURFACE_FEATURE_MUD_MOUND if feature_val > 0.76 else SURFACE_FEATURE_NONE
		BiomeType.PLAINS:
			return SURFACE_FEATURE_GRASS_KNOLL if feature_val > 0.8 else SURFACE_FEATURE_NONE
		BiomeType.FOREST:
			return SURFACE_FEATURE_STONE_OUTCROP if feature_val > 0.77 else SURFACE_FEATURE_NONE
		_:
			return SURFACE_FEATURE_NONE

func get_surface_feature_tag_at_pos(global_pos: Vector2) -> String:
	var tile_x = int(global_pos.x / 16.0)
	var tile_y = int(global_pos.y / 16.0)
	return get_surface_feature_tag_at_tile(tile_x, tile_y)

func _get_surface_feature_tag_from_context(global_x: int, global_y: int, surface_y: int, biome: BiomeType) -> String:
	if abs(global_y - surface_y) > 8:
		return SURFACE_FEATURE_NONE
	var feature_val = (noise_surface_feature.get_noise_2d(global_x, 0) + 1.0) * 0.5
	match biome:
		BiomeType.DESERT:
			return SURFACE_FEATURE_DESERT_SPIRE if feature_val > 0.82 else SURFACE_FEATURE_NONE
		BiomeType.TUNDRA:
			return SURFACE_FEATURE_FROST_SPIRE if feature_val > 0.78 else SURFACE_FEATURE_NONE
		BiomeType.SWAMP:
			return SURFACE_FEATURE_MUD_MOUND if feature_val > 0.76 else SURFACE_FEATURE_NONE
		BiomeType.PLAINS:
			return SURFACE_FEATURE_GRASS_KNOLL if feature_val > 0.8 else SURFACE_FEATURE_NONE
		BiomeType.FOREST:
			return SURFACE_FEATURE_STONE_OUTCROP if feature_val > 0.77 else SURFACE_FEATURE_NONE
		_:
			return SURFACE_FEATURE_NONE

func _get_cave_geology_radius_scale(surface_biome: BiomeType, relief_profile: String, depth: float) -> float:
	var scale := 1.0
	match surface_biome:
		BiomeType.DESERT:
			scale = 0.88
		BiomeType.SWAMP:
			scale = 1.12
		BiomeType.TUNDRA:
			scale = 0.93
		BiomeType.PLAINS:
			scale = 1.02
		_:
			scale = 1.0

	if relief_profile == RELIEF_PROFILE_MOUNTAIN:
		scale *= 0.9
	elif relief_profile == RELIEF_PROFILE_BASIN:
		scale *= 1.1

	var depth_gain := clampf((depth - 80.0) / 220.0, 0.0, 1.0)
	scale *= lerpf(1.0, 1.18, depth_gain)
	return scale

func _get_worm_lane_center_y(global_x: int, lane_y: float, depth: float) -> float:
	var curve_a := noise_tunnel.get_noise_2d(global_x * 0.015 + 17.0, depth * 0.008 - 31.0) * 7.5
	var curve_b := noise_cave_region.get_noise_2d(global_x * 0.028 - 53.0, depth * 0.014 + 11.0) * 4.2
	var curve_c := noise_surface_feature.get_noise_2d(global_x * 0.009 + 191.0, depth * 0.004 - 73.0) * 2.1
	return lane_y + curve_a + curve_b + curve_c

func _get_worm_main_radius(global_x: int, depth: float, surface_biome: BiomeType, relief_profile: String) -> float:
	var large := (noise_cave_region.get_noise_2d(global_x * 0.007 + 41.0, depth * 0.005 - 19.0) + 1.0) * 0.5
	var medium := (noise_tunnel.get_noise_2d(global_x * 0.021 - 73.0, depth * 0.013 + 29.0) + 1.0) * 0.5
	var radius := 3.8 + large * 4.2 + medium * 2.0
	radius *= _get_cave_geology_radius_scale(surface_biome, relief_profile, depth)
	return maxf(radius, 2.2)

func _should_carve_worm_main(global_x: int, global_y: int, lane_y: float, depth: float, surface_biome: BiomeType, relief_profile: String) -> bool:
	var center_y := _get_worm_lane_center_y(global_x, lane_y, depth)
	var radius := _get_worm_main_radius(global_x, depth, surface_biome, relief_profile)
	var dist := absf(float(global_y) - center_y)
	if dist > radius + 1.2:
		return false

	var edge_t := clampf(1.0 - dist / maxf(radius, 0.001), 0.0, 1.0)
	var wall_detail := noise_surface_feature.get_noise_2d(float(global_x) * 0.23 + 17.0, float(global_y) * 0.19 - 31.0) * (0.55 + edge_t * 0.45)
	var threshold := radius + wall_detail * 1.1
	return dist <= threshold

func _should_carve_worm_branch(global_x: int, global_y: int, lane_y: float, depth: float, surface_biome: BiomeType, relief_profile: String) -> bool:
	if depth < 42.0:
		return false

	var branch_gate := (noise_cave_region.get_noise_2d(global_x * 0.009 + 77.0, depth * 0.011 - 43.0) + 1.0) * 0.5
	if branch_gate < 0.67:
		return false

	var dir_selector := noise_tunnel.get_noise_2d(global_x * 0.013 - 17.0, depth * 0.007 + 59.0)
	var branch_dir := -1.0 if dir_selector < 0.0 else 1.0
	var main_center := _get_worm_lane_center_y(global_x, lane_y, depth)
	var lateral_strength := 8.0 + (noise_cave.get_noise_2d(global_x * 0.02 + 13.0, depth * 0.015) + 1.0) * 0.5 * 10.0
	var growth := clampf((depth - 38.0) / 150.0, 0.0, 1.0)
	var branch_center := main_center + branch_dir * lateral_strength * growth
	var branch_radius := _get_worm_main_radius(global_x, depth, surface_biome, relief_profile) * 0.52

	var dist := absf(float(global_y) - branch_center)
	if dist > branch_radius + 0.9:
		return false

	var branch_detail := noise_surface_feature.get_noise_2d(float(global_x) * 0.29 + 91.0, float(global_y) * 0.27 - 27.0) * 0.7
	return dist <= branch_radius + branch_detail

func _should_carve_accessible_cave_with_context(global_x: int, global_y: int, surface_base: float, lane_y: float, cave_info: Dictionary, is_spawn_protected: bool, surface_biome: BiomeType) -> bool:
	if is_spawn_protected:
		return false
	var depth = global_y - surface_base
	if depth <= 42.0:
		return false
	var relief_profile := String(cave_info.get("relief_profile", RELIEF_PROFILE_ROLLING))
	var c_val = noise_cave.get_noise_2d(global_x, global_y)
	var t_val = noise_tunnel.get_noise_2d(global_x, global_y)
	var cave_thresh = 0.55 if depth < 80.0 else 0.48
	var tunnel_thresh = 0.85
	var noise_carve = c_val > cave_thresh or t_val > tunnel_thresh
	var main_worm_carve := _should_carve_worm_main(global_x, global_y, lane_y, depth, surface_biome, relief_profile)
	var branch_worm_carve := _should_carve_worm_branch(global_x, global_y, lane_y, depth, surface_biome, relief_profile)
	var organic_carve := main_worm_carve or branch_worm_carve
	var lane_dist = abs(global_y - lane_y)

	# 浅层禁止随机噪声打孔，优先依赖入口和主矿道几何，避免“地上到处是坑”。
	if depth < 78.0:
		noise_carve = false
	if depth < 64.0 and lane_dist > 6.0 and cave_info.get("region", CAVE_REGION_SOLID) != CAVE_REGION_CONNECTOR:
		organic_carve = main_worm_carve and lane_dist <= 4.0
	match cave_info["region"]:
		CAVE_REGION_CONNECTOR:
			return true
		CAVE_REGION_OPEN_CAVERN:
			return lane_dist <= 12.0 or organic_carve or noise_carve
		CAVE_REGION_CHAMBER:
			return lane_dist <= 8.0 or organic_carve or noise_carve
		CAVE_REGION_TUNNEL:
			return lane_dist <= 3.0 or main_worm_carve or (organic_carve and noise_carve)
		CAVE_REGION_POCKET:
			return (branch_worm_carve or noise_carve) and cave_info["reachable"]
		_:
			return organic_carve or noise_carve

func _should_carve_accessible_cave(global_x: int, global_y: int, surface_base: float, is_spawn_protected: bool) -> bool:
	var lane_y = _get_cave_lane_y(global_x, surface_base)
	var relief_profile := get_surface_relief_profile_at_tile(global_x)
	var cave_info = _get_cave_region_info_from_context(global_x, global_y, surface_base, relief_profile, lane_y)
	var surface_biome := _get_surface_biome_from_climate(global_x, 0)
	return _should_carve_accessible_cave_with_context(global_x, global_y, surface_base, lane_y, cave_info, is_spawn_protected, surface_biome)

func _apply_surface_features(coord: Vector2i, result: Dictionary, column_contexts: Array) -> void:
	for x in range(3, 61):
		var global_x = coord.x * 64 + x
		var column_context: Dictionary = column_contexts[x]
		var surface_base = float(column_context.get("surface_base", 300.0))
		var top_y = int(floor(surface_base))
		var feature = _get_surface_feature_tag_from_context(global_x, top_y, top_y, int(column_context.get("surface_biome", BiomeType.FOREST)))
		if feature == SURFACE_FEATURE_NONE:
			continue
		if _is_in_structure_forbidden_zone(global_x, top_y):
			continue

		match feature:
			SURFACE_FEATURE_DESERT_SPIRE:
				for h in range(1, 4):
					result[0][Vector2i(x, top_y - h)] = {"source": tile_source_id, "atlas": biome_params[BiomeType.DESERT]["stone_block"]}
			SURFACE_FEATURE_FROST_SPIRE:
				for h in range(1, 5):
					result[0][Vector2i(x, top_y - h)] = {"source": tile_source_id, "atlas": biome_params[BiomeType.TUNDRA]["stone_block"]}
			SURFACE_FEATURE_MUD_MOUND:
				for ox in range(-1, 2):
					result[0][Vector2i(x + ox, top_y - 1)] = {"source": tile_source_id, "atlas": biome_params[BiomeType.SWAMP]["surface_block"]}
			SURFACE_FEATURE_GRASS_KNOLL:
				result[0][Vector2i(x, top_y - 1)] = {"source": grass_dirt_source_id, "atlas": grass_tile}
			SURFACE_FEATURE_STONE_OUTCROP:
				for ox in range(-1, 2):
					if ox == 0:
						result[0][Vector2i(x + ox, top_y - 1)] = {"source": tile_source_id, "atlas": stone_tile}
					elif abs(ox) == 1 and (noise_surface_feature.get_noise_2d(global_x + ox, 20) > -0.2):
						result[0][Vector2i(x + ox, top_y)] = {"source": tile_source_id, "atlas": stone_tile}

func generate_chunk_cells(coord: Vector2i, critical_only: bool = false) -> Dictionary:
	var result = { 0: {}, 1: {}, 2: {} }
	var chunk_origin = coord * 64
	var column_contexts: Array = []
	
	for x in range(64):
		var global_x = chunk_origin.x + x
		var column_context := _build_surface_column_context(global_x)
		var surface_base: float = column_context.get("surface_base", 300.0)
		var is_spawn_safe_column: bool = column_context.get("is_spawn_safe", false)
		var transition_context: Dictionary = column_context.get("transition_context", {})
		var lane_y: float = column_context.get("lane_y", surface_base + 54.0)
		var surface_biome: BiomeType = column_context.get("surface_biome", BiomeType.FOREST)
		var relief_profile: String = column_context.get("relief_profile", RELIEF_PROFILE_ROLLING)
		var entrance_info: Dictionary = column_context.get("entrance_info", _make_surface_entrance_none())
		var mountain_breach_info: Dictionary = column_context.get("mountain_breach_info", _make_mountain_breach_none())
		column_contexts.append(column_context)
		
		for y in range(64):
			var global_y = chunk_origin.y + y
			var local_pos = Vector2i(x, y)
			
			# 2. 垂直填充逻辑
			var is_solid = global_y > surface_base
			var current_biome: BiomeType = surface_biome
			var has_current_biome := false
			var cave_info := {}
			if is_solid:
				current_biome = _get_column_biome_at_depth(global_x, global_y, surface_base, surface_biome, transition_context)
				has_current_biome = true
				if _should_carve_mountain_worm_breach(global_x, global_y, mountain_breach_info):
					is_solid = false
				elif _should_carve_surface_entrance(global_x, global_y, entrance_info):
					is_solid = false
				elif _should_carve_entrance_route(global_x, global_y, entrance_info):
					is_solid = false
				else:
					cave_info = _get_cave_region_info_from_context(global_x, global_y, surface_base, relief_profile, lane_y)
			
			# 3. 深度洞穴
			if is_solid:
				var dist_from_surf = global_y - surface_base
				var is_spawn_protected = is_spawn_safe_column and dist_from_surf < 40.0
				
				if _should_carve_accessible_cave_with_context(global_x, global_y, surface_base, lane_y, cave_info, is_spawn_protected, surface_biome):
					is_solid = false
					
			if is_solid:
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
					if not critical_only:
						var mineral_tile = _get_mineral_at(global_x, global_y, depth)
						if mineral_tile != Vector2i(-1, -1):
							tile_data["atlas"] = mineral_tile
				
				# 强制将所有实心方块放在 Layer 0，确保玩家始终有物理碰撞
				result[0][local_pos] = tile_data
				
			# --- 背景墙逻辑：防止地下出现虚空 ---
			# 只要是在地表以下，就在 Layer 1 (背景) 放置背景墙
			if global_y > surface_base + 3.0:
				if not has_current_biome:
					current_biome = _get_column_biome_at_depth(global_x, global_y, surface_base, surface_biome, transition_context)
					has_current_biome = true
				var bg_biome = current_biome
				var bg_data = biome_params.get(bg_biome, biome_params[BiomeType.FOREST])
				
				# 在地下深处强制放置背景墙以填补洞穴
				var bg_tile = bg_data["sub_block"]
				if global_y > surface_base + 30.0:
					bg_tile = bg_data["stone_block"]
				
				result[1][local_pos] = {
					"source": bg_data.get("source_id", tile_source_id),
					"atlas": bg_tile
				}

	# 关键生成阶段只保留可通行地形与核心洞穴，次要地表装饰延后到 enrichment。
	if not critical_only:
		_apply_surface_features(coord, result, column_contexts)
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
		InfiniteChunkManager.restart(false)
		
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
	_clear_generation_caches()
	
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
	var surface_limit = get_surface_height_at(global_x)
	# 第一块实心砖块的索引
	var first_solid_y = ceil(surface_limit) 
	
	# 计算地表的绝对像素高度
	var surface_y_px = first_solid_y * 16
	
	# 根据 player.tscn 的碰撞体积偏移 (CollisionShape2D2 at y=15.15, size_y=55.68)
	var player_spawn_y = surface_y_px - 46
	
	# 计算 X 轴像素位置。同样要进行 Collision 偏移补偿 (-5.5)
	var player_spawn_x = global_x * 16 - 5.5
	
	return Vector2(player_spawn_x, player_spawn_y)
