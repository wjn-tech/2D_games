extends Node

const VFX_SCENE = preload("res://src/systems/magic/vfx/spell_absorption_vfx.gd")

func handle_npc_death(npc: BaseNPC):
	if not npc.npc_data or npc.npc_data.get("intrinsic_spell_pool") == null: return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	# Determine if we learn a new spell
	var pool = npc.npc_data.intrinsic_spell_pool
	var new_spells = pool.filter(func(id): return id not in GameState.unlocked_spells)
	
	var picked_spell := ""
	if new_spells.size() > 0:
		picked_spell = new_spells.pick_random()
	
	# Start VFX
	var vfx = Node2D.new()
	vfx.set_script(VFX_SCENE)
	get_tree().root.add_child(vfx)
	vfx.setup(npc.global_position, player, Color.MEDIUM_AQUAMARINE if picked_spell else Color.GRAY)
	
	if picked_spell:
		vfx.all_absorbed.connect(func(): GameState.unlock_spell(picked_spell))
