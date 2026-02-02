extends Node2D
class_name GameZone

@export var zone_id: String = "test_zone"
@export var zone_name: String = "测试区域"

# 资源点生成配置
@export var resource_spawn_points: Array[Marker2D] = [$"1"]
@export var gatherable_scene: PackedScene # 采集点场景

func _ready() -> void:
	print("进入区域: ", zone_name)
	_spawn_initial_resources()

func _spawn_initial_resources() -> void:
	if not gatherable_scene:
		push_warning("未绑定 gatherable_scene，无法生成资源")
		return
		
	for marker in resource_spawn_points:
		var resource = gatherable_scene.instantiate()
		add_child(resource)
		resource.global_position = marker.global_position
