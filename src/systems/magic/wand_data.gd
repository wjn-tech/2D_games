extends Resource
class_name WandData

@export var embryo: WandEmbryo
# Dictionary {(x,y): MaterialResource}
@export var visual_grid: Dictionary = {}
# List of materials used for stats (not visual blocks)
@export var passive_materials: Array[Resource] = []
# Graph data for logic. 
# Array of NodeData dictionaries: { "id": int, "type": String, "position": Vector2, "data": Variant }
@export var logic_nodes: Array = []
# Array of Connection dictionaries: { "from_id": int, "from_port": int, "to_id": int, "to_port": int }
@export var logic_connections: Array = []

# Runtime Cache
var compiled_program: SpellProgram

@export var recoil_multiplier: float = 1.0 # Multiplier for recoil force (allows low recoil mining wands)

func get_grid_resolution() -> int:
	if embryo:
		return 16 # Overridden to 16 for new decoration system
	return 16
