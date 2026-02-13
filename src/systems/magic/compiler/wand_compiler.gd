extends RefCounted
class_name WandCompiler

# Node Types Configuration
const NODE_TYPE_TRIGGER = "trigger" # Acts as Start OR intermediate
const NODE_TYPE_ACTION = "action_projectile"
const NODE_TYPE_MODIFIER = "modifier" # generic prefix, or specific
# If we have a dedicated "Source" node, we use that. 
# For now, let's treat "Trigger" nodes that have NO inputs as roots, 
# OR explicit "Mana Source" nodes. 
# Let's assume the user wants "Mana Source" -> ...
# But in the UI mocked in wand_editor.gd, we saw "Reactor" (generator).
const NODE_TYPE_SOURCE = "generator"

const MAX_COMPILATION_DEPTH = 20 # Safety break for recursions

# Main Entry Point
static func compile(wand_data: WandData) -> SpellProgram:
	var program = SpellProgram.new()
	program.is_valid = true
	
	if wand_data == null:
		program.is_valid = false
		program.compilation_errors.append("No WandData provided.")
		return program
		
	# 1. Build Adjacency Graph for Analysis
	var adj = _build_adjacency(wand_data)
	
	# 2. Cycle Detection
	if _detect_cycles(wand_data, adj):
		program.is_valid = false
		program.compilation_errors.append("Cycle detected in spell graph.")
		return program
		
	# 3. Mana Calculation
	# TODO: Get max mana from wand (currently relying on logic nodes to tell us costs)
	var current_mana_cost = 0.0
	for node in wand_data.logic_nodes:
		current_mana_cost += node.get("mana_cost", 0.0) # Assume nodes have cost
	
	program.total_mana_cost = current_mana_cost
	var wand_capacity = 100.0
	if wand_data.embryo:
		wand_capacity = wand_data.embryo.mana_capacity
	
	if current_mana_cost > wand_capacity:
		program.is_valid = false
		program.compilation_errors.append("Mana cost %s exceeds capacity %s." % [current_mana_cost, wand_capacity])
		return program

	# 4. Compiler Traversal
	# Find Roots: Nodes of type SOURCE, or Triggers with no incoming connections?
	# Based on prompt: "Start from Mana Source"
	var roots = _find_roots(wand_data, adj)
	
	if roots.is_empty():
		# Fallback: Find Triggers with no inputs? 
		# For now, if no roots, empty program.
		pass
	
	program.root_tier = _compile_tier(wand_data, roots, adj, 0)
	
	return program

static func _build_adjacency(wand_data: WandData) -> Dictionary:
	var adj = {}
	for node in wand_data.logic_nodes:
		adj[int(node.id)] = []
	
	for conn in wand_data.logic_connections:
		var from_id = int(conn["from_id"])
		var to_id = int(conn["to_id"])
		var from_port = int(conn.get("from_port", 0))
		if from_id in adj:
			adj[from_id].append({"to_id": to_id, "from_port": from_port})
			
	return adj

static func _detect_cycles(wand_data: WandData, adj: Dictionary) -> bool:
	var visited = {} # id -> true
	var recursion_stack = {} # id -> true
	
	for node in wand_data.logic_nodes:
		var id = int(node.id)
		if id not in visited:
			if _dfs_cycle_check(id, adj, visited, recursion_stack):
				return true
	return false

static func _dfs_cycle_check(current_id: int, adj: Dictionary, visited: Dictionary, stack: Dictionary) -> bool:
	visited[current_id] = true
	stack[current_id] = true
	
	if current_id in adj:
		for struct_obj in adj[current_id]:
			var neighbor_id = struct_obj.to_id
			if neighbor_id not in visited:
				if _dfs_cycle_check(neighbor_id, adj, visited, stack):
					return true
			elif neighbor_id in stack:
				return true
				
	stack.erase(current_id)
	return false

static func _find_roots(wand_data: WandData, adj: Dictionary) -> Array:
	var roots = []
	# Definition: Nodes with type "generator" (Source)
	# AND fall back to "trigger" if no generator is strictly required yet?
	# Instructions said: "Starts from Mana Source"
	
	# Let's count in-degrees
	var in_degree = {}
	for node in wand_data.logic_nodes:
		in_degree[int(node.id)] = 0
		
	for conn in wand_data.logic_connections:
		var to_id = int(conn["to_id"])
		in_degree[to_id] = in_degree.get(to_id, 0) + 1
		
	for node in wand_data.logic_nodes:
		var n_type = node.get("wand_logic_type")
		if not n_type: n_type = node.get("type")
		
		# If explicit source
		if n_type == NODE_TYPE_SOURCE:
			roots.append(node)
		
		# Allow Triggers to be roots if they have no inputs (Initial Trigger) 
		# This supports simple "Trigger -> Action" without a generator block if user didn't place one.
		elif n_type == NODE_TYPE_TRIGGER and in_degree[int(node.id)] == 0:
			roots.append(node)
	
	return roots

static func _compile_tier(wand_data: WandData, start_nodes: Array, adj: Dictionary, depth: int) -> ExecutionTier:
	var tier = ExecutionTier.new()
	if depth > MAX_COMPILATION_DEPTH:
		return tier

	for node in start_nodes:
		# Traverse from this node to find Actions/Triggers
		# Pass an empty modifier stack
		_traverse_path(wand_data, node, adj, [], tier, depth)
		
	return tier

static func _traverse_path(wand_data: WandData, current_node: Dictionary, adj: Dictionary, modifiers: Array, tier: ExecutionTier, depth: int):
	var node_type = current_node.get("wand_logic_type") # Using wand_editor naming convention
	if not node_type: node_type = current_node.get("type")
	
	# If this is a SOURCE (Generator), it technically doesn't do anything itself.
	# But if it's connected to nothing, the recursion stops here and adds no instructions.
	# The user complaint: "Only Generator fires a bullet".
	# If tier.instructions is empty at the end, SpellProcessor does nothing.
	# Check if user meant default Trigger logic?
	# Or maybe 'action_projectile' is being assumed?
	# Let's verify strict typing.
	
	# Check if current node is an Endpoint (Action or Trigger)
	if node_type == NODE_TYPE_ACTION or node_type == "action_projectile":
		var instruction = SpellInstruction.new()
		instruction.type = SpellInstruction.TYPE_PROJECTILE
		
		# Consistency Fix: try both value keys
		var val = current_node.get("value", {})
		if val.is_empty(): val = current_node.get("wand_logic_value", {})
		
		instruction.params = val.duplicate()
		instruction.modifiers = modifiers.duplicate()
		tier.instructions.append(instruction)
		# Stop traversal here (Bullet fired)
		return

	if node_type == "logic_sequence":
		var outputs = adj.get(int(current_node.id), [])
		# Sort by port (Top to Bottom)
		outputs.sort_custom(func(a, b): return a.from_port < b.from_port)
		
		for i in range(outputs.size()):
			var out_obj = outputs[i]
			var neighbor = _get_node_by_id(wand_data, out_obj.to_id)
			if not neighbor: continue
			
			var instr = SpellInstruction.new()
			instr.type = SpellInstruction.TYPE_TRIGGER_TIMER
			instr.params = {"duration": i * 0.2} # 0.2s delay step
			instr.modifiers = modifiers.duplicate()
			instr.child_tier = _compile_tier(wand_data, [neighbor], adj, depth + 1)
			tier.instructions.append(instr)
		return

	if node_type == NODE_TYPE_TRIGGER or node_type == "trigger":
		var instruction = SpellInstruction.new()
		# Use 'value' or 'wand_logic_value' consistent with logic_board export types
		var val = current_node.get("value", {}) 
		if val.is_empty(): val = current_node.get("wand_logic_value", {})
		
		var trig_type = val.get("trigger_type", "timer") 
		
		if trig_type == "collision":
			instruction.type = SpellInstruction.TYPE_TRIGGER_COLLISION
		elif trig_type == "disappear":
			instruction.type = SpellInstruction.TYPE_TRIGGER_DISAPPEAR
		else:
			instruction.type = SpellInstruction.TYPE_TRIGGER_TIMER # Default cast/timer
			if trig_type == "cast": instruction.params["duration"] = 0.0 # Instant? Or just pass through logic.
			
		instruction.params = val.duplicate()
		instruction.modifiers = modifiers.duplicate()
		
		# CRITICAL FIX 3: Trigger is a bullet that holds the NEXT logic.
		# Compile downstream nodes into the CHILD TIER.
		# And STOP traversing the current tier (don't create duplicates).
		var output_objs = adj.get(int(current_node.id), [])
		var next_nodes = []
		for obj in output_objs:
			var n = _get_node_by_id(wand_data, obj.to_id)
			if n: next_nodes.append(n)
		
		# Compile the payload (Reset modifiers for the payload? Usually yes, unless specified)
		instruction.child_tier = _compile_tier(wand_data, next_nodes, adj, depth + 1)
		
		tier.instructions.append(instruction)
		return

	# If Modifier
	var next_modifiers = modifiers.duplicate()
	if node_type != NODE_TYPE_SOURCE: # Source doesn't add modifiers usually, or does it?
		# Assuming modifier
		# Check if it IS a modifier? Or just assume everything else is?
		if node_type and (node_type.begins_with("modifier") or node_type == "modifier"):
			next_modifiers.append(current_node)
	
	# Continue Traversal
	var output_objs = adj.get(int(current_node.id), [])
	for obj in output_objs:
		var next_node = _get_node_by_id(wand_data, obj.to_id)
		if next_node:
			_traverse_path(wand_data, next_node, adj, next_modifiers, tier, depth)

static func _get_node_by_id(wand_data: WandData, id: int):
	for node in wand_data.logic_nodes:
		if int(node.id) == id:
			return node
	return null
