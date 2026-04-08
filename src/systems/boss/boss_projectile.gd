extends Area2D
class_name BossProjectile

@export var speed: float = 260.0
@export var damage: float = 12.0
@export var lifetime: float = 4.0
@export var radius: float = 5.0
@export var tint: Color = Color(1.0, 0.45, 0.45, 1.0)
@export var homing_strength: float = 0.0
@export var percent_max_hp_damage_on_hit: float = 0.0
@export var poison_duration: float = 0.0
@export var poison_tick_interval: float = 1.0
@export var poison_tick_max_hp_percent: float = 0.0

var direction: Vector2 = Vector2.RIGHT
var homing_target: Node2D = null
var _remaining_life: float = 0.0

func _ready() -> void:
	add_to_group("boss_projectiles")
	monitoring = true
	monitorable = true
	_remaining_life = lifetime
	queue_redraw()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup(dir: Vector2, hit_damage: float, move_speed: float, life: float, color: Color) -> void:
	direction = dir.normalized() if dir != Vector2.ZERO else Vector2.RIGHT
	damage = hit_damage
	speed = move_speed
	lifetime = life
	tint = color
	_remaining_life = lifetime
	queue_redraw()

func configure_homing(target: Node2D, strength: float) -> void:
	homing_target = target
	homing_strength = maxf(0.0, strength)

func configure_visual_profile(projectile_radius: float, alpha: float = 1.0) -> void:
	radius = maxf(1.5, projectile_radius)
	tint.a = clampf(alpha, 0.15, 1.0)
	queue_redraw()

func configure_status_effects(on_hit_max_hp_percent: float, poison_duration_sec: float, poison_tick_sec: float, poison_tick_percent: float) -> void:
	percent_max_hp_damage_on_hit = maxf(0.0, on_hit_max_hp_percent)
	poison_duration = maxf(0.0, poison_duration_sec)
	poison_tick_interval = maxf(0.1, poison_tick_sec)
	poison_tick_max_hp_percent = maxf(0.0, poison_tick_percent)

func _physics_process(delta: float) -> void:
	if homing_target and is_instance_valid(homing_target) and homing_strength > 0.0:
		var desired := (homing_target.global_position - global_position).normalized()
		if desired != Vector2.ZERO:
			var turn_factor := clampf(homing_strength * delta, 0.0, 1.0)
			direction = direction.slerp(desired, turn_factor).normalized()

	global_position += direction * speed * delta
	_remaining_life -= delta
	if _remaining_life <= 0.0:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, tint)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 18, Color(0.12, 0.12, 0.12, 0.95), 1.2)

func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if body.is_in_group("player"):
		var dealt_damage := damage
		if percent_max_hp_damage_on_hit > 0.0:
			dealt_damage += _get_body_max_health(body) * percent_max_hp_damage_on_hit
		if body.has_method("take_damage"):
			body.take_damage(dealt_damage, "boss_projectile")
		if poison_duration > 0.0 and poison_tick_max_hp_percent > 0.0 and body.has_method("apply_poison_effect"):
			body.apply_poison_effect(poison_duration, poison_tick_interval, poison_tick_max_hp_percent)
		if UIManager:
			UIManager.show_floating_text(str(int(dealt_damage)), global_position + Vector2(0, -14), Color(1.0, 0.4, 0.4))
		queue_free()
		return
	if body is StaticBody2D or body is TileMapLayer:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area == null:
		return
	if area.is_in_group("boss_gate"):
		queue_free()

func _get_body_max_health(body: Node) -> float:
	if body == null:
		return 0.0
	if body.get("attributes") != null and body.attributes and body.attributes.data:
		return float(body.attributes.data.max_health)
	return 0.0
