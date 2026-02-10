extends Resource
class_name BuildingResource

@export var id: String = ""
@export var display_name: String = ""
var building_name: String: get = _get_building_name
func _get_building_name(): return display_name
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var scene: PackedScene # 建筑场景（用于整体建筑）
@export var atlas_coords: Vector2i = Vector2i(-1, -1) # 瓦片坐标（用于单块瓦片建造）
@export var source_id: int = -1 # 瓦片源 ID，如果为 -1 则使用默认值
@export var cost: Dictionary = {} # { "item_id": amount }
@export var category: String = "General" # Housing, Production, Defense, Utility

# 地形要求
@export var requires_flat_ground: bool = true
@export var required_level: int = 1 # 建造所需的城邦等级
@export var requires_water_nearby: bool = false

# 功能属性
@export var population_bonus: int = 0
@export var food_production: float = 0.0
@export var defense_bonus: int = 0
@export var influence_radius: float = 200.0
