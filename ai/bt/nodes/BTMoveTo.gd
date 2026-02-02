@tool
extends BTAction
## BTMoveTo: 驱动 NPC 移动到指定坐标并等待到达

@export var target_pos_var: StringName = &"target_pos"
@export var arrival_tolerance: float = 10.0

func _tick(delta: float) -> Status:
	var actor = agent
	if not actor: return FAILURE
	
	var target = blackboard.get_var(target_pos_var, Vector2.ZERO)
	
	# 如果导航结束，返回 SUCCESS
	var nav: NavigationAgent2D = actor.get_node_or_null("NavigationAgent2D")
	if nav and nav.is_navigation_finished():
		actor.velocity.x = 0
		return SUCCESS
	
	# 驱动 NPC 移动逻辑
	if actor.has_method("move_along_path"):
		actor.move_along_path(target)
	else:
		# 备选：简单的横向移动
		var dir = (target - actor.global_position).normalized()
		actor.velocity.x = dir.x * actor.speed
	
	return RUNNING
