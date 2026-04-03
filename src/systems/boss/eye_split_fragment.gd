extends CharacterBody2D

signal fragment_defeated

const BOSS_PROJECTILE_SCENE := preload("res://scenes/entities/boss/boss_projectile.tscn")

@export var max_health: float = 48.0
@export var move_speed: float = 84.0
@export var gravity: float = 1700.0

var current_health: float = 0.0
var player_ref: Node2D = null
var _attack_timer: float = 0.8

func _ready() -> void:
	current_health = max_health
	collision_layer = LayerManager.LAYER_NPC
	collision_mask = LayerManager.LAYER_WORLD_0 | LayerManager.LAYER_PLAYER
	add_to_group("npcs")

func set_player(player: Node2D) -> void:
	player_ref = player

func _physics_process(delta: float) -> void:
	if player_ref and is_instance_valid(player_ref):
		var dx := player_ref.global_position.x - global_position.x
		velocity.x = move_toward(velocity.x, signf(dx) * move_speed, move_speed * 5.0 * delta)
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_fire_projectile()
			_attack_timer = 1.4
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0 * delta)

	velocity.y = minf(velocity.y + gravity * delta, 1100.0)
	move_and_slide()

func _fire_projectile() -> void:
	if BOSS_PROJECTILE_SCENE == null:
		return
	if player_ref == null or not is_instance_valid(player_ref):
		return
	var aim := (player_ref.global_position - global_position).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT
	var projectile = BOSS_PROJECTILE_SCENE.instantiate()
	if projectile and projectile.has_method("setup"):
		projectile.setup(aim, 8.0, 270.0, 2.4, Color(1.0, 0.58, 0.72))
	get_parent().add_child(projectile)
	if projectile is Node2D:
		(projectile as Node2D).global_position = global_position + Vector2(0, -10)

func take_damage(amount: float, _damage_type: String = "physical", _source: Node = null) -> void:
	current_health = max(0.0, current_health - amount)
	if current_health <= 0.0:
		emit_signal("fragment_defeated")
		queue_free()
