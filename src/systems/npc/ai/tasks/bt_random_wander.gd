@tool
extends BTAction
class_name BTRandomWander
## BTRandomWander
## 随机选择一个位置并在导航网格上移动过去。
## 依赖 Blackboard 变量: "spawn_pos" (Vector2), "speed" (float)

@export var radius: float = 300.0
@export var min_wait_time: float = 2.0
@export var max_wait_time: float = 5.0

var _target_pos: Vector2
var _timer: float = 0.0

func _tick(delta: float) -> Status:
	var npc: BaseNPC = agent as BaseNPC
	if not npc: return FAILURE
	
	# 如果正在移动
	if _target_pos != Vector2.ZERO:
		npc.move_along_path(_target_pos)
		
		# 检查是否到达
		if npc.global_position.distance_to(_target_pos) < 20.0 or npc.nav_agent.is_navigation_finished():
			npc.stop_movement()
			_target_pos = Vector2.ZERO
			_timer = randf_range(min_wait_time, max_wait_time) # 到达后休息一会
			return RUNNING
			
		return RUNNING
	
	# 如果正在等待
	if _timer > 0:
		_timer -= delta
		if _timer <= 0:
			# 等待结束，寻找新目标
			return SUCCESS #本次漫游周期完成
		return RUNNING
		
	return SUCCESS

func _enter() -> void:
	print("[BTRandomWander] Task Entered.")
	# 开始时选择一个新点
	var center = blackboard.get_var("spawn_pos", agent.global_position)
	_target_pos = _get_random_point(center)
	_timer = 0.0

func _get_random_point(center: Vector2) -> Vector2:
	# 2D 平台游戏逻辑：主要在 X 轴随机游荡
	var direction = 1 if randf() > 0.5 else -1
	var dist = randf_range(50.0, radius)
	var offset_x = direction * dist
	
	# 目标位置 Y 轴保持与中心点一致 (假设地面平坦或依靠 NavigationAgent 处理高差)
	var target = center + Vector2(offset_x, 0)
	
	print("[BTRandomWander] New Target: ", target, " (Center: ", center, ")")
	return target
