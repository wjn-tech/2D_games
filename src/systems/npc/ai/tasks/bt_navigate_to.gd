@tool
extends BTAction
class_name BTNavigateTo

## BTNavigateTo
## 导航到黑板变量指定的坐标或对象。

@export var target_var: StringName = &"target_pos"
@export var tolerance: float = 20.0

func _tick(_delta: float) -> Status:
	var npc: BaseNPC = agent as BaseNPC
	if not npc: return FAILURE
	
	var goal = blackboard.get_var(target_var)
	var goal_pos: Vector2
	
	if goal is Vector2:
		goal_pos = goal
	elif goal is Node2D and is_instance_valid(goal):
		goal_pos = goal.global_position
	else:
		return FAILURE
		
	if npc.global_position.distance_to(goal_pos) <= tolerance:
		npc.stop_movement()
		return SUCCESS
		
	npc.move_along_path(goal_pos)
	return RUNNING
