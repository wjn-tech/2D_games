extends Button

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pivot_offset = size / 2

func _on_mouse_entered() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)
	
	var col_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	col_tween.tween_property(self, "modulate", Color(1.5, 1.5, 2.0, 1), 0.2)
	
	# Attempt to increase letter spacing on hover if theme override supported (Godot 4 specific)
	add_theme_constant_override("h_separation", 24) # Increase icon separation

func _on_mouse_exited() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.4)
	
	var col_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	col_tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	remove_theme_constant_override("h_separation")

func _process(delta: float) -> void:
	# Ensure pivot stays centered if size changes (unlikely for fixed menu but good practice)
	if pivot_offset != size / 2:
		pivot_offset = size / 2
