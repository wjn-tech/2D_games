@tool
extends BTAction
class_name BTProjectileAttack
## BTProjectileAttack
## 泰拉瑞亚风格的远程攻击逻辑。
## 蓄力 -> 发射 -> 冷却。

@export var projectile_scene: PackedScene
@export var charge_time: float = 1.0
@export var cooldown_time: float = 2.0
@export var min_range: float = 100.0
@export var max_range: float = 600.0

var _timer: float = 0.0
enum Phase { IDLE, CHARGING, COOLDOWN }
var _current_phase = Phase.IDLE

func _tick(delta: float) -> Status:
	var npc: BaseNPC = agent as BaseNPC
	if not npc: return FAILURE
	
	var target = blackboard.get_var("target")
	if not is_instance_valid(target):
		_current_phase = Phase.IDLE
		return FAILURE
		
	var dist = npc.global_position.distance_to(target.global_position)
	
	match _current_phase:
		Phase.IDLE:
			if dist <= max_range and dist >= min_range:
				_current_phase = Phase.CHARGING
				_timer = charge_time
				# 可以添加蓄力特效提示
				return RUNNING
			return FAILURE # 不在攻击距离内
			
		Phase.CHARGING:
			_timer -= delta
			if _timer <= 0:
				# 执行发射
				npc.shoot_at(target.global_position, projectile_scene)
				_current_phase = Phase.COOLDOWN
				_timer = cooldown_time
				return SUCCESS
			return RUNNING
			
		Phase.COOLDOWN:
			_timer -= delta
			if _timer <= 0:
				_current_phase = Phase.IDLE
				return SUCCESS
			return RUNNING
			
	return RUNNING

func _enter() -> void:
	_timer = 0.0
	_current_phase = Phase.IDLE
