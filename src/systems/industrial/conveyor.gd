extends IndustrialEntity

## Conveyor
## 传送带：将上方的掉落物沿指定方向移动。

@export var move_direction: Vector2 = Vector2.RIGHT
@export var base_speed: float = 60.0

@onready var detection_area: Area2D = find_child("Area2D")

func _physics_process(delta: float) -> void:
	# 只有供电充足（>10%）时才运作
	if current_power_ratio < 0.1: return
	
	if not detection_area: return
	
	var actual_speed = base_speed * current_power_ratio
	var bodies = detection_area.get_overlapping_areas()
	for area in bodies:
		if area.has_method("collect"):
			area.global_position += move_direction * actual_speed * delta
