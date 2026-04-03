extends Node
class_name SpellProcessor

class SpellRunner extends Node:
	var schedule: Array = []
	var current_time: float = 0.0
	var casting_source: Node = null
	var wand_data: WandData
	var world_parent: Node
	var origin_position: Vector2 = Vector2.ZERO
	var origin_direction: Vector2 = Vector2.RIGHT
	var follow_source_transform: bool = false
	var recharge_duration: float = -1.0

	func _process(delta: float) -> void:
		current_time += delta
		var remaining: Array = []
		for event in schedule:
			var trigger_time = float(event.get("delay", 0.0))
			if trigger_time <= current_time:
				var spawn_position = origin_position
				var spawn_direction = origin_direction
				var live_source: Node2D = null
				if is_instance_valid(casting_source) and casting_source is Node2D:
					live_source = casting_source as Node2D
				if follow_source_transform:
					var live_transform = SpellProcessor._resolve_emission_transform(live_source, origin_position, origin_direction)
					spawn_position = live_transform.get("position", origin_position)
					spawn_direction = live_transform.get("direction", origin_direction)
				SpellProcessor._spawn_emission_record(event.get("record", {}), world_parent, spawn_position, spawn_direction, live_source, wand_data)
			else:
				remaining.append(event)

		schedule = remaining
		if schedule.is_empty():
			if recharge_duration >= 0.0 and wand_data:
				wand_data.trigger_recharge(recharge_duration)
				recharge_duration = -1.0
			queue_free()

static func cast_spell(wand_data: WandData, source_entity: Node2D, direction: Vector2, start_pos: Vector2 = Vector2.INF) -> float:
	if not wand_data:
		return 0.0
	if wand_data.recharge_timer > 0.0 or wand_data.cast_delay_timer > 0.0 or wand_data.is_recharging:
		return 0.0

	var program = WandCompiler.compile(wand_data)
	wand_data.compiled_program = program
	print("SpellProcessor: Casting wand ", wand_data.id, " | Program Valid: ", program.is_valid, " | Root Entries: ", program.root_tier.instructions.size())

	if not program.is_valid:
		print("SpellProcessor: Program invalid! Errors: ", program.compilation_errors)
		if wand_data.id != "starter_wand":
			return 0.0

	if program.root_tier.instructions.is_empty() and wand_data.id == "starter_wand":
		var fallback = SpellInstruction.new()
		fallback.type = SpellInstruction.TYPE_PROJECTILE
		fallback.params = {"speed": 800.0, "damage": 10.0, "mana_cost": 0.0}
		program.root_tier.instructions.append(fallback)

	if program.root_tier.instructions.is_empty():
		print("SpellProcessor: empty root tier after compile")
		return 0.0

	var plan = _build_cast_plan(program, wand_data)
	if plan.get("emissions", []).is_empty():
		print("SpellProcessor: no root-cycle emissions compiled")
		return 0.0

	var cycle_mana_cost = _get_cycle_mana_cost(wand_data, float(plan.get("total_mana_cost", 0.0)))
	if wand_data.current_mana < cycle_mana_cost:
		print("SpellProcessor: Not enough mana for cast cycle! cost=", cycle_mana_cost, " current=", wand_data.current_mana)
		return 0.0

	_apply_cycle_mana_cost(wand_data, cycle_mana_cost)

	var cast_origin = start_pos if start_pos != Vector2.INF else source_entity.global_position
	var world = _get_world_root()
	if not world:
		return 0.0

	var max_fire_delay = float(plan.get("max_fire_delay", 0.0))
	var recharge_time = float(plan.get("recharge_time", 0.01))
	var total_cycle_duration = max_fire_delay + recharge_time
	wand_data.cast_delay_timer = max(0.01, total_cycle_duration)

	_schedule_emissions(plan.get("emissions", []), cast_origin, direction, source_entity, world, wand_data, recharge_time, true)

	var recoil_force = 100.0 * float(wand_data.recoil_multiplier)
	if source_entity and source_entity.has_method("apply_knockback"):
		source_entity.apply_knockback(-_normalize_direction(direction) * recoil_force)

	return total_cycle_duration

static func execute_tier(tier: ExecutionTier, position: Vector2, direction: Vector2, source: Node2D = null, world_context: Node = null, modifiers: Array = [], top_level_parallel: bool = false, wand_data: WandData = null) -> float:
	if not tier or tier.instructions.is_empty():
		print("execute_tier: empty tier")
		return 0.0

	var world = world_context if world_context else _get_world_root()
	if not world:
		return 0.0

	var emissions: Array = []
	var summary = _make_summary()
	var ctx = _create_context(modifiers, [], true, true, 0.0)
	var mode = "PARALLEL" if top_level_parallel else "SEQUENTIAL"
	_evaluate_tier(tier, ctx, mode, emissions, summary, false)
	var max_delay = _get_max_emission_delay(emissions)
	_schedule_emissions(emissions, position, direction, source, world, wand_data, -1.0)
	return max_delay

static func execute_continuation(continuation: Dictionary, position: Vector2, direction: Vector2, source: Node2D = null, world_context: Node = null, wand_data: WandData = null) -> float:
	var emissions = continuation.get("emissions", [])
	if emissions.is_empty():
		return 0.0

	var world = world_context if world_context else _get_world_root()
	if not world:
		return 0.0

	var max_delay = _get_max_emission_delay(emissions)
	_schedule_emissions(emissions, position, direction, source, world, wand_data, -1.0)
	return max_delay

static func _build_cast_plan(program: SpellProgram, wand_data: WandData) -> Dictionary:
	var summary = _make_summary()
	var emissions: Array = []
	var base_delay = _get_base_cast_delay(wand_data)

	for root_instr in program.root_tier.instructions:
		var root_ctx = _create_context([], [], true, true, base_delay)
		_evaluate_instruction(root_instr, root_ctx, emissions, summary, true)

	return {
		"emissions": emissions,
		"total_mana_cost": _get_base_mana_cost(wand_data) + float(summary.get("total_mana_cost", 0.0)),
		"recharge_time": max(0.01, _get_base_recharge_time(wand_data) + float(summary.get("recharge_delta", 0.0))),
		"max_fire_delay": float(summary.get("root_max_fire_delay", 0.0)),
	}

static func _evaluate_tier(tier: ExecutionTier, context: Dictionary, mode: String, emission_target: Array, summary: Dictionary, is_root_cycle: bool) -> Dictionary:
	if not tier or tier.instructions.is_empty() or not context.get("enabled", true):
		return context

	if mode == "PARALLEL":
		for instr in tier.instructions:
			var branch_ctx = _inherit_context(context)
			_evaluate_instruction(instr, branch_ctx, emission_target, summary, is_root_cycle)
		return context

	var current_ctx = context
	for instr in tier.instructions:
		current_ctx = _evaluate_instruction(instr, current_ctx, emission_target, summary, is_root_cycle)
	return current_ctx

static func _evaluate_instruction(instr: SpellInstruction, context: Dictionary, emission_target: Array, summary: Dictionary, is_root_cycle: bool) -> Dictionary:
	if not instr or not context.get("enabled", true):
		return context

	if instr.type == SpellInstruction.TYPE_MODIFIER:
		return _evaluate_modifier(instr, context, emission_target, summary, is_root_cycle)

	if instr.type == SpellInstruction.TYPE_PROJECTILE or instr.type == SpellInstruction.TYPE_TRIGGER_TIMER or instr.type == SpellInstruction.TYPE_TRIGGER_HIT or instr.type == SpellInstruction.TYPE_TRIGGER_EXPIRATION:
		return _evaluate_materialization(instr, context, emission_target, summary, is_root_cycle)

	if instr.type == SpellInstruction.TYPE_LOGIC_BLOCK:
		if not instr.child_tier or instr.child_tier.instructions.is_empty():
			return context
		var child_ctx = _inherit_context(context)
		return _evaluate_tier(instr.child_tier, child_ctx, instr.child_mode, emission_target, summary, is_root_cycle)

	return context

static func _evaluate_modifier(instr: SpellInstruction, context: Dictionary, emission_target: Array, summary: Dictionary, is_root_cycle: bool) -> Dictionary:
	var next_ctx = _duplicate_context(context)
	next_ctx["local_load"].append(instr)
	_accumulate_mana(summary, _get_instruction_mana_value(instr))
	_accumulate_recharge(summary, _get_instruction_recharge_value(instr))
	if next_ctx.get("delay_enable", true):
		next_ctx["time_offset"] = float(next_ctx.get("time_offset", 0.0)) + _get_instruction_delay_value(instr)

	if instr.child_tier and not instr.child_tier.instructions.is_empty():
		var child_ctx = _inherit_context(next_ctx)
		return _evaluate_tier(instr.child_tier, child_ctx, instr.child_mode, emission_target, summary, is_root_cycle)

	return next_ctx

static func _evaluate_materialization(instr: SpellInstruction, context: Dictionary, emission_target: Array, summary: Dictionary, is_root_cycle: bool) -> Dictionary:
	var applied_modifiers = _get_effective_load(context)
	if instr.modifiers:
		applied_modifiers.append_array(instr.modifiers)

	var fire_delay = max(0.0, float(context.get("time_offset", 0.0)) + _get_instruction_delay_value(instr))
	_accumulate_mana(summary, _get_instruction_mana_value(instr))

	var continuation = {}
	if _is_trigger_instruction(instr) and instr.child_tier and not instr.child_tier.instructions.is_empty():
		continuation = _build_trigger_continuation(instr, summary)

	var record = {
		"instruction": instr.duplicate(),
		"applied_modifiers": applied_modifiers,
		"fire_delay": fire_delay,
		"continuation": continuation,
	}
	emission_target.append(record)
	if is_root_cycle:
		summary["root_max_fire_delay"] = max(float(summary.get("root_max_fire_delay", 0.0)), fire_delay)

	var next_ctx = _create_context([], [], true, context.get("delay_enable", true), fire_delay)
	if not _is_trigger_instruction(instr) and instr.child_tier and not instr.child_tier.instructions.is_empty():
		return _evaluate_tier(instr.child_tier, next_ctx, instr.child_mode, emission_target, summary, is_root_cycle)

	return next_ctx

static func _build_trigger_continuation(instr: SpellInstruction, summary: Dictionary) -> Dictionary:
	var continuation = {
		"emissions": [],
		"delay_enable": false,
	}
	if not instr.child_tier or instr.child_tier.instructions.is_empty():
		return continuation

	var payload_ctx = _create_context([], [], true, false, 0.0)
	_evaluate_tier(instr.child_tier, payload_ctx, instr.child_mode, continuation["emissions"], summary, false)
	return continuation

static func _schedule_emissions(emissions: Array, position: Vector2, direction: Vector2, source: Node = null, world_context: Node = null, wand_data: WandData = null, recharge_duration: float = -1.0, follow_source_transform: bool = false) -> void:
	if emissions.is_empty():
		if recharge_duration >= 0.0 and wand_data:
			wand_data.trigger_recharge(recharge_duration)
		return

	var normalized_direction = _normalize_direction(direction)
	var delayed_events: Array = []
	var source_node2d: Node2D = null
	if is_instance_valid(source) and source is Node2D:
		source_node2d = source as Node2D
	for record in emissions:
		var fire_delay = float(record.get("fire_delay", 0.0))
		if fire_delay <= 0.0:
			_spawn_emission_record(record, world_context, position, normalized_direction, source_node2d, wand_data)
		else:
			delayed_events.append({"delay": fire_delay, "record": record})

	if delayed_events.is_empty():
		if recharge_duration >= 0.0 and wand_data:
			wand_data.trigger_recharge(recharge_duration)
		return

	var runner = SpellRunner.new()
	runner.schedule = delayed_events
	runner.casting_source = source
	runner.wand_data = wand_data
	runner.world_parent = world_context
	runner.origin_position = position
	runner.origin_direction = normalized_direction
	runner.follow_source_transform = follow_source_transform
	runner.recharge_duration = recharge_duration
	world_context.add_child(runner)

static func _resolve_emission_transform(source: Node = null, fallback_position: Vector2 = Vector2.ZERO, fallback_direction: Vector2 = Vector2.RIGHT) -> Dictionary:
	var resolved_position = fallback_position
	var resolved_direction = _normalize_direction(fallback_direction)
	if not is_instance_valid(source) or not (source is Node2D):
		return {"position": resolved_position, "direction": resolved_direction}
	var source_node := source as Node2D

	if source_node.has_method("get_spell_spawn_transform"):
		var spawn_transform = source_node.call("get_spell_spawn_transform")
		if spawn_transform is Dictionary:
			if spawn_transform.get("position") is Vector2:
				resolved_position = spawn_transform.get("position")
			if spawn_transform.get("direction") is Vector2:
				resolved_direction = _normalize_direction(spawn_transform.get("direction"))
			return {"position": resolved_position, "direction": resolved_direction}

	resolved_position = source_node.global_position
	resolved_direction = Vector2.RIGHT.rotated(source_node.global_rotation)
	return {"position": resolved_position, "direction": _normalize_direction(resolved_direction)}

static func _spawn_emission_record(record: Dictionary, parent: Node, position: Vector2, direction: Vector2, source: Node = null, wand_data: WandData = null) -> void:
	var instr = record.get("instruction") as SpellInstruction
	if not instr:
		return

	var scene_to_spawn = _resolve_scene_for_instruction(instr)
	if not scene_to_spawn:
		print("SpellProcessor: Instruction has no scene mapped: ", instr.type)
		return

	var spawned_node = scene_to_spawn.instantiate()
	if not spawned_node:
		print("SpellProcessor: Failed to instantiate scene for type: ", instr.type)
		return

	var attach_parent = parent if parent else _get_world_root()
	if not attach_parent:
		return
	attach_parent.add_child(spawned_node)

	spawned_node.global_position = position
	var source_node2d: Node2D = null
	if is_instance_valid(source) and source is Node2D:
		source_node2d = source as Node2D
	if source_node2d and "caster" in spawned_node:
		spawned_node.caster = source_node2d
	if source_node2d and spawned_node is PhysicsBody2D and source_node2d is PhysicsBody2D:
		(spawned_node as PhysicsBody2D).add_collision_exception_with(source_node2d)

	var applied_modifiers = record.get("applied_modifiers", [])
	var spread = _get_total_spread(applied_modifiers)
	var normalized_direction = _normalize_direction(direction)
	if spread != 0.0:
		var rad = deg_to_rad(spread)
		var angle = normalized_direction.angle() + randf_range(-rad, rad)
		spawned_node.rotation = angle
	else:
		spawned_node.rotation = normalized_direction.angle()

	var final_params = _build_final_params(instr.params, applied_modifiers)
	if source_node2d and source_node2d.has_method("get_combat_damage_multiplier"):
		var damage_multiplier := maxf(0.0, float(source_node2d.call("get_combat_damage_multiplier")))
		final_params["damage"] = float(final_params.get("damage", 10.0)) * damage_multiplier
	if source_node2d and "caster" in spawned_node:
		spawned_node.caster = source_node2d

	if spawned_node.has_method("setup"):
		spawned_node.setup(final_params, applied_modifiers)

	if spawned_node is CharacterBody2D and LayerManager:
		var source_layer = LayerManager.active_layer
		if source_node2d and source_node2d.has_meta("current_layer"):
			source_layer = int(source_node2d.get_meta("current_layer"))
		var target_mask := LayerManager.LAYER_PLAYER | LayerManager.LAYER_NPC
		if source_node2d and source_node2d.is_in_group("player"):
			target_mask = LayerManager.LAYER_NPC
		elif source_node2d and source_node2d.is_in_group("npcs"):
			target_mask = LayerManager.LAYER_PLAYER
		spawned_node.collision_mask = LayerManager.get_world_bit(source_layer) | target_mask

	var continuation = record.get("continuation", {})
	if continuation is Dictionary and spawned_node.has_method("setup_trigger"):
		spawned_node.setup_trigger(continuation, wand_data)

static func _resolve_scene_for_instruction(instr: SpellInstruction):
	if instr.type == SpellInstruction.TYPE_PROJECTILE or instr.type == "PROJECTILE" or instr.type == "action_projectile":
		if instr.params is Dictionary and instr.params.get("projectile_id") == "healing_circle":
			return load("res://src/systems/magic/projectiles/projectile_healing_circle.tscn")
		return load("res://src/systems/magic/projectiles/projectile_standard.tscn")
	if instr.type == SpellInstruction.TYPE_TRIGGER_TIMER:
		return load("res://src/systems/magic/projectiles/spell_trigger_timer.tscn")
	if instr.type == SpellInstruction.TYPE_TRIGGER_HIT:
		return load("res://src/systems/magic/projectiles/spell_trigger_hit.tscn")
	if instr.type == SpellInstruction.TYPE_TRIGGER_EXPIRATION:
		return load("res://src/systems/magic/projectiles/spell_trigger_expiration.tscn")
	return null

static func _build_final_params(base_params: Variant, modifiers: Array) -> Dictionary:
	var final_params = base_params.duplicate() if base_params is Dictionary else {}
	for mod in modifiers:
		var mod_params = _get_modifier_params(mod)
		if not (mod_params is Dictionary):
			continue
		if mod_params.has("damage_add"):
			final_params["damage"] = float(final_params.get("damage", 10.0)) + float(mod_params["damage_add"])
		if mod_params.has("speed_add"):
			final_params["speed"] = float(final_params.get("speed", 300.0)) + float(mod_params["speed_add"])
		if mod_params.has("speed_multiplier"):
			final_params["speed"] = float(final_params.get("speed", 300.0)) * float(mod_params["speed_multiplier"])
		if mod_params.has("multiplier"):
			final_params["speed"] = float(final_params.get("speed", 300.0)) * float(mod_params["multiplier"])
		if mod_params.has("lifetime_add"):
			final_params["lifetime"] = float(final_params.get("lifetime", 1.0)) + float(mod_params["lifetime_add"])
		if mod_params.has("element"):
			final_params["element"] = mod_params["element"]
		if mod_params.has("damage_multiplier"):
			final_params["damage"] = float(final_params.get("damage", 10.0)) * float(mod_params["damage_multiplier"])
	return final_params

static func _get_total_spread(modifiers: Array) -> float:
	var spread = 0.0
	for mod in modifiers:
		var mod_params = _get_modifier_params(mod)
		if mod_params is Dictionary:
			spread += float(mod_params.get("spread", 0.0))
	return spread

static func _create_context(inherited_load: Array = [], local_load: Array = [], enabled: bool = true, delay_enable: bool = true, time_offset: float = 0.0) -> Dictionary:
	return {
		"inherited_load": inherited_load.duplicate(),
		"local_load": local_load.duplicate(),
		"enabled": enabled,
		"delay_enable": delay_enable,
		"time_offset": time_offset,
	}

static func _duplicate_context(context: Dictionary) -> Dictionary:
	return _create_context(
		context.get("inherited_load", []),
		context.get("local_load", []),
		context.get("enabled", true),
		context.get("delay_enable", true),
		float(context.get("time_offset", 0.0))
	)

static func _inherit_context(context: Dictionary, delay_enable_override: Variant = null, time_offset_override: Variant = null, clear_load: bool = false) -> Dictionary:
	var inherited = [] if clear_load else _get_effective_load(context)
	var delay_enable = context.get("delay_enable", true) if delay_enable_override == null else delay_enable_override
	var time_offset = float(context.get("time_offset", 0.0)) if time_offset_override == null else float(time_offset_override)
	return _create_context(inherited, [], context.get("enabled", true), delay_enable, time_offset)

static func _get_effective_load(context: Dictionary) -> Array:
	var combined = context.get("inherited_load", []).duplicate()
	combined.append_array(context.get("local_load", []))
	return combined

static func _make_summary() -> Dictionary:
	return {
		"total_mana_cost": 0.0,
		"recharge_delta": 0.0,
		"root_max_fire_delay": 0.0,
	}

static func _accumulate_mana(summary: Dictionary, amount: float) -> void:
	summary["total_mana_cost"] = float(summary.get("total_mana_cost", 0.0)) + amount

static func _accumulate_recharge(summary: Dictionary, amount: float) -> void:
	summary["recharge_delta"] = float(summary.get("recharge_delta", 0.0)) + amount

static func _get_instruction_mana_value(instr: SpellInstruction) -> float:
	if not instr or not (instr.params is Dictionary):
		return 0.0
	return float(instr.params.get("mana_cost", 0.0))

static func _get_instruction_delay_value(instr: SpellInstruction) -> float:
	if not instr or not (instr.params is Dictionary):
		return 0.0
	return float(instr.params.get("delay", 0.0))

static func _get_instruction_recharge_value(instr: SpellInstruction) -> float:
	if not instr or not (instr.params is Dictionary):
		return 0.0
	return float(instr.params.get("recharge", 0.0))

static func _get_modifier_params(modifier) -> Variant:
	if modifier is SpellInstruction:
		return modifier.params
	if modifier is Dictionary:
		return modifier.get("params", modifier)
	return null

static func _is_trigger_instruction(instr: SpellInstruction) -> bool:
	return instr and (instr.type == SpellInstruction.TYPE_TRIGGER_TIMER or instr.type == SpellInstruction.TYPE_TRIGGER_HIT or instr.type == SpellInstruction.TYPE_TRIGGER_EXPIRATION)

static func _get_base_cast_delay(wand_data: WandData) -> float:
	if wand_data and wand_data.embryo:
		return float(wand_data.embryo.cast_delay)
	return 0.0

static func _get_base_recharge_time(wand_data: WandData) -> float:
	if wand_data and wand_data.embryo:
		return float(wand_data.embryo.recharge_time)
	return 0.0

static func _get_base_mana_cost(wand_data: WandData) -> float:
	if wand_data and wand_data.embryo:
		return float(wand_data.embryo.base_mana_cost)
	return 0.0

static func _get_cycle_mana_cost(wand_data: WandData, compiled_cost: float) -> float:
	if wand_data and wand_data.id == "starter_wand":
		return 0.0
	return compiled_cost

static func _apply_cycle_mana_cost(wand_data: WandData, cost: float) -> void:
	if not wand_data:
		return
	wand_data.current_mana -= cost
	if wand_data.embryo:
		wand_data.current_mana = clamp(wand_data.current_mana, 0.0, float(wand_data.embryo.mana_capacity))
	print("SpellProcessor: Consumed cycle mana. Remaining=", wand_data.current_mana, " cost=", cost)

static func _get_max_emission_delay(emissions: Array) -> float:
	var max_delay = 0.0
	for record in emissions:
		max_delay = max(max_delay, float(record.get("fire_delay", 0.0)))
	return max_delay

static func _normalize_direction(direction: Vector2) -> Vector2:
	if direction == Vector2.ZERO:
		return Vector2.RIGHT
	return direction.normalized()

static func _get_world_root() -> Node:
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	var scene = tree.current_scene
	if not scene:
		return null
	var proj_root = scene.find_child("Projectiles", true, false)
	if proj_root:
		return proj_root
	var entities = scene.find_child("Entities", true, false)
	if entities:
		return entities
	return scene

static func get_wand_stats(wand_data: WandData) -> Dictionary:
	if not wand_data:
		return {}

	var program = wand_data.compiled_program
	if not program:
		program = WandCompiler.compile(wand_data)
		wand_data.compiled_program = program
	if not program.is_valid:
		return {}

	var plan = _build_cast_plan(program, wand_data)
	var stats = {
		"mana_cost": float(plan.get("total_mana_cost", 0.0)),
		"cast_delay": float(plan.get("max_fire_delay", 0.0)),
		"recharge_time": float(plan.get("recharge_time", 0.0)),
		"duration": float(plan.get("max_fire_delay", 0.0)),
		"projectile_count": 0,
		"total_damage": 0.0,
		"simulated_mana_usage": float(plan.get("total_mana_cost", 0.0)),
	}
	_accumulate_emission_stats(plan.get("emissions", []), stats)
	return stats

static func debug_build_cast_plan(wand_data: WandData) -> Dictionary:
	if not wand_data:
		return {}
	var program = WandCompiler.compile(wand_data)
	if not program.is_valid:
		return {
			"is_valid": false,
			"errors": program.compilation_errors,
		}
	var plan = _build_cast_plan(program, wand_data)
	plan["is_valid"] = true
	plan["errors"] = []
	return plan

static func debug_print_schedule(tier: ExecutionTier) -> void:
	if not tier:
		print("debug_print_schedule: no tier")
		return
	var emissions: Array = []
	var summary = _make_summary()
	var ctx = _create_context([], [], true, true, 0.0)
	_evaluate_tier(tier, ctx, "PARALLEL", emissions, summary, false)
	print("debug_print_schedule: total_time=", _get_max_emission_delay(emissions))
	for record in emissions:
		var instr = record.get("instruction") as SpellInstruction
		print("  time:", record.get("fire_delay", 0.0), " type:", instr.type if instr else "null", " params:", instr.params if instr else {})

static func _accumulate_emission_stats(emissions: Array, stats: Dictionary) -> void:
	for record in emissions:
		var instr = record.get("instruction") as SpellInstruction
		if not instr:
			continue
		stats["projectile_count"] += 1
		var params = _build_final_params(instr.params, record.get("applied_modifiers", []))
		stats["total_damage"] += float(params.get("damage", 10.0))
		var continuation = record.get("continuation", {})
		if continuation is Dictionary:
			_accumulate_emission_stats(continuation.get("emissions", []), stats)
