extends Camera2D

# Cutscene properties
var _target_position: Vector2 = Vector2.ZERO
var _is_cutscene_mode: bool = false
var _pan_tween: Tween
var _zoom_tween: Tween

var shake_duration: float = 0.0
var shake_intensity: float = 0.0
var default_offset: Vector2 = Vector2.ZERO

var player: Node2D

func _ready() -> void:
	# Register self with CinematicDirector if possible (or just be findable by group)
	add_to_group("main_camera")
	
	# Default zoom for 1080p resolution to maintain retro feel
	# 3x zoom results in effective 640x360 viewport for the game world
	zoom = Vector2(3.0, 3.0)
	
	default_offset = offset
	player = get_tree().get_first_node_in_group("player")
	if player:
		# 初始时直接对齐玩家位置，避免开局镜头从 (0,0) 滑动到生成点
		global_position = player.global_position

func _process(delta: float) -> void:
	# Handle Shake
	if shake_duration > 0:
		shake_duration -= delta
		offset = default_offset + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		offset = default_offset
		shake_intensity = 0.0

	# Handle Movement
	if _is_cutscene_mode:
		# In cutscene mode, move towards the target position smoothly (or let Tween handle it)
		# Should we let Tween handle position directly? Yes.
		pass
	elif player:
		# 平滑跟随玩家
		global_position = global_position.lerp(player.global_position, 10.0 * delta)

# --- Cinematic API ---

func pan_to(target_pos: Vector2, duration: float = 1.0) -> void:
	_is_cutscene_mode = true
	_target_position = target_pos
	
	if _pan_tween:
		_pan_tween.kill()
	
	_pan_tween = create_tween()
	_pan_tween.set_ease(Tween.EASE_OUT)
	_pan_tween.set_trans(Tween.TRANS_CUBIC)
	_pan_tween.tween_property(self, "global_position", _target_position, duration)

func zoom_to(target_zoom: Vector2, duration: float = 1.0) -> void:
	if _zoom_tween:
		_zoom_tween.kill()
		
	_zoom_tween = create_tween()
	_zoom_tween.set_ease(Tween.EASE_OUT)
	_zoom_tween.set_trans(Tween.TRANS_CUBIC)
	_zoom_tween.tween_property(self, "zoom", target_zoom, duration)

func restore_control(duration: float = 1.0) -> void:
	if not player:
		return
		
	# Pan back to player then unlock
	if _pan_tween:
		_pan_tween.kill()
		
	_pan_tween = create_tween()
	_pan_tween.set_ease(Tween.EASE_IN_OUT)
	_pan_tween.set_trans(Tween.TRANS_CUBIC)
	_pan_tween.tween_property(self, "global_position", player.global_position, duration)
	_pan_tween.tween_callback(func(): _is_cutscene_mode = false)

func shake_screen(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration
