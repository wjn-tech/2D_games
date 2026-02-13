@tool
extends BTAction
class_name BTFindWanderTarget

## BTFindWanderTarget
## 在范围内寻找一个随机的可导航点。

@export var radius: float = 200.0
@export var output_var: StringName = &"target_pos"

func _tick(_delta: float) -> Status:
	var npc: BaseNPC = agent as BaseNPC
	if not npc: return FAILURE
	
	# 获取一个随机偏移
	var random_offset = Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
	var target = npc.global_position + random_offset
	
	# 如果有导航网格，可以在这里尝试映射到最近的点
	# 简单处理：直接设置目标
	blackboard.set_var(output_var, target)
	
	return SUCCESS
