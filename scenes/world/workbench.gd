extends StaticBody2D

@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	# Keep layers correct
	add_to_group("p_interactable")
	add_to_group("workbench")
	
func interact(_player) -> void:
	var ui = get_tree().get_first_node_in_group("ui_manager")
	if ui:
		# Use default toggle behavior. UI manager usually handles instantiation.
		ui.toggle_window("CraftingWindow", "res://scenes/ui/CraftingWindow.tscn")
