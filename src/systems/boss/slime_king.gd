extends BossBase

const DASH_DURATION := 0.17
const DASH_COOLDOWN_PHASE_1 := 0.92
const DASH_COOLDOWN_PHASE_2 := 0.72
const DASH_SPEED_MULTIPLIER := 5.6
const ACID_SPRAY_COOLDOWN := 1.95
const ACID_PROJECTILE_SPEED := 330.0
const ACID_PROJECTILE_LIFETIME := 4.6
const ACID_HIT_MAX_HP_PERCENT := 0.06
const ACID_POISON_DURATION := 4.5
const ACID_POISON_TICK_INTERVAL := 0.9
const ACID_POISON_TICK_MAX_HP_PERCENT := 0.02

var _dash_timer: float = 0.0
var _dash_direction: float = 1.0
var _dash_cooldown: float = 0.0
var _acid_spray_cooldown: float = 0.0

func _ready() -> void:
	boss_id = "slime_king"
	display_name = "Slime King"
	max_health = 260.0
	move_speed = 108.0
	contact_damage = 18.0
	phase_two_threshold = 0.55
	super._ready()

func _process_attack(delta: float) -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return

	_dash_cooldown = maxf(0.0, _dash_cooldown - delta)
	_acid_spray_cooldown = maxf(0.0, _acid_spray_cooldown - delta)

	if _dash_timer > 0.0:
		_dash_timer = maxf(0.0, _dash_timer - delta)
		if is_on_wall():
			_dash_timer = 0.0
		else:
			velocity.x = _dash_direction * move_speed * DASH_SPEED_MULTIPLIER
		return

	var to_player := player_ref.global_position - global_position
	if to_player == Vector2.ZERO:
		return
	var horizontal_dir := signf(to_player.x)
	if horizontal_dir == 0.0:
		horizontal_dir = 1.0

	if _dash_cooldown <= 0.0:
		_dash_direction = horizontal_dir
		_dash_timer = DASH_DURATION
		_dash_cooldown = DASH_COOLDOWN_PHASE_2 if phase >= 2 else DASH_COOLDOWN_PHASE_1

	if phase >= 2 and _acid_spray_cooldown <= 0.0:
		_acid_spray_cooldown = ACID_SPRAY_COOLDOWN
		_fire_acid_spray(to_player.normalized())

func _fire_acid_spray(base_dir: Vector2) -> void:
	if base_dir == Vector2.ZERO:
		base_dir = Vector2.RIGHT

	for angle in [-0.3, -0.16, 0.0, 0.16, 0.3]:
		var projectile := spawn_projectile(
			base_dir.rotated(angle),
			0.0,
			ACID_PROJECTILE_SPEED,
			ACID_PROJECTILE_LIFETIME,
			Color(0.48, 0.96, 0.42, 0.95),
			Vector2(0, -12)
		)
		if projectile and projectile.has_method("configure_status_effects"):
			projectile.configure_status_effects(
				ACID_HIT_MAX_HP_PERCENT,
				ACID_POISON_DURATION,
				ACID_POISON_TICK_INTERVAL,
				ACID_POISON_TICK_MAX_HP_PERCENT
			)
