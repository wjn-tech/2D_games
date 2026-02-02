@tool
extends BTAction
class_name BTChaseTarget
## BTChaseTarget
## 持续向 Blackboard 中的 "target" 移动。
## 如果没有目标或目标失效，返回 FAILURE。

@export var tolerance: float = 40.0 # 接近到多少距离视为“追上也攻击”

func _tick(delta: float) -> Status:
	var npc: BaseNPC = agent as BaseNPC
	if not npc: return FAILURE
	
	var target = blackboard.get_var("target", null)
	if not is_instance_valid(target):
		npc.stop_movement()
		return FAILURE
	
	var dist = npc.global_position.distance_to(target.global_position)
	
	# 如果已经足够接近，进入攻击范围
	if dist <= tolerance:
		npc.stop_movement()
		return SUCCESS
		
	# 持续移动
	# print("[BTChase] Chasing target at ", target.global_position, " Dist: ", dist)
	npc.move_along_path(target.global_position)
	return RUNNING

func _enter() -> void:
	pass
