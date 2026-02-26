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
	# Ensure the correct theme is applied even if UIManager overrides it
	call_deferred("set_theme", load("res://ui/theme/main_menu_theme.tres"))

	# Entrance Animation
	modulate.a = 0.0
	scale = Vector2(0.95, 0.95)
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.3)
	
	# Load panel scenes
	_load_panels()
	
	# Connect tabs
	for key in tabs:
		tabs[key].pressed.connect(func(): _on_tab_pressed(key))
	
	$MainContainer/Layout/Footer/ApplyButton.pressed.connect(_on_apply_pressed)
	$MainContainer/Layout/Footer/ResetButton.pressed.connect(_on_reset_pressed)
	
	# Select default
	_on_tab_pressed("General")

	# Apply hover effects to all buttons recursively
	_recursively_connect_hover(self)

func _load_panels() -> void:
	# Load existing panels if available, otherwise create placeholders
	if FileAccess.file_exists("res://scenes/ui/settings/panels/GeneralPanel.tscn"):
		panels["General"] = load("res://scenes/ui/settings/panels/GeneralPanel.tscn").instantiate()
	if FileAccess.file_exists("res://scenes/ui/settings/panels/GraphicsPanel.tscn"):
		panels["Graphics"] = load("res://scenes/ui/settings/panels/GraphicsPanel.tscn").instantiate()
	if FileAccess.file_exists("res://scenes/ui/settings/panels/AudioPanel.tscn"):
		panels["Audio"] = load("res://scenes/ui/settings/panels/AudioPanel.tscn").instantiate()
	if FileAccess.file_exists("res://scenes/ui/settings/panels/InputPanel.tscn"):
		panels["Input"] = load("res://scenes/ui/settings/panels/InputPanel.tscn").instantiate()
	
	# If failed to load, create dummy controls to avoid crashes
	for key in tabs.keys():
		if not panels.has(key):
			var dummy = Label.new()
			dummy.text = key + " Settings (Coming Soon)"
			dummy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dummy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			dummy.custom_minimum_size = Vector2(0, 200)
			panels[key] = dummy

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
	# If SettingsManager exists, use it
	if ClassDB.class_exists("SettingsManager") or has_node("/root/SettingsManager"):
		# Assuming a singleton or static class
		# SettingsManager.save_settings()
		pass
	
	# Close animation
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(self, "scale", Vector2(0.95, 0.95), 0.2)
	tween.finished.connect(func(): 
		if UIManager.has_method("close_window"):
			UIManager.close_window("SettingsWindow")
		else:
			queue_free()
	)

func _on_reset_pressed() -> void:
	# Logic to reset settings
	pass

# Hover Effects Logic
func _recursively_connect_hover(node: Node) -> void:
	if node is Button:
		node.mouse_entered.connect(func(): _animate_button_enter(node))
		node.mouse_exited.connect(func(): _animate_button_exit(node))
		node.pivot_offset = node.size / 2 # Ensure center scaling
	
	for child in node.get_children():
		_recursively_connect_hover(child)

func _animate_button_enter(btn: Button) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(btn, "modulate", Color(1.2, 1.2, 1.5), 0.1)

func _animate_button_exit(btn: Button) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.1)
	tween.parallel().tween_property(btn, "modulate", Color.WHITE, 0.1)
