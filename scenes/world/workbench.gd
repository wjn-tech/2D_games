extends StaticBody2D

@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

func _ready() -> void:
	# Keep layers correct
	add_to_group("p_interactable")
	add_to_group("workbench")
	add_to_group("housing_table") # 也可以作为房屋的工作台
	
	# Force custom texture if available
	if sprite:
		var tex = load("res://assets/world/custom_furniture.png")
		if tex:
			var atlas = AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(0, 0, 32, 16)
			sprite.texture = atlas
			sprite.centered = false
	
func interact(_player) -> void:
	var ui = get_tree().get_first_node_in_group("ui_manager")
	if ui:
		# Use default toggle behavior. UI manager usually handles instantiation.
		ui.toggle_window("CraftingWindow", "res://scenes/ui/CraftingWindow.tscn")
