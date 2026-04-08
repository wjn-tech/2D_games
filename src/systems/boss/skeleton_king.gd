extends BossBase

const DASH_DURATION := 0.18
const DASH_COOLDOWN := 0.9
const DASH_SPEED_MULTIPLIER := 6.0
const VOLLEY_COOLDOWN_PHASE_1 := 2.3
const VOLLEY_COOLDOWN_PHASE_2 := 1.75
const VOLLEY_ARROW_COUNT := 10
const VOLLEY_SPREAD_RAD := 0.44
const ARROW_HOMING_STRENGTH_PHASE_1 := 9.0
const ARROW_HOMING_STRENGTH_PHASE_2 := 12.5
const ARROW_SPEED_PHASE_1 := 520.0
const ARROW_SPEED_PHASE_2 := 620.0
const ARROW_LIFETIME_PHASE_1 := 4.2
const ARROW_LIFETIME_PHASE_2 := 4.6
const ARROW_DAMAGE_PHASE_1 := 8.0
const ARROW_DAMAGE_PHASE_2 := 10.0
const ARROW_RADIUS := 3.8
const ARROW_ALPHA := 0.82

var _dash_timer: float = 0.0
var _dash_direction: float = 1.0
var _dash_cooldown: float = 0.0
var _volley_cooldown: float = 0.0

func _ready() -> void:
	boss_id = "skeleton_king"
	display_name = "Skeleton King"
	max_health = 320.0
	move_speed = 122.0
	contact_damage = 20.0
	phase_two_threshold = 0.52
	super._ready()

func _process_attack(delta: float) -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return

	_dash_cooldown = maxf(0.0, _dash_cooldown - delta)
	_volley_cooldown = maxf(0.0, _volley_cooldown - delta)

	if _dash_timer > 0.0:
		_dash_timer = maxf(0.0, _dash_timer - delta)
		if is_on_wall():
			_dash_timer = 0.0
		else:
			velocity.x = _dash_direction * move_speed * DASH_SPEED_MULTIPLIER
		return

	var delta_to_player := player_ref.global_position - global_position
	var aim := delta_to_player.normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT

	if _dash_cooldown <= 0.0 and absf(delta_to_player.x) < 420.0 and absf(delta_to_player.y) < 90.0:
		_dash_direction = signf(delta_to_player.x)
		if _dash_direction == 0.0:
			_dash_direction = 1.0
		_dash_timer = DASH_DURATION
		_dash_cooldown = DASH_COOLDOWN

	if _volley_cooldown <= 0.0:
		_volley_cooldown = VOLLEY_COOLDOWN_PHASE_2 if phase >= 2 else VOLLEY_COOLDOWN_PHASE_1
		_fire_bone_arrow_volley(aim)

func _fire_bone_arrow_volley(base_dir: Vector2) -> void:
	if base_dir == Vector2.ZERO:
		base_dir = Vector2.RIGHT
	var homing_strength := ARROW_HOMING_STRENGTH_PHASE_2 if phase >= 2 else ARROW_HOMING_STRENGTH_PHASE_1
	var arrow_speed := ARROW_SPEED_PHASE_2 if phase >= 2 else ARROW_SPEED_PHASE_1
	var arrow_lifetime := ARROW_LIFETIME_PHASE_2 if phase >= 2 else ARROW_LIFETIME_PHASE_1
	var arrow_damage := ARROW_DAMAGE_PHASE_2 if phase >= 2 else ARROW_DAMAGE_PHASE_1
	for i in range(VOLLEY_ARROW_COUNT):
		var t := float(i) / float(maxi(1, VOLLEY_ARROW_COUNT - 1))
		var angle := lerpf(-VOLLEY_SPREAD_RAD, VOLLEY_SPREAD_RAD, t)
		var projectile := spawn_projectile(
			base_dir.rotated(angle),
			arrow_damage,
			arrow_speed,
			arrow_lifetime,
			Color(0.95, 0.93, 0.78, ARROW_ALPHA),
			Vector2(0, -16)
		)
		if projectile and projectile.has_method("configure_homing"):
			projectile.configure_homing(player_ref, homing_strength)
		if projectile and projectile.has_method("configure_visual_profile"):
			projectile.configure_visual_profile(ARROW_RADIUS, ARROW_ALPHA)
