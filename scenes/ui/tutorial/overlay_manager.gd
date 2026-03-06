class_name OverlayManager
extends CanvasLayer

const InputPromptScene = preload("res://scenes/ui/tutorial/InputPrompt.tscn")
const GhostCursorScene = preload("res://scenes/ui/tutorial/GhostCursor.tscn")

@onready var input_container: Control = $InputContainer
@onready var ghost_layer: Control = $GhostLayer
@onready var highlight_mask: HighlightOverlay = $HighlightOverlay # Reuse existing component if possible

var active_prompts: Dictionary = {} # Key: Action (e.g. "move_forward"), Value: InputPrompt instance
var active_ghost: GhostCursor = null

func _ready() -> void:
	# Ensure layers are set correctly
	layer = 100 
	
func show_input_prompt(actions: Array[String], _message: String = ""):
	show_custom_input_prompt(actions, "", _message)

func show_custom_key_prompt(key_text: String, action_id: String = "custom", _message: String = ""):
	show_custom_input_prompt([action_id], key_text, _message)

func show_custom_input_prompt(actions: Array[String], custom_key: String = "", _message: String = ""):
	var screen_center = get_viewport().get_visible_rect().size / 2
	var offset_x = -(actions.size()-1) * 30 # Center them
	
	for action in actions:
		if active_prompts.has(action): continue
		
		var prompt = InputPromptScene.instantiate()
		if custom_key != "":
			prompt.set("custom_key", custom_key)
		input_container.add_child(prompt)
		prompt.setup(action)
		
		# Position them in center-bottom or near player if possible?
		# For now, put them near bottom center
		prompt.position = Vector2(screen_center.x + offset_x, screen_center.y + 200)
		offset_x += 60 # Spacing
		
		active_prompts[action] = prompt

func clear_prompts():
	for key in active_prompts:
		var node = active_prompts[key]
		if is_instance_valid(node):
			node.queue_free()
	active_prompts.clear()

func show_ghost_drag(start_pos: Vector2, end_pos: Vector2):
	clear_ghost()
	active_ghost = GhostCursorScene.instantiate()
	ghost_layer.add_child(active_ghost)
	active_ghost.start_drag(start_pos, end_pos)

func show_ghost_connect(start_pos: Vector2, end_pos: Vector2):
	clear_ghost()
	active_ghost = GhostCursorScene.instantiate()
	ghost_layer.add_child(active_ghost)
	active_ghost.start_connect(start_pos, end_pos)

func clear_ghost():
	if is_instance_valid(active_ghost):
		active_ghost.stop()
		# active_ghost.queue_free() # stop() does queue_free
	active_ghost = null

func highlight_element(control: Control, message: String = ""):
	if highlight_mask:
		highlight_mask.highlight(control, message)

func clear_highlight():
	if highlight_mask:
		highlight_mask.clear()
