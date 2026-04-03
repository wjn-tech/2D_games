extends BossBase

const SPLIT_FRAGMENT_SCENE := preload("res://scenes/entities/boss/eye_split_fragment.tscn")
const DASH_DURATION := 0.2
const DASH_COOLDOWN := 0.88
const DASH_SPEED_MULTIPLIER := 4.6
const SPLIT_FRAGMENT_COUNT := 10

var _dash_timer: float = 0.0
var _dash_direction: float = 1.0
var _dash_cooldown: float = 0.0
var _split_spawned: bool = false
var _split_phase_active: bool = false
var _fragments_remaining: int = 0

func _ready() -> void:
	boss_id = "eye_king"
	display_name = "Eye King"
	max_health = 300.0
	move_speed = 110.0
	contact_damage = 19.0
	phase_two_threshold = 0.5
	super._ready()

func _process_attack(delta: float) -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	if _split_phase_active:
		return

	_dash_cooldown = maxf(0.0, _dash_cooldown - delta)
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

	if _dash_cooldown <= 0.0:
		_dash_direction = signf(to_player.x)
		if _dash_direction == 0.0:
			_dash_direction = 1.0
		_dash_timer = DASH_DURATION
		_dash_cooldown = DASH_COOLDOWN

func _enter_phase_two() -> void:
	super._enter_phase_two()
	if _split_spawned:
		return
	_split_spawned = true
	_split_phase_active = true
	_spawn_split_fragments()
	_disable_main_form()

func _disable_main_form() -> void:
	combat_active = false
	visible = false
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)

func _spawn_split_fragments() -> void:
	if SPLIT_FRAGMENT_SCENE == null:
		emit_signal("boss_defeated", boss_id)
		queue_free()
		return
	_fragments_remaining = SPLIT_FRAGMENT_COUNT
	for i in range(SPLIT_FRAGMENT_COUNT):
		var fragment = SPLIT_FRAGMENT_SCENE.instantiate()
		if fragment == null:
			_fragments_remaining -= 1
			continue
		var angle := TAU * (float(i) / float(SPLIT_FRAGMENT_COUNT))
		var offset := Vector2(cos(angle), sin(angle)) * 74.0
		if fragment.has_method("set_player"):
			fragment.set_player(player_ref)
		if fragment.has_signal("fragment_defeated"):
			fragment.fragment_defeated.connect(_on_fragment_defeated)
		get_parent().add_child(fragment)
		if fragment is Node2D:
			(fragment as Node2D).global_position = global_position + offset

	if _fragments_remaining <= 0:
		emit_signal("boss_defeated", boss_id)
		queue_free()

func _on_fragment_defeated() -> void:
	_fragments_remaining = maxi(0, _fragments_remaining - 1)
	if _fragments_remaining == 0:
		emit_signal("boss_defeated", boss_id)
		queue_free()
