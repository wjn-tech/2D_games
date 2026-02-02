@tool
extends BTAction
## BTPickRandomPos: 在给定范围内选取一个随机点并写入 Blackboard

@export var pick_range: float = 200.0
@export var output_var: StringName = &"target_pos"

func _tick(delta: float) -> Status:
	var actor: Node2D = agent
	if not actor: return FAILURE
	
	var random_offset = Vector2(randf_range(-pick_range, pick_range), 0) # 2D 横向移动
	var target = actor.global_position + random_offset
	
	blackboard.set_var(output_var, target)
	return SUCCESS
