extends Button

func _ready() -> void:
	# Notification-based approach for improved reliability with slow mouse movement.
	# Standard signals are commented out to avoid dual-trigger issues.
	# mouse_entered.connect(_on_mouse_entered)
	# mouse_exited.connect(_on_mouse_exited)
	
	# Keep button_down for immediate click feedback.
	if not button_down.is_connected(_on_button_down):
		button_down.connect(_on_button_down)
	
	pivot_offset = size / 2
	# Force the button to catch mouse events.
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Ensure internal children (like labels or icons) do not intercept mouse events.
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		# 强制确保所有子节点不拦截事件
		for child in get_children():
			if child is Control:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_on_hover_start()
	elif what == NOTIFICATION_MOUSE_EXIT:
		_on_hover_end()

func _on_hover_start() -> void:
	# Centralized Audio Feedback via AudioManager.
	# if has_node("/root/AudioManager"):
	# 	get_node("/root/AudioManager").play_ui_sfx("hover")
	
	# Visual feedback: Scale and Modulate (color) animations.
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)
	
	var col_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	col_tween.tween_property(self, "modulate", Color(1.5, 1.5, 2.0, 1), 0.2)
	
	# Godot 4 specific theme tweak for visual distinction.
	add_theme_constant_override("h_separation", 24)

func _on_hover_end() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.4)
	
	var col_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	col_tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	remove_theme_constant_override("h_separation")

func _on_button_down() -> void:
	# if has_node("/root/AudioManager"):
	# 	get_node("/root/AudioManager").play_ui_sfx("click")
	pass

func _process(delta: float) -> void:
	# Ensure pivot stays centered if size changes (unlikely for fixed menu but good practice)
	if pivot_offset != size / 2:
		pivot_offset = size / 2
