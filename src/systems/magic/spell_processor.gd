extends Node
class_name SpellProcessor

const SCENE_PROJECTILE = preload("res://src/systems/magic/projectiles/projectile_standard.tscn")
const SCENE_TRIGGER_TIMER = preload("res://src/systems/magic/projectiles/trigger_timer.tscn")
const SCENE_TRIGGER_COLLISION = preload("res://src/systems/magic/projectiles/trigger_collision.tscn")
const SCENE_TRIGGER_DISAPPEAR = preload("res://src/systems/magic/projectiles/trigger_disappear.tscn")

class SpellRunner extends Node:
	var schedule: Array = [] # Array of [time, instruction, relative_pos, direction, parent_node, modifiers]
	var current_time: float = 0.0
	var casting_source: Node2D

	func _process(delta: float):
		current_time += delta
		var remaining = []
		for event in schedule:
			if event[0] <= current_time:
				# event format: [time, instr, pos, dir, parent, modifiers]
				var mods = []
				if event.size() >= 6:
					mods = event[5]
				print("RUNNER: current_time=", current_time, " trigger_time=", event[0], " instr=", event[1].type)
				SpellProcessor._spawn_instruction(event[1], event[4], event[2], event[3], casting_source, mods)
			else:
				remaining.append(event)

		schedule = remaining

		if schedule.is_empty():
			queue_free()

static func cast_spell(wand_data: WandData, source_entity: Node2D, direction: Vector2, start_pos: Vector2 = Vector2.INF) -> float:
	if not wand_data: return 0.0
	
	# 1. Check Cooldowns
	if wand_data.recharge_timer > 0.0 or wand_data.cast_delay_timer > 0.0 or wand_data.is_recharging:
		return 0.0

	# 2. Get/Compile Program
	# Force recompile on every cast to ensure compiler changes take effect
	var program = WandCompiler.compile(wand_data)
	wand_data.compiled_program = program
	
	if not program.is_valid:
		return 0.0
		
	var deck = program.root_tier.instructions
	if deck.is_empty():
		print("SpellProcessor: deck empty after compile; root_tier.instructions.size=", program.root_tier.instructions.size())
		# Also dump compiled program for diagnosis
		SpellProcessor.debug_print_schedule(program.root_tier)
		return 0.0

	# Debug: print deck contents (types and child tiers)
	print("SpellProcessor: compiled deck_count=", deck.size())
	for i in range(deck.size()):
		var d = deck[i]
		var child_exists = d.child_tier != null and not d.child_tier.instructions.is_empty()
		print("SpellProcessor: deck[", i, "] type=", d.type, " child_exists=", child_exists)

	var cast_origin = start_pos if start_pos != Vector2.INF else source_entity.global_position
	
	# 3. Execution (Deck Draw Loop)
	var active_modifiers = []
	var draw_count = 1
	var fired_any = false
	var accumulated_cast_delay = 0.0
	var accumulated_recharge_time = 0.0

	# debug: deck summary omitted
	
	# Safety brake
	var iterations = 0
	
	while draw_count > 0 and iterations < 50:
		iterations += 1
		
		# Check Deck Empty
		if wand_data.deck_index >= deck.size():
			# Trigger Recharge
			var final_recharge = max(0.01, program.total_recharge_time + accumulated_recharge_time)
			wand_data.trigger_recharge(final_recharge)
			draw_count = 0 # Stop casting
			break
			
		var instr = deck[wand_data.deck_index]
		
		# 4. Mana Check
		var cost = instr.params.get("mana_cost", 0.0) if instr.params is Dictionary else 0.0
		if wand_data.current_mana < cost:
			# Not enough mana. 
			# In Noita, if we can't afford the NEXT spell in a cast, we just stop.
			# But we DON'T necessarily trigger reload unless it was the end of the deck.
			# However, most players expect the wand to "think" it's empty if they hold fire.
			# To avoid a "dead lock" where deck_index is stuck on a spell you can't afford:
			# If we can't afford it, we don't advance the index, and we return.
			# Next frame, we try again.
			draw_count = 0
			break
			
		wand_data.current_mana -= cost
		wand_data.deck_index += 1
		
		# Process Instruction
		
		# Modifiers
		if instr.type == SpellInstruction.TYPE_MODIFIER:
			# Modifiers don't consume draw_count (usually in Noita modifiers draw 1 to replace themselves)
			# Effect: Add to active modifiers
			# And they draw another card? Yes.
			# So distinct from "Multicast" which ADDS to draw count.
			# A regular modifier consumes 1 draw slot but ADDS 1 draw slot? 
			# Basically it is "free" distinct from the projectile
			
			active_modifiers.append(instr)
			
			# Check mechanics: Does modifier consume mana? Yes.
			if instr.params is Dictionary:
				accumulated_cast_delay += instr.params.get("delay", 0.0)
				accumulated_recharge_time += instr.params.get("recharge", 0.0)
			
			# Usually modifier draws next spell automatically, so we DON'T decrement draw_count?
			# Correct.
			continue
			
		# Projectiles / Triggers (Action)
		if instr.type == SpellInstruction.TYPE_PROJECTILE or instr.type == SpellInstruction.TYPE_TRIGGER_TIMER or instr.type == SpellInstruction.TYPE_TRIGGER_COLLISION or instr.type == SpellInstruction.TYPE_TRIGGER_DISAPPEAR or instr.type == SpellInstruction.TYPE_LOGIC_BLOCK:
			
			if instr.type == SpellInstruction.TYPE_LOGIC_BLOCK:
				# Execute child tier sequentially and accumulate delays.
				if instr.child_tier:
					var child_total_delay = execute_tier(instr.child_tier, cast_origin, direction, source_entity, _get_world_root(), active_modifiers, instr.child_mode == "PARALLEL")
					# Child tier schedules may take time; ensure recharge waits for them
					accumulated_cast_delay += child_total_delay
					accumulated_recharge_time += child_total_delay
					# Optionally accumulate recharge modifiers from the logic block itself
					if instr.params is Dictionary:
						accumulated_recharge_time += instr.params.get("recharge", 0.0)
				else:
					# No child tier: nothing to run
					null
			else:
				# Combine instr.modifiers (if any from compiler) with active_modifiers
				var applied_modifiers = active_modifiers.duplicate()
				applied_modifiers.append_array(instr.modifiers)

				# For projectiles/triggers, child_tier is attached to the spawned instance
				# and will be executed by the instance when its trigger condition occurs.
				# Do NOT execute child_tier here at cast time for projectiles.

				# Spawn the projectile/trigger but with a duplicated instruction that
				# has child_tier cleared to avoid double-running payload when the
				# projectile's own trigger fires later.
				var spawn_instr = instr.duplicate()
				# If this instruction's child_tier was marked immediate (from a root/source pending attach),
				# execute it now and do NOT pass it to the spawned projectile (prevent double-run).
				if instr.child_exec_immediate and instr.child_tier and not instr.child_tier.instructions.is_empty():
					print("CAST: executing immediate child_tier for instr at deck_index=", wand_data.deck_index - 1)
					var child_total_delay = execute_tier(instr.child_tier, cast_origin, direction, source_entity, _get_world_root(), applied_modifiers, instr.child_mode == "PARALLEL")
					print("CAST: immediate child_tier total_delay=", child_total_delay)
					# Clear on the spawned instruction so projectile won't run it later
					spawn_instr.child_tier = null
				else:
					# Pass payload to projectile to execute on trigger
					# spawn_instr.child_tier remains set
					pass
				_spawn_instruction(spawn_instr, _get_world_root(), cast_origin, direction, source_entity, applied_modifiers)
			
			fired_any = true
			draw_count -= 1
			
			if instr.params is Dictionary:
				accumulated_cast_delay += instr.params.get("delay", 0.0)
				accumulated_recharge_time += instr.params.get("recharge", 0.0)
			
			# Recoil
			var recoil_force = 100.0 # Base
			if source_entity.has_method("apply_knockback"):
				source_entity.apply_knockback(-direction.normalized() * recoil_force)
	
	# End of Cast
	if fired_any:
		# Final Cast Delay is Wand Base + Sum of Spell Modifiers
		var final_delay = max(0.01, program.total_cast_delay + accumulated_cast_delay)
		wand_data.cast_delay_timer = final_delay
	
	return accumulated_cast_delay

static func _spawn_instruction(instr: SpellInstruction, parent: Node, pos: Vector2, dir: Vector2, source: Node2D = null, modifiers: Array = []):
	print("SPAWN: instr=", instr.type, " pos=", pos, " dir=", dir, " modifiers_count=", modifiers.size())
	# Only execute child_tier immediately if this instruction is a pure logic-block.
	# For projectiles/triggers, pass the child_tier to the spawned instance so it
	# can execute later when its trigger condition occurs.
	if instr.child_tier and not instr.child_tier.instructions.is_empty() and instr.type == SpellInstruction.TYPE_LOGIC_BLOCK:
		print("SPAWN: instr is LOGIC_BLOCK, executing child_tier immediately, modifiers_count=", modifiers.size())
		var child_total = execute_tier(instr.child_tier, pos, dir, source, parent, modifiers, instr.child_mode == "PARALLEL")
		print("SPAWN: executed child_tier total_delay=", child_total)
		instr.child_tier = null
	var scene_to_spawn = SCENE_PROJECTILE
	
	match instr.type:
		SpellInstruction.TYPE_PROJECTILE:
			scene_to_spawn = SCENE_PROJECTILE
		SpellInstruction.TYPE_TRIGGER_TIMER:
			scene_to_spawn = SCENE_TRIGGER_TIMER
		SpellInstruction.TYPE_TRIGGER_COLLISION:
			scene_to_spawn = SCENE_TRIGGER_COLLISION
		SpellInstruction.TYPE_TRIGGER_DISAPPEAR:
			scene_to_spawn = SCENE_TRIGGER_DISAPPEAR
		SpellInstruction.TYPE_LOGIC_BLOCK:
			# Not a scene. Just execute children.
			if instr.child_tier:
				# Recursively execute this tier immediately.
				# Modifiers context?
				# Modifiers applied to this block should apply to children? YES.
				# But execute_tier takes no modifiers arg.
				# We should probably pass them.
				# For now, simplistic recursion:
				execute_tier(instr.child_tier, pos, dir, source, parent, modifiers)
			return
		_:
			pass
			
	if not scene_to_spawn:
		return
		
	var instance = scene_to_spawn.instantiate()
	instance.global_position = pos
	
	# Apply Modifiers Logic (Spread)
	var spread = 0.0
	for mod in modifiers:
		var m_params = null
		if mod is SpellInstruction:
			m_params = mod.params
		elif mod is Dictionary:
			m_params = mod.get("params", mod)
		
		if m_params is Dictionary:
			spread += m_params.get("spread", 0.0)
	
	if spread != 0.0:
		var rad = deg_to_rad(spread)
		var angle = dir.angle() + randf_range(-rad, rad)
		instance.rotation = angle
	else:
		instance.rotation = dir.angle()
	
	# Apply Modifiers Logic (Stats)
	var final_params = instr.params.duplicate()
	for mod in modifiers:
		var m_params = null
		if mod is SpellInstruction:
			m_params = mod.params
		elif mod is Dictionary:
			m_params = mod.get("params", mod)
		
		if not (m_params is Dictionary):
			continue
		# Use has() so zero-values are respected
		if m_params.has("damage_add"):
			final_params["damage"] = final_params.get("damage", 10.0) + float(m_params["damage_add"])
		if m_params.has("speed_add"):
			final_params["speed"] = final_params.get("speed", 300.0) + float(m_params["speed_add"])
		if m_params.has("speed_multiplier"):
			final_params["speed"] = final_params.get("speed", 300.0) * float(m_params["speed_multiplier"])
		if m_params.has("multiplier"):
			final_params["speed"] = final_params.get("speed", 300.0) * float(m_params["multiplier"])
		if m_params.has("lifetime_add"):
			final_params["lifetime"] = final_params.get("lifetime", 1.0) + float(m_params["lifetime_add"])
		# Elemental or effect modifiers
		if m_params.has("element"):
			final_params["element"] = m_params["element"]
		if m_params.has("damage_multiplier"):
			final_params["damage"] = final_params.get("damage", 10.0) * float(m_params["damage_multiplier"])

	if instance.has_method("setup"):
		instance.setup(final_params, modifiers) # Keep passing modifications just in case
	
	if source and "caster" in instance:
		instance.caster = source

	if instance is CharacterBody2D:
		instance.collision_mask = LayerManager.LAYER_WORLD_0 | LayerManager.LAYER_NPC

	# Pass child tier for triggers: ensure all instances that support setup_trigger receive it
	if instr.child_tier and instance.has_method("setup_trigger"):
		# Pass modifiers directly to the trigger instance (avoid mutating shared child_tier)
		if modifiers and instr.child_tier:
			instance.setup_trigger(instr.child_tier, modifiers, instr.child_mode)
		else:
			instance.setup_trigger(instr.child_tier, [], instr.child_mode)
	
	parent.add_child(instance)

static func execute_tier(tier: ExecutionTier, position: Vector2, direction: Vector2, source: Node2D = null, world_context: Node = null, modifiers: Array = [], top_level_parallel: bool = false) -> float:
	if not tier or tier.instructions.is_empty():
		print("execute_tier: empty tier")
		return 0.0

	print("execute_tier: tier_count=", tier.instructions.size(), " modifiers=", modifiers.size())

	var world = world_context if world_context else _get_world_root()
	if not world: return 0.0

	# Instead of spawning everything immediately, schedule the tier's instructions
	# on a SpellRunner so branches are executed sequentially with delays between them.
	return schedule_tier(tier, position, direction, source, world, modifiers, top_level_parallel)


static func schedule_tier(tier: ExecutionTier, position: Vector2, direction: Vector2, source: Node2D, world_context: Node, modifiers: Array, top_level_parallel: bool=false) -> float:
	# Create a SpellRunner which will spawn instructions at the scheduled times
	var world = world_context if world_context else _get_world_root()
	if not world: return 0.0

	var runner = SpellRunner.new()
	runner.casting_source = source
	runner.schedule = []

	var total_added = _append_tier_to_runner(runner, tier, position, direction, world, modifiers, 0.0, top_level_parallel)

	# Add runner to the world so it processes its schedule
	world.add_child(runner)
	print("schedule_tier: added runner schedule_count=", runner.schedule.size(), " total_added=", total_added)
	return total_added


static func _append_tier_to_runner(runner: SpellRunner, tier: ExecutionTier, position: Vector2, direction: Vector2, parent: Node, modifiers: Array, base_offset: float, top_level_parallel: bool=false) -> float:
	# If caller requests top-level parallel, schedule each top instruction at the same base_offset
	if top_level_parallel:
		var max_added = 0.0
		for instr in tier.instructions:
			var tmp = ExecutionTier.new()
			tmp.instructions.clear()
			tmp.instructions.append(instr.duplicate())
			var combined_mods = modifiers.duplicate()
			if instr.modifiers:
				combined_mods.append_array(instr.modifiers)
			var added = _append_tier_to_runner(runner, tmp, position, direction, parent, combined_mods, base_offset, false)
			print("WAND_RUNNER_DBG: scheduled top-level parallel child at offset=", base_offset, " added_duration=", added, " child_type=", instr.type)
			if added > max_added:
				max_added = added
		return max_added

	var offset = base_offset
	var local_mods = modifiers.duplicate()
	for instr in tier.instructions:
		# Modifiers accumulate and apply to the next projectile in this tier
		if instr.type == SpellInstruction.TYPE_MODIFIER:
			local_mods.append(instr)
			# Modifiers don't schedule a separate event
			continue

		if instr.type == SpellInstruction.TYPE_LOGIC_BLOCK and instr.child_tier:
			# Prepare base combined modifiers: parent's modifiers + this instruction's modifiers
			var base_mods = local_mods.duplicate()
			if instr.modifiers:
				base_mods.append_array(instr.modifiers)

			if instr.child_mode == "PARALLEL":
				# Schedule each child branch at the same offset; advance by the longest child duration
				var max_added = 0.0
				for child_instr in instr.child_tier.instructions:
					var tmp = ExecutionTier.new()
					tmp.instructions.clear()
					# Duplicate the child (including nested child_tier) and force its top-level delay to 0
					var child_dup = child_instr.duplicate()
					if child_dup.params is Dictionary:
						child_dup.params["delay"] = 0.0
					tmp.instructions.append(child_dup)
					var combined_mods = base_mods.duplicate()
					if child_instr.modifiers:
						combined_mods.append_array(child_instr.modifiers)
					var added = _append_tier_to_runner(runner, tmp, position, direction, parent, combined_mods, offset, false)
					print("WAND_RUNNER_DBG: scheduled child at offset=", offset, " added_duration=", added, " child_type=", child_instr.type)
					if added > max_added:
						max_added = added
				offset += max_added
				# After a logic block, modifiers are not automatically consumed; keep local_mods
				continue
			else:
				# Sequential: append entire child tier at current offset
				var added_seq = _append_tier_to_runner(runner, instr.child_tier, position, direction, parent, base_mods, offset, false)
				offset += added_seq
				continue

		# For projectiles and triggers: schedule them with accumulated local_mods
		var combined_mods = local_mods.duplicate()
		if instr.modifiers:
			combined_mods.append_array(instr.modifiers)

		var sched_instr = instr.duplicate()
		runner.schedule.append([offset, sched_instr, position, direction, parent, combined_mods])

		# Consumed modifiers apply to this projectile only
		local_mods.clear()

		var instr_delay = 0.0
		if instr.params is Dictionary:
			instr_delay = float(instr.params.get("delay", 0.0))
		offset += instr_delay

	return offset - base_offset

static func _get_world_root() -> Node:
	var tree = Engine.get_main_loop() as SceneTree
	if not tree: return null
	return tree.current_scene

static func get_wand_stats(wand_data: WandData) -> Dictionary:
	if not wand_data: return {}
	
	var program = wand_data.compiled_program
	if not program:
		program = WandCompiler.compile(wand_data)
		wand_data.compiled_program = program
		
	if not program.is_valid: return {}
	
	var stats = {
		"mana_cost": program.total_mana_cost,
		"cast_delay": program.total_cast_delay,
		"recharge_time": program.total_recharge_time,
		"duration": program.total_cast_delay, # For UI compatibility
		"projectile_count": 0,
		"total_damage": 0.0,
		"simulated_mana_usage": 0.0
	}
	
	# Traverse Deck
	for instr in program.root_tier.instructions:
		_accumulate_stats_recursive(instr, stats)
		
	return stats

static func debug_print_schedule(tier: ExecutionTier) -> void:
	# Helper to dump how a tier would be scheduled (for debugging tree vs linear behavior)
	if not tier: 
		print("debug_print_schedule: no tier")
		return

	var runner = SpellRunner.new()
	runner.casting_source = null
	runner.schedule = []

	var total = _append_tier_to_runner(runner, tier, Vector2.ZERO, Vector2.RIGHT, _get_world_root(), [], 0.0, false)

	print("debug_print_schedule: total_time=", total)
	for e in runner.schedule:
		var t = e[0]
		var instr = e[1]
		print("  time:", t, " type:", instr.type, " params:", instr.params)


static func _accumulate_stats_recursive(instr: SpellInstruction, stats: Dictionary):
	if instr.params is Dictionary:
		stats.simulated_mana_usage += instr.params.get("mana_cost", 0.0)
		
		if instr.type == SpellInstruction.TYPE_PROJECTILE:
			stats.total_damage += instr.params.get("damage", 10.0)
	
	if instr.child_tier:
		for sub_instr in instr.child_tier.instructions:
			_accumulate_stats_recursive(sub_instr, stats)
