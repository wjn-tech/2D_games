extends BTCondition

## 检查视野内是否有可攻击或可逃避的目标
## 并更新 Blackboard 里的 target

@export var group_name: String = "player"

func _tick(_delta: float) -> int:
	var npc = agent as BaseNPC
	if not npc: return FAILURE
	
	# 先检查当前目标是否仍然有效
	var current_target = blackboard.get_var("target")
	if is_instance_valid(current_target):
		var dist = npc.global_position.distance_to(current_target.global_position)
		if dist <= npc.detection_range:
			return SUCCESS
	
	# 搜索新目标
	var players = npc.get_tree().get_nodes_in_group(group_name)
	for p in players:
		if p is Node2D:
			var dist = npc.global_position.distance_to(p.global_position)
			if dist <= npc.detection_range:
				blackboard.set_var("target", p)
				return SUCCESS
				
	return FAILURE
