extends Resource
class_name ItemData

@export var id: String = ""
@export var display_name: String = "Item"
@export var icon: Texture2D
@export var max_stack: int = 1
@export var scene_to_equip: PackedScene

# Quality properties for crafted items
var quality_score: float = 0.0
var quality_grade: String = "Common"
var crafted_by: String = ""

# Virtual function for standard "use" action (like drinking a potion)
func _on_use(player: Node):
	pass
