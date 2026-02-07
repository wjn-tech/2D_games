extends Control

@onready var content_area = %ContentArea
@onready var tabs = {
	"General": %TabGeneral,
	"Graphics": %TabGraphics,
	"Audio": %TabAudio,
	"Input": %TabInput
}

var current_panel: Control = null
var panels = {}

func _ready() -> void:
	# Load panel scenes
	_load_panels()
	
	# Connect tabs
	for key in tabs:
		tabs[key].pressed.connect(func(): _on_tab_pressed(key))
	
	$MainContainer/Footer/ApplyButton.pressed.connect(_on_apply_pressed)
	$MainContainer/Footer/ResetButton.pressed.connect(_on_reset_pressed)
	
	# Select default
	_on_tab_pressed("General")

func _load_panels() -> void:
	# For simplicity in this iteration, we create them dynamically or load from packed scenes if they existed
	# We will implement rudimentary panel generation here for Phase 2
	
	panels["General"] = load("res://scenes/ui/settings/panels/GeneralPanel.tscn").instantiate()
	panels["Graphics"] = load("res://scenes/ui/settings/panels/GraphicsPanel.tscn").instantiate()
	panels["Audio"] = load("res://scenes/ui/settings/panels/AudioPanel.tscn").instantiate()
	panels["Input"] = load("res://scenes/ui/settings/panels/InputPanel.tscn").instantiate()
	
	for key in panels:
		content_area.add_child(panels[key])
		panels[key].visible = false

func _on_tab_pressed(tab_name: String) -> void:
	# Update toggle state
	for key in tabs:
		tabs[key].set_pressed_no_signal(key == tab_name)
	
	# Switch content
	for key in panels:
		panels[key].visible = (key == tab_name)

func _on_apply_pressed() -> void:
	SettingsManager.save_settings()
	UIManager.close_window("SettingsWindow")

func _on_reset_pressed() -> void:
	# Confirmation logic could go here
	SettingsManager.reset_to_defaults()
	# Refresh UI
	for key in panels:
		if panels[key].has_method("refresh_ui"):
			panels[key].refresh_ui()
