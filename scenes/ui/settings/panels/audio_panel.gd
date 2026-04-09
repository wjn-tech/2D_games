extends VBoxContainer

const AUDIO_ROWS = [
	{"label": "主音量 (Master)", "bus": "Master", "key": "master_vol", "fallback": 1.0},
	{"label": "音乐 (Music)", "bus": "Music", "key": "music_vol", "fallback": 0.8},
	{"label": "音效 (SFX)", "bus": "SFX", "key": "sfx_vol", "fallback": 1.0},
	{"label": "界面 (UI)", "bus": "UI", "key": "ui_vol", "fallback": 1.0},
]

func _ready() -> void:
	refresh_ui()

func refresh_ui() -> void:
	# Clear existing children if any
	for child in get_children():
		child.queue_free()
	
	for row in AUDIO_ROWS:
		_add_volume_slider(String(row.label), String(row.key), float(row.fallback), String(row.bus))

func _add_volume_slider(label_text: String, key: String, fallback: float, bus_name: String) -> void:
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 0)
	label.size_flags_horizontal = SIZE_SHRINK_BEGIN
	
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var val_label = Label.new()
	val_label.custom_minimum_size = Vector2(50, 0)
	
	var current = SettingsManager.get_value("Audio", key)
	if current == null: 
		current = fallback
	
	slider.value = float(current)
	val_label.text = "%d%%" % (slider.value * 100)
	
	slider.value_changed.connect(func(v):
		val_label.text = "%d%%" % (v * 100)
		SettingsManager.set_value("Audio", key, v)
		if has_node("/root/AudioManager") and get_node("/root/AudioManager").has_method("set_bus_volume"):
			get_node("/root/AudioManager").set_bus_volume(bus_name, v)
	)
	
	hbox.add_child(label)
	hbox.add_child(slider)
	hbox.add_child(val_label)
	add_child(hbox)
