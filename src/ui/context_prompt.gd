extends Control
class_name ContextPrompt

var label: Label
var action_container: VBoxContainer

func _ready() -> void:
	_ensure_nodes()

func _ensure_nodes() -> void:
	if not label:
		label = get_node_or_null("VBoxContainer/Label")
	if not action_container:
		action_container = get_node_or_null("VBoxContainer/ActionContainer")

func setup(npc_name: String, alignment: String) -> void:
	_ensure_nodes()
	if label:
		label.text = "[ " + npc_name + " ]"
		if alignment == "Hostile":
			label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		elif alignment == "Friendly":
			label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))

func update_prompt(npc: Node) -> void:
	_ensure_nodes()
	if not action_container: return
	
	for c in action_container.get_children():
		c.queue_free()
		
	if npc.has_method("get_contextual_actions"):
		var actions = npc.get_contextual_actions()
		for action in actions:
			var prompt_label = Label.new()
			prompt_label.text = "[" + action.key + "] " + action.label
			prompt_label.add_theme_font_size_override("font_size", 10)
			if action.key == "E":
				prompt_label.add_theme_color_override("font_color", Color.YELLOW)
			else:
				prompt_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
			action_container.add_child(prompt_label)
