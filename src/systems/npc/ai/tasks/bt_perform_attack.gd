@tool
extends BTAction
class_name BTPerformAttack
## BTPerformAttack
## 执行攻击动作并造成伤害。

@export var damage: float = 10.0
@export var animation_name: String = "attack"
@export var damage_type: String = "physical"
@export var windup_time: float = 0.18
@export var cooldown: float = 1.0
@export var hit_reach_bonus: float = 10.0

enum Phase { READY, WINDUP, COOLDOWN }

var _phase: Phase = Phase.READY
var _timer: float = 0.0
var _queued_target: Node2D = null

func _tick(delta: float) -> Status:
	var npc: BaseNPC = agent as BaseNPC
	if not npc:
		return FAILURE

	match _phase:
		Phase.COOLDOWN:
			_timer -= delta
			if _timer <= 0.0:
				_phase = Phase.READY
				return SUCCESS
			return RUNNING

		Phase.WINDUP:
			npc.stop_movement()
			_timer -= delta
			if _timer > 0.0:
				return RUNNING
			return _resolve_attack(npc)

	var target = blackboard.get_var("target", null)
	if not is_instance_valid(target):
		return FAILURE

	var dist = npc.global_position.distance_to(target.global_position)
	if dist > npc.attack_range + hit_reach_bonus:
		return FAILURE

	_queued_target = target
	_phase = Phase.WINDUP
	_timer = windup_time
	_play_attack_windup(npc, target)
	return RUNNING

func _enter() -> void:
	_phase = Phase.READY
	_timer = 0.0
	_queued_target = null

func _resolve_attack(npc: BaseNPC) -> Status:
	var target = _queued_target
	_queued_target = null
	if not is_instance_valid(target):
		_phase = Phase.READY
		return FAILURE

	var dist = npc.global_position.distance_to(target.global_position)
	if dist > npc.attack_range + hit_reach_bonus:
		_phase = Phase.READY
		return FAILURE

	_play_attack_hit(npc, target)
	if CombatManager:
		CombatManager.deal_damage(npc, target, damage, damage_type)
	elif target.has_method("take_damage"):
		target.take_damage(damage)

	_phase = Phase.COOLDOWN
	_timer = cooldown
	return SUCCESS

func _play_attack_windup(npc: BaseNPC, target: Node2D) -> void:
	var min_vis = npc.get_node_or_null("MinimalistEntity")
	if not min_vis:
		return
	var dir = (target.global_position - npc.global_position).normalized()
	var start_pos = min_vis.position
	var tw = npc.create_tween()
	tw.tween_property(min_vis, "position", start_pos - dir * 4.0, min(0.08, windup_time))
	tw.tween_property(min_vis, "modulate", Color(1.4, 0.85, 0.85), min(0.08, windup_time))

func _play_attack_hit(npc: BaseNPC, target: Node2D) -> void:
	var min_vis = npc.get_node_or_null("MinimalistEntity")
	if not min_vis:
		return
	var dir = (target.global_position - npc.global_position).normalized()
	var start_pos = min_vis.position
	var tw = npc.create_tween()
	tw.tween_property(min_vis, "position", start_pos + dir * 10.0, 0.06)
	tw.tween_property(min_vis, "position", start_pos, 0.1)
	tw.tween_property(min_vis, "modulate", Color.WHITE, 0.08)
