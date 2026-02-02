extends StaticBody2D

@onready var sprite = $Sprite2D

enum BuildingType { DECOR, WORKSHOP, HOUSING, STORAGE }
@export var type: BuildingType = BuildingType.DECOR
@export var buff_radius: float = 200.0
@export var efficiency_bonus: float = 0.2

var building_resource: BuildingResource

func _ready() -> void:
	add_to_group("settlement_buildings")
	_apply_buffs()

func setup(resource: BuildingResource):
	building_resource = resource
	if resource:
		buff_radius = resource.influence_radius
		if sprite and resource.icon:
			sprite.texture = resource.icon
	
func _apply_buffs() -> void:
	# 简单的逻辑：影响范围内正在采集/工作的 NPC
	# 注意：注册动作现在由 BuildingManager 统一处理，以确保传递正确的 BuildingResource
	pass
