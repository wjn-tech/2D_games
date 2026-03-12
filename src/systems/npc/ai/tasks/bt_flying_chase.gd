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
@export var charge_time: float = 0.2
@export var dash_duration: float = 0.45
@export var recover_time: float = 0.15
@export var dash_trigger_range: float = 420.0
@export var dash_min_range: float = 90.0
@export var dash_damage: float = 12.0
@export var dash_damage_type: String = "physical"
@export var dash_hit_radius: float = 28.0

enum Phase { CHASE, CHARGING, DASHING, RECOVERING }

var _wave_timer: float = 0.0
var _dash_timer: float = 0.0
var _phase_timer: float = 0.0
var _phase: Phase = Phase.CHASE
var _dash_dir: Vector2 = Vector2.ZERO
var _dealt_damage_this_dash: bool = false

func _tick(delta: float) -> Status:
	var npc: BaseNPC = agent as BaseNPC
	if not npc: return FAILURE
	
	var target = blackboard.get_var("target")
	if not is_instance_valid(target): return FAILURE
	
	var dist = npc.global_position.distance_to(target.global_position)
	var dir = npc.global_position.direction_to(target.global_position)
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	
	match _phase:
		Phase.CHARGING:
			npc.stop_movement()
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_phase = Phase.DASHING
				_phase_timer = dash_duration
				_dealt_damage_this_dash = false
				_play_dash_feedback(npc)
			return RUNNING

		Phase.DASHING:
			npc.velocity = _dash_dir * dash_speed
			_try_dash_hit(npc, target)
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_phase = Phase.RECOVERING
				_phase_timer = recover_time
				_dash_timer = dash_cooldown
			return RUNNING

		Phase.RECOVERING:
			npc.velocity = _dash_dir * (move_speed * 0.35)
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_phase = Phase.CHASE
			return RUNNING

	_dash_timer -= delta
	_wave_timer += delta * 5.0
	var side_dir = Vector2(-dir.y, dir.x)
	var wave_offset = side_dir * sin(_wave_timer) * wave_amplitude
	npc.velocity = (dir * move_speed) + wave_offset

	if _dash_timer <= 0.0 and dist <= dash_trigger_range and dist >= dash_min_range:
		_phase = Phase.CHARGING
		_phase_timer = charge_time
		_dash_dir = dir
		npc.stop_movement()
		_play_charge_feedback(npc)
		
	return RUNNING

func _enter() -> void:
	_phase = Phase.CHASE
	_dash_timer = randf_range(1.0, 3.0)
	_phase_timer = 0.0
	_wave_timer = 0.0
	_dealt_damage_this_dash = false

func _try_dash_hit(npc: BaseNPC, target: Node2D) -> void:
	if _dealt_damage_this_dash:
		return
	if npc.global_position.distance_to(target.global_position) > dash_hit_radius:
		return
	if CombatManager:
		CombatManager.deal_damage(npc, target, dash_damage, dash_damage_type)
	elif target.has_method("take_damage"):
		target.take_damage(dash_damage, dash_damage_type, npc)
	_dealt_damage_this_dash = true

func _play_charge_feedback(npc: BaseNPC) -> void:
	var min_vis = npc.get_node_or_null("MinimalistEntity")
	if not min_vis:
		return
	var start_scale = min_vis.scale
	var tw = npc.create_tween()
	tw.tween_property(min_vis, "scale", start_scale * Vector2(1.12, 0.88), min(0.12, charge_time))
	tw.parallel().tween_property(min_vis, "modulate", Color(1.5, 0.7, 0.7), min(0.12, charge_time))
	tw.tween_property(min_vis, "scale", start_scale, 0.08)
	tw.parallel().tween_property(min_vis, "modulate", Color.WHITE, 0.08)

func _play_dash_feedback(npc: BaseNPC) -> void:
	var min_vis = npc.get_node_or_null("MinimalistEntity")
	if not min_vis:
		return
	var start_scale = min_vis.scale
	var tw = npc.create_tween()
	tw.tween_property(min_vis, "scale", start_scale * Vector2(1.3, 0.78), 0.06)
	tw.parallel().tween_property(min_vis, "modulate", Color(1.8, 0.9, 0.9), 0.06)
	tw.tween_property(min_vis, "scale", start_scale, 0.12)
	tw.parallel().tween_property(min_vis, "modulate", Color.WHITE, 0.12)
