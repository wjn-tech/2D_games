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

func normalize_grid():
	var new_grid = {}
	for key in visual_grid.keys():
		var coords = key
		if key is String:
			# Convert "(x, y)" or "Vector2i(x, y)" to Vector2i
			var s = key.replace("(", "").replace(")", "").replace("Vector2i", "").strip_edges()
			var parts = s.split(",")
			if parts.size() == 2:
				coords = Vector2i(int(parts[0]), int(parts[1]))
		
		if coords is Vector2i:
			new_grid[coords] = visual_grid[key]
	visual_grid = new_grid

# Runtime Cache
# Noita Logic: A list of "Cast Blocks". The wand iterates through these blocks.
# When the iterator finishes, the wand recharges.
var compiled_blocks: Array = [] 
var deck_index: int = 0
var is_recharging: bool = false
# The compiled program is deprecated but kept if strictly needed for old reference, ideally replaced by block iteration
var compiled_program: SpellProgram 

@export var recoil_multiplier: float = 1.0 # Multiplier for recoil force (allows low recoil mining wands)

# Mana System (Noita Style)
# The wand handles its own Recharge and Cast Delay state now
@export var current_mana: float = 200.0
var recharge_timer: float = 0.0 # Time until reload finishes
var cast_delay_timer: float = 0.0 # Time until next cast allowed

func update_mana(delta: float):
	if not embryo: return
	
	# Handle timers
	if is_recharging:
		if recharge_timer > 0:
			recharge_timer -= delta
		
		# Check completion
		if recharge_timer <= 0:
			recharge_timer = 0
			is_recharging = false
			deck_index = 0
	
	if cast_delay_timer > 0:
		cast_delay_timer -= delta
	
	# Recharge Mana (Always occurring in Noita)
	# Increased default regen to make machine guns viable
	if current_mana < embryo.mana_capacity:
		current_mana = min(embryo.mana_capacity, current_mana + embryo.mana_recharge_speed * delta) 

## Trigger the recharge state. Called when deck is empty or out of mana.
func trigger_recharge(recharge_duration: float):
	if is_recharging: return
	
	is_recharging = true
	# Use max to ensure we don't have negative recharge time, though Noita allows it for instant loops
	recharge_timer = max(0.01, recharge_duration)
	deck_index = 0
	
	# The user requested a mana boost upon recharge
	if embryo:
		current_mana = min(embryo.mana_capacity, current_mana + embryo.mana_recharge_burst)

func get_grid_resolution() -> int:
	if embryo:
		return 16 # Overridden to 16 for new decoration system
	return 16
