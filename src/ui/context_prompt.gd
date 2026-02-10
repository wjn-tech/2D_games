extends Control
class_name ContextPrompt

@onready var label: Label = $VBoxContainer/Label
@onready var action_container: VBoxContainer = $VBoxContainer/ActionContainer

func _ready() -> void:
	if not label:
		# Fallback if scene structure is different or created via code
		pass

func setup(npc_name: String, alignment: String) -> void:
	if has_node("VBoxContainer/Label"):
		$VBoxContainer/Label.text = "[ " + npc_name + " ]"
		if alignment == "Hostile":
			$VBoxContainer/Label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		elif alignment == "Friendly":
			$VBoxContainer/Label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))

func update_prompt(npc: Node) -> void:
	# Clear old prompts (except name)
	if not has_node("VBoxContainer/ActionContainer"): return
	
	var container = $VBoxContainer/ActionContainer
	for c in container.get_children():
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
			container.add_child(prompt_label)
