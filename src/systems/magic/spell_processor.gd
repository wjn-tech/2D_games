extends Node
class_name SpellProcessor

const SCENE_PROJECTILE = preload("res://src/systems/magic/projectiles/projectile_standard.tscn")
const SCENE_TRIGGER_TIMER = preload("res://src/systems/magic/projectiles/trigger_timer.tscn")
const SCENE_TRIGGER_COLLISION = preload("res://src/systems/magic/projectiles/trigger_collision.tscn")
const SCENE_TRIGGER_DISAPPEAR = preload("res://src/systems/magic/projectiles/trigger_disappear.tscn")

static func cast_spell(wand_data: WandData, source_entity: Node2D, direction: Vector2, start_pos: Vector2 = Vector2.INF):
	if not wand_data: return
	
	# Combat Juice: Recoil
	# Ideally magnitude depends on spell power, but flat 150 is a good feeling start
	var recoil_force = 150.0 * wand_data.recoil_multiplier
	if source_entity.has_method("apply_knockback") and recoil_force > 0:
		source_entity.apply_knockback(-direction.normalized() * recoil_force)
	
	var program = wand_data.compiled_program
	if not program:
		program = WandCompiler.compile(wand_data)
		wand_data.compiled_program = program
	
	if not program.is_valid:
		push_warning("Attempted to cast invalid wand: ", program.compilation_errors)
		return

	var cast_origin = start_pos if start_pos != Vector2.INF else source_entity.global_position
	execute_tier(program.root_tier, cast_origin, direction)

static func execute_tier(tier: ExecutionTier, position: Vector2, direction: Vector2, world_context: Node = null):
	if not tier: return
	
	var world = world_context
	if not world:
		world = _get_world_root()
		
	if not world: 
		push_error("SpellProcessor: Cannot find World/Level to spawn projectiles.")
		return

	for instr in tier.instructions:
		_spawn_instruction(instr, world, position, direction)

static func _spawn_instruction(instr: SpellInstruction, parent: Node, pos: Vector2, dir: Vector2):
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
		_:
			# Default fallback
			pass
			
	if not scene_to_spawn:
		return
		
	var instance = scene_to_spawn.instantiate()
	instance.global_position = pos
	
	# FIX 2: Revert random spread. Keep them identical.
	instance.rotation = dir.angle()
	
	if instance.has_method("setup"):
		instance.setup(instr.params, instr.modifiers)
	
	# Ensure projectiles can hit both the world and NPCs (Layer 1 | Layer 32)
	if instance is CharacterBody2D:
		instance.collision_mask = LayerManager.LAYER_WORLD_0 | LayerManager.LAYER_NPC
	
	if instr.child_tier and instance.has_method("setup_trigger"):
		instance.setup_trigger(instr.child_tier)
	
	parent.add_child(instance)

static func _get_world_root() -> Node:
	var tree = Engine.get_main_loop() as SceneTree
	if not tree: return null
	return tree.current_scene
