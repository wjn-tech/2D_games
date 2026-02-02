extends BTAction

## 在限制范围内选取一个随机游荡目标点
## 并存入 Blackboard

@export var range_var: String = "wander_radius"
@export var output_var: String = "wander_pos"

func _tick(_delta: float) -> int:
	var npc = agent as BaseNPC
	if not npc: return FAILURE
	
	var radius = blackboard.get_var(range_var, 300.0)
	var center = npc.spawn_position
	
	# 考虑住所位置
	if npc.home_position != Vector2.ZERO:
		center = npc.home_position
		radius = 150.0 # 在家附近游荡范围较小
		
	var random_offset = randf_range(-radius, radius)
	var target_pos = center + Vector2(random_offset, 0) # 2D 横向游荡
	
	blackboard.set_var(output_var, target_pos)
	return SUCCESS
