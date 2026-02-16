extends RefCounted
class_name WandCompiler

# Bump this when making breaking changes to compilation output
const COMPILE_VERSION: int = 1

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
	# debug: compile start
	
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
		
	# 3. Mana & Stat Calculation
	var current_mana_cost = 0.0
	var base_cast_delay = 0.0
	var base_recharge_time = 0.0
	
	if wand_data.embryo:
		current_mana_cost = wand_data.embryo.base_mana_cost
		base_cast_delay = wand_data.embryo.cast_delay
		base_recharge_time = wand_data.embryo.recharge_time
		
	# Program totals for Wand stats (this is the base before modifiers)
	program.total_cast_delay = base_cast_delay
	program.total_recharge_time = base_recharge_time
	
	# Sum up total mana cost of ALL logic nodes for validation
	for node in wand_data.logic_nodes:
		var val = node.get("value", {})
		if val is Dictionary and val.is_empty(): 
			val = node.get("wand_logic_value", {})
		
		if val is Dictionary:
			current_mana_cost += val.get("mana_cost", 0.0)
	
	program.total_mana_cost = current_mana_cost
	var wand_capacity = 100.0
	if wand_data.embryo:
		wand_capacity = wand_data.embryo.mana_capacity
	
	if current_mana_cost > wand_capacity:
		program.is_valid = false
		program.compilation_errors.append("Mana cost %s exceeds capacity %s." % [current_mana_cost, wand_capacity])
		return program

	# 4. Compiler Traversal
	# Flatten the graph into a linear Deck of instructions.
	# We perform a topological sort or DFS respecting port order.
	var roots = _find_roots(wand_data, adj)
	
	# Fix 1: If roots are empty, try to find ANY node to start with, usually the one with the lowest ID or visually top-left?
	# However, _find_roots looks for SOURCE or orphan triggers.
	# If roots are still empty, check for ANY orphan node (in-degree 0).
	
	if roots.is_empty() and not wand_data.logic_nodes.is_empty():
		# Find ANY node with in-degree 0
		var in_degree = {}
		for node in wand_data.logic_nodes:
			in_degree[str(node.id)] = 0
		for conn in wand_data.logic_connections:
			var to_id = str(conn.get("to_id", ""))
			in_degree[to_id] = in_degree.get(to_id, 0) + 1
			
		for node in wand_data.logic_nodes:
			if in_degree[str(node.id)] == 0:
				roots.append(node)
				
		# If still empty (Cycle?), pick the first one.
		if roots.is_empty():
			roots.append(wand_data.logic_nodes[0])

	var deck_instructions: Array[SpellInstruction] = []
	# If a source/root node has multiple outputs, we compile its outputs
	# as a child_tier and attach to the next deck instruction via this pending slot.
	var pending_child_tier: ExecutionTier = null
	var pending_child_mode: String = ""
	
	# We maintain a visited set to avoid cycles (already checked) and handle multiple paths
	var visited = {} 
	
	# Hybrid Compilation:
	# 1. Identify "Deck Sequence" vs "Tree Payload".
	# The Main Path follows the primary output connection linearly.
	# Branching outputs (e.g. from Multicast or Sequence) are compiled as immediate Sub-Tiers (Trees).
	
	for root in roots:
		# We use a cursor-based traversal for the main deck
		var current = root
		while current:
			var node_type = ""
			var outputs_all = []
			var node_id = str(current.id)
			if node_id in visited: break
			visited[node_id] = true
			
			# Add instruction to deck
			var instruction = _create_instruction(wand_data, current, adj)

			# Compute outputs early for special handling (e.g. source with multiple outputs)
			outputs_all = adj.get(node_id, [])
			# If this is a source/root with multiple outputs, compile all of them as a child tier
			# and attach to the next real deck instruction (we skip sources in the deck).
			node_type = current.get("wand_logic_type")
			if not node_type: node_type = current.get("type")
			if node_type == NODE_TYPE_SOURCE and outputs_all.size() > 1:
				var root_children = _get_children(wand_data, current, adj)
				if not root_children.is_empty():
					pending_child_tier = _compile_tree_tier(wand_data, root_children, adj, 0)
					pending_child_mode = "PARALLEL"
					print("WAND_COMPILER: source node has multiple outputs, compiled pending child_tier for root=", node_id)
			
			if instruction == null:
				current = _get_next_main_node(wand_data, current, adj)
				continue

			# If this node has branching logic (Sequence/Multicast), we compile children as a Tree/Sub-Tier
			# instead of flattening them into the main deck sequence, 
			# UNLESS it's a "Passthrough" modifier which just continues the deck.
			
			node_type = current.get("wand_logic_type")
			if not node_type: node_type = current.get("type")

			# Aggressive fallback: if this node has multiple outputs, treat it as a branching logic block
			outputs_all = adj.get(node_id, [])
			if outputs_all.size() > 1 and (instruction and (instruction.child_tier == null or instruction.child_tier.instructions.is_empty())):
				var fb_children = _get_children(wand_data, current, adj)
				if not fb_children.is_empty():
					instruction.child_tier = _compile_tree_tier(wand_data, fb_children, adj, 0)
					instruction.child_mode = "PARALLEL"
					instruction.type = SpellInstruction.TYPE_LOGIC_BLOCK
					print("WAND_COMPILER: auto-branch fallback applied for node=", node_id)
			
			if node_type == "logic_sequence" or node_type == "multicast": 
				# Example: A Multicast node in the Deck. 
				# It should execute its children IMMEDIATELY as one action.
				# So we compile its children into a child_tier of this instruction.
				var children = _get_children(wand_data, current, adj)
				if not children.is_empty():
					instruction.child_tier = _compile_tree_tier(wand_data, children, adj, 0)
					# Preserve execution mode so runtime can choose sequential vs parallel
					# Set child execution mode based on node type
					if node_type == "multicast":
						instruction.child_mode = "PARALLEL"
					else:
						instruction.child_mode = "SEQUENTIAL"
					# Treat branching nodes as logic blocks so their child_tier is executed
					# at cast time (compiled into the deck) rather than left to a projectile
					# trigger. This ensures multicast runs its children immediately/parallel
					# as part of the wand cast.
					instruction.type = SpellInstruction.TYPE_LOGIC_BLOCK
					# debug: explicit branch compiled

				# General fallback: if a node has multiple outputs but wasn't explicitly
				# marked as a branching node, treat it as a branching LOGIC_BLOCK as well.
				else:
					var outputs = adj.get(node_id, [])
					if outputs.size() > 1:
						children = _get_children(wand_data, current, adj)
						if not children.is_empty():
							instruction.child_tier = _compile_tree_tier(wand_data, children, adj, 0)
							instruction.child_mode = "PARALLEL"
							instruction.type = SpellInstruction.TYPE_LOGIC_BLOCK
							# debug: auto-branch compiled
					# debug: compiled branching node
			
			# Append to Deck
			# Skip Source nodes in the final deck usually, unless they have properties?
			if node_type != NODE_TYPE_SOURCE:
				if instruction:
					# If we have a pending child_tier from a previous source, attach it here.
					if pending_child_tier != null:
						instruction.child_tier = pending_child_tier
						instruction.child_mode = pending_child_mode
						# Mark that this child_tier should be executed immediately at cast time
						# (this handles the case where root/source branches should fire as part of the cast)
						instruction.child_exec_immediate = true
						pending_child_tier = null
						pending_child_mode = ""
					deck_instructions.append(instruction)
			
			# Move to NEXT node in the "Main Sequence".
			# For linear deck, we assume Port 0 is the "Next Card".
			# If a node has multiple outputs, usually:
			# - Multicast: Outputs are parallel. We might treat them all as children (Tree).
			# - Sequence: Outputs are sequential.
			# - Modifier: Output is the modified spell.
			
			# HYBRID LOGIC:
			# If it's a Modifier, we continue to the next node as the "Next Card".
			# If it's a Projectile, the next node is the "Next Card".
			# If it's a Trigger, the payload is in 'child_tier', and the next node out of Port 0 is "Next Card"? 
			# Actually, Triggers usually consume the card.
			
			current = _get_next_main_node(wand_data, current, adj)

	# Safely populate root_tier.instructions to ensure element types match
	program.root_tier.instructions.clear()
	for instr in deck_instructions:
		program.root_tier.instructions.append(instr)
	# mark compile version so runtime can detect stale caches
	program.compile_version = COMPILE_VERSION

	# Debug: print final deck summary
	print("WAND_COMPILER: compiled deck_count=", deck_instructions.size())
	for i in range(deck_instructions.size()):
		var ii = deck_instructions[i]
		var has_child = ii.child_tier != null and not ii.child_tier.instructions.is_empty()
		print("WAND_COMPILER: deck[", i, "] type=", ii.type, " has_child=", has_child)

	
	return program

# Compiles a subgraph as a Tree (Parallel execution)
static func _compile_tree_tier(wand_data: WandData, start_nodes: Array, adj: Dictionary, depth: int) -> ExecutionTier:
	var tier = ExecutionTier.new()
	if depth > 10: return tier
	
	for node in start_nodes:
		print("WAND_COMPILER: _compile_tree_tier depth=", depth, " node=", node.id)
		var instr = _create_instruction(wand_data, node, adj)
		if not instr: continue
		
		# Recursively compile children
		var children = _get_children(wand_data, node, adj)
		if not children.is_empty():
			instr.child_tier = _compile_tree_tier(wand_data, children, adj, depth + 1)
			
		tier.instructions.append(instr)
		
	return tier

static func _get_children(wand_data: WandData, node: Dictionary, adj: Dictionary) -> Array:
	var children = []
	var outputs = adj.get(str(node.id), [])
	outputs.sort_custom(func(a, b): return a.from_port < b.from_port)
	for out_obj in outputs:
		var n = _get_node_by_id(wand_data, out_obj.to_id)
		if n: children.append(n)
	return children

static func _get_next_main_node(wand_data: WandData, current: Dictionary, adj: Dictionary):
	# Gets the node connected to the first output port (Main Sequence)
	var outputs = adj.get(str(current.id), [])
	if outputs.is_empty(): return null
	
	# Assume Port 0 is the main flow
	# Filter for port 0? Or just take the first one?
	# Let's verify if we need port-specific logic. 
	# For now, take the first connection found.
	# But strictly, we should probably look for 'flow' port.
	# Assuming standard left-to-right flow where any output continues the chain
	# UNLESS it's a Branching node which we handled inside the loop.
	
	# If we handled the children as a Tree (logic_sequence), 
	# Does the Sequence node ALSO have a "Next" output?
	# Usually Sequence has multiple outputs.
	# If we compiled all outputs into child_tier, then there is NO next main node.
	# The Sequence consumes the flow.
	
	var node_type = current.get("wand_logic_type")
	if not node_type: node_type = current.get("type")
	
	if node_type == "logic_sequence" or node_type == "multicast":
		return null # Flow consumed by tree conversion
		
	if node_type == NODE_TYPE_TRIGGER or node_type == "trigger":
		# Trigger payload is in child_tier.
		# Does Trigger have a "Pass Through" or "Next" port?
		# Usually Trigger is an Action that Contains another Action.
		# It relies on the payload to do things. 
		# It sits in the deck. The next card is... 
		# If the graph continues AFTER the payload, is that the next card?
		# No, the graph defines the payload.
		return null 
	
	# Default (Modifiers, Projectiles that are just linear)
	# Find connection from Port 0 (Flow)
	for out in outputs:
		# If strict ports used: if out.from_port == 0: ...
		var n = _get_node_by_id(wand_data, out.to_id)
		if n: return n
		
	return null

static func _build_adjacency(wand_data: WandData) -> Dictionary:
	var adj = {}
	for node in wand_data.logic_nodes:
		adj[str(node.id)] = []
	
	for conn in wand_data.logic_connections:
		var from_id = str(conn.get("from_id", ""))
		var to_id = str(conn.get("to_id", ""))
		var from_port = int(conn.get("from_port", 0))
		if from_id in adj:
			adj[from_id].append({"to_id": to_id, "from_port": from_port})
			
	return adj

static func _detect_cycles(wand_data: WandData, adj: Dictionary) -> bool:
	var visited = {} # id -> true
	var recursion_stack = {} # id -> true
	
	for node in wand_data.logic_nodes:
		var id = str(node.id)
		if id not in visited:
			if _dfs_cycle_check(id, adj, visited, recursion_stack):
				return true
	return false

static func _dfs_cycle_check(current_id: String, adj: Dictionary, visited: Dictionary, stack: Dictionary) -> bool:
	visited[current_id] = true
	stack[current_id] = true
	
	if current_id in adj:
		for struct_obj in adj[current_id]:
			var neighbor_id = str(struct_obj.to_id)
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
		in_degree[str(node.id)] = 0
		
	for conn in wand_data.logic_connections:
		var to_id = str(conn.get("to_id", ""))
		in_degree[to_id] = in_degree.get(to_id, 0) + 1
		
	for node in wand_data.logic_nodes:
		var n_type = node.get("wand_logic_type")
		if not n_type: n_type = node.get("type")
		
		# If explicit source
		if n_type == NODE_TYPE_SOURCE:
			roots.append(node)
		
		# Allow Triggers to be roots if they have no inputs (Initial Trigger) 
		elif n_type == NODE_TYPE_TRIGGER and in_degree.get(str(node.id), 0) == 0:
			roots.append(node)
	
	return roots

static func _compile_linear_path(wand_data: WandData, current_node: Dictionary, adj: Dictionary, deck: Array[SpellInstruction], visited: Dictionary):
	var node_id = str(current_node.id)
	
	# Linear Graph Traversal: 
	# Add current node instruction to deck
	# Then move to next connected node in port order
	
	var node_type = current_node.get("wand_logic_type")
	if not node_type: node_type = current_node.get("type")
	
	# Skip Source/Generator nodes themselves, they are just start points
	if node_type != NODE_TYPE_SOURCE:
		var instr = _create_instruction(wand_data, current_node, adj)
		if instr:
			deck.append(instr)
			
			# If this node is a Trigger, we might need to compile its payload separately?
			# Current implementation of _create_instruction handles child_tier recursively 
			# IF we keep that logic.
			# But here we want a linear deck. 
			# If Trigger has a payload, it is EXECUTED when the trigger hits.
			# So it remains a child_tier.
			# But the connection AFTER the trigger (if any) continues the deck.
			# Wait. A Trigger usually consumes the connection.
			# Does a Trigger have a "Next" port and a "Payload" port?
			# Usually Trigger has 1 output: The Payload.
			# So a Trigger effectively ENDS the current sequence branch, and starts a new context.
			# So we do NOT continue traversing from a Trigger into the main deck?
			# Unless it's a "Pass Through" trigger?
			# Let's assume Trigger output = Payload. 
			# So we STOP linear traversal here for this branch.
			return 

	# Continue Traversal to next node in the chain
	var outputs = adj.get(node_id, [])
	# Sort by port
	outputs.sort_custom(func(a, b): return a.from_port < b.from_port)
	
	for out_obj in outputs:
		var next_node = _get_node_by_id(wand_data, out_obj.to_id)
		if next_node:
			# If branching (e.g. Multicast or Sequence), we visit all.
			# They added sequantially to the deck.
			_compile_linear_path(wand_data, next_node, adj, deck, visited)

static func _create_instruction(wand_data: WandData, node: Dictionary, adj: Dictionary) -> SpellInstruction:
	var node_type = node.get("wand_logic_type")
	if not node_type: node_type = node.get("type")
	
	var instr = SpellInstruction.new()
	var val = node.get("value", {})
	if val.is_empty(): val = node.get("wand_logic_value", {})
	
	instr.params = val.duplicate()
	
	if node_type == NODE_TYPE_ACTION or node_type == "action_projectile":
		instr.type = SpellInstruction.TYPE_PROJECTILE
		return instr
		
	elif node_type == NODE_TYPE_TRIGGER or node_type == "trigger":
		var trig_type = val.get("trigger_type", "timer")
		if trig_type == "collision": instr.type = SpellInstruction.TYPE_TRIGGER_COLLISION
		elif trig_type == "disappear": instr.type = SpellInstruction.TYPE_TRIGGER_DISAPPEAR
		else: instr.type = SpellInstruction.TYPE_TRIGGER_TIMER

		# Compile Payload (Recursive)
		# For the payload, we treat it as a sub-deck (tier)
		var output_objs = adj.get(str(node.id), [])
		var next_nodes = []
		for obj in output_objs:
			var n = _get_node_by_id(wand_data, obj.to_id)
			if n: next_nodes.append(n)
		
		# We need a new recursion for the payload, 
		# which creates a ExecutionTier valid for the trigger
		var payload_tier = ExecutionTier.new()
		var payload_deck: Array[SpellInstruction] = []
		for n in next_nodes:
			_compile_linear_path(wand_data, n, adj, payload_deck, {})
		
		# Safely populate payload_tier.instructions
		payload_tier.instructions.clear()
		for pi in payload_deck:
			payload_tier.instructions.append(pi)
		instr.child_tier = payload_tier
		instr.child_mode = "PARALLEL"
		
		return instr
		
	elif node_type.begins_with("modifier"):
		# Modifiers in the deck are just instructions that change stats? 
		# Or do they wrap the next instruction?
		# In Noita, a modifier is an item in the deck. 
		# SpellProcessor must handle it.
		# So verify we have a TYPE_MODIFIER?
		# SpellInstruction currently has TYPE_PROJECTILE, TYPE_TRIGGER...
		# Let's add TYPE_MODIFIER or just use PROJECTILE with special params?
		# Let's assume we can add a custom type or reuse Projectile with 0 damage/speed but modifiers.
		# But wait, SpellInstruction has a 'modifiers' array.
		# If we find a standalone modifier node in the graph, it should be an instruction in the deck.
		# When executed, it modifies the NEXT spell.
		# So we need SpellInstruction.TYPE_MODIFIER.
		# I should check SpellInstruction definition.
		instr.type = "MODIFIER" # Ad-hoc string type if enum not available, or I'll check/add it.
		return instr

	# Sequence?
	if node_type == "logic_sequence":
		# Sequence node is just a structural node in the graph to split flow.
		# It doesn't become an instruction itself.
		# Its children are added to the deck by the traversal loop in `_compile_linear_path`.
		return null
		
	return instr

static func _get_node_by_id(wand_data: WandData, id):
	var s_id = str(id)
	for node in wand_data.logic_nodes:
		if str(node.id) == s_id:
			return node
	return null
