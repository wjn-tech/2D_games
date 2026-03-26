extends RefCounted
class_name WandCompiler

const COMPILE_VERSION: int = 3

const NODE_TYPE_TRIGGER = "trigger"
const NODE_TYPE_ACTION = "action_projectile"
const NODE_TYPE_MODIFIER = "modifier"
const NODE_TYPE_SOURCE = "generator"

const BRANCH_TYPE_PARALLEL = "PARALLEL"
const BRANCH_TYPE_SEQUENTIAL = "SEQUENTIAL"

const MIN_COMPILATION_DEPTH_LIMIT = 64

static func compile(wand_data: WandData) -> SpellProgram:
	var program = SpellProgram.new()
	program.is_valid = true

	if wand_data == null:
		program.is_valid = false
		program.compilation_errors.append("No WandData provided.")
		return program

	var adj = _build_adjacency(wand_data)
	if _detect_cycles(wand_data, adj):
		program.is_valid = false
		program.compilation_errors.append("Cycle detected in spell graph.")
		return program

	var base_mana_cost = 0.0
	var base_cast_delay = 0.0
	var base_recharge_time = 0.0
	if wand_data.embryo:
		base_mana_cost = wand_data.embryo.base_mana_cost
		base_cast_delay = wand_data.embryo.cast_delay
		base_recharge_time = wand_data.embryo.recharge_time

	program.total_cast_delay = base_cast_delay
	program.total_recharge_time = base_recharge_time

	var roots = _find_roots(wand_data, adj)
	if roots.is_empty() and not wand_data.logic_nodes.is_empty():
		roots = _find_orphan_roots(wand_data)
	if roots.is_empty() and not wand_data.logic_nodes.is_empty():
		roots.append(wand_data.logic_nodes[0])

	roots.sort_custom(_sort_nodes)

	program.root_tier.instructions.clear()
	for root in roots:
		var root_instr = _compile_root_entry(wand_data, root, adj, 0)
		if root_instr:
			program.root_tier.instructions.append(root_instr)

	var summary = _summarize_tier(program.root_tier)
	program.total_mana_cost = base_mana_cost + float(summary.get("mana_cost", 0.0))
	program.total_recharge_time = base_recharge_time + float(summary.get("recharge_delta", 0.0))

	var wand_capacity = 100.0
	if wand_data.embryo:
		wand_capacity = wand_data.embryo.mana_capacity

	if program.total_mana_cost > wand_capacity:
		program.is_valid = false
		program.compilation_errors.append("Mana cost %s exceeds capacity %s." % [program.total_mana_cost, wand_capacity])
		return program

	program.compile_version = COMPILE_VERSION

	print("WAND_COMPILER: compiled root_entries=", program.root_tier.instructions.size())
	for i in range(program.root_tier.instructions.size()):
		var instr = program.root_tier.instructions[i]
		var has_child = instr.child_tier != null and not instr.child_tier.instructions.is_empty()
		print("WAND_COMPILER: root[", i, "] type=", instr.type, " has_child=", has_child, " mode=", instr.child_mode)

	return program

static func _compile_root_entry(wand_data: WandData, root: Dictionary, adj: Dictionary, depth: int) -> SpellInstruction:
	var node_type = _get_node_type(root)
	if node_type == NODE_TYPE_SOURCE:
		var source_instr = SpellInstruction.new()
		var val = _get_node_value(root)
		source_instr.type = SpellInstruction.TYPE_LOGIC_BLOCK
		source_instr.params = val.duplicate()
		source_instr.child_exec_immediate = true
		var children = _get_children(wand_data, root, adj)
		source_instr.child_mode = _determine_child_mode(node_type, children.size())
		source_instr.child_tier = _compile_children_tier(wand_data, children, adj, depth + 1)
		if source_instr.child_tier and not source_instr.child_tier.instructions.is_empty():
			return source_instr
		return null

	return _compile_recursive_instruction(wand_data, root, adj, depth)

static func _compile_recursive_instruction(wand_data: WandData, node: Dictionary, adj: Dictionary, depth: int) -> SpellInstruction:
	if depth > _get_max_compilation_depth(wand_data):
		return null

	var instr = _create_instruction(node)
	if not instr:
		return null

	var node_type = _get_node_type(node)
	var children = _get_children(wand_data, node, adj)
	if not children.is_empty():
		instr.child_tier = _compile_children_tier(wand_data, children, adj, depth + 1)
		instr.child_mode = _determine_child_mode(node_type, children.size())
		if instr.type == SpellInstruction.TYPE_LOGIC_BLOCK:
			instr.child_exec_immediate = true

	return instr

static func _compile_children_tier(wand_data: WandData, start_nodes: Array, adj: Dictionary, depth: int) -> ExecutionTier:
	var tier = ExecutionTier.new()
	if depth > _get_max_compilation_depth(wand_data):
		return tier

	for node in start_nodes:
		var instr = _compile_recursive_instruction(wand_data, node, adj, depth)
		if instr:
			tier.instructions.append(instr)

	return tier

static func _create_instruction(node: Dictionary) -> SpellInstruction:
	var node_type = _get_node_type(node)
	var instr = SpellInstruction.new()
	var val = _get_node_value(node)
	instr.params = val.duplicate()

	if node_type == NODE_TYPE_ACTION:
		instr.type = SpellInstruction.TYPE_PROJECTILE
		return instr

	if node_type == NODE_TYPE_SOURCE:
		instr.type = SpellInstruction.TYPE_LOGIC_BLOCK
		return instr

	if node_type == NODE_TYPE_TRIGGER:
		var trig_type = str(instr.params.get("trigger_type", "timer"))
		if trig_type == "collision":
			instr.type = SpellInstruction.TYPE_TRIGGER_HIT
		elif trig_type == "disappear":
			instr.type = SpellInstruction.TYPE_TRIGGER_EXPIRATION
		else:
			instr.type = SpellInstruction.TYPE_TRIGGER_TIMER
			if trig_type == "cast" and not instr.params.has("duration"):
				instr.params["duration"] = 0.0
		return instr

	if node_type == "splitter" or node_type == "logic_splitter" or node_type == "multicast" or node_type == "logic_sequence":
		instr.type = SpellInstruction.TYPE_LOGIC_BLOCK
		return instr

	if node_type.begins_with(NODE_TYPE_MODIFIER):
		instr.type = SpellInstruction.TYPE_MODIFIER
		if not instr.params.has("type"):
			instr.params["type"] = node_type
		return instr

	return null

static func _determine_child_mode(node_type: String, child_count: int) -> String:
	if child_count <= 1:
		return BRANCH_TYPE_SEQUENTIAL
	if node_type == "logic_sequence":
		return BRANCH_TYPE_SEQUENTIAL
	if node_type == "splitter" or node_type == "logic_splitter" or node_type == "multicast" or node_type == NODE_TYPE_SOURCE:
		return BRANCH_TYPE_PARALLEL
	return BRANCH_TYPE_PARALLEL

static func _summarize_tier(tier: ExecutionTier) -> Dictionary:
	var summary = {
		"mana_cost": 0.0,
		"recharge_delta": 0.0,
	}
	if not tier:
		return summary

	for instr in tier.instructions:
		_summarize_instruction(instr, summary)

	return summary

static func _summarize_instruction(instr: SpellInstruction, summary: Dictionary) -> void:
	if not instr:
		return

	var mana_cost = float(instr.params.get("mana_cost", 0.0)) if instr.params is Dictionary else 0.0
	var recharge_delta = float(instr.params.get("recharge", 0.0)) if instr.params is Dictionary else 0.0

	if instr.type == SpellInstruction.TYPE_MODIFIER:
		summary["mana_cost"] += mana_cost
		summary["recharge_delta"] += recharge_delta
	elif instr.type == SpellInstruction.TYPE_PROJECTILE or instr.type == SpellInstruction.TYPE_TRIGGER_TIMER or instr.type == SpellInstruction.TYPE_TRIGGER_HIT or instr.type == SpellInstruction.TYPE_TRIGGER_EXPIRATION:
		summary["mana_cost"] += mana_cost

	if instr.child_tier:
		for child in instr.child_tier.instructions:
			_summarize_instruction(child, summary)

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
	var visited = {}
	var recursion_stack = {}

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
		for edge in adj[current_id]:
			var neighbor_id = str(edge.to_id)
			if neighbor_id not in visited:
				if _dfs_cycle_check(neighbor_id, adj, visited, stack):
					return true
			elif neighbor_id in stack:
				return true

	stack.erase(current_id)
	return false

static func _find_roots(wand_data: WandData, adj: Dictionary) -> Array:
	var roots = []
	var in_degree = {}
	for node in wand_data.logic_nodes:
		in_degree[str(node.id)] = 0

	for conn in wand_data.logic_connections:
		var to_id = str(conn.get("to_id", ""))
		in_degree[to_id] = in_degree.get(to_id, 0) + 1

	for node in wand_data.logic_nodes:
		var node_type = _get_node_type(node)
		if node_type == NODE_TYPE_SOURCE:
			roots.append(node)
		elif node_type == NODE_TYPE_TRIGGER and in_degree.get(str(node.id), 0) == 0:
			roots.append(node)

	return roots

static func _find_orphan_roots(wand_data: WandData) -> Array:
	var roots = []
	var in_degree = {}
	for node in wand_data.logic_nodes:
		in_degree[str(node.id)] = 0
	for conn in wand_data.logic_connections:
		var to_id = str(conn.get("to_id", ""))
		in_degree[to_id] = in_degree.get(to_id, 0) + 1
	for node in wand_data.logic_nodes:
		if in_degree.get(str(node.id), 0) == 0:
			roots.append(node)
	return roots

static func _get_children(wand_data: WandData, node: Dictionary, adj: Dictionary) -> Array:
	var children = []
	var outputs = adj.get(str(node.id), [])
	outputs.sort_custom(func(a, b): return int(a.from_port) < int(b.from_port))
	for edge in outputs:
		var child = _get_node_by_id(wand_data, edge.to_id)
		if not child.is_empty():
			children.append(child)
	return children

static func _get_max_compilation_depth(wand_data: WandData) -> int:
	if wand_data == null:
		return MIN_COMPILATION_DEPTH_LIMIT
	return max(MIN_COMPILATION_DEPTH_LIMIT, wand_data.logic_nodes.size() + 4)

static func _get_node_by_id(wand_data: WandData, id) -> Dictionary:
	var target_id = str(id)
	for node in wand_data.logic_nodes:
		if str(node.id) == target_id:
			return node
	return {}

static func _get_node_type(node: Dictionary) -> String:
	var node_type = node.get("wand_logic_type")
	if not node_type:
		node_type = node.get("type", "")
	return str(node_type)

static func _get_node_value(node: Dictionary) -> Dictionary:
	var val = node.get("value", {})
	if val is Dictionary and val.is_empty():
		val = node.get("wand_logic_value", {})
	if val is Dictionary:
		return val
	return {}

static func _sort_nodes(a: Dictionary, b: Dictionary) -> bool:
	var pos_a = a.get("position", Vector2.ZERO)
	var pos_b = b.get("position", Vector2.ZERO)
	if pos_a is Vector2 and pos_b is Vector2:
		if not is_equal_approx(pos_a.y, pos_b.y):
			return pos_a.y < pos_b.y
		if not is_equal_approx(pos_a.x, pos_b.x):
			return pos_a.x < pos_b.x
	return int(a.get("id", 0)) < int(b.get("id", 0))
