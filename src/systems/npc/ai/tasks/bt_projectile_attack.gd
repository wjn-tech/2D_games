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
@export var track_target_during_charge: bool = false

var _timer: float = 0.0
enum Phase { IDLE, CHARGING, COOLDOWN }
var _current_phase = Phase.IDLE
var _locked_target_pos: Vector2 = Vector2.ZERO

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
				_locked_target_pos = target.global_position
				npc.stop_movement()
				_play_charge_feedback(npc)
				# 可以添加蓄力特效提示
				return RUNNING
			return FAILURE # 不在攻击距离内
			
		Phase.CHARGING:
			npc.stop_movement()
			if track_target_during_charge:
				_locked_target_pos = target.global_position
			_timer -= delta
			if _timer <= 0:
				# 执行发射
				npc.shoot_at(_locked_target_pos, projectile_scene)
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
	_locked_target_pos = Vector2.ZERO

func _play_charge_feedback(npc: BaseNPC) -> void:
	var min_vis = npc.get_node_or_null("MinimalistEntity")
	if not min_vis:
		return
	var tw = npc.create_tween()
	tw.tween_property(min_vis, "scale", min_vis.scale * Vector2(1.08, 0.92), min(0.12, charge_time))
	tw.tween_property(min_vis, "modulate", Color(1.4, 1.2, 0.8), min(0.12, charge_time))
	tw.tween_property(min_vis, "scale", min_vis.scale, 0.1)
	tw.tween_property(min_vis, "modulate", Color.WHITE, 0.1)
