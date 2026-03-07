extends VBoxContainer

const BUSSES = ["Master", "Music", "SFX", "Ambient"]

func _ready() -> void:
	refresh_ui()

func refresh_ui() -> void:
	# Clear existing children if any
	for child in get_children():
		child.queue_free()
	
	# Create sliders for each bus
	for bus_name in BUSSES:
		_add_volume_slider(bus_name)

func _add_volume_slider(bus_name: String) -> void:
	var hbox = HBoxContainer.new()
	var label = Label.new()
	
	# Simple translation
	var translated_name = bus_name
	match bus_name:
		"Master": translated_name = "主音量 (Master)"
		"Music": translated_name = "音乐 (Music)"
		"SFX": translated_name = "音效 (SFX)"
		"Ambient": translated_name = "环境 (Ambient)"
	
	label.text = translated_name
	label.custom_minimum_size = Vector2(120, 0)
	label.size_flags_horizontal = SIZE_SHRINK_BEGIN
	
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var val_label = Label.new()
	val_label.custom_minimum_size = Vector2(50, 0)
	
	# Current value check from SettingsManager
	var key = bus_name.to_lower() + "_volume"
	var current = SettingsManager.get_value("Audio", key)
	if current == null: 
		current = 1.0
	
	slider.value = float(current)
	val_label.text = "%d%%" % (slider.value * 100)
	
	# Connect to SettingsManager AND AudioManager
	slider.value_changed.connect(func(v):
		val_label.text = "%d%%" % (v * 100)
		SettingsManager.set_value("Audio", key, v)
		# Update AudioManager immediately
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").set_bus_volume(bus_name, v)
	)
	
	hbox.add_child(label)
	hbox.add_child(slider)
	hbox.add_child(val_label)
	add_child(hbox)
