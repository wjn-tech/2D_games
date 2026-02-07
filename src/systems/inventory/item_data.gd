extends Resource
class_name ItemData

@export var id: String = ""
@export var display_name: String = "Item"
@export var icon: Texture2D
@export var max_stack: int = 1
@export var scene_to_equip: PackedScene

# Virtual function for standard "use" action (like drinking a potion)
func _on_use(player: Node):
	pass
