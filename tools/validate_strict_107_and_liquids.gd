@tool
extends SceneTree

const WorldGeneratorScript = preload("res://src/systems/world/world_generator.gd")
const WorldTopologyScript = preload("res://src/systems/world/world_topology.gd")

const TEST_SEED = 902311

func _init() -> void:
	var failures: Array[String] = []

	var topology = WorldTopologyScript.new()
	topology.name = "WorldTopology"
	get_root().add_child(topology)
	topology.create_new_world(TEST_SEED, "medium", topology.TOPOLOGY_MODE_PLANETARY)

	var generator = WorldGeneratorScript.new()
	generator.name = "WorldGeneratorValidation"
	get_root().add_child(generator)
	generator.seed_value = TEST_SEED
	generator.terraria_strict_chunk_pipeline = true
	generator.terraria_emit_step_trace = true
	generator.terraria_user_skip_steps = []
	generator._setup_noises()

	var sample_coords = [
		Vector2i(0, 6),
		Vector2i(5, 12),
		Vector2i(11, 20),
	]

	var has_water = false
	var has_lava = false

	for coord in sample_coords:
		var cells = generator.generate_chunk_cells(coord, false)

		var trace = cells.get("_terraria_step_trace", [])
		if not (trace is Array):
			failures.append("trace missing or invalid for chunk %s" % str(coord))
			continue
		if trace.size() != 107:
			failures.append("trace size != 107 for chunk %s (actual=%d)" % [str(coord), trace.size()])

		var skipped = 0
		for entry in trace:
			if not (entry is Dictionary):
				continue
			if String(entry.get("status", "")) == "skipped":
				skipped += 1
		if skipped != 0:
			failures.append("unexpected skipped steps in chunk %s (count=%d)" % [str(coord), skipped])

		var seeds = cells.get("_liquid_seeds", [])
		if coord.y >= 10 and (not (seeds is Array) or seeds.is_empty()):
			failures.append("deep chunk has no liquid seeds: %s" % str(coord))
		if seeds is Array:
			for seed_entry in seeds:
				if not (seed_entry is Dictionary):
					continue
				var t = String(seed_entry.get("type", ""))
				if t == "water":
					has_water = true
				elif t == "lava":
					has_lava = true

	if not has_water:
		failures.append("no water seed found in sampled chunks")
	if not has_lava:
		failures.append("no lava seed found in sampled chunks")

	if failures.is_empty():
		print("PASS: strict 107 and liquid seed checks")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
