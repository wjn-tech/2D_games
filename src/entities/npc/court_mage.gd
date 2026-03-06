extends Node2D
class_name CourtMage

# Configuration
@export var float_speed: float = 2.0
@export var float_height: float = 10.0
@export var movement_threshold: float = 1.0

# References
@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var trail_particles: CPUParticles2D = $TrailSystem/TrailParticles

# State
var _time_accum: float = 0.0
var _last_global_pos: Vector2
var _current_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	_last_global_pos = global_position
	if trail_particles:
		trail_particles.emitting = false

func _process(delta: float) -> void:
	_time_accum += delta
	
	# calculate velocity manually since we are moved by AnimationPlayer/Tweens usually
	var current_pos = global_position
	# Smooth velocity calculation
	var frame_velocity = (current_pos - _last_global_pos) / delta
	_current_velocity = _current_velocity.lerp(frame_velocity, 10.0 * delta)
	_last_global_pos = current_pos
	
	_process_floating(delta)
	_process_movement_effects(delta)

func _process_floating(delta: float) -> void:
	if visuals:
		# Sine wave floating
		var offset_y = sin(_time_accum * float_speed) * float_height
		visuals.position.y = offset_y

func _process_movement_effects(delta: float) -> void:
	var speed = _current_velocity.length()
	var is_moving = speed > movement_threshold
	
	# Facing Direction
	if abs(_current_velocity.x) > 1.0:
		if visuals:
			# If moving right (positive X), face right (scale.x = 1)
			# If moving left (negative X), face left (scale.x = -1)
			# Assuming default sprite faces RIGHT.
			visuals.scale.x = 1 if _current_velocity.x > 0 else -1
			
	# Trail Effect
	if trail_particles:
		trail_particles.emitting = is_moving
