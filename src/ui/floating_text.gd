extends Label

class_name FloatingText

func _ready():
	# Set default properties if not set
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Animation
	var tween = create_tween()
	var target_pos = position + Vector2(randf_range(-20, 20), -50)
	
	tween.tween_property(self, "position", target_pos, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 1.0).set_delay(0.5)
	
	tween.finished.connect(queue_free)

func setup(text_content: String, color: Color = Color.WHITE):
	text = text_content
	add_theme_color_override("font_color", color)
	add_theme_font_size_override("font_size", 16)
	# You can add more styling here
