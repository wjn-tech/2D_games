extends VBoxContainer

func _ready() -> void:
	refresh_ui()

func refresh_ui() -> void:
	for child in get_children():
		child.queue_free()
	
	_add_checkbox("全屏 (Fullscreen)", "Graphics", "window_mode", 
		func(v): return DisplayServer.WINDOW_MODE_FULLSCREEN if v else DisplayServer.WINDOW_MODE_WINDOWED, 
		func(v): return v == DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	
	_add_checkbox("垂直同步 (VSync)", "Graphics", "vsync")
	
	_add_slider("粒子质量 (Particles)", "Graphics", "particles_quality", 0.0, 2.0, 0.1)
	_add_slider("亮度 (Brightness)", "Graphics", "brightness", 0.5, 1.5, 0.05)

func _add_checkbox(label_text: String, section: String, key: String, val_converter = null, check_converter = null) -> void:
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	var check = CheckBox.new()
	
	var current_val = SettingsManager.get_value(section, key)
	if check_converter:
		check.button_pressed = check_converter.call(current_val)
	else:
		check.button_pressed = bool(current_val)
		
	check.toggled.connect(func(pressed):
		var val = pressed
		if val_converter:
			val = val_converter.call(pressed)
		SettingsManager.set_value(section, key, val)
	)
	
	hbox.add_child(label)
	hbox.add_child(check)
	add_child(hbox)

func _add_slider(label_text: String, section: String, key: String, min_v: float, max_v: float, step: float) -> void:
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var slider = HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.custom_minimum_size = Vector2(200, 0)
	
	var val_label = Label.new()
	val_label.custom_minimum_size = Vector2(50, 0)
	
	var current = SettingsManager.get_value(section, key)
	if current == null: current = min_v
	slider.value = float(current)
	val_label.text = "%.2f" % slider.value
	
	slider.value_changed.connect(func(v):
		val_label.text = "%.2f" % v
		SettingsManager.set_value(section, key, v)
	)
	
	hbox.add_child(label)
	hbox.add_child(slider)
	hbox.add_child(val_label)
	add_child(hbox)
