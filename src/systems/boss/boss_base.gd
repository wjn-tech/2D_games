extends CharacterBody2D
class_name BossBase

signal boss_defeated(boss_id: String)
signal phase_changed(new_phase: int)
signal health_changed(current_health: float, max_health: float)

const BOSS_PROJECTILE_SCENE := preload("res://scenes/entities/boss/boss_projectile.tscn")

@export var boss_id: String = "boss"
@export var display_name: String = "Boss"
@export var max_health: float = 220.0
@export var move_speed: float = 85.0
@export var contact_damage: float = 12.0
@export var contact_range_x: float = 32.0
@export var contact_range_y: float = 42.0
@export var contact_hit_cooldown: float = 0.7
@export var phase_two_threshold: float = 0.5
@export var gravity: float = 1800.0

var current_health: float = 0.0
var phase: int = 1
var combat_active: bool = false
var player_ref: Node2D = null
var _contact_cooldown: float = 0.0

@onready var _visual := get_node_or_null("MinimalistEntity")

func _ready() -> void:
	add_to_group("npcs")
	add_to_group("bosses")
	collision_layer = LayerManager.LAYER_NPC
	collision_mask = LayerManager.LAYER_WORLD_0 | LayerManager.LAYER_PLAYER
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)

func set_player(player: Node2D) -> void:
	player_ref = player

func activate_combat() -> void:
	combat_active = true

func _physics_process(delta: float) -> void:
	if _contact_cooldown > 0.0:
		_contact_cooldown = max(0.0, _contact_cooldown - delta)

	if not combat_active:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 6.0 * delta)
		velocity.y = minf(velocity.y + gravity * delta, 1200.0)
		move_and_slide()
		return

	if player_ref and is_instance_valid(player_ref):
		var dx := player_ref.global_position.x - global_position.x
		var dir := signf(dx)
		var contact_scale := _get_contact_scale()
		var contact_x := contact_range_x * contact_scale
		var contact_y := contact_range_y * contact_scale
		if absf(dx) > 12.0:
			velocity.x = move_toward(velocity.x, dir * move_speed, move_speed * 5.0 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, move_speed * 5.0 * delta)

		if _contact_cooldown <= 0.0 and absf(dx) < contact_x and absf(player_ref.global_position.y - global_position.y) < contact_y:
			if player_ref.has_method("take_damage"):
				var outgoing_damage := contact_damage
				if has_method("get_combat_damage_multiplier"):
					outgoing_damage *= maxf(0.0, float(call("get_combat_damage_multiplier")))
				player_ref.take_damage(outgoing_damage, "boss_contact")
			_contact_cooldown = contact_hit_cooldown
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 5.0 * delta)

	velocity.y = minf(velocity.y + gravity * delta, 1200.0)
	_process_attack(delta)
	move_and_slide()

func _process_attack(_delta: float) -> void:
	pass

func take_damage(amount: float, _damage_type: String = "physical", _source: Node = null) -> void:
	current_health = max(0.0, current_health - amount)
	emit_signal("health_changed", current_health, max_health)
	if UIManager:
		UIManager.show_floating_text(str(int(amount)), global_position + Vector2(0, -20), Color.ORANGE_RED)
	if _visual:
		var tween = create_tween()
		tween.tween_property(_visual, "modulate", Color(1.0, 0.35, 0.35), 0.08)
		tween.tween_property(_visual, "modulate", Color.WHITE, 0.08)

	if phase == 1 and current_health <= max_health * phase_two_threshold:
		_enter_phase_two()

	if current_health <= 0.0:
		combat_active = false
		emit_signal("boss_defeated", boss_id)
		queue_free()

func get_current_health() -> float:
	return current_health

func get_max_health() -> float:
	return max_health

func get_boss_display_name() -> String:
	if String(display_name).strip_edges().is_empty():
		return boss_id
	return display_name

func _enter_phase_two() -> void:
	phase = 2
	emit_signal("phase_changed", phase)

func spawn_projectile(dir: Vector2, damage: float, speed: float, life: float, color: Color, offset: Vector2 = Vector2.ZERO) -> Node:
	if BOSS_PROJECTILE_SCENE == null:
		return null
	var dir_norm := dir.normalized() if dir != Vector2.ZERO else Vector2.RIGHT
	var projectile = BOSS_PROJECTILE_SCENE.instantiate()
	if projectile == null:
		return null
	if projectile.has_method("setup"):
		projectile.setup(dir_norm, damage, speed, life, color)
	if get_parent() == null:
		return null
	get_parent().add_child(projectile)
	if projectile is Node2D:
		var scale_factor := _get_contact_scale()
		var scaled_offset := Vector2(offset.x * scale_factor, offset.y * scale_factor)
		var launch_clearance := dir_norm * (14.0 * scale_factor)
		(projectile as Node2D).global_position = global_position + scaled_offset + launch_clearance
	return projectile

func _get_contact_scale() -> float:
	return maxf(1.0, maxf(absf(global_scale.x), absf(global_scale.y)))
