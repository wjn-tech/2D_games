extends CanvasLayer

@onready var log_label: RichTextLabel = $ContentContainer/LogLabel
@onready var crt_overlay: ColorRect = $CRTOverlay
@onready var background: ColorRect = $Background

var _tween: Tween

func _ready() -> void:
	# Keep existing text for preview, or clear it
	# clear()
	pass

func clear() -> void:
	if log_label:
		log_label.text = ""
		log_label.visible_characters = -1

func show_terminal() -> void:
	self.visible = true
	var mat = crt_overlay.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("aim_alpha", 1.0)
	# CanvasLayer does not have modulate, applying to Background instead
	if background:
		background.modulate.a = 1.0

func hide_terminal(duration: float = 1.0) -> void:
	var t = create_tween()
	# CanvasLayer does not have modulate, applying to Background and children
	t.tween_property(background, "modulate:a", 0.0, duration)
	t.parallel().tween_property(log_label, "modulate:a", 0.0, duration)
	t.tween_callback(func(): self.visible = false)

func type_text(text: String, speed: float = 0.02) -> void:
	if not log_label: return
	
	if log_label.text != "":
		log_label.text += "\n"
		
	var start_count = log_label.get_total_character_count()
	log_label.text += text
	var end_count = log_label.get_total_character_count()
	
	# If visible_characters was -1 (all), set it to start_count to hide new text
	if log_label.visible_characters == -1:
		log_label.visible_characters = start_count
	# Or if user manually called type_text twice, ensure we start from current visible char count
	elif log_label.visible_characters < start_count:
		# Jump to start_count if previous animation not finished? 
		# Better to let it flow or force jump. Here we force jump.
		log_label.visible_characters = start_count
	
	if _tween and _tween.is_valid():
		_tween.kill()
	
	_tween = create_tween()
	var char_count = end_count - start_count
	var duration = char_count * speed
	_tween.tween_property(log_label, "visible_characters", end_count, duration)

func set_text_color(color: Color) -> void:
	if log_label:
		# Use push_color if we want to change future text, but here we want global override for "Critical" state
		# Or just change the default color for new appendages
		log_label.add_theme_color_override("default_color", color)
		# Force update existing text if needed? No, just future text or whole label. 
		# If user wants red text mid-stream, they should use BBCode. 
		# But since we use simple strings in sequence manager, let's just override default.
		pass

func flash(color: Color = Color.WHITE, duration: float = 0.5) -> void:
	if not background: return
	
	var original = background.color
	background.color = color
	var t = create_tween()
	t.tween_property(background, "color", original, duration).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func glitch(intensity: float = 0.05, duration: float = 0.5) -> void:
	var mat = crt_overlay.material as ShaderMaterial
	if not mat: return
	
	var original_ab = 0.005 # Default
	
	var t = create_tween()
	# Spike up
	t.tween_method(func(v): mat.set_shader_parameter("aberration", v), original_ab, intensity, duration * 0.1)
	# Random noise
	t.tween_callback(func(): _random_glitch_step(mat, intensity, int(duration/0.05)))
	# Settle down
	t.tween_method(func(v): mat.set_shader_parameter("aberration", v), intensity, original_ab, duration * 0.5).set_delay(duration * 0.4)

func _random_glitch_step(mat: ShaderMaterial, intensity: float, steps: int) -> void:
	if steps <= 0: return
	
	mat.set_shader_parameter("aberration", randf() * intensity)
	get_tree().create_timer(0.05).timeout.connect(func(): _random_glitch_step(mat, intensity, steps - 1))
