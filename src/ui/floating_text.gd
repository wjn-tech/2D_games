extends Label

class_name FloatingText

func _ready():
	# Set default properties if not set
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Set pivot to center for scaling
	pivot_offset = size / 2.0
	
	# Animation
	var tween = create_tween()
	var target_pos = position + Vector2(randf_range(-20, 20), -50)
	
	# Pop effect
	scale = Vector2.ZERO
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	
	tween.parallel().tween_property(self, "position", target_pos, 0.8).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.3)
	
	tween.finished.connect(queue_free)

func setup(text_content: String, color: Color = Color.WHITE):
	text = text_content
	add_theme_color_override("font_color", color)
	add_theme_font_size_override("font_size", 16)
	# You can add more styling here
