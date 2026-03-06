class_name InputPrompt
extends Control

@onready var key_panel: PanelContainer = $KeyPanel
@onready var label: Label = $KeyPanel/Label
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

# Configuration
var action_name: String = ""
var custom_key: String = ""
var is_pressed: bool = false
var fade_on_press: bool = true

func setup(action: String, auto_fade: bool = true):
	action_name = action
	fade_on_press = auto_fade
	
	if custom_key != "":
		label.text = custom_key
		return
	
	# Get key name from InputMap
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		var event = events[0]
		if event is InputEventKey:
			label.text = OS.get_keycode_string(event.physical_keycode)
		elif event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				label.text = "LMB"
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				label.text = "RMB"
	else:
		label.text = action_name.substr(0, 1).to_upper() # Fallback

func press():
	if is_pressed: return
	is_pressed = true
	
	if anim.has_animation("press"):
		anim.play("press")
	
	if fade_on_press:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.2)
		tween.tween_callback(queue_free)

func _input(event: InputEvent):
	if action_name == "" or is_pressed: return
	
	if event.is_action_pressed(action_name):
		press()
