extends BTAction

## 使用 NavigationAgent2D 移动到指定位置
## 兼容坐标 (Vector2) 或 节点 (Node2D)

@export var target_var: String = "target" # Blackboard 变量名
@export var tolerance: float = 30.0

func _tick(_delta: float) -> int:
	var npc = agent as BaseNPC
	if not npc: return FAILURE
	
	var goal = blackboard.get_var(target_var)
	var goal_pos: Vector2
	
	if goal is Vector2:
		goal_pos = goal
	elif goal is Node2D:
		goal_pos = goal.global_position
	else:
		return FAILURE
		
	# 如果已经到达
	if npc.global_position.distance_to(goal_pos) <= tolerance:
		npc.velocity.x = 0
		return SUCCESS
		
	# 驱动移动
	npc.move_along_path(goal_pos)
	
	return RUNNING
