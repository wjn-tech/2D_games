@tool
extends BTCondition
class_name BTIsTargetVisible
## BTIsTargetVisible
## 检查 "target" 是否在感知范围内且没有视觉遮挡。

@export var check_fov: bool = false # 是否检查视锥（此项目可能不需要）
@export var use_raycast: bool = true # 是否使用射线检测墙壁

func _tick(delta: float) -> Status:
	var npc: BaseNPC = agent as BaseNPC
	if not npc: return FAILURE
	
	var target = blackboard.get_var("target", null)
	if not is_instance_valid(target):
		return FAILURE
		
	var dist = npc.global_position.distance_to(target.global_position)
	var range = blackboard.get_var("detection_range", 300.0)
	
	if dist > range:
		return FAILURE
		
	if use_raycast:
		var space = npc.get_world_2d().direct_space_state
		# 射线排除自己和目标（只检测世界）
		var query = PhysicsRayQueryParameters2D.create(npc.global_position, target.global_position)
		if LayerManager:
			query.collision_mask = LayerManager.LAYER_WORLD_0 # 只检测地形
		else:
			query.collision_mask = 1
			
		var result = space.intersect_ray(query)
		if result:
			# 如果碰到了东西，说明有墙
			return FAILURE
			
	return SUCCESS
