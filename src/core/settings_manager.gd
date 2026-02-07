extends Node

## SettingsManager (Autoload)
## Handles saving/loading configuration to user://settings.cfg and applying them.

signal settings_changed(section: String, key: String, value: Variant)

const SAVE_PATH = "user://settings.cfg"

# Default Configuration
var _defaults = {
	"General": {
		"language": "zh",
		"show_damage_numbers": true,
		"screenshake_intensity": 1.0,
		"pause_on_lost_focus": true
	},
	"Graphics": {
		"window_mode": DisplayServer.WINDOW_MODE_WINDOWED, # 0=Windowed, 3=Fullscreen
		"resolution_index": 2, # Default to 1280x720 (index depends on list)
		"vsync": true,
		"max_fps": 60,
		"particles_quality": 1.0,
		"brightness": 1.0,
		"contrast": 1.0,
		"gamma": 1.0
	},
	"Audio": {
		"master_vol": 1.0,
		"music_vol": 0.8,
		"sfx_vol": 1.0,
		"ui_vol": 1.0,
		"mute_on_lost_focus": false
	},
	"Input": {} # Dynamically populated
}

var _config = ConfigFile.new()
var _current_settings = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply_all_settings()

## --- Core I/O ---

func load_settings() -> void:
	var err = _config.load(SAVE_PATH)
	if err != OK:
		print("SettingsManager: No saved settings found. Using defaults.")
		_current_settings = _defaults.duplicate(true)
		save_settings() # Create file with defaults
	else:
		_current_settings = _defaults.duplicate(true)
		for section in _defaults.keys():
			for key in _defaults[section].keys():
				var saved_val = _config.get_value(section, key)
				if saved_val != null:
					_current_settings[section][key] = saved_val
		
		# Load Input map specifically
		_load_input_map()

func save_settings() -> void:
	for section in _current_settings.keys():
		for key in _current_settings[section].keys():
			_config.set_value(section, key, _current_settings[section][key])
	
	# Save Input map specifically
	_save_input_map()
	
	_config.save(SAVE_PATH)
	print("SettingsManager: Saved configuration.")

func get_value(section: String, key: String):
	if _current_settings.has(section) and _current_settings[section].has(key):
		return _current_settings[section][key]
	return null

func set_value(section: String, key: String, value: Variant) -> void:
	if not _current_settings.has(section):
		_current_settings[section] = {}
	
	_current_settings[section][key] = value
	emit_signal("settings_changed", section, key, value)
	
	# Auto-apply certain settings immediately
	match section:
		"Graphics": _apply_graphics_setting(key, value)
		"Audio": _apply_audio_setting(key, value)
		"General": _apply_general_setting(key, value)

## --- Application Logic ---

func apply_all_settings() -> void:
	for key in _current_settings["Graphics"]:
		_apply_graphics_setting(key, _current_settings["Graphics"][key])
	
	for key in _current_settings["Audio"]:
		_apply_audio_setting(key, _current_settings["Audio"][key])

	# General settings are mostly polled, but some apply immediately
	get_tree().paused = false # Ensure we aren't stuck

func _apply_graphics_setting(key: String, value: Variant) -> void:
	match key:
		"window_mode":
			var mode = value as int
			if mode == 3: # Fullscreen
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			elif mode == 4: # Exclusive Fullscreen
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				# Reset size if coming back from fullscreen
				# DisplayServer.window_set_size(Vector2i(1280, 720)) 
		"vsync":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED)
		"max_fps":
			Engine.max_fps = value if value > 0 else 0
		"brightness", "contrast", "gamma":
			# Need a WorldEnvironment to apply this. 
			# We can use a group "WorldEnvironment" to find it.
			var env_node = get_tree().get_first_node_in_group("world_environment")
			if env_node and env_node.environment:
				env_node.environment.adjustment_enabled = true
				if key == "brightness": env_node.environment.adjustment_brightness = value
				if key == "contrast": env_node.environment.adjustment_contrast = value
				if key == "gamma": env_node.environment.adjustment_saturation = value # Godot has saturation, not gamma usually exposed directly in adjustment without custom color correction texture. Mapping gamma to saturation for now or skipping.

func _apply_audio_setting(key: String, value: Variant) -> void:
	var bus_name = ""
	match key:
		"master_vol": bus_name = "Master"
		"music_vol": bus_name = "Music"
		"sfx_vol": bus_name = "SFX"
		"ui_vol": bus_name = "UI"
	
	if bus_name != "":
		var bus_idx = AudioServer.get_bus_index(bus_name)
		if bus_idx != -1:
			# Convert linear 0.0-1.0 to db. Silence at 0.
			var db = linear_to_db(max(value, 0.0001))
			AudioServer.set_bus_volume_db(bus_idx, db)
			AudioServer.set_bus_mute(bus_idx, value <= 0.01)

func _apply_general_setting(key: String, value: Variant) -> void:
	pass

## --- Input Logic ---

func _load_input_map() -> void:
	var input_section = _config.get_section_keys("Input")
	for action in input_section:
		var events = _config.get_value("Input", action)
		if events is Array:
			InputMap.action_erase_events(action)
			for event in events:
				InputMap.action_add_event(action, event)
	
	print("SettingsManager: Loaded Input mappings.")

func _save_input_map() -> void:
	for action in InputMap.get_actions():
		# Filter out built-in UI actions if desired
		if action.begins_with("ui_"): continue
		
		var events = InputMap.action_get_events(action)
		_config.set_value("Input", action, events)

func reset_to_defaults() -> void:
	_current_settings = _defaults.duplicate(true)
	apply_all_settings()
	# save_settings() # Optional: save immediately or wait for explicit save? The window calls save on Apply.
	# But Reset usually implies immediate effect.
	save_settings()
	
	reset_input_to_defaults()
	
	# Emit updates for UI
	for section in _current_settings:
		if section == "Input": continue
		for key in _current_settings[section]:
			emit_signal("settings_changed", section, key, _current_settings[section][key])

func reset_input_to_defaults() -> void:
	InputMap.load_from_project_settings()
	_save_input_map()
	emit_signal("settings_changed", "Input", "all", null)

