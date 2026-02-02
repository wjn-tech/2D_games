@tool
extends BTAction
class_name BTSlimeJump
## BTSlimeJump
## 泰拉瑞亚风格的史莱姆跳跃逻辑。
## 落地后等待一段时间，然后向目标跳跃。

@export var jump_force_y: float = 600.0
@export var jump_force_x: float = 300.0
@export var wait_time_min: float = 1.0
@export var wait_time_max: float = 2.0

var _timer: float = 0.0
var _is_jumping: bool = false

func _tick(delta: float) -> Status:
	var npc: BaseNPC = agent as BaseNPC
	if not npc: return FAILURE
	
	if _is_jumping:
		if npc.is_on_floor() and npc.velocity.y >= 0:
			_is_jumping = false
			_timer = randf_range(wait_time_min, wait_time_max)
			npc.velocity.x = 0
			return SUCCESS
		return RUNNING
	
	if _timer > 0:
		_timer -= delta
		npc.velocity.x = 0
		return RUNNING
	
	# 执行跳跃
	var target = blackboard.get_var("target")
	var dir = 0
	if is_instance_valid(target):
		dir = sign(target.global_position.x - npc.global_position.x)
	else:
		# 随机闲逛跳跃
		dir = 1 if randf() > 0.5 else -1
		
	npc.jump(dir * jump_force_x, jump_force_y)
	_is_jumping = true
	return RUNNING

func _enter() -> void:
	_timer = 0.0
	_is_jumping = false
