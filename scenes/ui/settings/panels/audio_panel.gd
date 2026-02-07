extends VBoxContainer

const BUSSES = ["Master", "Music", "SFX"]

func _ready() -> void:
	refresh_ui()

func refresh_ui() -> void:
	for child in get_children():
		child.queue_free()
	
	for bus_name in BUSSES:
		_add_volume_slider(bus_name)

func _add_volume_slider(bus_name: String) -> void:
	var hbox = HBoxContainer.new()
	var label = Label.new()
	var translated_name = bus_name
	match bus_name:
		"Master": translated_name = "主音量 (Master)"
		"Music": translated_name = "音乐 (Music)"
		"SFX": translated_name = "音效 (SFX)"
	
	label.text = translated_name
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(200, 0)
	
	var val_label = Label.new()
	val_label.custom_minimum_size = Vector2(50, 0)
	
	# Current value check
	var key = bus_name.to_lower() + "_volume"
	var current = SettingsManager.get_value("Audio", key)
	if current == null: current = 1.0
	slider.value = float(current)
	val_label.text = "%d%%" % (slider.value * 100)
	
	slider.value_changed.connect(func(v):
		val_label.text = "%d%%" % (v * 100)
		SettingsManager.set_value("Audio", key, v)
	)
	
	hbox.add_child(label)
	hbox.add_child(slider)
	hbox.add_child(val_label)
	add_child(hbox)
