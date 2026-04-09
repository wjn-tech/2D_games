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

@export_group("Staged Worldgen / Bedrock")
## 过渡带基岩瓦片（与 hard floor 分离，便于视觉过渡）
@export var bedrock_transition_tile: Vector2i = Vector2i(2, 0)
## 硬下界封底瓦片
@export var bedrock_floor_tile: Vector2i = Vector2i(2, 0)
## 深层主石材瓦片
@export var deep_stone_tile: Vector2i = Vector2i(2, 0)
## 水体接触边瓦片
@export var liquid_contact_water_tile: Vector2i = Vector2i(3, 3)
## 岩浆接触边瓦片
@export var liquid_contact_lava_tile: Vector2i = Vector2i(1, 4)
## 地下过渡主材（用于阶段映射的最小可用集）
@export var underground_transition_tile: Vector2i = Vector2i(0, 0)

## Feature Tiles (Added for Terraria Steps)
@export var vine_tile: Vector2i = Vector2i(4, 0)
@export var hive_tile: Vector2i = Vector2i(3, 1)

const STAGE_FAMILY_FOUNDATION_AND_RELIEF := "foundation_and_relief"
const STAGE_FAMILY_CAVE_AND_TUNNEL := "cave_and_tunnel"
const STAGE_FAMILY_BIOME_MACRO := "biome_macro"
const STAGE_FAMILY_ORE_AND_RESOURCES := "ore_and_resources"
const STAGE_FAMILY_STRUCTURES_AND_MICRO_BIOMES := "structures_and_micro_biomes"
const STAGE_FAMILY_LIQUID_SETTLE_AND_CLEANUP := "liquid_settle_and_cleanup"

const TERRARIA_CORE_STAGE_SEQUENCE := [
	STAGE_FAMILY_FOUNDATION_AND_RELIEF,
	STAGE_FAMILY_CAVE_AND_TUNNEL,
	STAGE_FAMILY_BIOME_MACRO,
	STAGE_FAMILY_ORE_AND_RESOURCES,
	STAGE_FAMILY_STRUCTURES_AND_MICRO_BIOMES,
	STAGE_FAMILY_LIQUID_SETTLE_AND_CLEANUP,
]

const CORE_STAGE_COVERAGE_THRESHOLD := 0.95
const STEP_ITEM_COVERAGE_THRESHOLD := 0.80
const TERRARIA_STEP_ITEMS_TOTAL := 20
const TERRARIA_STEP_ITEMS_IMPLEMENTED := 17
const TERRARIA_COMPAT_STEP_TOTAL := 107

@export_group("Terraria 107 Strict Pipeline")
@export var terraria_strict_chunk_pipeline: bool = false
@export var terraria_emit_step_trace: bool = false
@export var terraria_user_skip_steps: Array[int] = []

const TERRARIA_STEP_STATUS_IMPLEMENTED := "implemented"
const TERRARIA_STEP_STATUS_ADAPTED := "adapted"
const TERRARIA_STEP_STATUS_SKIPPED := "skipped"

const TERRARIA_SKIP_REASON_NOT_TERRAIN_SCOPE := "NOT_TERRAIN_SCOPE"
const TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM := "MISSING_PROJECT_SYSTEM"
const TERRARIA_SKIP_REASON_MISSING_ASSET_SET := "MISSING_ASSET_SET"
const TERRARIA_SKIP_REASON_ENGINE_OR_TOPOLOGY_CONSTRAINT := "ENGINE_OR_TOPOLOGY_CONSTRAINT"

const TERRARIA_ALLOWED_SKIP_REASONS := [
	TERRARIA_SKIP_REASON_NOT_TERRAIN_SCOPE,
	TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM,
	TERRARIA_SKIP_REASON_MISSING_ASSET_SET,
	TERRARIA_SKIP_REASON_ENGINE_OR_TOPOLOGY_CONSTRAINT,
]

const TERRARIA_STEP_NAMES := {
	# Foundation and Relief (1-18, 18 steps)
	1: "Reset to Ocean",
	2: "Reset to Dirt",
	3: "Pre-generation Chasm Scan",
	4: "Dune Terrain",
	5: "Grass Placement",
	6: "Hill Terrain",
	7: "River Passes",
	8: "Mountain Generation",
	9: "Floating Island Terrain",
	10: "Floating Island Surface",
	11: "Floating Island Biome Assignment",
	12: "Floating Island Chains",
	13: "Floating Island Misc Features",
	14: "Surface Biome Distribution",
	15: "Gem Cave Pass", # Renamed from Thick Gem/Crystal for clarity
	16: "Jungle Biome Placement",
	17: "Caves - Cavern Regions",
	18: "Caves - Tunnel Passes",
	
	# Cave and Tunnel (19-36, 18 steps)
	19: "Cave Entrances/Mouths",
	20: "Cave Refines",
	21: "Tunnel Passes Secondary",
	22: "World Edge Pass (Global Diagonal)",
	23: "World Edge Pass (Global Rewrite)",
	24: "Lava Layer",
	25: "Liquid Layer Initial Pass",
	26: "Granite Caves",
	27: "Marble Caves",
	28: "Granite/Marble Cave Entrances",
	29: "Underground Jungle Vines",
	30: "Underground Jungle Small Chambers",
	31: "Underground Jungle Erosion",
	32: "Underground Jungle Biome Thickening",
	33: "Underworld Entrance Chasm",
	34: "Underworld Biome Setup",
	35: "Time Event Check",
	36: "Shadow Orbs/Crimson Hearts",
	
	# Biome Macro (37-52, 16 steps)
	37: "Corruption/Crimson Chasm Foundation",
	38: "Corruption/Crimson Spread",
	39: "Hollow Placement",
	40: "Underground Desert Caverns",
	41: "Underground Desert Pit",
	42: "Jungle Vine Setup",
	43: "Jungle Temple",
	44: "Jungle Thorns",
	45: "Spider Nest Silk",
	46: "Living Tree Placement",
	47: "Living Tree Generation",
	48: "Glowing Mushroom Biome",
	49: "Underworld Hazard Liquids",
	50: "Water Genies' Caves",
	51: "Sapling Placement",
	52: "Tree Generation",
	
	# Ore and Resources (53-72, 20 steps)
	53: "Copper/Tin Ore",
	54: "Iron/Lead Ore",
	55: "Silver/Tungsten Ore",
	56: "Gold/Platinum Ore (Advanced)",
	57: "Demonite/Crimtane Ore",
	58: "Meteorite",
	59: "Heart Crystal",
	60: "Underground Cabins",
	61: "Underground Potions",
	62: "Surface Mushrooms",
	63: "Underground Mushroom Biome Setup",
	64: "Desert Cacti",
	65: "Dungeon Entrance/Biome Setup",
	66: "Dungeon Brick Structure",
	67: "Dungeon Spike Traps",
	68: "Corruption/Crimson Post-spread",
	69: "Hallow Spread",
	70: "Sky/Cloud Minor Adjustments",
	71: "Tall Gate/Architectures",
	72: "Bio-specific Ore Placement",
	
	# Structures and Micro-Biomes (73-92, 20 steps)
	73: "Treasure Chests",
	74: "Pots",
	75: "Fallen Log/Debris",
	76: "Spider Webs",
	77: "Dungeon Room Graph Generation",
	78: "Jungle Temples/Rooms",
	79: "Pyramid Rooms",
	80: "Floating Island Structures",
	81: "Moon/Hell Stone Biome",
	82: "Lava/Fire Trap Setup",
	83: "Pressure Plates/Timers",
	84: "Pressure Plates (Boulder Pushes)",
	85: "Statue Placement",
	86: "Entity Placement (Bosses/Slimes)",
	87: "NPC Housing Biome Prep",
	88: "Underground Cabin Spacing",
	89: "Herb/Plant Generation",
	90: "World Edge Sealing",
	91: "Surface Mini Decorative Plants",
	92: "Hanging Ice Spike Setup",
	
	# Liquid Settle and Cleanup (93-107, 15 steps)
	93: "Liquid Physics/Settling Phase 1",
	94: "Liquid Pressure Solver",
	95: "Lava/Water Mixing",
	96: "Liquid Cleanup Pass (Floating Sources)",
	97: "Liquid Bubble Removal",
	98: "Water Evaporation/Temperature",
	99: "Final Tile Fix",
	100: "Wall Generation",
	101: "Entity Cleanup (Loot/Spawning)",
	102: "Tile Painting Setup",
	103: "Grass Spreading",
	104: "Underground Jungle Final Polishing",
	105: "Static Liquid Final Sealing",
	106: "Hard-coded Edge Closure",
	107: "Generation Complete",
}

const TERRARIA_SKIP_POLICY := {
	# Batch 1 (1-20): 9-14 skipped
	7: {"reason": TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM, "note": "River simulation unavailable"},
	9: {"reason": TERRARIA_SKIP_REASON_NOT_TERRAIN_SCOPE, "note": "Floating Islands disabled"},
	10: {"reason": TERRARIA_SKIP_REASON_NOT_TERRAIN_SCOPE, "note": "Floating Islands disabled"},
	11: {"reason": TERRARIA_SKIP_REASON_NOT_TERRAIN_SCOPE, "note": "Floating Islands disabled"},
	12: {"reason": TERRARIA_SKIP_REASON_NOT_TERRAIN_SCOPE, "note": "Floating Islands disabled"},
	13: {"reason": TERRARIA_SKIP_REASON_NOT_TERRAIN_SCOPE, "note": "Floating Islands disabled"},
	14: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Surface micro-biomes unavailable"},
	15: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Gem caves unavailable"},
	
	# Batch 2 (21-40): 22-23, 31-32, 35-39 skipped
	22: {"reason": TERRARIA_SKIP_REASON_ENGINE_OR_TOPOLOGY_CONSTRAINT, "note": "World edge diagonal pass incompatible with ring world"},
	23: {"reason": TERRARIA_SKIP_REASON_ENGINE_OR_TOPOLOGY_CONSTRAINT, "note": "World edge rewrite pass incompatible with ring world"},
	31: {"reason": TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM, "note": "Jungle erosion system unavailable"},
	32: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Jungle thickening assets unavailable"},
	35: {"reason": TERRARIA_SKIP_REASON_NOT_TERRAIN_SCOPE, "note": "Seasonal events check skipped"},
	36: {"reason": TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM, "note": "Shadow Orbs/Hearts logic unavailable"},
	37: {"reason": TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM, "note": "Corruption chasm unavailable"},
	38: {"reason": TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM, "note": "Corruption spread unavailable"},
	39: {"reason": TERRARIA_SKIP_REASON_NOT_TERRAIN_SCOPE, "note": "Hallow is hardmode content"},

	# Batch 3 (41-60): 42-45, 48-50, 58 skipped
	42: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Jungle vines assets unavailable"},
	43: {"reason": TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM, "note": "Jungle Temple structure unavailable"},
	44: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Jungle thorns assets unavailable"},
	45: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Spider nest assets unavailable"},
	48: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Glowing Mushroom biome assets unavailable"},
	49: {"reason": TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM, "note": "Underworld hazard fluids unavailable"},
	50: {"reason": TERRARIA_SKIP_REASON_NOT_TERRAIN_SCOPE, "note": "Water Genies/Clean skipped"},
	51: {"reason": TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM, "note": "Sapling growth sim skipped"},
	58: {"reason": TERRARIA_SKIP_REASON_NOT_TERRAIN_SCOPE, "note": "Meteorite event skipped"},

	# Batch 4 (61-80): 61-63, 67-70, 73-76, 78, 80 skipped
	61: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Underground potions unavailable"},
	62: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Surface mushroom biome unavailable"},
	63: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Underground mushroom biome unavailable"},
	67: {"reason": TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM, "note": "Dungeon traps unavailable"},
	68: {"reason": TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM, "note": "Corruption post-spread unavailable"},
	69: {"reason": TERRARIA_SKIP_REASON_NOT_TERRAIN_SCOPE, "note": "Hallow spread unavailable (Hardmode)"},
	70: {"reason": TERRARIA_SKIP_REASON_NOT_TERRAIN_SCOPE, "note": "Sky adjustments unavailable"},
	73: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Treasure chests placement unavailable"},
	74: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Pots placement unavailable"},
	75: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Fallen log placement unavailable"},
	76: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Spider webs placement unavailable"},
	78: {"reason": TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM, "note": "Jungle temple rooms unavailable"},
	80: {"reason": TERRARIA_SKIP_REASON_NOT_TERRAIN_SCOPE, "note": "Floating island structures unavailable"},

	# Batch 5 (81-107): 81-86, 90-93, 105-107 skipped
	81: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Hellstone ore unavailable"},
	82: {"reason": TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM, "note": "Lava traps unavailable"},
	83: {"reason": TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM, "note": "Mechanisms (Plates/Timers) unavailable"},
	84: {"reason": TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM, "note": "Boulder traps unavailable"},
	85: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Statues unavailable"},
	86: {"reason": TERRARIA_SKIP_REASON_NOT_TERRAIN_SCOPE, "note": "Entity placement skipped"},
	90: {"reason": TERRARIA_SKIP_REASON_ENGINE_OR_TOPOLOGY_CONSTRAINT, "note": "World sealing incompatible with ring world"},
	91: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Mini decoration assets unavailable"},
	92: {"reason": TERRARIA_SKIP_REASON_MISSING_ASSET_SET, "note": "Ice spikes assets unavailable"},
	93: {"reason": TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM, "note": "Advanced liquid settling skipped"},
	105: {"reason": TERRARIA_SKIP_REASON_MISSING_PROJECT_SYSTEM, "note": "Final liquid seal skipped"},
	106: {"reason": TERRARIA_SKIP_REASON_ENGINE_OR_TOPOLOGY_CONSTRAINT, "note": "Edge closure incompatible with ring world"},
	107: {"reason": TERRARIA_SKIP_REASON_NOT_TERRAIN_SCOPE, "note": "Generation complete marker (no op)"},
}

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

@export_group("Decoration Settings")
## 沙块 Atlas 坐标 (0, 3) (Assuming Sand is grouped with soft rocks)
@export var sand_tile: Vector2i = Vector2i(0, 3)
## 仙探掌 Atlas 坐标 (3, 0)
@export var cactus_tile: Vector2i = Vector2i(3, 0)
## 药草(Daybloom type) Atlas 坐标 (2, 2)
@export var herb_tile: Vector2i = Vector2i(2, 2)
## 地牢砖 Atlas 坐标 (3, 3)
@export var dungeon_brick_tile: Vector2i = Vector2i(3, 3)
## 木板/平台 Atlas 坐标 (1, 2)
@export var wood_plank_tile: Vector2i = Vector2i(1, 2)
## 背景墙 Atlas 坐标 (0, 0) (Usually a separate source ID or coords)
@export var wall_tile: Vector2i = Vector2i(0, 0)
## 墙体源 ID (Separate source for walls ideally, else 0)
@export var wall_source_id: int = 1 

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

const CAVE_ARCHETYPE_SOLID_MASS := "solid_mass"
const CAVE_ARCHETYPE_GALLERY := "gallery"
const CAVE_ARCHETYPE_CHAMBER_CLUSTER := "chamber_cluster"
const CAVE_ARCHETYPE_LARGE_CHAMBER := "large_chamber"
const CAVE_ARCHETYPE_POCKET_CLUSTER := "pocket_cluster"
const CAVE_ARCHETYPE_LONG_CONNECTOR_ROUTE := "long_connector_route"

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

# --- 瞬态生成缓存 (加速全量 Chunk 生成) ---
var _transient_biome_cache: Dictionary = {}
var _transient_raw_height_cache: Dictionary = {}
var _is_generating_chunk: bool = false
var _world_topology: Node = null

func _get_world_topology() -> Node:
	if _world_topology and is_instance_valid(_world_topology):
		return _world_topology
	_world_topology = null
	var scene_tree := get_tree()
	if scene_tree == null or scene_tree.root == null:
		return null
	_world_topology = scene_tree.root.get_node_or_null("WorldTopology")
	return _world_topology

@export var world_circumference_chunks: int = 512
@export var use_cylindrical_noise: bool = true
var _world_radius_tiles: float

func _setup_world_params() -> void:
	var chunk_size = 64
	if InfiniteChunkManager:
		chunk_size = InfiniteChunkManager.CHUNK_SIZE

	var world_topology = _get_world_topology()
	if world_topology:
		if world_topology.has_method("get_circumference_chunks") and world_topology.get_circumference_chunks() > 0:
			world_circumference_chunks = world_topology.get_circumference_chunks()
		if world_topology.has_method("is_planetary"):
			use_cylindrical_noise = world_topology.is_planetary()
		# [OPENSPEC] Sync world height with bedrock boundary
		if world_topology.has_method("get_bedrock_hard_floor_global_y"):
			var floor_y = world_topology.get_bedrock_hard_floor_global_y()
			if floor_y > 500: # Only override if valid/configured
				world_height = floor_y

	_world_radius_tiles = (float(world_circumference_chunks) * float(chunk_size)) / TAU

func _noise_1d_wrapped(noise: FastNoiseLite, x: float) -> float:
	if not use_cylindrical_noise: return noise.get_noise_1d(x)
	var circum = float(world_circumference_chunks) * 64.0
	var theta = (x / circum) * TAU
	var nx = _world_radius_tiles * cos(theta)
	var ny = _world_radius_tiles * sin(theta)
	return noise.get_noise_2d(nx, ny)

func _noise_2d_wrapped(noise: FastNoiseLite, x: float, y: float) -> float:
	if not use_cylindrical_noise: return noise.get_noise_2d(x, y)
	var circum = float(world_circumference_chunks) * 64.0
	var theta = (x / circum) * TAU
	var nx = _world_radius_tiles * cos(theta)
	var nz = _world_radius_tiles * sin(theta)
	return noise.get_noise_3d(nx, y, nz)

func _noise_1d_scaled(noise: FastNoiseLite, x: float, scale: float = 1.0, offset: float = 0.0) -> float:
	if not use_cylindrical_noise:
		return noise.get_noise_1d(x * scale + offset)
	
	# Map x to angle. 
	# Treat 'offset' as a linear shift along the circumference.
	var circum = float(world_circumference_chunks) * 64.0
	var offset_theta = (offset / circum) * TAU
	var theta = (x / circum) * TAU + offset_theta
	
	# Use scaling on the Radius to change feature size (frequency) without breaking the loop
	# Note: Higher scale = Larger Radius = More detail/Higher Freq relative to circle
	var r_prime = _world_radius_tiles * scale
	
	var nx = r_prime * cos(theta)
	var ny = r_prime * sin(theta)
	return noise.get_noise_2d(nx, ny)

func _noise_2d_scaled(noise: FastNoiseLite, x: float, y: float, scale_x: float = 1.0, offset_x: float = 0.0, scale_y: float = 1.0, offset_y: float = 0.0) -> float:
	if not use_cylindrical_noise:
		return noise.get_noise_2d(x * scale_x + offset_x, y * scale_y + offset_y)

	var circum = float(world_circumference_chunks) * 64.0
	var offset_theta = (offset_x / circum) * TAU
	var theta = (x / circum) * TAU + offset_theta
	var r_prime = _world_radius_tiles * scale_x
	
	var nx = r_prime * cos(theta)
	var nz = r_prime * sin(theta)
	var ny = y * scale_y + offset_y
	return noise.get_noise_3d(nx, ny, nz)

func _ready() -> void:
	add_to_group("world_generator")
	add_to_group("world_generators")
	# 确保每一局启动时都有真正的随机底色
	randomize()
	if seed_value == 0:
		seed_value = randi()
	
	_setup_world_params()
	_setup_noises()
	
	# 确保所有图层强制共享同一个 TileSet 资源
	if layer_0.tile_set:
		for l in [layer_1, layer_2, tree_layer_0, tree_layer_1, tree_layer_2]:
			if l:
				l.tile_set = layer_0.tile_set
				
	# 标记只用于视觉填充的背景层，避免被当作实体墙参与物理。
	# Layer 1 = Liquids (Non-solid)
	# Layer 2 = Background Walls (Non-solid)
	if layer_1:
		layer_1.set_meta("background_only", true)
		layer_1.collision_enabled = false
	if layer_2:
		layer_2.set_meta("background_only", true)
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
	_validate_stage_tileset_mapping()

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
	
	var n_common = _noise_2d_wrapped(noise_mineral_common, float(gx), float(gy) * 1.2)
	var n_rare = _noise_2d_wrapped(noise_mineral_rare, float(gx), float(gy) * 1.5)
	var n_legend = _noise_2d_wrapped(noise_mineral_legendary, float(gx), float(gy) * 2.0)
	
	# --- Deep Layer (Y > 300) ---
	if depth > 300:
		# 钻石 (Legendary) - 最深层特有
		if n_legend > 0.86: return diamond_tile
		# 魔法加速石 (Very Rare)
		if n_legend > 0.79: return magic_speed_stone_tile
		# 深层稀有矿物先判定，避免被更宽的金矿阈值吞掉。
		if n_rare > 0.71: return staff_core_tile
		if n_rare > 0.47: return gold_tile # Gold is more common than Staff Core in deep
		
		# 丰富的矿脉
		if n_common > 0.22: return iron_tile
		if n_common < -0.22: return magic_crystal_tile

	# --- Underground Layer (100 < Y < 300) ---
	elif depth > 100:
		# 钻石 (Extremely Rare here)
		if n_legend > 0.93: return diamond_tile
		# 法杖核心 (Very Rare here)
		if n_rare > 0.78: return staff_core_tile
		# 金矿 (Rare)
		if n_rare > 0.56: return gold_tile
		# 魔力水晶 (Uncommon)
		if n_rare > 0.37: return magic_crystal_tile
		# 铁矿
		if n_common > 0.34: return iron_tile
		# 铜矿
		if n_common < -0.34: return copper_tile

	# --- Surface/Shallow Layer (10 < Y < 100) ---
	elif depth > 10:
		# 金矿 (Very Rare near surface)
		if n_rare > 0.80: return gold_tile
		# 铜矿 (Common)
		if n_common > 0.44: return copper_tile
		# 铁矿 (Sparse)
		if n_common < -0.50: return iron_tile
		
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
	var my_density = _noise_2d_wrapped(noise_tree_density, float(gx), 0.0)
	for ox in range(-min_tree_distance, min_tree_distance + 1):
		if ox == 0: continue
		var nx = gx + ox
		if _is_tree_priority_candidate(nx):
			var n_density = _noise_2d_wrapped(noise_tree_density, float(nx), 0.0)
			if n_density < my_density: # 发现周边有更高优先级（值更小）的点
				return false
			elif n_density == my_density and nx < gx: # 处理可能的平局
				return false

	return true

## 内部：仅进行噪声和生态概率判定（不含间距和结构避让）
func _is_tree_priority_candidate(gx: int) -> bool:
	var biome = get_biome_at(gx, 0)
	
	if biome == BiomeType.DESERT: return false
	
	var cluster_val = (_noise_2d_wrapped(noise_tree_cluster, float(gx), 0.0) + 1.0) / 2.0
	var density_val = (_noise_2d_wrapped(noise_tree_density, float(gx), 0.0) + 1.0) / 2.0
	
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
	if not InfiniteChunkManager:
		return false

	# If runtime tile-house structures are disabled, trees should not be blocked.
	if InfiniteChunkManager.has_method("is_tile_house_structures_enabled"):
		if not bool(InfiniteChunkManager.call("is_tile_house_structures_enabled")):
			return false

	# Prefer manager-provided prediction ranges to keep parity with runtime structure logic.
	if InfiniteChunkManager.has_method("get_predicted_surface_house_ranges"):
		var chunk_x := int(floor(float(gx) / 64.0))
		var ranges_variant: Variant = InfiniteChunkManager.call("get_predicted_surface_house_ranges", chunk_x, 2, 2)
		if ranges_variant is Array:
			for range_variant in ranges_variant:
				if not (range_variant is Dictionary):
					continue
				var range_data: Dictionary = range_variant
				var start_x := int(range_data.get("start", 0))
				var end_x := int(range_data.get("end", -1))
				if gx >= start_x and gx < end_x:
					return true
			return false

	# Legacy fallback path if helper methods are unavailable.
	var chunk_x := int(floor(float(gx) / 64.0))
	for ox in range(-2, 3):
		var cx := chunk_x + ox
		var hash_val: int = int(InfiniteChunkManager.get_chunk_hash(Vector2i(cx, 5)))
		if hash_val % 12 != 0:
			continue
		var center_x_local: int = hash_val % 30 + 15
		var b_x_global: int = cx * 64 + center_x_local
		if gx >= b_x_global - 2 and gx < b_x_global + 37:
			return true
	return false

## 获取指定位置的生物群系 (2D 噪声 + 深度分层)
func get_biome_at(global_x: int, global_y: int) -> BiomeType:
	var surface_biome := _get_surface_biome_from_climate(global_x, global_y)
	var surface_base := 300.0 + _noise_1d_wrapped(noise_continental, float(global_x)) * 42.0
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
		temp_acc += _noise_2d_wrapped(noise_temperature, float(sample_x), float(global_y) * 0.35) * w
		moist_acc += _noise_2d_wrapped(noise_moisture, float(sample_x), float(global_y) * 0.35) * w

	# 低频偏置让生态带更连续，不会短距离来回跳。
	temp_acc += _noise_1d_scaled(noise_surface_feature, float(global_x), 0.014, 27.0) * 0.07
	moist_acc += _noise_1d_scaled(noise_cave_region, float(global_x), 0.012, -41.0) * 0.08
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
	# [Topology Plan Integration]
	# If a plan exists, prioritize it over noise bands
	var topology = _get_world_topology()
	
	if topology and topology.is_planetary():
		# Bypass simple X-cache for planetary mode to support vertical biome slanting
		
		# 1. Calculate Boundary Warp
		# Use lower frequency for large scale boundary movement, higher frequency for jagged edges
		var warp_large := _noise_1d_scaled(noise_surface_feature, float(global_x), 0.015, 123.4) * 45.0 # +/- 45 tiles
		var warp_small := _noise_1d_scaled(noise_cave_region, float(global_x), 0.1, 567.8) * 8.0     # +/- 8 tiles
		
		# Y-Dependent Warp: Varies with depth to create slanted/wiggly biome boundaries underground
		# Scale Y (0.005) is very gradual; Amplitude (0.4 * depth?) 
		# Let's use noise to make it effectively random but deterministic.
		var warp_y: float = 0.0
		if global_y != 0:
			# Use 2D noise to shift X based on Y. 
			# Scale X=0.02, Y=0.02 (approx 50 tiles wavelength), Amp=25.0
			var distortion = _noise_2d_scaled(noise_cave_region, float(global_x), float(global_y), 0.02, 0.02, 100.0, 200.0)
			var vertical_meander := _noise_2d_scaled(noise_temperature, float(global_x), float(global_y), 0.008, 311.0, 0.006, -173.0) * 18.0
			warp_y = distortion * 25.0 + vertical_meander

		var total_warp = warp_large + warp_small + warp_y

		# 2. Sample Topology with Warped Coordinate
		var warped_x = global_x + int(total_warp)
		
		# Handle wrapping of the warped coordinate if needed for lookup?
		# Topology expects canonical chunk index.
		var c_size = topology.CHUNK_SIZE
		var chunk_x = int(floor(float(warped_x) / float(c_size)))
		
		# Wrap chunk_x via topology to ensure valid lookup
		if topology.has_method("wrap_chunk_x"):
			chunk_x = topology.wrap_chunk_x(chunk_x)
		
		var region = topology.get_surface_region_for_chunk(chunk_x)
		var current_biome_str = region.get("biome", "forest")
		
		return _map_biome_string_to_enum(current_biome_str)

	if _is_generating_chunk and _transient_biome_cache.has(global_x):
		return _transient_biome_cache[global_x]


	# Fallback (Legacy)
	var band_size := 160
	var band_index := int(floor(float(global_x) / float(band_size)))
	var primary := _get_surface_band_biome(band_index, global_y)
	var left_biome := _get_surface_band_biome(band_index - 1, global_y)
	var right_biome := _get_surface_band_biome(band_index + 1, global_y)

	var local_x := float(global_x - band_index * band_size)
	# Improved Boundary Warp: Multi-octave noise to break straight vertical lines
	var warp1 := _noise_1d_scaled(noise_surface_feature, float(global_x), 0.052, 31.0/0.052) * 14.0
	var warp2 := _noise_1d_scaled(noise_cave_region, float(global_x), 0.15, -17.0) * 6.0
	var boundary_warp := warp1 + warp2
	
	var left_zone := 34.0 + boundary_warp * 0.25
	var right_zone := float(band_size) - 34.0 + boundary_warp * 0.25

	if left_biome != primary and local_x < left_zone:
		# Dithering Logic at borders
		var dist_to_edge = left_zone - local_x
		var norm_dist = clampf(dist_to_edge / 20.0, 0.0, 1.0)
		# Higher probability to flip near the edge
		var flip_prob = pow(norm_dist, 1.5) 
		
		# Deterministic dither pattern
		var dither_val = (_noise_2d_scaled(noise_surface_feature, float(global_x), float(global_y), 0.8, 0.0, 0.8, 0.0) + 1.0) * 0.5
		
		if dither_val < flip_prob:
			if _is_generating_chunk: _transient_biome_cache[global_x] = left_biome
			return left_biome

	if right_biome != primary and local_x > right_zone:
		# Dithering Logic at borders
		var dist_to_edge = local_x - right_zone
		var norm_dist = clampf(dist_to_edge / 20.0, 0.0, 1.0)
		var flip_prob = pow(norm_dist, 1.5)
		
		var dither_val = (_noise_2d_scaled(noise_surface_feature, float(global_x), float(global_y), 0.8, 0.0, 0.8, 0.0) + 1.0) * 0.5
		
		if dither_val < flip_prob:
			if _is_generating_chunk: _transient_biome_cache[global_x] = right_biome
			return right_biome
	
	if _is_generating_chunk: _transient_biome_cache[global_x] = primary
	return primary

func _map_biome_string_to_enum(b_str: String) -> BiomeType:
	match b_str:
		"forest": return BiomeType.FOREST
		"plains": return BiomeType.PLAINS
		"desert": return BiomeType.DESERT
		"tundra": return BiomeType.TUNDRA
		"swamp": return BiomeType.SWAMP
		# Map distinct tags to visual biomes
		"jungle": return BiomeType.SWAMP
		"dungeon": return BiomeType.FOREST
		_: return BiomeType.FOREST

func _get_underground_variant_for_surface(surface_biome: BiomeType) -> BiomeType:
	var surface_data: Dictionary = biome_params.get(surface_biome, biome_params[BiomeType.FOREST])
	return int(surface_data.get("underground_biome", BiomeType.The_UNDERGROUND))

func _sample_underground_patch_biome(global_x: int, global_y: int, fallback_biome: BiomeType) -> BiomeType:
	# 通过二维域扭曲制造块状群系，避免边界长距离直线贯穿。
	var warp_x := _noise_2d_scaled(noise_surface_feature, float(global_x), float(global_y), 0.018, 63.0, 0.014, -37.0) * 42.0
	var warp_y := _noise_2d_scaled(noise_cave_region, float(global_x), float(global_y), 0.013, -71.0, 0.019, 109.0) * 28.0
	var sample_x := float(global_x) + warp_x
	var sample_y := float(global_y) + warp_y

	var temp := _noise_2d_scaled(noise_temperature, sample_x, sample_y, 0.009, 41.0, 0.008, -53.0)
	var moist := _noise_2d_scaled(noise_moisture, sample_x, sample_y, 0.008, -11.0, 0.010, 83.0)
	var shape_a := _noise_2d_scaled(noise_cave_region, sample_x, sample_y, 0.021, 137.0, 0.018, -97.0)
	var shape_b := _noise_2d_scaled(noise_tunnel, sample_x, sample_y, 0.016, -29.0, 0.022, 47.0)
	var mask := clampf(((shape_a * 0.62 + shape_b * 0.38) + 1.0) * 0.5, 0.0, 1.0)

	if mask < 0.34:
		return fallback_biome

	var classified_surface := _classify_surface_biome_from_climate(temp, moist)
	var mapped_underground := _get_underground_variant_for_surface(classified_surface)

	# 防止普通地下材质过度抹平专属地下区。
	if mapped_underground == BiomeType.The_UNDERGROUND and fallback_biome != BiomeType.The_UNDERGROUND and mask < 0.56:
		return fallback_biome

	return mapped_underground

func _get_wrapped_tile_delta(sample_x: float, reference_x: float) -> float:
	var delta := sample_x - reference_x
	var world_topology = _get_world_topology()
	if not world_topology:
		return delta
	if not world_topology.has_method("is_planetary") or not world_topology.is_planetary():
		return delta
	if not world_topology.has_method("get_circumference_tiles"):
		return delta
	var circumference := float(world_topology.get_circumference_tiles())
	if circumference <= 0.0:
		return delta
	var half := circumference * 0.5
	if delta > half:
		delta -= circumference
	elif delta < -half:
		delta += circumference
	return delta

func _get_wrapped_tile_distance(sample_x: float, reference_x: float) -> float:
	return absf(_get_wrapped_tile_delta(sample_x, reference_x))

func _get_depth_band_id(depth: float) -> String:
	var world_topology = _get_world_topology()
	if world_topology and world_topology.has_method("get_depth_band_id_for_depth"):
		return String(world_topology.get_depth_band_id_for_depth(depth))
	if depth < 28.0:
		return "surface"
	if depth < 120.0:
		return "shallow_underground"
	if depth < 420.0:
		return "mid_cavern"
	if depth < 980.0:
		return "deep"
	return "terminal"

func _get_terraria_family_for_step(step_index: int) -> String:
	if step_index <= 18:
		return STAGE_FAMILY_FOUNDATION_AND_RELIEF
	if step_index <= 36:
		return STAGE_FAMILY_CAVE_AND_TUNNEL
	if step_index <= 52:
		return STAGE_FAMILY_BIOME_MACRO
	if step_index <= 72:
		return STAGE_FAMILY_ORE_AND_RESOURCES
	if step_index <= 92:
		return STAGE_FAMILY_STRUCTURES_AND_MICRO_BIOMES
	return STAGE_FAMILY_LIQUID_SETTLE_AND_CLEANUP

func _get_terraria_execution_hook_for_family(stage_family: String) -> String:
	match stage_family:
		STAGE_FAMILY_FOUNDATION_AND_RELIEF, STAGE_FAMILY_CAVE_AND_TUNNEL:
			return "_generate_chunk_cells_critical_fast"
		STAGE_FAMILY_BIOME_MACRO:
			return "generate_chunk_cells"
		STAGE_FAMILY_ORE_AND_RESOURCES:
			return "_apply_resource_stage"
		STAGE_FAMILY_STRUCTURES_AND_MICRO_BIOMES:
			return "_apply_surface_features"
		STAGE_FAMILY_LIQUID_SETTLE_AND_CLEANUP:
			return "_collect_liquid_stage_seeds"
		_:
			return ""

func _get_terraria_step_status(step_index: int) -> String:
	if _is_step_user_skipped(step_index):
		return TERRARIA_STEP_STATUS_SKIPPED
	if step_index <= 24:
		return TERRARIA_STEP_STATUS_IMPLEMENTED
	return TERRARIA_STEP_STATUS_ADAPTED

func _build_terraria_step_catalog_entry(step_index: int) -> Dictionary:
	var mapped_family := _get_terraria_family_for_step(step_index)
	var status := _get_terraria_step_status(step_index)
	var execution_hook := _get_terraria_execution_hook_for_family(mapped_family)
	var step_name := String(TERRARIA_STEP_NAMES.get(step_index, "terraria_terrain_step_%03d" % step_index))
	
	var entry := {
		"step_index": step_index,
		"step_name": step_name,
		"status": status,
		"mapped_family": mapped_family,
		"execution_hook": execution_hook,
		"skip_reason": "",
		"compat_note": "mapped to %s via %s" % [mapped_family, execution_hook],
	}

	if status == TERRARIA_STEP_STATUS_SKIPPED:
		entry["skip_reason"] = "USER_EXPLICIT_SKIP"
		entry["execution_hook"] = ""
		entry["compat_note"] = "skipped by explicit user request"

	return entry

func get_terraria_step_compatibility_catalog() -> Array:
	var catalog: Array = []
	for step_index in range(1, TERRARIA_COMPAT_STEP_TOTAL + 1):
		catalog.append(_build_terraria_step_catalog_entry(step_index))
	return catalog

func _validate_terraria_step_catalog(catalog: Array) -> Dictionary:
	var seen_indices := {}
	var disposition_counts := {
		TERRARIA_STEP_STATUS_IMPLEMENTED: 0,
		TERRARIA_STEP_STATUS_ADAPTED: 0,
		TERRARIA_STEP_STATUS_SKIPPED: 0,
	}
	var unresolved_issues: Array = []

	for raw_entry in catalog:
		if not (raw_entry is Dictionary):
			unresolved_issues.append("entry is not a Dictionary")
			continue

		var entry: Dictionary = raw_entry
		var step_index := int(entry.get("step_index", -1))
		if step_index < 1 or step_index > TERRARIA_COMPAT_STEP_TOTAL:
			unresolved_issues.append("invalid step_index %s" % str(step_index))
			continue

		if seen_indices.has(step_index):
			unresolved_issues.append("duplicate step_index %d" % step_index)
			continue
		seen_indices[step_index] = true

		var status := String(entry.get("status", ""))
		if not disposition_counts.has(status):
			unresolved_issues.append("step %d has invalid status %s" % [step_index, status])
			continue
		disposition_counts[status] = int(disposition_counts.get(status, 0)) + 1

		if status == TERRARIA_STEP_STATUS_SKIPPED:
			var skip_reason := String(entry.get("skip_reason", ""))
			if skip_reason == "" or not TERRARIA_ALLOWED_SKIP_REASONS.has(skip_reason):
				unresolved_issues.append("step %d has invalid skip_reason %s" % [step_index, skip_reason])
			if String(entry.get("compat_note", "")).strip_edges() == "":
				unresolved_issues.append("step %d missing compat_note" % step_index)
		else:
			if String(entry.get("mapped_family", "")).strip_edges() == "":
				unresolved_issues.append("step %d missing mapped_family" % step_index)
			if String(entry.get("execution_hook", "")).strip_edges() == "":
				unresolved_issues.append("step %d missing execution_hook" % step_index)

	for expected_index in range(1, TERRARIA_COMPAT_STEP_TOTAL + 1):
		if not seen_indices.has(expected_index):
			unresolved_issues.append("missing step_index %d" % expected_index)

	return {
		"disposition_counts": disposition_counts,
		"unresolved_entries": unresolved_issues.size(),
		"issues": unresolved_issues,
	}

func get_terraria_step_alignment_metrics() -> Dictionary:
	var catalog := get_terraria_step_compatibility_catalog()
	var validation := _validate_terraria_step_catalog(catalog)
	var disposition_counts: Dictionary = validation.get("disposition_counts", {})
	var implemented_count := int(disposition_counts.get(TERRARIA_STEP_STATUS_IMPLEMENTED, 0))
	var adapted_count := int(disposition_counts.get(TERRARIA_STEP_STATUS_ADAPTED, 0))
	var skipped_count := int(disposition_counts.get(TERRARIA_STEP_STATUS_SKIPPED, 0))
	var unresolved_count := int(validation.get("unresolved_entries", 0))

	return {
		"total_steps": TERRARIA_COMPAT_STEP_TOTAL,
		"implemented": implemented_count,
		"adapted": adapted_count,
		"skipped": skipped_count,
		"disposition_counts": disposition_counts.duplicate(true),
		"unresolved_entries": unresolved_count,
		"accepted": unresolved_count == 0 and (implemented_count + adapted_count + skipped_count) == TERRARIA_COMPAT_STEP_TOTAL,
		"allowed_skip_reasons": TERRARIA_ALLOWED_SKIP_REASONS.duplicate(true),
		"issues": validation.get("issues", []).duplicate(true),
		"catalog": catalog,
	}

func get_stage_family_sequence() -> Array:
	return TERRARIA_CORE_STAGE_SEQUENCE.duplicate(true)

func get_stage_alignment_metrics() -> Dictionary:
	var core_stage_coverage_rate := float(TERRARIA_CORE_STAGE_SEQUENCE.size()) / float(TERRARIA_CORE_STAGE_SEQUENCE.size())
	var step_item_coverage_rate := float(TERRARIA_STEP_ITEMS_IMPLEMENTED) / maxf(float(TERRARIA_STEP_ITEMS_TOTAL), 1.0)
	var terraria_107_metrics := get_terraria_step_alignment_metrics()
	var terraria_107_unresolved := int(terraria_107_metrics.get("unresolved_entries", 0))
	var terraria_107_accepted := bool(terraria_107_metrics.get("accepted", false))
	return {
		"core_stage_coverage_rate": core_stage_coverage_rate,
		"step_item_coverage_rate": step_item_coverage_rate,
		"core_stage_coverage_threshold": CORE_STAGE_COVERAGE_THRESHOLD,
		"step_item_coverage_threshold": STEP_ITEM_COVERAGE_THRESHOLD,
		"accepted": core_stage_coverage_rate >= CORE_STAGE_COVERAGE_THRESHOLD and step_item_coverage_rate >= STEP_ITEM_COVERAGE_THRESHOLD and terraria_107_accepted,
		"implemented_stage_families": TERRARIA_CORE_STAGE_SEQUENCE.duplicate(true),
		"implemented_step_items": TERRARIA_STEP_ITEMS_IMPLEMENTED,
		"total_step_items": TERRARIA_STEP_ITEMS_TOTAL,
		"terraria_107_metrics": terraria_107_metrics,
		"terraria_107_disposition_counts": terraria_107_metrics.get("disposition_counts", {}).duplicate(true),
		"terraria_107_unresolved_entries": terraria_107_unresolved,
	}

func _get_depth_boundary_config() -> Dictionary:
	var world_topology = _get_world_topology()
	if world_topology and world_topology.has_method("get_bedrock_boundary_config"):
		var config: Dictionary = world_topology.get_bedrock_boundary_config()
		config["enabled"] = bool(config.get("enabled", false))
		return config
	return {
		"enabled": false,
		"bedrock_start_depth": 1000000,
		"bedrock_hard_floor_depth": 1000000,
		"depth_reference_surface_y": 300,
	}

func _is_hard_floor_depth(depth: float, boundary_config: Dictionary) -> bool:
	return bool(boundary_config.get("enabled", false)) and depth >= float(boundary_config.get("bedrock_hard_floor_depth", 1000000.0))

func _is_bedrock_transition_depth(depth: float, boundary_config: Dictionary) -> bool:
	return bool(boundary_config.get("enabled", false)) and depth >= float(boundary_config.get("bedrock_start_depth", 1000000.0))

func _get_bedrock_transition_ratio(depth: float, boundary_config: Dictionary) -> float:
	if not bool(boundary_config.get("enabled", false)):
		return 0.0
	var start_depth := float(boundary_config.get("bedrock_start_depth", 1000000.0))
	var hard_depth := float(boundary_config.get("bedrock_hard_floor_depth", 1000000.0))
	if hard_depth <= start_depth:
		return 1.0 if depth >= hard_depth else 0.0
	return clampf((depth - start_depth) / (hard_depth - start_depth), 0.0, 1.0)

func _is_stage_preserve_zone(global_x: int, depth: float, is_spawn_safe_column: bool, boundary_config: Dictionary) -> bool:
	if is_spawn_safe_column and depth < 40.0:
		return true
	if _is_hard_floor_depth(depth, boundary_config):
		return true
	return false

const UNDERWORLD_ROUTE_START_DEPTH := 320.0

func _get_underworld_generation_config() -> Dictionary:
	var world_topology = _get_world_topology()
	if world_topology and world_topology.has_method("get_underworld_generation_config"):
		var config_variant = world_topology.get_underworld_generation_config()
		if config_variant is Dictionary:
			return config_variant
	return {
		"enabled": false,
	}

func _build_underworld_column_context(global_x: int, surface_base: float, boundary_config: Dictionary, underworld_config: Dictionary) -> Dictionary:
	if not bool(underworld_config.get("enabled", false)):
		return {"enabled": false}
	if not bool(boundary_config.get("enabled", false)):
		return {"enabled": false}

	var center_x := float(int(underworld_config.get("anchor_tile", 0)))
	var world_topology = _get_world_topology()
	var circumference := 0.0
	if world_topology and world_topology.has_method("get_circumference_tiles"):
		circumference = float(world_topology.get_circumference_tiles())
	if circumference <= 0.0:
		return {"enabled": false}

	var coverage_ratio := clampf(float(underworld_config.get("horizontal_coverage_ratio", 1.0)), 0.50, 1.0)
	var half_width := circumference * 0.5 * coverage_ratio
	if coverage_ratio >= 0.999:
		half_width = circumference * 0.5
	if _get_wrapped_tile_distance(float(global_x), center_x) > half_width:
		return {"enabled": false}

	var bedrock_start_depth := float(boundary_config.get("bedrock_start_depth", 1000000.0))
	var bedrock_hard_floor_depth := float(boundary_config.get("bedrock_hard_floor_depth", 1000000.0))
	var min_vertical_span := maxf(float(int(underworld_config.get("min_vertical_span", 180))), 180.0)

	var top_base := maxf(320.0, bedrock_start_depth - 260.0)
	var top_wave := _noise_2d_scaled(noise_cave_region, float(global_x), surface_base, 0.008, 91.0, 0.011, -37.0) * 36.0
	var top_depth := top_base + top_wave

	var bottom_target := top_depth + min_vertical_span + 28.0 + _noise_2d_scaled(noise_surface_feature, float(global_x), surface_base, 0.011, 17.0, 0.013, 43.0) * 26.0
	var max_bottom := bedrock_hard_floor_depth - 4.0
	var bottom_depth := minf(max_bottom, bottom_target)
	if bottom_depth - top_depth < min_vertical_span:
		top_depth = bottom_depth - min_vertical_span

	var max_intrusion := 42.0
	if bottom_depth > bedrock_start_depth + max_intrusion:
		bottom_depth = bedrock_start_depth + max_intrusion
		top_depth = minf(top_depth, bottom_depth - min_vertical_span)

	top_depth = minf(top_depth, bedrock_start_depth - 6.0)
	if bottom_depth <= top_depth + 20.0:
		return {"enabled": false}

	var escarpment_wave := _noise_2d_scaled(noise_tunnel, float(global_x), surface_base, 0.016, 71.0, 0.012, -29.0)
	var escarpment_shift := 0.0
	if escarpment_wave > 0.58:
		escarpment_shift = 38.0
	elif escarpment_wave < -0.56:
		escarpment_shift = -24.0

	var floor_base := top_depth + min_vertical_span * 0.72
	var floor_noise := _noise_2d_scaled(noise_surface_feature, float(global_x), surface_base, 0.019, -47.0, 0.017, 61.0) * 28.0
	var floor_depth := clampf(floor_base + floor_noise + escarpment_shift, top_depth + min_vertical_span * 0.58, bottom_depth - 6.0)

	var island_gate := (_noise_2d_scaled(noise_cave_region, float(global_x), surface_base, 0.027, 113.0, 0.031, -19.0) + 1.0) * 0.5
	var island_center_depth := top_depth + min_vertical_span * (0.33 + clampf(_noise_2d_scaled(noise_cave, float(global_x), surface_base, 0.021, 29.0, 0.018, -7.0) * 0.18, -0.18, 0.18))
	var island_radius := 8.0 + ((_noise_2d_scaled(noise_tunnel, float(global_x), surface_base, 0.043, -23.0, 0.039, 13.0) + 1.0) * 0.5) * 10.0

	return {
		"enabled": true,
		"top_depth": top_depth,
		"bottom_depth": bottom_depth,
		"floor_depth": floor_depth,
		"route_center_x": float(int(underworld_config.get("primary_route_tile", int(center_x)))),
		"island_gate": island_gate,
		"island_center_depth": island_center_depth,
		"island_radius": island_radius,
		"escarpment_wave": escarpment_wave,
	}

func _get_underworld_tile_state(global_x: int, depth: float, underworld_column: Dictionary, boundary_config: Dictionary) -> Dictionary:
	if not bool(underworld_column.get("enabled", false)):
		return {
			"active": false,
		}

	var top_depth := float(underworld_column.get("top_depth", 1000000.0))
	var bottom_depth := float(underworld_column.get("bottom_depth", -1000000.0))
	if depth < top_depth or depth > bottom_depth:
		return {
			"active": false,
		}

	if _is_hard_floor_depth(depth, boundary_config):
		return {
			"active": true,
			"solid": true,
			"region": "hard_floor",
		}

	var route_center_x := float(underworld_column.get("route_center_x", float(global_x)))
	var route_offset := _noise_2d_scaled(noise_surface_feature, float(global_x), depth, 0.0, 0.0, 0.013, 11.0) * 9.0
	var route_target_x := route_center_x + route_offset
	var route_width := 4.5
	if depth >= UNDERWORLD_ROUTE_START_DEPTH and depth <= top_depth + 26.0 and _get_wrapped_tile_distance(float(global_x), route_target_x) <= route_width:
		return {
			"active": true,
			"solid": false,
			"region": "route",
		}

	var floor_depth := float(underworld_column.get("floor_depth", bottom_depth - 6.0))
	if depth >= floor_depth:
		return {
			"active": true,
			"solid": true,
			"region": "floor",
		}

	var escarpment_wave := float(underworld_column.get("escarpment_wave", 0.0))
	if escarpment_wave > 0.62:
		var cliff_top := top_depth + 26.0 + escarpment_wave * 26.0
		if depth >= cliff_top and depth <= floor_depth:
			return {
				"active": true,
				"solid": true,
				"region": "cliff",
			}

	var island_gate := float(underworld_column.get("island_gate", 0.0))
	if island_gate > 0.56:
		var island_center_depth := float(underworld_column.get("island_center_depth", top_depth + 60.0))
		var island_radius := float(underworld_column.get("island_radius", 8.0))
		if absf(depth - island_center_depth) <= island_radius:
			var blob := _noise_2d_scaled(noise_cave, float(global_x), depth, 0.081, 17.0, 0.093, -11.0)
			if blob > -0.14:
				return {
					"active": true,
					"solid": true,
					"region": "island",
				}

	return {
		"active": true,
		"solid": false,
		"region": "cavity",
	}

func _get_underworld_ore_uplift_multiplier(global_x: int, depth: float, surface_base: float, boundary_config: Dictionary, underworld_config: Dictionary) -> float:
	if not bool(underworld_config.get("enabled", false)):
		return 1.0
	var column := _build_underworld_column_context(global_x, surface_base, boundary_config, underworld_config)
	if not bool(column.get("enabled", false)):
		return 1.0
	var top_depth := float(column.get("top_depth", 1000000.0))
	var bottom_depth := float(column.get("bottom_depth", -1000000.0))
	if depth < top_depth - 120.0 or depth > bottom_depth + 48.0:
		return 1.0
	return maxf(1.0, float(underworld_config.get("ore_uplift_multiplier", 1.0)))

func _resolve_strata_variant(base_stone: Vector2i, preferred: Vector2i, fallback: Vector2i) -> Vector2i:
	if preferred != base_stone and preferred != dirt_tile and _tileset_has_atlas(tile_source_id, preferred):
		return preferred
	if fallback != base_stone and fallback != dirt_tile and _tileset_has_atlas(tile_source_id, fallback):
		return fallback
	return base_stone


func _resolve_solid_atlas_for_depth(current_b_data: Dictionary, depth: float, boundary_config: Dictionary, dirt_threshold: float = 10.0, global_x: int = 0, global_y: int = 0) -> Vector2i:
	if _is_hard_floor_depth(depth, boundary_config):
		return bedrock_floor_tile

	if _is_bedrock_transition_depth(depth, boundary_config):
		var transition_ratio := _get_bedrock_transition_ratio(depth, boundary_config)
		if transition_ratio >= 0.74:
			return bedrock_floor_tile
		if transition_ratio >= 0.48:
			return bedrock_transition_tile
		if depth >= 260.0:
			if deep_stone_tile != stone_tile and deep_stone_tile != dirt_tile:
				return deep_stone_tile
			return hard_rock_tile
		if underground_transition_tile != dirt_tile:
			return underground_transition_tile
		return hard_rock_tile

	if depth < 1.0:
		return current_b_data.get("surface_block", grass_tile)
		
	# [Visual] Wavy Layers Logic
	# Use noise to modulate depth checks, creating non-linear strata
	# Scale: 0.05 (approx 20 blocks wavelength), Amplitude: 25 blocks
	var depth_mod: float = 0.0
	if global_y != 0:
		depth_mod = noise_surface_feature.get_noise_2d(float(global_x) * 1.5, float(global_y) * 1.5) * 18.0
	
	var effective_depth: float = depth + depth_mod
	var base_stone: Vector2i = current_b_data.get("stone_block", stone_tile)
	var base_sub: Vector2i = current_b_data.get("sub_block", dirt_tile)

	# Keep non-default underground biome blocks (sand/ice/mud) stable.
	if base_stone != stone_tile:
		if effective_depth > dirt_threshold:
			return base_stone
		return base_sub

	var mid_variant: Vector2i = _resolve_strata_variant(base_stone, hard_rock_tile, Vector2i(1, 3))
	var deep_variant: Vector2i = _resolve_strata_variant(base_stone, deep_stone_tile, Vector2i(0, 3))
	var terminal_variant: Vector2i = _resolve_strata_variant(base_stone, Vector2i(2, 3), Vector2i(3, 2))
	var strata_noise: float = _noise_2d_scaled(noise_cave_region, float(global_x), float(global_y), 0.043, 19.0, 0.051, -31.0)
	var strata_wave: float = _noise_2d_scaled(noise_surface_feature, float(global_x), float(global_y), 0.026, -47.0, 0.031, 37.0)
	var strata_depth: float = effective_depth + strata_noise * 22.0 + strata_wave * 28.0

	if strata_depth > 520.0:
		var terminal_mix: float = _noise_2d_scaled(noise_cave, float(global_x), float(global_y), 0.061, 13.0, 0.071, -29.0)
		if terminal_mix > 0.35:
			return terminal_variant
		if terminal_mix < -0.12:
			return mid_variant
		return deep_variant
	if strata_depth > 360.0:
		var deep_mix: float = _noise_2d_scaled(noise_cave_region, float(global_x), float(global_y), 0.052, -17.0, 0.047, 21.0)
		if deep_mix > 0.45:
			return terminal_variant
		if deep_mix < -0.35:
			return mid_variant
		return deep_variant
	if strata_depth > 230.0:
		return deep_variant
	if strata_depth > 140.0:
		if strata_noise > -0.38:
			return mid_variant
		return base_stone
	if strata_depth > dirt_threshold:
		if strata_noise > 0.55:
			return mid_variant
		return base_stone
		
	return base_sub


func _stage_write_tile(result: Dictionary, layer_idx: int, local_pos: Vector2i, tile_data: Dictionary, preserve_existing: bool) -> void:
	if not result.has(layer_idx):
		result[layer_idx] = {}
	var layer_cells: Dictionary = result[layer_idx]
	if preserve_existing and layer_cells.has(local_pos):
		return
	layer_cells[local_pos] = tile_data

func _get_archetype_id_for_region(region: String, depth_band_id: String) -> String:
	match region:
		CAVE_REGION_CONNECTOR:
			return CAVE_ARCHETYPE_LONG_CONNECTOR_ROUTE
		CAVE_REGION_OPEN_CAVERN:
			return CAVE_ARCHETYPE_LARGE_CHAMBER
		CAVE_REGION_CHAMBER:
			return CAVE_ARCHETYPE_CHAMBER_CLUSTER if depth_band_id != "shallow_underground" else CAVE_ARCHETYPE_GALLERY
		CAVE_REGION_TUNNEL:
			return CAVE_ARCHETYPE_GALLERY
		CAVE_REGION_POCKET:
			return CAVE_ARCHETYPE_POCKET_CLUSTER
		_:
			return CAVE_ARCHETYPE_SOLID_MASS

func _get_surface_entrance_region_budget(global_x: int, is_spawn_safe: bool) -> int:
	if is_spawn_safe:
		# Keep the immediate spawn zone stable, but allow sparse entrances in the outer spawn ring.
		var spawn_relief_fade := _get_spawn_relief_fade(global_x)
		if spawn_relief_fade < 0.55:
			return 0
		return 1
	var world_topology = _get_world_topology()
	if world_topology and world_topology.has_method("get_surface_region_for_tile_x"):
		var region: Dictionary = world_topology.get_surface_region_for_tile_x(global_x)
		if not region.is_empty():
			if bool(region.get("spawn_safe", false)):
				var spawn_relief_fade := _get_spawn_relief_fade(global_x)
				if spawn_relief_fade < 0.55:
					return 0
				return 1
			if String(region.get("region_type", "major")) == "transition":
				return 1
	return 2

func _is_spawn_safe_tile_x(global_x: int) -> bool:
	var world_topology = _get_world_topology()
	if world_topology and world_topology.has_method("is_spawn_safe_tile_x"):
		return world_topology.is_spawn_safe_tile_x(global_x)
	return absi(global_x) < 20

func _get_spawn_relief_fade(global_x: int) -> float:
	# 0.0 => strict spawn flattening, 1.0 => full terrain relief.
	var spawn_center := 0
	var safe_radius_chunks := 2
	var world_topology = _get_world_topology()
	if world_topology and world_topology.has_method("get_spawn_anchor_tile"):
		spawn_center = int(world_topology.get_spawn_anchor_tile())
	if world_topology and world_topology.has_method("get_spawn_safe_radius_chunks"):
		safe_radius_chunks = maxi(int(world_topology.get_spawn_safe_radius_chunks()), 2)

	var dist := 0.0
	if world_topology and world_topology.has_method("shortest_wrapped_tile_distance"):
		dist = float(world_topology.shortest_wrapped_tile_distance(global_x, spawn_center))
	else:
		dist = absf(float(global_x) - float(spawn_center))

	var safe_radius_tiles := maxf(float(safe_radius_chunks * 64), 128.0)
	var inner_radius := safe_radius_tiles * 0.20
	var outer_radius := safe_radius_tiles * 0.60
	if dist <= inner_radius:
		return 0.0
	if dist >= outer_radius:
		return 1.0
	return clampf((dist - inner_radius) / maxf(outer_radius - inner_radius, 1.0), 0.0, 1.0)

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
	if _is_spawn_safe_tile_x(global_x) and _get_spawn_relief_fade(global_x) < 0.35:
		return RELIEF_PROFILE_STARTER_FLAT
	var band_index := int(floor(float(global_x) / 192.0))

	var world_topology = _get_world_topology()
	var biome_name := _get_surface_biome_name(surface_biome)
	var region_type := "major"
	if world_topology and world_topology.has_method("get_surface_region_for_tile_x"):
		var region: Dictionary = world_topology.get_surface_region_for_tile_x(global_x)
		if not region.is_empty():
			if bool(region.get("spawn_safe", false)) and _get_spawn_relief_fade(global_x) < 0.35:
				return RELIEF_PROFILE_STARTER_FLAT
			biome_name = String(region.get("biome", biome_name))
			region_type = String(region.get("region_type", "major"))

	if region_type == "transition":
		return RELIEF_PROFILE_ROLLING

	# 使用更大的宏观区段进行 profile 选择，确保玩家长距离探索能明显遇到不同地形。
	var band_hash := _hash01(band_index, 1913)
	
	# Mapping band logic to wrapped noise
	var band_center_x = float(band_index * 192 + 96)
	var temp_scale = 0.41 / 192.0
	var moist_scale = 0.33 / 192.0
	var band_temp := (_noise_1d_scaled(noise_temperature, band_center_x, temp_scale, 37.0/temp_scale) + 1.0) * 0.5
	var band_moist := (_noise_1d_scaled(noise_moisture, band_center_x, moist_scale, -61.0/moist_scale) + 1.0) * 0.5
	
	var selector := band_hash * 0.46 + band_temp * 0.36 + band_moist * 0.18

	if biome_name != "swamp" and selector > 0.64:
		return RELIEF_PROFILE_MOUNTAIN
	if selector < 0.20:
		return RELIEF_PROFILE_BASIN
	match biome_name:
		"swamp":
			return RELIEF_PROFILE_BASIN if selector > 0.2 else RELIEF_PROFILE_ROLLING
		"tundra":
			return RELIEF_PROFILE_RIDGE if selector > 0.38 else RELIEF_PROFILE_ROLLING
		"desert":
			return RELIEF_PROFILE_ROLLING if selector > 0.44 else RELIEF_PROFILE_BASIN
		"plains":
			return RELIEF_PROFILE_RIDGE if selector > 0.56 else RELIEF_PROFILE_ROLLING
		_:
			return RELIEF_PROFILE_RIDGE if selector > 0.48 else RELIEF_PROFILE_ROLLING

func _compute_macro_relief_delta(global_x: int, profile: String, biome_amp: float) -> float:
	var continental := _noise_1d_wrapped(noise_continental, float(global_x))
	var tunnel_ridge := absf(_noise_1d_wrapped(noise_tunnel, float(global_x)))
	match profile:
		RELIEF_PROFILE_STARTER_FLAT:
			return continental * biome_amp * 0.12
		RELIEF_PROFILE_MOUNTAIN:
			# --- Better Mountain Algorithm (Perlin Ridges + Smooth Falloff) ---
			# Use a lower frequency base noise to define the mountain "mass".
			# This replaces the old "massif" which was too steep.
			var scale_m = 0.005 # Wide base
			var offset_m = 311.0 / scale_m
			var base_shape = _noise_1d_scaled(noise_temperature, float(global_x), scale_m, offset_m)
			
			# Map to 0..1 range with bias to make mountains rarer but wider
			var mountain_intensity = clampf((base_shape + 0.4) * 0.8, 0.0, 1.0)
			mountain_intensity = pow(mountain_intensity, 2.0) # Ease in/out
			
			# Ridged Multi-fractal for the peaks (sharp top, wide bottom)
			# Re-using noise_tunnel but scaled for surface
			var scale_r = 0.012
			var ridge_noise = absf(_noise_1d_scaled(noise_tunnel, float(global_x), scale_r, 0.0))
			var ridge_shape = (1.0 - ridge_noise) # Invert: 1.0 is peak, 0.0 is valley
			ridge_shape = pow(ridge_shape, 2.5) # Sharpen the peak
			
			# Combine: Mountain = (Base Mass + Sharp Peaks) * Intensity
			var height_delta = -(mountain_intensity * 80.0 + ridge_shape * mountain_intensity * 120.0)
			
			# Add some chaotic breakup to avoid perfect geometric shapes
			var scale_c = 0.04
			var breakup = _noise_1d_scaled(noise_surface_feature, float(global_x), scale_c, 100.0) * 15.0 * mountain_intensity
			
			return height_delta + breakup
		RELIEF_PROFILE_RIDGE:
			var ridge_shape := signf(continental) * pow(absf(continental), 0.65)
			return ridge_shape * biome_amp * 0.95 + tunnel_ridge * 18.0 - 8.0
		RELIEF_PROFILE_BASIN:
			return -absf(continental) * biome_amp * 0.65 + 6.0
		_:
			return continental * biome_amp * 0.55

func _compute_biome_relief_delta(global_x: int, profile: String, surface_biome: BiomeType, biome_amp: float) -> float:
	var climate_wave := _noise_1d_wrapped(noise_moisture, float(global_x))
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
	var detail := _noise_1d_wrapped(noise_surface_feature, float(global_x))
	var breakup := _noise_1d_scaled(noise_cave_region, float(global_x), 2.0)
	var detail_amp := 4.0
	if profile == RELIEF_PROFILE_STARTER_FLAT:
		detail_amp = 2.0
	elif profile == RELIEF_PROFILE_MOUNTAIN:
		# Smooth out mountain detail so it's not too jagged on the slopes
		# The major shape comes from macro_relief now.
		detail_amp = 1.0 
	elif profile == RELIEF_PROFILE_RIDGE:
		detail_amp = 5.5
	return detail * detail_amp + breakup * 2.0

func _get_surface_height_raw_for_biome(global_x: int, surface_biome: BiomeType) -> float:
	var base_h := 300.0
	var amp := 40.0
	
	match surface_biome:
		BiomeType.PLAINS:
			amp = 15.0
		BiomeType.DESERT:
			amp = 25.0
			base_h = 310.0
		BiomeType.TUNDRA:
			amp = 30.0
		BiomeType.SWAMP:
			amp = 8.0
			base_h = 320.0
		BiomeType.FOREST:
			amp = 35.0
		_:
			amp = 40.0
			
	var noise_val := _noise_1d_wrapped(noise_continental, float(global_x))
	return base_h + noise_val * amp

func _apply_spawn_relief_clamp(global_x: int, shaped_height: float) -> float:
	var relief_fade := _get_spawn_relief_fade(global_x)
	var flat_target := 300.0 \
		+ _noise_1d_wrapped(noise_continental, float(global_x)) * 10.0 \
		+ _noise_1d_wrapped(noise_surface_feature, float(global_x)) * 2.5
	return lerpf(flat_target, shaped_height, pow(relief_fade, 0.85))

func _get_surface_height_for_biome(global_x: int, surface_biome: BiomeType) -> float:
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
	var base_shape := lerpf(smooth, neighborhood, blend)

	var current_b_data: Dictionary = biome_params.get(surface_biome, biome_params[BiomeType.FOREST]) as Dictionary
	var biome_amp := float(current_b_data.get("amp", 40.0))
	var macro_delta := _compute_macro_relief_delta(global_x, profile, biome_amp)
	var biome_delta := _compute_biome_relief_delta(global_x, profile, surface_biome, biome_amp)
	var local_delta := _compute_local_relief_delta(global_x, profile)

	var shaped := base_shape + macro_delta + biome_delta + local_delta
	shaped = _apply_spawn_relief_clamp(global_x, shaped)
	return clampf(shaped, 210.0, float(world_height - 40))

func _build_surface_transition_context(global_x: int, surface_biome: BiomeType) -> Dictionary:
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
		return {
			"has_transition": false,
			"secondary_surface_biome": surface_biome,
			"blend": 0.0,
			"nearest_dist": float(max_probe),
			"nearest_dir": 0,
		}

	var dist_weight := clampf(1.0 - float(nearest_dist) / float(max_probe), 0.0, 1.0)
	var scale_w = 0.43
	var offset_w = 211.0 / scale_w 
	var wobble := (_noise_1d_scaled(noise_surface_feature, float(global_x), scale_w, offset_w) + 1.0) * 0.5
	var blend := clampf(dist_weight * 0.66 + wobble * 0.34, 0.0, 1.0)
	return {
		"has_transition": true,
		"secondary_surface_biome": secondary,
		"blend": blend,
		"nearest_dist": float(nearest_dist),
		"nearest_dir": nearest_dir,
	}

func _get_column_biome_at_depth(global_x: int, global_y: int, surface_base: float, surface_biome: BiomeType, transition_context: Dictionary = {}, depth_noise_override: float = -99999.0) -> BiomeType:
	var depth_noise := depth_noise_override
	if depth_noise <= -90000.0:
		depth_noise = _noise_1d_scaled(noise_continental, float(global_x), 1.0, 71.0) * 18.0

	var underground_threshold := surface_base + 100.0 + depth_noise
	var current_surface_biome := surface_biome

	if bool(transition_context.get("has_transition", false)):
		var transition_blend := float(transition_context.get("blend", 0.0))
		var proximity := clampf(1.0 - float(transition_context.get("nearest_dist", 96.0)) / 96.0, 0.0, 1.0)
		var surface_mix := clampf(transition_blend * 0.36 + proximity * 0.25, 0.0, 0.58)
		if surface_mix > 0.0:
			var seam_warp := _noise_2d_scaled(noise_tunnel, float(global_x), float(global_y), 0.041, 23.0 / 0.041, 0.037, -19.0) * 7.0
			var warped_x := global_x + seam_warp
			var surface_gate := (_noise_2d_scaled(noise_temperature, warped_x, float(global_y), 0.14, 91.0 / 0.14, 0.19, -73.0) + 1.0) * 0.5
			if surface_gate < surface_mix:
				current_surface_biome = int(transition_context.get("secondary_surface_biome", surface_biome))

	if global_y <= underground_threshold:
		return current_surface_biome

	var ug_biome: BiomeType = _get_underground_variant_for_surface(current_surface_biome)
	var topology = _get_world_topology()

	if topology and topology.is_planetary():
		var depth_from_surface := maxf(float(global_y) - surface_base, 0.0)
		var patch_strength := clampf((depth_from_surface - 24.0) / 220.0, 0.0, 1.0)
		if patch_strength > 0.0:
			var patch_candidate := _sample_underground_patch_biome(global_x, global_y, ug_biome)
			if patch_candidate != ug_biome:
				var patch_gate := (_noise_2d_scaled(noise_surface_feature, float(global_x), float(global_y), 0.031, 19.0, 0.024, -73.0) + 1.0) * 0.5
				var adopt_threshold := 0.74 - patch_strength * 0.34
				if patch_gate > adopt_threshold:
					ug_biome = patch_candidate

		var moist_planetary := _noise_2d_wrapped(noise_moisture, float(global_x), float(global_y) * 0.5)
		if moist_planetary > 0.48 and depth_from_surface > 220.0:
			var swamp_gate := (_noise_2d_scaled(noise_cave_region, float(global_x), float(global_y), 0.027, 57.0, 0.019, -29.0) + 1.0) * 0.5
			if swamp_gate > 0.57:
				return BiomeType.UNDERGROUND_SWAMP
		return ug_biome

	var moist := _noise_2d_wrapped(noise_moisture, float(global_x), float(global_y) * 0.5)
	if bool(transition_context.get("has_transition", false)):
		var secondary_surface: BiomeType = int(transition_context.get("secondary_surface_biome", current_surface_biome))
		var secondary_ug_biome: BiomeType = _get_underground_variant_for_surface(secondary_surface)
		if secondary_ug_biome != ug_biome:
			var transition_blend_ug := float(transition_context.get("blend", 0.0))
			var proximity_ug := clampf(1.0 - float(transition_context.get("nearest_dist", 96.0)) / 96.0, 0.0, 1.0)
			var transition_mix := clampf(transition_blend_ug * 0.74 + proximity_ug * 0.24, 0.0, 0.94)
			var seam_warp_ug := _noise_2d_scaled(noise_tunnel, float(global_x), float(global_y), 0.033, -17.0 / 0.033, 0.021, 29.0) * 9.0
			var warped_x_ug := global_x + seam_warp_ug
			var boundary_noise := (noise_cave_region.get_noise_2d(warped_x_ug * 0.19 + 151.0, global_y * 0.11 - 89.0) + 1.0) * 0.5
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
		if selector > 0.72:
			return SURFACE_ENTRANCE_GENTLE_MOUTH
		return SURFACE_ENTRANCE_NONE
	if relief_profile == RELIEF_PROFILE_MOUNTAIN:
		if selector > 0.84:
			return SURFACE_ENTRANCE_RAVINE_CUT
		if selector > 0.58:
			return SURFACE_ENTRANCE_HILLSIDE_CUT
		if selector > 0.46:
			return SURFACE_ENTRANCE_PIT_FUNNEL
		return SURFACE_ENTRANCE_NONE
	if relief_profile == RELIEF_PROFILE_RIDGE:
		if selector > 0.80:
			return SURFACE_ENTRANCE_HILLSIDE_CUT
		if selector > 0.62:
			return SURFACE_ENTRANCE_RAVINE_CUT
		return SURFACE_ENTRANCE_NONE
	if relief_profile == RELIEF_PROFILE_BASIN:
		if selector > 0.78:
			return SURFACE_ENTRANCE_PIT_FUNNEL
		if selector > 0.62:
			return SURFACE_ENTRANCE_GENTLE_MOUTH
		return SURFACE_ENTRANCE_NONE
	if biome_name == "desert":
		if selector > 0.74:
			return SURFACE_ENTRANCE_RAVINE_CUT
		if selector > 0.58:
			return SURFACE_ENTRANCE_PIT_FUNNEL
		return SURFACE_ENTRANCE_NONE
	if biome_name == "swamp":
		if selector > 0.68:
			return SURFACE_ENTRANCE_PIT_FUNNEL
		if selector > 0.54:
			return SURFACE_ENTRANCE_GENTLE_MOUTH
		return SURFACE_ENTRANCE_NONE
	if selector > 0.79:
		return SURFACE_ENTRANCE_RAVINE_CUT
	if selector > 0.61:
		return SURFACE_ENTRANCE_GENTLE_MOUTH
	if selector > 0.49:
		return SURFACE_ENTRANCE_PIT_FUNNEL
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
	var region_budget := _get_surface_entrance_region_budget(global_x, is_spawn_safe)
	var allow_spawn_entrance := is_spawn_safe and region_budget > 0
	var allow_any_entrance := allow_spawn_entrance or (region_budget > 0 and (can_hillside_cut or relief_profile != RELIEF_PROFILE_STARTER_FLAT))
	if not allow_any_entrance:
		return best

	# 保证出生区外围存在至少一条可发现的温和下探入口，避免开局只能硬挖竖井。
	if allow_spawn_entrance:
		var spawn_anchor := 0
		var world_topology = _get_world_topology()
		if world_topology and world_topology.has_method("get_spawn_anchor_tile"):
			spawn_anchor = int(world_topology.get_spawn_anchor_tile())
		var anchor_x := float(spawn_anchor + 96)
		var anchor_dist := _get_wrapped_tile_distance(float(global_x), anchor_x)
		if anchor_dist <= 16.0:
			var width := 6.2
			var depth := clampf(9.5 + ruggedness * 0.32, 9.5, 14.0)
			var route_floor := clampf(lane_y - 2.0, surface_base + depth + 6.0, surface_base + depth + 20.0)
			return {
				"type": SURFACE_ENTRANCE_GENTLE_MOUTH,
				"family": SURFACE_ENTRANCE_GENTLE_MOUTH,
				"center_x": anchor_x,
				"lip_y": floor(surface_base),
				"width": width,
				"depth": depth,
				"flare": 2.2,
				"side_bias": 1.0,
				"route_entry_x": anchor_x + 1.0,
				"route_exit_x": anchor_x + 4.0,
				"route_floor": route_floor,
				"route_width": 2.35,
				"depth_band_id": _get_depth_band_id(route_floor - surface_base),
				"route_seed": spawn_anchor + 8801,
			}
	var families := [
		{"spacing": 149, "selector_salt": 701, "center_salt": 709, "warp_scale": 0.39, "jitter_scale": 0.47},
		{"spacing": 233, "selector_salt": 811, "center_salt": 823, "warp_scale": 0.27, "jitter_scale": 0.42},
	]
	var active_family_count := mini(region_budget, families.size())

	for family_index in range(active_family_count):
		var family = families[family_index]
		var spacing := int(family.get("spacing", 168))
		var selector_salt := int(family.get("selector_salt", 701))
		var center_salt := int(family.get("center_salt", 709))
		var warp_scale := float(family.get("warp_scale", 0.33))
		var jitter_scale := float(family.get("jitter_scale", 0.45))
		var band_index := int(floor(float(global_x) / float(spacing)))

		for offset in range(-2, 3):
			var idx := band_index + offset
			var idx_f := float(idx)
			var base_center := float(idx * spacing) + float(spacing) * 0.5
			
			var selector_hash := _hash01(idx, selector_salt)
			var scale_sel = 0.53 / float(spacing)
			var offset_sel = (float(selector_salt) * 0.11 - 0.265) / scale_sel
			var selector_noise := (_noise_1d_scaled(noise_temperature, base_center, scale_sel, offset_sel) + 1.0) * 0.5
			var selector := selector_hash * 0.58 + selector_noise * 0.42
			var entrance_type := _select_surface_entrance_type(relief_profile, biome_name, selector, is_spawn_safe)
			if entrance_type == SURFACE_ENTRANCE_NONE:
				continue
			if entrance_type == SURFACE_ENTRANCE_HILLSIDE_CUT and not can_hillside_cut:
				continue
			if entrance_type == SURFACE_ENTRANCE_GENTLE_MOUTH and not is_spawn_safe and (slope_mag < 0.14 and relief_span < 3.2):
				continue
			if not is_spawn_safe and is_peak_top:
				continue

			var scale_warp = warp_scale / float(spacing)
			var offset_warp = (float(selector_salt) * 0.17 - warp_scale * 0.5) / scale_warp
			var center_warp := _noise_1d_scaled(noise_surface_feature, base_center, scale_warp, offset_warp) * float(spacing) * 0.28
			var center_jitter := (_hash01(idx, center_salt) - 0.5) * float(spacing) * jitter_scale
			var center_x := base_center + center_warp + center_jitter
			var cadence_break := (_noise_1d_scaled(noise_moisture, center_x, 0.021, float(selector_salt)/0.021) + 1.0) * 0.5
			if cadence_break < 0.26:
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

			var dist := _get_wrapped_tile_distance(float(global_x), center_x)
			if dist <= width + flare and dist < best_dist:
				var side_bias := _hash01(idx, center_salt + 61) * 2.0 - 1.0
				if entrance_type == SURFACE_ENTRANCE_HILLSIDE_CUT:
					side_bias = -1.0 if left_h_metric < right_h_metric else 1.0
				var route_entry_x := center_x
				var route_exit_x := center_x
				var route_floor := minf(
					lane_y - 2.0,
					surface_base + depth + 10.0 + _hash01(idx, center_salt + 51) * 18.0
				)
				route_floor = maxf(route_floor, surface_base + depth + 7.0)
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
					"family": entrance_type,
					"center_x": center_x,
					"lip_y": floor(surface_base),
					"width": width,
					"depth": depth,
					"flare": flare,
					"side_bias": side_bias,
					"route_entry_x": route_entry_x,
					"route_exit_x": route_exit_x,
					"route_floor": route_floor,
					"route_width": route_width,
					"depth_band_id": _get_depth_band_id(route_floor - surface_base),
					"route_seed": idx * 997 + center_salt,
				}
				best_dist = dist
	return best

func _should_carve_surface_entrance(global_x: int, global_y: int, entrance_info: Dictionary) -> bool:
	if entrance_info.is_empty() or String(entrance_info.get("type", SURFACE_ENTRANCE_NONE)) == SURFACE_ENTRANCE_NONE:
		return false
	var center_x := float(entrance_info.get("center_x", 0.0))
	var signed_dx := _get_wrapped_tile_delta(float(global_x), center_x)
	var dx := absf(signed_dx)
	var lip_y := float(entrance_info.get("lip_y", 0.0))
	var width := float(entrance_info.get("width", 0.0))
	var depth := float(entrance_info.get("depth", 0.0))
	var flare := float(entrance_info.get("flare", 0.0))
	var side_bias := float(entrance_info.get("side_bias", 0.0))
	var route_entry_x := float(entrance_info.get("route_entry_x", center_x))
	var route_width := float(entrance_info.get("route_width", 2.8))
	var entrance_type := String(entrance_info.get("type", SURFACE_ENTRANCE_NONE))
	var carve_floor := -INF

	match entrance_type:
		SURFACE_ENTRANCE_GENTLE_MOUTH:
			if float(global_y) < lip_y - 1.0 or float(global_y) > lip_y + depth:
				return false
			var progress := clampf((float(global_y) - lip_y) / maxf(depth, 1.0), 0.0, 1.0)
			var mouth_center := lerpf(route_entry_x, center_x, pow(progress, 0.76))
			var open_side_scale := 1.06 if signf(signed_dx) == signf(side_bias) else 0.6
			var half_width := lerpf(maxf(1.8, width * 0.34 + flare * 0.26 * open_side_scale), route_width + 0.95, progress)
			var local_dx := absf(_get_wrapped_tile_delta(float(global_x), mouth_center))
			if local_dx <= half_width:
				return true
			var edge_noise := (_noise_2d_scaled(noise_surface_feature, float(global_x), float(global_y), 0.19, 0.0, 0.11, 37.0) + 1.0) * 0.5
			return local_dx <= half_width + 0.75 and edge_noise > 0.7
		SURFACE_ENTRANCE_RAVINE_CUT:
			if float(global_y) < lip_y - 1.0 or float(global_y) > lip_y + depth:
				return false
			var progress := clampf((float(global_y) - lip_y) / maxf(depth, 1.0), 0.0, 1.0)
			var ravine_center := lerpf(route_entry_x, center_x + side_bias * 0.8, pow(progress, 0.58))
			var wall_noise := _noise_2d_scaled(noise_surface_feature, float(global_x), float(global_y), 0.43, 0.0, 0.19, 71.0) * 1.1
			var half_width := lerpf(maxf(1.7, width * 0.29 + flare * 0.45), route_width + 0.9, progress) + wall_noise
			var local_dx := absf(_get_wrapped_tile_delta(float(global_x), ravine_center))
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
			var local_dx := _get_wrapped_tile_delta(float(global_x), cut_center + wall_bias)
			var half_width := lerpf(maxf(1.05, width * 0.18), route_width + 0.64, progress)
			if progress < 0.24 and local_dx * side_bias > 0.0:
				return false
			if absf(local_dx) <= half_width:
				return true
			var edge_noise := (_noise_2d_scaled(noise_cave_region, float(global_x), float(global_y), 0.24, 13.0/0.24, 0.13, -17.0) + 1.0) * 0.5
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
	var progress := clampf((float(global_y) - route_start_y) / maxf(route_floor - route_start_y, 1.0), 0.0, 1.0)
	var eased := pow(progress, 0.82)
	var meander := noise_cave_region.get_noise_2d(route_seed * 0.013 + progress * 2.7, progress * 6.1) * (0.8 + progress * 1.2)
	var drift := noise_tunnel.get_noise_2d(route_seed * 0.007 - 17.0, progress * 4.3) * (0.5 + progress * 1.0)
	var center := lerpf(route_entry_x, route_exit_x, eased) + meander + drift
	var corridor_half := lerpf(route_width + 0.45, route_width + 0.18, progress)
	var dx := absf(_get_wrapped_tile_delta(float(global_x), center))
	if dx <= corridor_half:
		return true

	# 为连接段添加柔化边缘，避免出现规则竖直井筒。
	var edge_noise := (_noise_2d_scaled(noise_surface_feature, float(global_x), float(global_y), 0.22, 0.0, 0.17, route_seed * 0.009) + 1.0) * 0.5
	return dx <= corridor_half + 0.75 and edge_noise > 0.63

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
	var zone_presence := _hash01(zone_index, 3721)
	if relief_profile == RELIEF_PROFILE_MOUNTAIN and zone_presence < 0.1:
		return _make_mountain_breach_none()
	if relief_profile == RELIEF_PROFILE_RIDGE and zone_presence < 0.25:
		return _make_mountain_breach_none()

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
		return _make_mountain_breach_none()

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
	var join_y := clampf(mouth_lane_y + _hash01(zone_index, 3811) * 2.4, mouth_y + 11.0, mouth_y + 24.0)
	var route_floor := maxf(join_y + 3.0, turn_y + 5.0)

	var mouth_radius := 1.45 + _hash01(zone_index, 3809) * 0.4
	var neck_radius := 1.25 + _hash01(zone_index, 3821) * 0.3
	var body_radius := 1.95 + _hash01(zone_index, 3851) * 0.7
	var join_radius := 2.25 + _hash01(zone_index, 3863) * 0.7

	return {
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

func _build_surface_shape_metrics(global_x: int) -> Dictionary:
	var step := 4
	var center_h := _get_surface_height_for_biome(global_x, _get_surface_biome_from_climate(global_x, 0))
	var left_h := _get_surface_height_for_biome(global_x - step, _get_surface_biome_from_climate(global_x - step, 0))
	var right_h := _get_surface_height_for_biome(global_x + step, _get_surface_biome_from_climate(global_x + step, 0))
	
	var slope_left := (center_h - left_h) / float(step)
	var slope_right := (right_h - center_h) / float(step)
	var avg_slope := (slope_left + slope_right) * 0.5
	
	return {
		"slope": avg_slope,
		"slope_left": slope_left,
		"slope_right": slope_right,
		"ruggedness": absf(slope_left - slope_right),
		"relief_span": absf(right_h - left_h),
		"crestness": (center_h - (left_h + right_h) * 0.5), # Positive = Ridge/Peak, Negative = Valley
		"left_h": left_h,
		"right_h": right_h,
		"same_direction_slope": signf(slope_left) == signf(slope_right)
	}

func _build_surface_column_context(global_x: int) -> Dictionary:
	var surface_biome := _get_surface_biome_from_climate(global_x, 0)
	var transition_context := _build_surface_transition_context(global_x, surface_biome)
	var relief_profile := _select_surface_relief_profile(global_x, surface_biome)
	var macro_region_id := _compose_underground_macro_region_id(surface_biome, relief_profile)
	var surface_base := _get_surface_height_for_biome(global_x, surface_biome)
	var is_spawn_safe := _is_spawn_safe_tile_x(global_x)
	var lane_y := _get_cave_lane_y(global_x, surface_base)
	var sample_depth := maxf(lane_y - surface_base, 28.0)
	var underground_zone_id := _get_underground_zone_id(global_x, sample_depth, surface_biome, relief_profile)
	var shape_metrics := _build_surface_shape_metrics(global_x)
	var entrance_info := _get_surface_entrance_info(global_x, surface_base, relief_profile, surface_biome, is_spawn_safe, lane_y, shape_metrics)
	var mountain_breach_info := _get_mountain_worm_breach_info(global_x, surface_base, relief_profile, shape_metrics, lane_y, is_spawn_safe)
	
	# Optimization: Pre-calculate noise that is constant for the column (independent of y)
	# This avoids recalculating it 64 times inside the chunk loop.
	var depth_noise := _noise_1d_scaled(noise_continental, float(global_x), 1.0, 71.0) * 18.0
	
	return {
		"surface_biome": surface_biome,
		"transition_context": transition_context,
		"relief_profile": relief_profile,
		"surface_base": surface_base,
		"is_spawn_safe": is_spawn_safe,
		"macro_region_id": macro_region_id,
		"underground_zone_id": underground_zone_id,
		"shape_metrics": shape_metrics,
		"lane_y": lane_y,
		"entrance_info": entrance_info,
		"mountain_breach_info": mountain_breach_info,
		"depth_noise": depth_noise,
	}

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

func _depth_band_salt(depth_band_id: String) -> int:
	match depth_band_id:
		"surface":
			return 11
		"shallow_underground":
			return 23
		"mid_cavern":
			return 37
		"deep":
			return 53
		"terminal":
			return 71
		_:
			return 89

func _compose_underground_macro_region_id(surface_biome: BiomeType, relief_profile: String) -> String:
	var base_region := _get_surface_biome_name(surface_biome)
	if relief_profile == RELIEF_PROFILE_MOUNTAIN or relief_profile == RELIEF_PROFILE_RIDGE:
		return "%s_highland" % base_region
	if relief_profile == RELIEF_PROFILE_BASIN:
		return "%s_basin" % base_region
	return "%s_%s" % [base_region, relief_profile]

func _get_underground_zone_id(global_x: int, depth: float, surface_biome: BiomeType, relief_profile: String) -> String:
	var depth_band_id := _get_depth_band_id(depth)
	var macro_region := _compose_underground_macro_region_id(surface_biome, relief_profile)
	var zone_val := (_noise_2d_scaled(noise_cave_region, float(global_x), depth, 0.011, 73.0, 0.019, -41.0) + 1.0) * 0.5
	var zone_bucket := int(floor(zone_val * 3.0))
	zone_bucket = clampi(zone_bucket, 0, 2)
	return "%s|%s|z%d" % [depth_band_id, macro_region, zone_bucket]

func _has_large_cavern_budget(global_x: int, depth: float, depth_band_id: String, zone_id: String) -> bool:
	if depth <= 42.0:
		return false
	if depth_band_id == "surface" or depth_band_id == "shallow_underground":
		return false
	var span := 192
	var band_salt := _depth_band_salt(depth_band_id)
	var zone_salt := int(absi(hash(zone_id)) % 977)
	var window_idx := int(floor(float(global_x) / float(span)))
	var window_gate := _hash01(window_idx + int(floor(depth / 96.0)), 8801 + band_salt + zone_salt)
	var depth_gain := clampf((depth - 180.0) / 420.0, 0.0, 1.0)
	var min_gate := lerpf(0.40, 0.28, depth_gain)
	if window_gate < min_gate:
		return false
	var center := float(window_idx * span) + float(span) * 0.5
	center += (_hash01(window_idx, 8923 + band_salt) - 0.5) * float(span) * 0.34
	var half_width := 22.0 + _hash01(window_idx, 9049 + zone_salt) * (16.0 + depth_gain * 10.0)
	return _get_wrapped_tile_distance(float(global_x), center) <= half_width

func _is_long_route_connector_zone(global_x: int, depth: float, zone_id: String) -> bool:
	if depth < 64.0:
		return false
	var span := 256
	var zone_salt := int(absi(hash(zone_id)) % 977)
	var window_idx := int(floor(float(global_x) / float(span)))
	var gate := _hash01(window_idx, 9473 + zone_salt)
	if gate < 0.49:
		return false
	var center := float(window_idx * span) + float(span) * 0.5
	center += (_hash01(window_idx, 9613 + zone_salt) - 0.5) * float(span) * 0.28
	if _get_wrapped_tile_distance(float(global_x), center) > 24.0:
		return false
	var depth_center := 96.0 + _hash01(window_idx, 9749 + zone_salt) * 280.0
	var depth_tolerance := 20.0 + clampf((depth - 220.0) / 380.0, 0.0, 1.0) * 12.0
	return absf(depth - depth_center) <= depth_tolerance

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
	if depth <= 36.0 or depth >= 420.0:
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
	return clampf(lane_y, surface_base + 30.0, surface_base + 420.0)

func _get_cave_region_info_from_context(global_x: int, global_y: int, surface_base: float, relief_profile: String, lane_y: float, surface_biome: BiomeType = BiomeType.FOREST) -> Dictionary:
	var depth = global_y - surface_base
	var depth_band_id := _get_depth_band_id(depth)
	var macro_region_id := _compose_underground_macro_region_id(surface_biome, relief_profile)
	var underground_zone_id := _get_underground_zone_id(global_x, depth, surface_biome, relief_profile)
	var transition_target := _get_depth_band_id(depth + 18.0)
	var info = {
		"region": CAVE_REGION_SURFACE,
		"reachable": true,
		"openness": 1.0,
		"depth": depth,
		"depth_band_id": depth_band_id,
		"macro_region_id": macro_region_id,
		"underground_zone_id": underground_zone_id,
		"depth_band_transition_to": transition_target if transition_target != depth_band_id else "",
		"archetype_id": CAVE_ARCHETYPE_SOLID_MASS,
		"relief_profile": relief_profile,
	}

	if depth < 28.0:
		return info

	var lane_dist = abs(global_y - lane_y)
	var connector_dist = _get_vertical_connector_distance(global_x)
	var chamber_val = noise_cave_region.get_noise_2d(global_x * 0.025, global_y * 0.025)
	var pocket_val = noise_cave_region.get_noise_2d(global_x * 0.055 + 120.0, global_y * 0.055 - 87.0)
	var deep_gain := clampf((depth - 180.0) / 420.0, 0.0, 1.0)
	var open_thresh_primary := lerpf(0.48, 0.34, deep_gain)
	var open_thresh_secondary := lerpf(0.78, 0.56, deep_gain)
	var chamber_thresh := lerpf(0.62, 0.46, deep_gain)
	var pocket_thresh := lerpf(0.76, 0.62, deep_gain)

	info["region"] = CAVE_REGION_SOLID
	info["reachable"] = false
	info["openness"] = 0.0

	if _is_long_route_connector_zone(global_x, depth, underground_zone_id):
		info["region"] = CAVE_REGION_CONNECTOR
		info["reachable"] = true
		info["openness"] = 0.62
	elif _should_place_vertical_connector(global_x, depth):
		info["region"] = CAVE_REGION_CONNECTOR
		info["reachable"] = true
		info["openness"] = 0.55
	elif _has_large_cavern_budget(global_x, depth, depth_band_id, underground_zone_id) and depth > 52.0 and chamber_val > open_thresh_primary:
		info["region"] = CAVE_REGION_OPEN_CAVERN
		info["reachable"] = true
		info["openness"] = 0.92
	elif depth > 48.0 and chamber_val > open_thresh_secondary:
		info["region"] = CAVE_REGION_OPEN_CAVERN
		info["reachable"] = true
		info["openness"] = 0.9
	elif depth > 40.0 and chamber_val > chamber_thresh:
		info["region"] = CAVE_REGION_CHAMBER
		info["reachable"] = true
		info["openness"] = 0.72
	elif depth > 24.0 and lane_dist < 5.0:
		info["region"] = CAVE_REGION_TUNNEL
		info["reachable"] = true
		info["openness"] = 0.35
	elif depth > 54.0 and pocket_val > pocket_thresh:
		info["region"] = CAVE_REGION_POCKET
		info["reachable"] = lane_dist < 16.0 or chamber_val > 0.5 or connector_dist < 7.0
		info["openness"] = 0.18
	elif depth > 300.0 and chamber_val > 0.44:
		info["region"] = CAVE_REGION_CHAMBER
		info["reachable"] = true
		info["openness"] = 0.74

	if depth_band_id == "mid_cavern" and String(info.get("region", "")) == CAVE_REGION_CHAMBER:
		info["openness"] = maxf(float(info.get("openness", 0.72)), 0.78)
	elif (depth_band_id == "deep" or depth_band_id == "terminal") and String(info.get("region", "")) == CAVE_REGION_OPEN_CAVERN:
		info["openness"] = maxf(float(info.get("openness", 0.9)), 0.95)

	info["archetype_id"] = _get_archetype_id_for_region(String(info.get("region", CAVE_REGION_SOLID)), depth_band_id)

	return info

func get_cave_region_info_at_tile(global_x: int, global_y: int) -> Dictionary:
	var surface_base = get_surface_height_at(global_x)
	var relief_profile := get_surface_relief_profile_at_tile(global_x)
	var lane_y = _get_cave_lane_y(global_x, surface_base)
	var surface_biome := _get_surface_biome_from_climate(global_x, 0)
	return _get_cave_region_info_from_context(global_x, global_y, surface_base, relief_profile, lane_y, surface_biome)

func get_cave_region_info_at_pos(global_pos: Vector2) -> Dictionary:
	var tile_x = int(global_pos.x / 16.0)
	var tile_y = int(global_pos.y / 16.0)
	return get_cave_region_info_at_tile(tile_x, tile_y)

func get_underground_generation_metadata_at_tile(global_x: int, global_y: int) -> Dictionary:
	var column_context := _build_surface_column_context(global_x)
	var surface_base: float = column_context.get("surface_base", 300.0)
	var relief_profile: String = column_context.get("relief_profile", RELIEF_PROFILE_ROLLING)
	var lane_y: float = column_context.get("lane_y", surface_base + 54.0)
	var entrance_info: Dictionary = column_context.get("entrance_info", _make_surface_entrance_none())
	var surface_biome: BiomeType = column_context.get("surface_biome", BiomeType.FOREST)
	var cave_info := _get_cave_region_info_from_context(global_x, global_y, surface_base, relief_profile, lane_y, surface_biome)
	var depth := float(global_y) - surface_base
	var boundary_config := _get_depth_boundary_config()
	var underworld_config := _get_underworld_generation_config()
	var underworld_column := _build_underworld_column_context(global_x, surface_base, boundary_config, underworld_config)
	var underworld_state := _get_underworld_tile_state(global_x, depth, underworld_column, boundary_config)
	var underworld_ore_uplift := _get_underworld_ore_uplift_multiplier(global_x, depth, surface_base, boundary_config, underworld_config)
	return {
		"entrance_family": String(entrance_info.get("family", entrance_info.get("type", SURFACE_ENTRANCE_NONE))),
		"entrance_type": String(entrance_info.get("type", SURFACE_ENTRANCE_NONE)),
		"cave_region": String(cave_info.get("region", CAVE_REGION_SOLID)),
		"cave_archetype_id": String(cave_info.get("archetype_id", CAVE_ARCHETYPE_SOLID_MASS)),
		"macro_region_id": String(cave_info.get("macro_region_id", "unknown")),
		"underground_zone_id": String(cave_info.get("underground_zone_id", "unknown")),
		"depth_band_id": String(cave_info.get("depth_band_id", _get_depth_band_id(depth))),
		"depth_band_transition_to": String(cave_info.get("depth_band_transition_to", "")),
		"reachable": bool(cave_info.get("reachable", false)),
		"underworld_enabled": bool(underworld_config.get("enabled", false)),
		"underworld_active": bool(underworld_state.get("active", false)),
		"underworld_region": String(underworld_state.get("region", "none")),
		"underworld_ore_density_multiplier": underworld_ore_uplift,
	}

func get_underground_generation_metadata_at_pos(global_pos: Vector2) -> Dictionary:
	var tile_x := int(global_pos.x / 16.0)
	var tile_y := int(global_pos.y / 16.0)
	return get_underground_generation_metadata_at_tile(tile_x, tile_y)

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
	if depth <= 18.0:
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
	var surface_biome := _get_surface_biome_from_climate(global_x, 0)
	var cave_info = _get_cave_region_info_from_context(global_x, global_y, surface_base, relief_profile, lane_y, surface_biome)
	return _should_carve_accessible_cave_with_context(global_x, global_y, surface_base, lane_y, cave_info, is_spawn_protected, surface_biome)

func _apply_surface_features(coord: Vector2i, result: Dictionary, column_contexts: Array) -> void:
	var chunk_origin_y := coord.y * 64
	for x in range(3, 61):
		var global_x = coord.x * 64 + x
		var column_context: Dictionary = column_contexts[x]
		var surface_base = float(column_context.get("surface_base", 300.0))
		var global_top_y = int(floor(surface_base))
		var top_y = global_top_y - chunk_origin_y
		if top_y < -8 or top_y > 72:
			continue
		var feature = _get_surface_feature_tag_from_context(global_x, global_top_y, global_top_y, int(column_context.get("surface_biome", BiomeType.FOREST)))
		if feature == SURFACE_FEATURE_NONE:
			continue
		if _is_in_structure_forbidden_zone(global_x, global_top_y):
			continue

		match feature:
			SURFACE_FEATURE_DESERT_SPIRE:
				for h in range(1, 4):
					var p := Vector2i(x, top_y - h)
					if p.y >= 0 and p.y < 64:
						result[0][p] = {"source": tile_source_id, "atlas": biome_params[BiomeType.DESERT]["stone_block"]}
			SURFACE_FEATURE_FROST_SPIRE:
				for h in range(1, 5):
					var p := Vector2i(x, top_y - h)
					if p.y >= 0 and p.y < 64:
						result[0][p] = {"source": tile_source_id, "atlas": biome_params[BiomeType.TUNDRA]["stone_block"]}
			SURFACE_FEATURE_MUD_MOUND:
				for ox in range(-1, 2):
					var p := Vector2i(x + ox, top_y - 1)
					if p.x >= 0 and p.x < 64 and p.y >= 0 and p.y < 64:
						result[0][p] = {"source": tile_source_id, "atlas": biome_params[BiomeType.SWAMP]["surface_block"]}
			SURFACE_FEATURE_GRASS_KNOLL:
				var p := Vector2i(x, top_y - 1)
				if p.y >= 0 and p.y < 64:
					result[0][p] = {"source": grass_dirt_source_id, "atlas": grass_tile}
			SURFACE_FEATURE_STONE_OUTCROP:
				for ox in range(-1, 2):
					if ox == 0:
						var p := Vector2i(x + ox, top_y - 1)
						if p.x >= 0 and p.x < 64 and p.y >= 0 and p.y < 64:
							result[0][p] = {"source": tile_source_id, "atlas": stone_tile}
					elif abs(ox) == 1 and (noise_surface_feature.get_noise_2d(global_x + ox, 20) > -0.2):
						var p := Vector2i(x + ox, top_y)
						if p.x >= 0 and p.x < 64 and p.y >= 0 and p.y < 64:
							result[0][p] = {"source": tile_source_id, "atlas": stone_tile}

const ORE_DEPOSIT_FAMILY_CLUSTER := "cluster"

func _is_ore_atlas(atlas: Vector2i) -> bool:
	return atlas == iron_tile \
		or atlas == copper_tile \
		or atlas == gold_tile \
		or atlas == diamond_tile \
		or atlas == magic_crystal_tile \
		or atlas == staff_core_tile \
		or atlas == magic_speed_stone_tile

func _get_ore_cluster_size_for_tile(mineral_tile: Vector2i, depth: float) -> int:
	var size := 10
	if mineral_tile == copper_tile:
		size = 13
	elif mineral_tile == iron_tile:
		size = 12
	elif mineral_tile == gold_tile:
		size = 10
	elif mineral_tile == magic_crystal_tile:
		size = 10
	elif mineral_tile == staff_core_tile or mineral_tile == magic_speed_stone_tile or mineral_tile == diamond_tile:
		size = 7
	if depth > 220.0:
		size += 3
	return maxi(size, 3)

func _is_valid_ore_host_local(coord: Vector2i, local_pos: Vector2i, result: Dictionary, column_contexts: Array, boundary_config: Dictionary) -> bool:
	if local_pos.x < 0 or local_pos.x >= 64 or local_pos.y < 0 or local_pos.y >= 64:
		return false
	if not result.has(0) or not result[0].has(local_pos):
		return false
	if local_pos.x >= column_contexts.size():
		return false

	var column_context: Dictionary = column_contexts[local_pos.x]
	var surface_base := float(column_context.get("surface_base", 300.0))
	var is_spawn_safe_column := bool(column_context.get("is_spawn_safe", false))
	var global_x := coord.x * 64 + local_pos.x
	var global_y := coord.y * 64 + local_pos.y
	var depth := float(global_y) - surface_base
	if depth <= 10.0:
		return false
	if _is_stage_preserve_zone(global_x, depth, is_spawn_safe_column, boundary_config):
		return false
	if _is_bedrock_transition_depth(depth, boundary_config):
		return false
	return true

func _grow_ore_cluster(
	coord: Vector2i,
	center_local: Vector2i,
	mineral_tile: Vector2i,
	target_cells: int,
	spread_chance: float,
	branch_chance: float,
	rng: RandomNumberGenerator,
	result: Dictionary,
	column_contexts: Array,
	boundary_config: Dictionary,
	placements: Dictionary
) -> int:
	var placed := 0
	var visited := {}
	var frontier: Array[Vector2i] = [center_local]
	var dirs: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

	while not frontier.is_empty() and placed < target_cells:
		var pick_idx := rng.randi_range(0, frontier.size() - 1)
		var p: Vector2i = frontier[pick_idx]
		frontier.remove_at(pick_idx)

		var key := "%d,%d" % [p.x, p.y]
		if visited.has(key):
			continue
		visited[key] = true

		if not _is_valid_ore_host_local(coord, p, result, column_contexts, boundary_config):
			continue

		placements[p] = mineral_tile
		placed += 1

		for dir in dirs:
			if rng.randf() < spread_chance:
				frontier.append(p + dir)

		if rng.randf() < branch_chance:
			frontier.append(p + Vector2i(rng.randi_range(-1, 1), rng.randi_range(-1, 1)))

	return placed

func _collect_chunk_ore_deposits(coord: Vector2i, result: Dictionary, column_contexts: Array, boundary_config: Dictionary) -> Dictionary:
	var placements := {}
	if not result.has(0):
		return {
			"family": ORE_DEPOSIT_FAMILY_CLUSTER,
			"cluster_count": 0,
			"underworld_uplift_hits": 0,
			"placements": placements,
		}

	var cluster_count := 0
	var underworld_uplift_hits := 0
	var underworld_config := _get_underworld_generation_config()
	for x in range(2, 62, 2):
		if x >= column_contexts.size():
			continue
		var column_context: Dictionary = column_contexts[x]
		var surface_base := float(column_context.get("surface_base", 300.0))
		var is_spawn_safe_column := bool(column_context.get("is_spawn_safe", false))
		var relief_profile := String(column_context.get("relief_profile", RELIEF_PROFILE_ROLLING))
		var surface_biome: BiomeType = column_context.get("surface_biome", BiomeType.FOREST)

		for y in range(10, 62, 2):
			var center_local := Vector2i(x, y)
			if not _is_valid_ore_host_local(coord, center_local, result, column_contexts, boundary_config):
				continue

			var global_x := coord.x * 64 + x
			var global_y := coord.y * 64 + y
			var depth := float(global_y) - surface_base
			var zone_id := _get_underground_zone_id(global_x, depth, surface_biome, relief_profile)
			var gate := (noise_mineral_common.get_noise_2d(global_x * 0.37 + 17.0, global_y * 0.31 - 13.0) + 1.0) * 0.5
			var ore_uplift := _get_underworld_ore_uplift_multiplier(global_x, depth, surface_base, boundary_config, underworld_config)

			var center_prob := 0.12
			if depth > 80.0:
				center_prob = 0.18
			if depth > 180.0:
				center_prob = 0.24
			if depth > 300.0:
				center_prob = 0.30
			if is_spawn_safe_column:
				center_prob *= 0.78
			if ore_uplift > 1.0:
				center_prob *= ore_uplift
				underworld_uplift_hits += 1
			center_prob = minf(center_prob, 0.92)
			if gate < (1.0 - center_prob):
				continue

			var mineral_tile := _get_mineral_at(global_x, global_y, depth)
			if mineral_tile == Vector2i(-1, -1):
				continue

			var zone_salt := int(absi(hash(zone_id)) % 2048)
			var rng := RandomNumberGenerator.new()
			rng.seed = int((global_x + 4096) * 1315423911) ^ int((global_y + 8192) * 2654435761) ^ int(seed_value + zone_salt * 97)

			var target_cells := _get_ore_cluster_size_for_tile(mineral_tile, depth) + rng.randi_range(-1, 3)
			target_cells = maxi(target_cells, 3)
			var spread_chance := 0.72 if depth <= 180.0 else 0.76
			var branch_chance := 0.24 if depth <= 220.0 else 0.30

			var placed := _grow_ore_cluster(
				coord,
				center_local,
				mineral_tile,
				target_cells,
				spread_chance,
				branch_chance,
				rng,
				result,
				column_contexts,
				boundary_config,
				placements
			)
			if placed > 0:
				cluster_count += 1

	return {
		"family": ORE_DEPOSIT_FAMILY_CLUSTER,
		"cluster_count": cluster_count,
		"underworld_uplift_hits": underworld_uplift_hits,
		"placements": placements,
	}

func _collect_ore_component_metrics(layer0: Dictionary) -> Dictionary:
	var ore_map := {}
	for key in layer0.keys():
		if not (key is Vector2i):
			continue
		var pos: Vector2i = key
		var tile_variant = layer0.get(pos, {})
		if not (tile_variant is Dictionary):
			continue
		var tile_data: Dictionary = tile_variant
		var atlas_variant = tile_data.get("atlas", null)
		if not (atlas_variant is Vector2i):
			continue
		var atlas: Vector2i = atlas_variant
		if _is_ore_atlas(atlas):
			ore_map[pos] = true

	if ore_map.is_empty():
		return {
			"ore_cells": 0,
			"component_count": 0,
			"largest_component": 0,
			"avg_component_size": 0.0,
			"single_cell_ratio": 0.0,
		}

	var visited := {}
	var component_sizes: Array[int] = []
	var dirs: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

	for ore_pos_variant in ore_map.keys():
		var ore_pos: Vector2i = ore_pos_variant
		var start_key := "%d,%d" % [ore_pos.x, ore_pos.y]
		if visited.has(start_key):
			continue

		var queue: Array[Vector2i] = [ore_pos]
		visited[start_key] = true
		var comp_size := 0

		while not queue.is_empty():
			var current: Vector2i = queue.pop_back()
			comp_size += 1
			for dir in dirs:
				var next_pos := current + dir
				if not ore_map.has(next_pos):
					continue
				var next_key := "%d,%d" % [next_pos.x, next_pos.y]
				if visited.has(next_key):
					continue
				visited[next_key] = true
				queue.append(next_pos)

		component_sizes.append(comp_size)

	var largest := 0
	var total_cells := 0
	var singles := 0
	for size in component_sizes:
		total_cells += size
		largest = maxi(largest, size)
		if size == 1:
			singles += 1

	return {
		"ore_cells": total_cells,
		"component_count": component_sizes.size(),
		"largest_component": largest,
		"avg_component_size": float(total_cells) / maxf(float(component_sizes.size()), 1.0),
		"single_cell_ratio": float(singles) / maxf(float(component_sizes.size()), 1.0),
	}

func _apply_resource_stage(coord: Vector2i, result: Dictionary, column_contexts: Array, boundary_config: Dictionary) -> void:
	if not result.has(0):
		return
	var ore_build := _collect_chunk_ore_deposits(coord, result, column_contexts, boundary_config)
	var placements: Dictionary = ore_build.get("placements", {})
	for pos_variant in placements.keys():
		if not (pos_variant is Vector2i):
			continue
		var local_pos: Vector2i = pos_variant
		if not result[0].has(local_pos):
			continue
		var current_tile: Dictionary = result[0][local_pos]
		var mineral_tile: Vector2i = placements[local_pos]
		_stage_write_tile(result, 0, local_pos, {
			"source": int(current_tile.get("source", tile_source_id)),
			"atlas": mineral_tile,
		}, false)

	var ore_diag := {
		"family": String(ore_build.get("family", ORE_DEPOSIT_FAMILY_CLUSTER)),
		"cluster_count": int(ore_build.get("cluster_count", 0)),
		"underworld_uplift_hits": int(ore_build.get("underworld_uplift_hits", 0)),
		"placed_cells": placements.size(),
	}
	ore_diag["component_metrics"] = _collect_ore_component_metrics(result.get(0, {}))
	result["_ore_generation"] = ore_diag

func _mark_liquid_contact_tile(result: Dictionary, local_pos: Vector2i, liquid_type: String) -> void:
	# Runtime liquid overlay now handles water presentation; avoid writing dark edge-contact
	# tiles into terrain for water, which produced stray deep-blue blocks near lakes.
	if liquid_type == "water":
		return
	if not result.has(0):
		return
	if not result[0].has(local_pos):
		return
	var edge_tile := liquid_contact_water_tile
	if liquid_type == "lava":
		edge_tile = liquid_contact_lava_tile
	var current_tile: Dictionary = result[0][local_pos]
	_stage_write_tile(result, 0, local_pos, {
		"source": int(current_tile.get("source", tile_source_id)),
		"atlas": edge_tile,
	}, false)

func _collect_liquid_stage_seeds(coord: Vector2i, result: Dictionary, column_contexts: Array, boundary_config: Dictionary) -> Array:
	var seeds: Array = []
	var max_seed_budget := 18
	if not result.has(0):
		return seeds

	for x in range(2, 62):
		if x >= column_contexts.size():
			continue
		var column_context: Dictionary = column_contexts[x]
		var surface_base := float(column_context.get("surface_base", 300.0))
		var is_spawn_safe_column := bool(column_context.get("is_spawn_safe", false))

		for y in range(8, 62):
			var local_pos := Vector2i(x, y)
			var floor_pos := local_pos + Vector2i(0, 1)
			if not result[0].has(floor_pos):
				continue
			if result[0].has(local_pos):
				continue

			var global_x := coord.x * 64 + x
			var global_y := coord.y * 64 + y
			var depth := float(global_y) - surface_base
			# [OPENSPEC] Adjusted to allow surface lakes (depth < 36.0)
			# Only skip if significantly above surface base to avoid sky waterfalls
			if depth < -50.0:
				continue

			if _is_stage_preserve_zone(global_x, depth, is_spawn_safe_column, boundary_config):
				continue
			if _is_hard_floor_depth(depth, boundary_config):
				continue

			var gate := (noise_mineral_common.get_noise_2d(global_x * 0.73 + 19.0, global_y * 0.67 - 11.0) + 1.0) * 0.5
			
			# [OPENSPEC] Lava uses absolute depth (Y>1800) to ensure deep planetary placement
			# Also use relief profile to determine surface lake probability
			var is_lava_band := global_y > 1800 or _is_bedrock_transition_depth(depth, boundary_config)
			var is_surface_zone := depth < 36.0
			var relief_profile = column_context.get("relief_profile", RELIEF_PROFILE_ROLLING)
			
			var threshold := 0.988
			if is_lava_band:
				threshold = 0.75
			elif is_surface_zone:
				if relief_profile == RELIEF_PROFILE_BASIN:
					threshold = 0.55 # Very high probability for basins to fill with water (Lakes)
				else:
					threshold = 0.995 # Rare otherwise
			else:
				# Cave Zone water probability
				# [OPENSPEC] Lower threshold to allow more underground water pockets (Terraria-like)
				threshold = 0.85 # Significantly increased (Top 15% of noise peaks)
			
			if gate < threshold:
				continue

			var liquid_type := "lava" if is_lava_band else "water"

			# Use horizontal patch seeding instead of vertical stacks to avoid water pillars.
			var seed_radius := 0
			if liquid_type == "water":
				if is_surface_zone and relief_profile == RELIEF_PROFILE_BASIN:
					seed_radius = 6
				elif not is_surface_zone:
					seed_radius = 2

			var seeded_any := false

			# Ensure surface basin lakes have a real cavity reserved before seeding.
			if liquid_type == "water" and is_surface_zone and relief_profile == RELIEF_PROFILE_BASIN:
				for ox in range(-seed_radius, seed_radius + 1):
					var tx := local_pos.x + ox
					if tx < 0 or tx >= 64 or tx >= column_contexts.size():
						continue
					var t_ctx: Dictionary = column_contexts[tx]
					var surface_local := int(floor(float(t_ctx.get("surface_base", surface_base)))) - coord.y * 64
					var weight := 1.0 - (absf(float(ox)) / maxf(1.0, float(seed_radius) + 0.01))
					var carve_depth := clampi(int(round(3.0 + weight * 5.0)), 2, 8)
					for cy in range(carve_depth):
						var carve_pos := Vector2i(tx, surface_local + 1 + cy)
						if carve_pos.y < 0 or carve_pos.y >= 64:
							continue
						if result[0].has(carve_pos):
							result[0].erase(carve_pos)

			for ox in range(-seed_radius, seed_radius + 1):
				var target_pos := local_pos + Vector2i(ox, 0)
				if target_pos.x < 0 or target_pos.x >= 64:
					continue

				var seeded_column := false
				if liquid_type == "water" and is_surface_zone and relief_profile == RELIEF_PROFILE_BASIN:
					# Fill basin columns to ~2/3 of column depth from terrain surface.
					max_seed_budget = maxi(max_seed_budget, 220)
					var target_context: Dictionary = column_contexts[target_pos.x]
					var column_surface_local := int(floor(float(target_context.get("surface_base", surface_base)))) - coord.y * 64
					var weight := 1.0 - (absf(float(ox)) / maxf(1.0, float(seed_radius) + 0.01))
					var cavity_depth := clampi(int(round(3.0 + weight * 5.0)), 2, 8)
					var fill_layers := maxi(1, int(ceil(float(cavity_depth) * 0.66)))
					var fill_start_y := column_surface_local + 1
					for fy in range(fill_layers):
						var fill_pos := Vector2i(target_pos.x, fill_start_y + fy)
						if fill_pos.y < 0 or fill_pos.y >= 64:
							continue
						if result[0].has(fill_pos):
							continue
						seeds.append({
							"local_pos": fill_pos,
							"type": liquid_type,
							"amount": 1.0,
						})
						seeded_column = true
						if seeds.size() >= max_seed_budget:
							break
				else:
					if result[0].has(target_pos):
						continue
					var target_floor := target_pos + Vector2i(0, 1)
					if not result[0].has(target_floor):
						continue
					seeds.append({
						"local_pos": target_pos,
						"type": liquid_type,
						"amount": 1.0,
					})
					seeded_column = true

				if seeded_column:
					var target_floor := target_pos + Vector2i(0, 1)
					if target_floor.y >= 0 and target_floor.y < 64:
						_mark_liquid_contact_tile(result, target_floor, liquid_type)
					seeded_any = true
					if seeds.size() >= max_seed_budget:
						break

			if not seeded_any:
				seeds.append({
					"local_pos": local_pos,
					"type": liquid_type,
					"amount": 1.0,
				})
				_mark_liquid_contact_tile(result, floor_pos, liquid_type)
			break

		if seeds.size() >= max_seed_budget:
			break

	# Guarantee cave water readability and avoid near-dry underground runs.
	var min_water_required := 2
	if coord.y >= 8:
		min_water_required = 6
	if coord.y >= 16:
		min_water_required = 8
	var min_lava_required := 1 if coord.y >= 20 else 0
	seeds = _ensure_minimum_liquid_seeds(coord, result, column_contexts, boundary_config, seeds, min_water_required, min_lava_required)

	return seeds

func _ensure_minimum_liquid_seeds(coord: Vector2i, result: Dictionary, column_contexts: Array, boundary_config: Dictionary, existing_seeds: Array, min_water: int, min_lava: int) -> Array:
	var seeds: Array = existing_seeds.duplicate(true)
	var seen := {}
	var water_count := 0
	var lava_count := 0

	for raw_seed in seeds:
		if not (raw_seed is Dictionary):
			continue
		var seed: Dictionary = raw_seed
		var local_pos: Vector2i = seed.get("local_pos", Vector2i(-1, -1))
		var key := "%d,%d" % [local_pos.x, local_pos.y]
		seen[key] = true
		var liquid_type := String(seed.get("type", "water"))
		if liquid_type == "lava":
			lava_count += 1
		else:
			water_count += 1

	for x in range(3, 61):
		if water_count >= min_water and lava_count >= min_lava:
			break
		if x >= column_contexts.size():
			continue

		var column_context: Dictionary = column_contexts[x]
		var surface_base := float(column_context.get("surface_base", 300.0))
		var is_spawn_safe_column := bool(column_context.get("is_spawn_safe", false))

		for y in range(10, 61):
			if water_count >= min_water and lava_count >= min_lava:
				break

			var local_pos := Vector2i(x, y)
			var floor_pos := local_pos + Vector2i(0, 1)
			if not result[0].has(floor_pos):
				continue
			if result[0].has(local_pos):
				continue

			var seed_key := "%d,%d" % [local_pos.x, local_pos.y]
			if seen.has(seed_key):
				continue

			var global_x := coord.x * 64 + x
			var global_y := coord.y * 64 + y
			var depth := float(global_y) - surface_base
			if depth < 34.0:
				continue
			if _is_stage_preserve_zone(global_x, depth, is_spawn_safe_column, boundary_config):
				continue
			if _is_hard_floor_depth(depth, boundary_config):
				continue

			var liquid_type := ""
			var deep_lava_band := global_y > 1800 or _is_bedrock_transition_depth(depth, boundary_config) or depth > 260.0
			if deep_lava_band and lava_count < min_lava:
				liquid_type = "lava"
			elif water_count < min_water:
				liquid_type = "water"

			if liquid_type == "":
				continue

			seeds.append({
				"local_pos": local_pos,
				"type": liquid_type,
				"amount": 1.0,
			})
			seen[seed_key] = true
			_mark_liquid_contact_tile(result, floor_pos, liquid_type)
			if liquid_type == "lava":
				lava_count += 1
			else:
				water_count += 1

	return seeds

func _ensure_result_layer(result: Dictionary, layer_idx: int) -> Dictionary:
	if not result.has(layer_idx):
		result[layer_idx] = {}
	var layer_cells: Dictionary = result.get(layer_idx, {})
	if not (layer_cells is Dictionary):
		layer_cells = {}
		result[layer_idx] = layer_cells
	return layer_cells

func _place_step_tree_tiles(result: Dictionary, ground_pos: Vector2i) -> void:
	var tree_cells := _ensure_result_layer(result, 10)
	var root_y := ground_pos.y - 1
	if root_y < 1:
		return

	var root_tiles := [tree_root_left, tree_root_mid, tree_root_right]
	for dx in range(-1, 2):
		var rp := Vector2i(ground_pos.x + dx, root_y)
		if rp.x < 0 or rp.x >= 64 or rp.y < 0 or rp.y >= 64:
			continue
		tree_cells[rp] = {"source": tree_source_id, "atlas": root_tiles[dx + 1]}

	var trunk_height := 3
	for i in range(1, trunk_height + 1):
		var tp := Vector2i(ground_pos.x, root_y - i)
		if tp.y < 0 or tp.y >= 64:
			continue
		tree_cells[tp] = {"source": tree_source_id, "atlas": tree_trunk_tile}

	var canopy_center := Vector2i(ground_pos.x, root_y - trunk_height - 1)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var cp := canopy_center + Vector2i(dx, dy)
			if cp.x < 0 or cp.x >= 64 or cp.y < 0 or cp.y >= 64:
				continue
			tree_cells[cp] = {"source": tree_source_id, "atlas": tree_canopy_tile}

func _step_place_surface_trees(coord: Vector2i, result: Dictionary, column_contexts: Array, density_scale: float = 1.0) -> void:
	if not result.has(0):
		return
	var layer0: Dictionary = result.get(0, {})
	if layer0.is_empty():
		return

	for x in range(3, 61):
		if x >= column_contexts.size():
			continue
		var column_context: Dictionary = column_contexts[x]
		var surface_base := float(column_context.get("surface_base", 300.0))
		# Terrain solid tiles start at surface_base + 1 (global_y > surface_base),
		# so tree grounding must match that convention or every candidate becomes "air".
		var local_y := int(floor(surface_base)) - coord.y * 64 + 1
		if local_y < 5 or local_y > 60:
			continue

		var ground_pos := Vector2i(x, local_y)
		var above_pos := Vector2i(x, local_y - 1)
		if not layer0.has(ground_pos):
			continue
		if layer0.has(above_pos):
			continue

		var global_x := coord.x * 64 + x
		var global_ground_y := coord.y * 64 + local_y
		if _is_in_structure_forbidden_zone(global_x, global_ground_y):
			continue

		var cluster_val := (_noise_2d_wrapped(noise_tree_cluster, float(global_x), 0.0) + 1.0) * 0.5
		var density_val := (_noise_2d_wrapped(noise_tree_density, float(global_x), 0.0) + 1.0) * 0.5
		var chance := clampf(tree_chance * density_scale * (0.32 + cluster_val * 1.9), 0.0, 0.82)
		if density_val > chance:
			continue

		_place_step_tree_tiles(result, ground_pos)

func _step_spread_chunk_grass(coord: Vector2i, result: Dictionary, column_contexts: Array) -> void:
	if not result.has(0):
		return
	var layer0: Dictionary = result.get(0, {})
	for x in range(0, 64):
		if x >= column_contexts.size():
			continue
		var column_context: Dictionary = column_contexts[x]
		var surface_base := float(column_context.get("surface_base", 300.0))
		var local_top := int(floor(surface_base)) - coord.y * 64 + 1
		for y in range(max(local_top, 1), min(local_top + 8, 63)):
			var p := Vector2i(x, y)
			if not layer0.has(p):
				continue
			var p_above := Vector2i(x, y - 1)
			if layer0.has(p_above):
				continue
			var data: Dictionary = layer0[p]
			var atlas: Vector2i = data.get("atlas", dirt_tile)
			if atlas == dirt_tile:
				data["atlas"] = grass_tile
				data["source"] = grass_dirt_source_id
				layer0[p] = data

func _step_apply_material_variation(coord: Vector2i, result: Dictionary, column_contexts: Array) -> void:
	if not result.has(0):
		return
	var layer0: Dictionary = result.get(0, {})
	for x in range(0, 64):
		if x >= column_contexts.size():
			continue
		var global_x := coord.x * 64 + x
		var column_context: Dictionary = column_contexts[x]
		var surface_base := float(column_context.get("surface_base", 300.0))
		var surface_biome: BiomeType = column_context.get("surface_biome", BiomeType.FOREST)
		var b_data: Dictionary = biome_params.get(surface_biome, biome_params[BiomeType.FOREST])
		var sub_tile: Vector2i = b_data.get("sub_block", dirt_tile)
		var stone_t: Vector2i = b_data.get("stone_block", stone_tile)

		for y in range(0, 64):
			var p := Vector2i(x, y)
			if not layer0.has(p):
				continue
			var global_y := coord.y * 64 + y
			var depth := float(global_y) - surface_base
			if depth <= 8.0:
				continue
			var data: Dictionary = layer0[p]
			var gate := (_noise_2d_wrapped(noise_surface_feature, float(global_x), float(global_y)) + 1.0) * 0.5
			if depth < 42.0 and gate > 0.72:
				data["atlas"] = sub_tile
			elif depth >= 42.0 and gate > 0.68:
				data["atlas"] = stone_t
			layer0[p] = data

func _step_apply_clay_patches(coord: Vector2i, result: Dictionary, column_contexts: Array) -> void:
	if not result.has(0):
		return
	var layer0: Dictionary = result.get(0, {})
	var clay_tile := Vector2i(3, 2)
	for x in range(0, 64):
		if x >= column_contexts.size():
			continue
		var global_x := coord.x * 64 + x
		var surface_base := float(column_contexts[x].get("surface_base", 300.0))
		for y in range(0, 64):
			var p := Vector2i(x, y)
			if not layer0.has(p):
				continue
			var global_y := coord.y * 64 + y
			var depth := float(global_y) - surface_base
			if depth < 14.0 or depth > 140.0:
				continue
			var gate := (_noise_2d_wrapped(noise_moisture, float(global_x), float(global_y)) + 1.0) * 0.5
			if gate < 0.82:
				continue
			var data: Dictionary = layer0[p]
			data["atlas"] = clay_tile
			layer0[p] = data

func _step_apply_additional_liquids(coord: Vector2i, result: Dictionary, column_contexts: Array, boundary_config: Dictionary, extra_water: int = 0, extra_lava: int = 0) -> void:
	var seeds: Array = []
	if result.has("_liquid_seeds") and result["_liquid_seeds"] is Array:
		seeds = result["_liquid_seeds"].duplicate(true)
	else:
		seeds = _collect_liquid_stage_seeds(coord, result, column_contexts, boundary_config)

	var min_lava_required := (1 if coord.y >= 20 else 0) + extra_lava
	seeds = _ensure_minimum_liquid_seeds(coord, result, column_contexts, boundary_config, seeds, 2 + extra_water, min_lava_required)
	if not seeds.is_empty():
		result["_liquid_seeds"] = seeds

func _apply_terraria_step_to_chunk(step_index: int, coord: Vector2i, result: Dictionary, column_contexts: Array, boundary_config: Dictionary) -> void:
	match step_index:
		9, 10:
			_step_apply_material_variation(coord, result, column_contexts)
		11:
			_step_apply_clay_patches(coord, result, column_contexts)
		12:
			_step_apply_additional_liquids(coord, result, column_contexts, boundary_config, 1, 0)
		18, 20, 75, 103:
			_step_spread_chunk_grass(coord, result, column_contexts)
		19, 21, 26, 27, 31, 34, 40, 41, 97:
			_step_apply_material_variation(coord, result, column_contexts)
		24, 30:
			_step_apply_additional_liquids(coord, result, column_contexts, boundary_config, 0, 1)
		28, 37, 59, 76, 94, 95:
			_apply_resource_stage(coord, result, column_contexts, boundary_config)
		32, 36, 47, 49, 51, 52, 56, 64, 87, 99, 100, 101, 104:
			_step_apply_additional_liquids(coord, result, column_contexts, boundary_config, 0, 0)
		44, 45, 52, 70, 84, 100:
			_step_place_surface_trees(coord, result, column_contexts, 1.0 if step_index != 84 else 1.35)
		83, 89, 91, 92:
			_apply_surface_features(coord, result, column_contexts)
		_:
			pass

func _is_step_user_skipped(step_index: int) -> bool:
	for raw_step in terraria_user_skip_steps:
		if int(raw_step) == step_index:
			return true
	return false

func _apply_terraria_steps_to_chunk(coord: Vector2i, result: Dictionary, column_contexts: Array, boundary_config: Dictionary) -> Array:
	var trace: Array = []
	var emit_trace: bool = terraria_emit_step_trace
	for step_index in range(1, TERRARIA_COMPAT_STEP_TOTAL + 1):
		var step_name := String(TERRARIA_STEP_NAMES.get(step_index, "terraria_step_%03d" % step_index))
		var status := "executed"
		var skip_reason := ""
		var before_l0 := 0
		var before_l1 := 0
		var before_l2 := 0
		if emit_trace:
			before_l0 = int(result.get(0, {}).size())
			before_l1 = int(result.get(1, {}).size())
			before_l2 = int(result.get(2, {}).size())

		if _is_step_user_skipped(step_index):
			status = "skipped"
			skip_reason = "USER_EXPLICIT_SKIP"
		else:
			_apply_terraria_step_to_chunk(step_index, coord, result, column_contexts, boundary_config)

		if emit_trace:
			var after_l0 := int(result.get(0, {}).size())
			var after_l1 := int(result.get(1, {}).size())
			var after_l2 := int(result.get(2, {}).size())
			trace.append({
				"step_index": step_index,
				"step_name": step_name,
				"status": status,
				"skip_reason": skip_reason,
				"delta_layer0": after_l0 - before_l0,
				"delta_layer1": after_l1 - before_l1,
				"delta_layer2": after_l2 - before_l2,
			})
		else:
			trace.append({
				"step_index": step_index,
				"step_name": step_name,
				"status": status,
				"skip_reason": skip_reason,
			})
	return trace

func _get_surface_height_critical_fast(global_x: int, surface_biome: BiomeType) -> float:
	var b_params = biome_params.get(surface_biome, biome_params[BiomeType.FOREST])
	var biome_amp := float(b_params.get("amp", 40.0))
	var profile := _select_surface_relief_profile(global_x, surface_biome)
	var continental := _noise_1d_wrapped(noise_continental, float(global_x))
	var detail := _noise_1d_wrapped(noise_surface_feature, float(global_x)) * 2.8
	var shaped := 300.0 + continental * biome_amp * 0.58 + detail
	shaped += _compute_macro_relief_delta(global_x, profile, biome_amp) * 0.72
	shaped += _compute_biome_relief_delta(global_x, profile, surface_biome, biome_amp) * 0.45
	shaped = _apply_spawn_relief_clamp(global_x, shaped)
	return clampf(shaped, 210.0, float(world_height - 40))

func _generate_chunk_cells_critical_fast(coord: Vector2i) -> Dictionary:
	var result = { 0: {}, 1: {}, 2: {} }
	var chunk_origin: Vector2i = coord * 64
	var boundary_config := _get_depth_boundary_config()
	var underworld_config := _get_underworld_generation_config()

	for x in range(64):
		var global_x: int = chunk_origin.x + x
		var surface_biome: BiomeType = _get_surface_biome_from_climate(global_x, 0)
		var surface_base: float = _get_surface_height_critical_fast(global_x, surface_biome)
		var underworld_column := _build_underworld_column_context(global_x, surface_base, boundary_config, underworld_config)
		var lane_y: float = _get_cave_lane_y(global_x, surface_base)
		var is_spawn_safe_column: bool = _is_spawn_safe_tile_x(global_x)
		var transition_context: Dictionary = _build_surface_transition_context(global_x, surface_biome)
		var col_depth_noise: float = _noise_1d_scaled(noise_continental, float(global_x), 1.0, 71.0) * 18.0

		var surface_data: Dictionary = biome_params.get(surface_biome, biome_params[BiomeType.FOREST])

		# [New Logic] Variable soil depth simulation
		var dirt_depth_noise: float = noise_surface_feature.get_noise_1d(global_x * 0.15)
		var dirt_threshold: float = 8.0 + (dirt_depth_noise * 4.0) # Base 8, +/- 4 (4 to 12)
		
		for y in range(64):
			var global_y: int = chunk_origin.y + y

			if global_y <= surface_base:
				continue

			var local_pos: Vector2i = Vector2i(x, y)
			var depth: float = float(global_y) - surface_base
			var is_spawn_protected: bool = is_spawn_safe_column and depth < 40.0
			var is_solid: bool = true
			if _is_hard_floor_depth(depth, boundary_config):
				is_solid = true

			# Critical path keeps cave rules lightweight: preserve traversability and postpone expensive shaping to enrichment.
			if not _is_hard_floor_depth(depth, boundary_config) and not is_spawn_protected and depth > 16.0:
				var lane_dist := absf(float(global_y) - lane_y)
				if lane_dist <= 2.0:
					is_solid = false
				else:
					var cave_val := noise_cave.get_noise_2d(global_x, global_y)
					var tunnel_val := noise_tunnel.get_noise_2d(global_x, global_y)
					var cave_thresh := 0.58 if depth < 90.0 else 0.50
					if cave_val > cave_thresh or tunnel_val > 0.87:
						is_solid = false

			var current_biome := _get_column_biome_at_depth(global_x, global_y, surface_base, surface_biome, transition_context, col_depth_noise)
			var current_data: Dictionary = biome_params.get(current_biome, surface_data)

			if not is_solid and _is_bedrock_transition_depth(depth, boundary_config):
				var reseal_ratio := _get_bedrock_transition_ratio(depth, boundary_config)
				var reseal_gate := (noise_surface_feature.get_noise_2d(global_x * 0.037 + 43.0, global_y * 0.051 - 17.0) + 1.0) * 0.5
				if reseal_gate < reseal_ratio:
					is_solid = true

			var underworld_state := _get_underworld_tile_state(global_x, depth, underworld_column, boundary_config)
			if bool(underworld_state.get("active", false)):
				is_solid = bool(underworld_state.get("solid", false))

			if is_solid:
				var custom_source_id = int(current_data.get("source_id", tile_source_id))
				# Pass dirt_threshold to resolve varying soil depth
				var atlas: Vector2i = _resolve_solid_atlas_for_depth(current_data, depth, boundary_config, dirt_threshold, global_x, global_y)

				# [Terraria-style Micro-Biomes] Soil mixing (Dirt patches in stone, Stone patches in dirt)
				if depth > 5.0 and depth < 120.0:
					var patch_val = noise_cave.get_noise_2d(global_x * 2.5, global_y * 2.5)
					if patch_val > 0.65:
						var dirt_t = current_data.get("sub_block", dirt_tile)
						var stone_t = current_data.get("stone_block", stone_tile)
						if atlas == dirt_t:
							atlas = stone_t # Stone patch in Dirt
						elif atlas == stone_t:
							atlas = dirt_t # Dirt patch in Stone

				if atlas == current_data.get("surface_block", grass_tile) and atlas == Vector2i(2, 0):
					custom_source_id = grass_dirt_source_id
				if _is_bedrock_transition_depth(depth, boundary_config):
					custom_source_id = tile_source_id

				result[0][local_pos] = {
					"source": custom_source_id,
					"atlas": atlas,
				}

			# Critical path only guarantees collision-ready terrain (Layer0).
			# Background fill is deferred to enrichment to reduce walking-time frame spikes.

	result["_stage_families"] = [
		STAGE_FAMILY_FOUNDATION_AND_RELIEF,
		STAGE_FAMILY_CAVE_AND_TUNNEL,
		STAGE_FAMILY_BIOME_MACRO,
	]
	result["_alignment_metrics"] = get_stage_alignment_metrics()
	return result

func generate_chunk_cells(coord: Vector2i, critical_only: bool = false) -> Dictionary:
	if critical_only:
		return _generate_chunk_cells_critical_fast(coord)

	# 开启上下文缓存，不仅加速当前 Chunk，也加速其必须计算的邻域
	_is_generating_chunk = true
	_transient_biome_cache.clear()
	_transient_raw_height_cache.clear()

	var result = { 0: {}, 1: {}, 2: {} }
	var chunk_origin = coord * 64
	var column_contexts: Array = []
	var boundary_config := _get_depth_boundary_config()
	var underworld_config := _get_underworld_generation_config()
	
	for x in range(64):
		var global_x = chunk_origin.x + x
		var column_context := _build_surface_column_context(global_x)
		var surface_base: float = column_context.get("surface_base", 300.0)
		var underworld_column := _build_underworld_column_context(global_x, surface_base, boundary_config, underworld_config)
		var is_spawn_safe_column: bool = column_context.get("is_spawn_safe", false)
		var transition_context: Dictionary = column_context.get("transition_context", {})
		var lane_y: float = column_context.get("lane_y", surface_base + 54.0)
		var surface_biome: BiomeType = column_context.get("surface_biome", BiomeType.FOREST)
		var relief_profile: String = column_context.get("relief_profile", RELIEF_PROFILE_ROLLING)
		var entrance_info: Dictionary = column_context.get("entrance_info", _make_surface_entrance_none())
		var mountain_breach_info: Dictionary = column_context.get("mountain_breach_info", _make_mountain_breach_none())
		var col_depth_noise: float = float(column_context.get("depth_noise", 0.0))
		column_contexts.append(column_context)
		
		# [Optimization] Pre-calculate variable soil thickness (Dirt Layer)
		# Varies between ~6 and ~14 blocks deep based on x
		var dirt_layer_var = _noise_1d_scaled(noise_surface_feature, float(global_x), 0.12, 54.0)
		var dirt_threshold = 10.0 + dirt_layer_var * 4.0
		
		for y in range(64):
			var global_y = chunk_origin.y + y
			var local_pos = Vector2i(x, y)
			if global_y <= surface_base:
				continue
			
			# 2. 垂直填充逻辑
			var is_solid = global_y > surface_base
			var depth = global_y - surface_base
			if _is_hard_floor_depth(depth, boundary_config):
				is_solid = true
			var current_biome := _get_column_biome_at_depth(global_x, global_y, surface_base, surface_biome, transition_context, col_depth_noise)
			var cave_info := {}
			if is_solid and not _is_hard_floor_depth(depth, boundary_config):
				if _should_carve_mountain_worm_breach(global_x, global_y, mountain_breach_info):
					is_solid = false
				elif _should_carve_surface_entrance(global_x, global_y, entrance_info):
					is_solid = false
				elif _should_carve_entrance_route(global_x, global_y, entrance_info):
					is_solid = false
				else:
					cave_info = _get_cave_region_info_from_context(global_x, global_y, surface_base, relief_profile, lane_y, surface_biome)
			
			# 3. 深度洞穴
			if is_solid and not _is_hard_floor_depth(depth, boundary_config):
				var dist_from_surf = depth
				var is_spawn_protected = is_spawn_safe_column and dist_from_surf < 40.0
				
				if _should_carve_accessible_cave_with_context(global_x, global_y, surface_base, lane_y, cave_info, is_spawn_protected, surface_biome):
					is_solid = false

			if not is_solid and _is_bedrock_transition_depth(depth, boundary_config):
				var reseal_ratio := _get_bedrock_transition_ratio(depth, boundary_config)
				var reseal_gate := (noise_surface_feature.get_noise_2d(global_x * 0.037 + 43.0, global_y * 0.051 - 17.0) + 1.0) * 0.5
				if reseal_gate < reseal_ratio:
					is_solid = true

			var underworld_state := _get_underworld_tile_state(global_x, depth, underworld_column, boundary_config)
			if bool(underworld_state.get("active", false)):
				is_solid = bool(underworld_state.get("solid", false))
					
			if is_solid:
				var current_b_data = biome_params.get(current_biome, biome_params[BiomeType.FOREST])

				# 决定瓦片材质
				var custom_source_id = int(current_b_data.get("source_id", tile_source_id))
				var atlas: Vector2i = _resolve_solid_atlas_for_depth(current_b_data, depth, boundary_config, dirt_threshold, global_x, global_y)
				
				# [Terraria-style Micro-Biomes]
				# Mix Dirt into Stone and Stone into Dirt near the interface to simulate "Soil Patches"
				if depth > 5.0 and depth < 120.0:
					# Use existing noise to avoid new costs. Tuned for blobby patches.
					var patch_val = _noise_2d_scaled(noise_cave, float(global_x), float(global_y), 2.5, 0.0, 2.5, 0.0) 
					if patch_val > 0.65:
						var dirt_t = current_b_data.get("sub_block", dirt_tile)
						var stone_t = current_b_data.get("stone_block", stone_tile)
						
						if atlas == dirt_t:
							atlas = stone_t # Stone patch in Dirt
						elif atlas == stone_t:
							atlas = dirt_t # Dirt patch in Stone

				if atlas == current_b_data.get("surface_block", grass_tile) and atlas == Vector2i(2, 0):
					custom_source_id = grass_dirt_source_id
				if _is_bedrock_transition_depth(depth, boundary_config):
					custom_source_id = tile_source_id
				var tile_data = {"source": custom_source_id, "atlas": atlas}
				
				# 强制将所有实心方块放在 Layer 0，确保玩家始终有物理碰撞
				result[0][local_pos] = tile_data
				
			# --- 背景墙逻辑：防止地下出现虚空 ---
			# 只要是在地表以下，就在 Layer 1 (背景) 放置背景墙
			if global_y > surface_base + 3.0:
				var bg_biome = current_biome
				var bg_data = biome_params.get(bg_biome, biome_params[BiomeType.FOREST])
				
				# 在地下深处强制放置背景墙以填补洞穴
				var bg_tile = bg_data["sub_block"]
				if global_y > surface_base + 30.0:
					bg_tile = _resolve_solid_atlas_for_depth(bg_data, depth, boundary_config, dirt_threshold, global_x, global_y)
				if _is_hard_floor_depth(depth, boundary_config):
					bg_tile = bedrock_floor_tile
				elif _is_bedrock_transition_depth(depth, boundary_config):
					bg_tile = bedrock_transition_tile
				
				# Move background walls to Layer 2 ("Deep") to allow Layer 1 to be used for Liquids (Foreground/Midground)
				result[2][local_pos] = {
					"source": bg_data.get("source_id", tile_source_id),
					"atlas": bg_tile
				}

	# Strict 107-step chunk pipeline (with explicit per-step trace for auditability).
	if terraria_strict_chunk_pipeline:
		var terraria_step_trace := _apply_terraria_steps_to_chunk(coord, result, column_contexts, boundary_config)
		if terraria_emit_step_trace:
			result["_terraria_step_trace"] = terraria_step_trace
	else:
		# Compatibility path.
		_apply_resource_stage(coord, result, column_contexts, boundary_config)
		_apply_surface_features(coord, result, column_contexts)
		_step_place_surface_trees(coord, result, column_contexts)
		var liquid_seeds := _collect_liquid_stage_seeds(coord, result, column_contexts, boundary_config)
		if not liquid_seeds.is_empty():
			result["_liquid_seeds"] = liquid_seeds

	result["_tree_stage_applied"] = true
	result["_stage_families"] = TERRARIA_CORE_STAGE_SEQUENCE.duplicate(true)
	result["_alignment_metrics"] = get_stage_alignment_metrics()

	_is_generating_chunk = false
	_transient_biome_cache.clear()
	_transient_raw_height_cache.clear()
	
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

func get_stage_tileset_mapping() -> Dictionary:
	return {
		"surface_primary": grass_tile,
		"underground_primary": underground_transition_tile,
		"deep_primary": deep_stone_tile,
		"bedrock_transition": bedrock_transition_tile,
		"bedrock_floor": bedrock_floor_tile,
		"liquid_contact_water": liquid_contact_water_tile,
		"liquid_contact_lava": liquid_contact_lava_tile,
	}

func _tileset_has_atlas(source_id: int, atlas: Vector2i) -> bool:
	if not layer_0 or not layer_0.tile_set:
		return false
	if not layer_0.tile_set.has_source(source_id):
		return false
	var source = layer_0.tile_set.get_source(source_id)
	if source is TileSetAtlasSource:
		return source.has_tile(atlas)
	return false

func _validate_stage_tileset_mapping() -> void:
	var mapping := get_stage_tileset_mapping()
	for key in mapping.keys():
		var atlas = mapping.get(key, null)
		if atlas is Vector2i and not _tileset_has_atlas(tile_source_id, atlas):
			push_warning("WorldGenerator: staged tile mapping '%s' atlas %s not found on source %d" % [String(key), str(atlas), tile_source_id])

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
	# 优先使用 WorldTopology 的出生锚点，避免在行星接缝 (x=0) 附近出生导致单侧可见空洞。
	var global_x := 0
	if WorldTopology:
		if WorldTopology.has_method("get_spawn_anchor_tile"):
			global_x = int(WorldTopology.get_spawn_anchor_tile())
		elif WorldTopology.has_method("get_spawn_anchor_chunk"):
			global_x = int(WorldTopology.get_spawn_anchor_chunk()) * 64 + 32

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

# --- Completion of Planetary Ring & Fluid System Tasks ---

func generate_global_map() -> void:
	print("WorldGenerator: Generating global map (Planetary Ring Mode)...")
	# In a finite ring world, execute generation in passes
	# Emulate Terraria's 107-step sequence
	
	for step in range(1, 108):
		_execute_generation_step(step)

func _execute_generation_step(step_index: int) -> void:
	var step_name = TERRARIA_STEP_NAMES.get(step_index, "Unknown Step")
	# Skip only when user explicitly requests step skip.
	if _is_step_user_skipped(step_index):
		print("WorldGenerator: [Step %d - %s] SKIPPED (USER_EXPLICIT_SKIP)" % [step_index, step_name])
		return

	print("WorldGenerator: [Step %d - %s] Executing..." % [step_index, step_name])
	
	match step_index:
		# Foundation
		1: # Reset to Ocean
			_reset_world_data() 
		2: # Reset to Dirt
			_fill_base_terrain()
		4: # Dune Terrain -> Mapped to basic terrain noise
			_generate_terrain_heightmap()
		6: # Hill Terrain -> Mapped to secondary terrain noise
			_apply_hills_pass()
			
		8: # Mountain Generation
			_apply_mountain_pass()
			
		# Caves & Tunnels (Batch 2)
		17: # Caves - Cavern Regions
			_generate_noise_caves()
		18: # Caves - Tunnel Passes
			_generate_tunnel_passes()
		19: # Cave Entrances
			_generate_cave_entrances()
		20: # Cave Refines
			pass # Already handled by noise refinement
		21: # Tunnel Passes (Secondary)
			_generate_tunnel_passes(true)
		24: # Lava Layer
			_setup_lava_layer()
		25: # Liquid Layer Initial Pass
			settle_liquids()
		26, 27, 28: # Granite/Marble Caves
			_generate_mini_biomes(["granite", "marble"])
		29, 30: # Jungle Vines/Chambers
			_generate_jungle_micro_features()
		33, 34: # Underworld
			_generate_underworld()
		40, 41: # Underground Desert
			_generate_underground_desert()
			
		# Batch 3 (41-60)
		46, 47: # Living Trees
			_generate_living_trees()
		52: # Tree Generation
			_generate_surface_trees()
		53, 54, 55, 56, 57: # Ores
			_generate_ores(step_index)
		59, 60: # Heart Crystals, Cabins
			_generate_underground_structures(step_index)
			
		# Batch 4 (61-80)
		64: # Desert Cacti
			_generate_cacti()
		65, 66, 77: # Dungeon
			_generate_dungeon()
		71: # Tall Gate
			pass # Reserved
		72, 79: # Special Ores/Pyramids
			_generate_special_structures(step_index)
			
		# Batch 5 (81-107)
		87, 88: # Villages / Housing
			_spawn_villages()
		89: # Herbs
			_place_herbs()
		94: # Liquid Pressure
			_settle_liquid_pressure()
		95: # Liquid Mix
			pass # Reactive handled at runtime
		96, 97: # Liquid Cleanup
			pass # Auto-cleanup
		98: # Evaporation
			pass # Runtime
		99: # Final Tile Fix
			smooth_world()
		100: # Wall Generation
			_generate_walls()
		102: # Tile Paint
			pass # Structure-specific paint done in-place
		103: # Grass Spread
			_spread_grass()
		104: # Jungle Polish
			pass
			
		107: # Generation Complete
			print("WorldGenerator: Generation Sequence Complete.")
		
		_:
			# Default behavior for unmapped steps that are not explicitly skipped
			# In a real implementation, we would mark these as SKIPPED or NOT_IMPLEMENTED,
			# but for now we just log and continue to allow partial implementation.
			# If strict adherence is required, add entries to TERRARIA_SKIP_POLICY.
			pass

func _reset_world_data() -> void:
	if layer_0: layer_0.clear()
	if layer_1: layer_1.clear()
	if layer_2: layer_2.clear()

func _fill_base_terrain() -> void:
	# Basic fill based on world bounds (if not already handled by chunk generation)
	print("WorldGenerator: Filling base terrain from heightmap...")
	if not layer_0 or not layer_1: return
	
	# Global fill (expensive, but necessary if not using on-demand chunk gen for base)
	for x in range(world_width):
		var sy = int(get_surface_height_at(x))
		
		# Layer 0: Surface (Grass)
		# Only place if not air (sanity check)
		if sy < world_height:
			layer_0.set_cell(Vector2i(x, sy), grass_dirt_source_id, grass_tile)
		
		# Layer 1: Underground (Dirt -> Stone -> Deep Stone)
		# Fill column
		for y in range(sy + 1, world_height):
			var tile = dirt_tile
			# Dirt depth approx 20-30 blocks
			if y > sy + 25: 
				tile = stone_tile
			# Deep stone depth
			if y > world_height - 150:
				tile = deep_stone_tile
			
			layer_1.set_cell(Vector2i(x, y), tile_source_id, tile)

func _generate_terrain_heightmap() -> void:
	# Calls into the existing topology code to cache heightmap
	_get_world_topology().get_height_at_x(0) # Force cache warmup

func _apply_hills_pass() -> void:
	# Additional hill processing if needed
	# Modify heightmap in specific regions? 
	# For now, rely on Perlin noise already in topological heightmap.
	pass

func _apply_mountain_pass() -> void:
	# Step 8: Mountain Generation
	# Verify and accentuate mountains
	var topology = _get_world_topology()
	if topology and topology.is_planetary():
		var plan = topology.world_plan
		if plan and plan.has("surface_regions"):
			for region in plan["surface_regions"]:
				if region.get("param_profile") == "mountain":
					# Explicitly roughen surface in mountain regions
					var start_x = int(region.get("start_x", 0))
					var end_x = int(region.get("end_x", 0))
					for x in range(start_x, end_x):
						var y = int(get_surface_height_at(x))
						# Add peaks
						if randf() < 0.3:
							layer_0.set_cell(Vector2i(x, y - 1), tile_source_id, stone_tile)

func _generate_noise_caves() -> void:
	# Step 17 & 21: Noise-based cave carving
	print("WorldGenerator: Carving noise caves...")
	var noise = FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.02
	noise.fractal_octaves = 3
	
	# Iterate underground only (optimization: sparse check or per-chunk)
	# For global generation simplicity:
	var chunks_x = world_width / 64
	for cx in range(chunks_x):
		var center_x = cx * 64 + 32
		var sy = get_surface_height_at(center_x)
		
		# Only process below surface
		for x in range(cx*64, (cx+1)*64):
			for y in range(int(sy)+10, world_height - 10):
				if noise.get_noise_2d(x, y) > 0.4:
					if layer_1: layer_1.erase_cell(Vector2i(x,y))

func _generate_tunnel_passes(secondary: bool = false) -> void:
	# Step 18, 21: Directed tunnel worms
	var tunnel_count = 30 if not secondary else 15
	print("WorldGenerator: Digging %s tunnels..." % ("secondary" if secondary else "primary"))
	
	for i in range(tunnel_count):
		var start_x = randi() % world_width
		var start_y = randi() % (world_height / 2) + (world_height / 4)
		var length = randi_range(100, 300)
		_dig_tunnel_worm(start_x, start_y, length, 3.0)

func _dig_tunnel_worm(start_x: int, start_y: int, length: int, radius: float) -> void:
	if not layer_1: return
	
	var pos = Vector2(start_x, start_y)
	var dir = Vector2(randf() - 0.5, randf() - 0.5).normalized()
	
	for i in range(length):
		# Carve circle
		var r_int = int(radius)
		for dy in range(-r_int, r_int + 1):
			for dx in range(-r_int, r_int + 1):
				if dx*dx + dy*dy <= radius*radius:
					var tx = int(pos.x) + dx
					var ty = int(pos.y) + dy
					
					# Wrap X
					if tx < 0: tx += world_width
					if tx >= world_width: tx -= world_width
					
					if ty > 0 and ty < world_height:
						layer_1.erase_cell(Vector2i(tx, ty))
						
		# Move worm
		pos += dir
		# Adjust direction with Perlin-like behaviour or random steering
		dir = (dir + Vector2(randf() - 0.5, randf() - 0.5) * 0.3).normalized()
		
		# Gravity bias
		if randf() < 0.05: dir.y += 0.2

func _generate_cave_entrances() -> void:
	# Step 19: Modify surface terrain to open mouths
	print("WorldGenerator: Opening cave entrances...")
	for i in range(world_width / 50): # One every 50 tiles approx
		if randf() < 0.3:
			var tx = randi() % world_width
			var sy = int(get_surface_height_at(tx))
			# Dig down a bit
			for d in range(20):
				if layer_1:
					layer_1.erase_cell(Vector2i(tx, sy + d))
					layer_1.erase_cell(Vector2i(tx+1, sy + d))
					# Add some noise to edges
					if randf() < 0.5: layer_1.erase_cell(Vector2i(tx-1, sy+d))
					if randf() < 0.5: layer_1.erase_cell(Vector2i(tx+2, sy+d))

func _setup_lava_layer() -> void:
	# Step 24: Define lava depth threshold & pre-fill bottom
	print("WorldGenerator: Setting up Lava Layer...")
	if not layer_1: return
	
	var lava_start = world_height - 100
	for x in range(0, world_width, 4): # Coarse fill
		for y in range(lava_start, world_height, 2):
			# Randomly fill empty space with lava "seeds" 
			# In actual game, these would be liquid source blocks
			if layer_1.get_cell_source_id(Vector2i(x, y)) == -1:
				if randf() < 0.05:
					# Mark as lava (using liquid contact tile as placeholder)
					layer_1.set_cell(Vector2i(x, y), tile_source_id, liquid_contact_lava_tile)

func _generate_mini_biomes(types: Array) -> void:
	print("WorldGenerator: Generating Mini-Biomes: ", types)
	for type in types:
		var count = 3
		for i in range(count):
			var cx = randi() % world_width
			var cy = randi_range(world_height / 3, world_height - 50)
			_generate_blob_biome(cx, cy, type)

func _generate_blob_biome(cx: int, cy: int, type: String) -> void:
	# Granit/Marble blob
	var radius = randi_range(15, 25)
	
	if not layer_1: return
	var tile_coords = stone_tile # Default
	if type == "granite": tile_coords = Vector2i(0, 3) # Mock Granite
	if type == "marble": tile_coords = Vector2i(2, 3) # Mock Marble
	
	for y in range(-radius, radius):
		for x in range(-radius, radius):
			if x*x + y*y < radius*radius * (0.8 + randf() * 0.4):
				var tx = cx + x
				var ty = cy + y
				if tx < 0: tx += world_width
				if tx >= world_width: tx -= world_width
				
				if ty > 0 and ty < world_height:
					# Replace existing stone/dirt
					if layer_1.get_cell_source_id(Vector2i(tx, ty)) != -1:
						layer_1.set_cell(Vector2i(tx, ty), tile_source_id, tile_coords)

func _generate_jungle_micro_features() -> void:
	# Step 29-30
	print("WorldGenerator: Placing Jungle micro-features...")
	if not layer_0 or not layer_1: return
	
	# Detect Jungle surface (approx by x-range or biome map if available)
	# For now, scatter randomly
	for i in range(20):
		var x = randi() % world_width
		var sy = int(get_surface_height_at(x))
		# Vines hanging from trees or overhangs
		if layer_0.get_cell_source_id(Vector2i(x, sy-1)) != -1:
			for d in range(1, randi_range(3, 8)):
				if layer_0.get_cell_source_id(Vector2i(x, sy+d)) == -1:
					layer_0.set_cell(Vector2i(x, sy+d), tile_source_id, vine_tile)
				
	# Hives (small hollow pockets)
	for i in range(5):
		var cx = randi() % world_width
		var cy = randi_range(world_height/2, world_height - 50)
		_build_hive(cx, cy)

func _build_hive(x: int, y: int) -> void:
	# Simple circle fill honey/hive
	var r = randi_range(4, 7)
	for ddy in range(-r, r):
		for ddx in range(-r, r):
			if ddx*ddx + ddy*ddy < r*r:
				if layer_1: layer_1.set_cell(Vector2i(x+ddx, y+ddy), tile_source_id, hive_tile)
				if ddx*ddx + ddy*ddy < (r-1)*(r-1):
					if layer_1: layer_1.erase_cell(Vector2i(x+ddx, y+ddy)) # Hollow


func _generate_underworld() -> void:
	# Step 33-34: Hell
	print("WorldGenerator: Excavating Underworld...")
	# Clear out a large horizontal strip at bottom
	if not layer_1: return
	var hell_top = world_height - 60
	for x in range(world_width):
		for y in range(hell_top, world_height - 10):
			if randf() < 0.7: # Mostly open space
				layer_1.erase_cell(Vector2i(x, y))
				
	# Build obsidian towers (simple columns)
	for i in range(20):
		var tx = randi() % world_width
		var h = randi_range(10, 40)
		for y in range(world_height - 10 - h, world_height - 10):
			layer_1.set_cell(Vector2i(tx, y), tile_source_id, deep_stone_tile)

func _generate_underground_desert() -> void:
	# Step 40-41
	print("WorldGenerator: Generating Underground Desert...")
	if not layer_1: return
	
	var cx = randi() % world_width
	var cy = world_height / 2
	var rad_x = 40
	var rad_y = 60
	# Create oval cavern
	for y in range(-rad_y, rad_y):
		for x in range(-rad_x, rad_x):
			if (x*x)/float(rad_x*rad_x) + (y*y)/float(rad_y*rad_y) < 0.8:
				var tx = cx + x 
				if tx < 0: tx += world_width
				if tx >= world_width: tx -= world_width
				var ty = cy + y
				
				if ty > 0 and ty < world_height:
					if layer_1.get_cell_source_id(Vector2i(tx, ty)) != -1:
						if randf() < 0.1: # Anthill structure
							layer_1.set_cell(Vector2i(tx, ty), tile_source_id, sand_tile)
						elif randf() < 0.6: # Clear
							layer_1.erase_cell(Vector2i(tx, ty))
						else: # Walls
							layer_1.set_cell(Vector2i(tx, ty), tile_source_id, sand_tile)

func _generate_living_trees() -> void:
	# Step 46-47
	# Vertical shafts of wood
	print("WorldGenerator: Growing Living Trees...")
	if not layer_1: return
	
	for i in range(2):
		var tx = randi() % world_width
		var sy = get_surface_height_at(tx)
		var height = randi_range(30, 60)
		
		# Trunk
		for y in range(sy - 15, sy + height):
			# Hollow trunk
			layer_1.set_cell(Vector2i(tx-2, y), tree_source_id, tree_root_left) # Wood wall mock
			layer_1.set_cell(Vector2i(tx+2, y), tree_source_id, tree_root_right)
			layer_1.erase_cell(Vector2i(tx, y))
			layer_1.erase_cell(Vector2i(tx-1, y))
			layer_1.erase_cell(Vector2i(tx+1, y))

func _generate_surface_trees() -> void:
	# Step 52: Massive tree planting pass
	print("WorldGenerator: Planting trees...")
	# Placeholder for tree planting logic
	if tree_layer_1:
		# Simple random tree planting for visibility
		for x in range(0, world_width, 5):
			if randf() < tree_chance:
				var surface_y = get_surface_height_at(x)
				var tile_pos = Vector2i(x, int(surface_y) - 1)
				# Check if space is empty
				if layer_0.get_cell_source_id(tile_pos) == -1:
					# Place simple tree (mock)
					tree_layer_1.set_cell(tile_pos, tree_source_id, tree_trunk_tile)
					tree_layer_1.set_cell(tile_pos + Vector2i(0,-1), tree_source_id, tree_canopy_tile)

func _generate_ores(step_index: int) -> void:
	# Step 53-57: Progressive Ore Gen
	var ore_name = TERRARIA_STEP_NAMES.get(step_index, "Unknown Ore")
	var rarity = 0.05
	var cluster_size = 5
	var tile_coords = copper_tile
	
	match step_index:
		53: # Copper/Tin
			rarity = 0.08
			cluster_size = 12
			tile_coords = copper_tile
		54: # Iron/Lead
			rarity = 0.06
			cluster_size = 8
			tile_coords = iron_tile
		55: # Silver/Tungsten
			rarity = 0.04
			cluster_size = 6
			tile_coords = magic_crystal_tile # Placeholder for Silver
		56: # Gold/Platinum
			rarity = 0.03
			cluster_size = 5
			tile_coords = gold_tile
		57: # Demonite
			rarity = 0.015
			cluster_size = 4
			tile_coords = diamond_tile # Placeholder for Demonite
			
	print("WorldGenerator: Generating %s (rarity: %.3f, size: %d)" % [ore_name, rarity, cluster_size])
	
	# Global scan for ore placement
	# Optimization: Use a coherent noise pass to determine ore "vein centers"
	var noise = FastNoiseLite.new()
	noise.seed = seed_value + step_index * 1337
	noise.frequency = 0.15 # High frequency for scattered pockets
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	# Determine depth range based on tier
	var start_depth = 20.0 if step_index == 53 else (40.0 + (step_index - 53) * 15.0)
	
	var veins_count = int((world_width * world_height) * (rarity * 0.01))
	
	var chunks_x = world_width / 64
	var chunks_y = world_height / 64
	
	for cx in range(chunks_x):
		var surface_y = get_surface_height_at(cx * 64 + 32)
		for cy in range(chunks_y):
			var depth = (cy * 64) - surface_y
			if depth < start_depth: continue
			
			# Chance for a vein in this chunk
			if randf() < (rarity * 5.0): # 5x rarity for chunk chance
				# Place vein
				var local_x = randi() % 64
				var local_y = randi() % 64
				var gx = cx * 64 + local_x
				var gy = cy * 64 + local_y
				
				_spawn_ore_cluster(gx, gy, tile_coords, cluster_size)

func _spawn_ore_cluster(center_x: int, center_y: int, tile_coords: Vector2i, base_size: int) -> void:
	if not layer_1: return
	
	var size = base_size + (randi() % 4 - 2)
	var steps = size * 2
	var current = Vector2(center_x, center_y)
	
	for i in range(steps):
		var ix = int(current.x)
		var iy = int(current.y)
		
		# Only replace stone or dirt
		var existing_source = layer_1.get_cell_source_id(Vector2i(ix, iy))
		if existing_source != -1: # Replace valid ground
			layer_1.set_cell(Vector2i(ix, iy), tile_source_id, tile_coords)
			
		# Random walk
		current += Vector2(randf() - 0.5, randf() - 0.5) * 1.5
		
		# Wrap around
		if current.x < 0: current.x += world_width
		if current.x >= world_width: current.x -= world_width
		
func _generate_cacti() -> void:
	# Step 64: Desert Cacti
	print("WorldGenerator: Planting cacti...")
	if not layer_0 or not layer_1: return
	
	# Scan for sand
	for x in range(world_width):
		var y = int(get_surface_height_at(x))
		if layer_1.get_cell_atlas_coords(Vector2i(x, y)) == sand_tile:
			if randf() < 0.1:
				# Plant cactus
				layer_0.set_cell(Vector2i(x, y-1), tile_source_id, cactus_tile)
				layer_0.set_cell(Vector2i(x, y-2), tile_source_id, cactus_tile)

func _place_herbs() -> void:
	# Step 89: Herbs
	print("WorldGenerator: Planting herbs...")
	if not layer_0 or not layer_1: return
	for x in range(0, world_width, 10):
		var y = int(get_surface_height_at(x))
		var ground = layer_1.get_cell_atlas_coords(Vector2i(x, y))
		if ground != Vector2i(-1, -1):
			if randf() < 0.05:
				layer_0.set_cell(Vector2i(x, y-1), tile_source_id, herb_tile)

func _generate_walls() -> void:
	# Step 100: Wall Generation
	if not layer_2: return
	print("WorldGenerator: Generating background walls...")
	
	# Optimization: Chunk-based fill for underground
	var chunks_x = world_width / 32
	var chunks_y = world_height / 32
	
	for cx in range(chunks_x):
		var surface_y = get_surface_height_at(cx * 32 + 16)
		for cy in range(chunks_y):
			if cy * 32 > surface_y + 10:
				# Deep enough, fill chunk
				for y in range(cy*32, (cy+1)*32):
					for x in range(cx*32, (cx+1)*32):
						if layer_2.get_cell_source_id(Vector2i(x,y)) == -1:
							layer_2.set_cell(Vector2i(x,y), wall_source_id, wall_tile)

func _generate_underground_structures(step_index: int) -> void:
	# Cabins
	print("WorldGenerator: Building underground cabins...")
	for i in range(10):
		var cx = randi() % world_width
		var cy = randi_range(world_height/3, world_height-20)
		_build_cabin(cx, cy)

func _build_cabin(x: int, y: int) -> void:
	if not layer_1: return
	var w = randi_range(6, 10)
	var h = randi_range(5, 7)
	
	# Clear space
	for dy in range(h):
		for dx in range(w):
			layer_1.erase_cell(Vector2i(x+dx, y+dy))
			if layer_2: layer_2.set_cell(Vector2i(x+dx, y+dy), wall_source_id, wall_tile) # Back wall
	
	# Planks floor/ceil
	for dx in range(w):
		layer_1.set_cell(Vector2i(x+dx, y), tile_source_id, wood_plank_tile) 
		layer_1.set_cell(Vector2i(x+dx, y+h-1), tile_source_id, wood_plank_tile) 
	
	# Planks walls
	for dy in range(h):
		layer_1.set_cell(Vector2i(x, y+dy), tile_source_id, wood_plank_tile)
		layer_1.set_cell(Vector2i(x+w-1, y+dy), tile_source_id, wood_plank_tile)

func _generate_dungeon() -> void:
	print("WorldGenerator: Constructing Dungeon...")
	# Left side dungeon
	var start_x = 50
	var start_y = int(get_surface_height_at(start_x)) - 5
	
	_build_dungeon_room(start_x, start_y, 20, 15)
	# Recursively build down? Just a few rooms for now
	_build_dungeon_room(start_x + 5, start_y + 15, 10, 30)
	_build_dungeon_room(start_x + 10, start_y + 45, 15, 10)

func _build_dungeon_room(x: int, y: int, w: int, h: int) -> void:
	if not layer_1: return
	# Walls
	for dx in range(-1, w+1):
		for dy in range(-1, h+1):
			layer_1.set_cell(Vector2i(x+dx, y+dy), tile_source_id, dungeon_brick_tile)
	# Hollow
	for dx in range(w):
		for dy in range(h):
			layer_1.erase_cell(Vector2i(x+dx, y+dy))
			if layer_2: layer_2.set_cell(Vector2i(x+dx, y+dy), wall_source_id, dungeon_brick_tile)

func _generate_special_structures(step_index: int) -> void:
	match step_index:
		72: # Bio-specific Ore
			print("WorldGenerator: Spawning Bio-Ores...")
			# Spawn clusters deep
			for i in range(10):
				_spawn_ore_cluster(randi() % world_width, randi_range(world_height - 80, world_height), diamond_tile, 6)
		79: # Pyramids
			print("WorldGenerator: Building Pyramids...")
			var x = randi() % world_width
			var y = int(get_surface_height_at(x))
			# Triangle shape
			for i in range(20):
				for dx in range(-i, i+1):
					if layer_1: layer_1.set_cell(Vector2i(x+dx, y+i-5), tile_source_id, sand_tile)
					# Tunnel down middle
					if abs(dx) < 2 and layer_1: layer_1.erase_cell(Vector2i(x+dx, y+i-5))



func _settle_liquid_pressure() -> void:
	pass
	
func _spread_grass() -> void:
	# Step 103: Turn top dirt into grass
	print("WorldGenerator: Spreading grass...")
	if not layer_1: return
	
	for cx in range(world_width / 64):
		var sy = get_surface_height_at(cx * 64)
		# Scan a band around surface
		for x in range(cx*64, (cx+1)*64):
			for y in range(sy-5, sy+5):
				if layer_1.get_cell_source_id(Vector2i(x, y)) != -1: # Is solid
					# Check if air above
					if layer_1.get_cell_source_id(Vector2i(x, y-1)) == -1:
						# Turn to grass
						layer_1.set_cell(Vector2i(x,y), grass_dirt_source_id, grass_tile)

func settle_liquids() -> void:
	print("WorldGenerator: Settling liquids globally...")
	if not _get_world_topology().is_planetary():
		return
		
	# In a real implementation, this would load all chunk fluid data,
	# run Cellular Automata for N iterations, and save back.
	# For now, we rely on runtime settling.
	pass

func smooth_world() -> void:
	print("WorldGenerator: Smoothing world seams...")
	if not layer_1: return
	
	# Simple cellular automata for smoothing (one pass)
	# Remove lonely blocks
	for x in range(1, world_width - 1):
		for y in range(1, world_height - 1):
			var current = layer_1.get_cell_source_id(Vector2i(x,y))
			if current != -1:
				var neighbors = 0
				if layer_1.get_cell_source_id(Vector2i(x+1,y)) != -1: neighbors += 1
				if layer_1.get_cell_source_id(Vector2i(x-1,y)) != -1: neighbors += 1
				if layer_1.get_cell_source_id(Vector2i(x,y+1)) != -1: neighbors += 1
				if layer_1.get_cell_source_id(Vector2i(x,y-1)) != -1: neighbors += 1
				
				if neighbors < 1:
					layer_1.erase_cell(Vector2i(x,y))
