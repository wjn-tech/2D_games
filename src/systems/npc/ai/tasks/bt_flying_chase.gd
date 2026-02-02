@tool
extends BTAction
class_name BTFlyingChase
## BTFlyingChase
## 泰拉瑞亚风格的恶魔眼飞行逻辑。
## 正弦波接近 -> 瞄准 -> 冲刺。

@export var move_speed: float = 200.0
@export var dash_speed: float = 600.0
@export var wave_amplitude: float = 50.0
@export var dash_cooldown: float = 3.0

var _timer: float = 0.0
var _dash_timer: float = 0.0
var _is_dashing: bool = false
var _dash_dir: Vector2 = Vector2.ZERO

func _tick(delta: float) -> Status:
	var npc: BaseNPC = agent as BaseNPC
	if not npc: return FAILURE
	
	var target = blackboard.get_var("target")
	if not is_instance_valid(target): return FAILURE
	
	if _is_dashing:
		npc.velocity = _dash_dir * dash_speed
		_timer -= delta
		if _timer <= 0:
			_is_dashing = false
			_dash_timer = dash_cooldown
			return SUCCESS
		return RUNNING
	
	_dash_timer -= delta
	
	# 正常接近逻辑 (正弦波)
	var dir = npc.global_position.direction_to(target.global_position)
	var side_dir = Vector2(-dir.y, dir.x) # 垂直向量
	_timer += delta * 5.0
	
	var wave_offset = side_dir * sin(_timer) * wave_amplitude
	npc.velocity = (dir * move_speed) + (wave_offset)
	
	# 冲刺判定
	if _dash_timer <= 0 and npc.global_position.distance_to(target.global_position) < 400.0:
		_is_dashing = true
		_dash_dir = dir
		_timer = 0.6 # 冲刺持续时间
		
	return RUNNING

func _enter() -> void:
	_is_dashing = false
	_dash_timer = randf_range(1.0, 3.0)
	_timer = 0.0
