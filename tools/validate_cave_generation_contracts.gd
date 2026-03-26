@tool
extends SceneTree

const WorldGeneratorScript = preload("res://src/systems/world/world_generator.gd")
const WorldTopologyScript = preload("res://src/systems/world/world_topology.gd")

const TEST_SEED := 902311

func _init() -> void:
	var topology = WorldTopologyScript.new()
	topology.name = "WorldTopology"
	get_root().add_child(topology)
	topology.create_new_world(TEST_SEED, "medium", topology.TOPOLOGY_MODE_PLANETARY)

	var generator = WorldGeneratorScript.new()
	generator.seed_value = TEST_SEED
	generator._setup_noises()

	_validate_determinism(generator)
	_validate_entrance_discoverability(generator)
	_validate_deep_cavern_diversity(generator)
	_validate_long_connector_presence(generator)

	print("Cave generation contract validation passed.")
	quit()

func _validate_determinism(generator: Node) -> void:
	var probes := [
		Vector2i(128, 340),
		Vector2i(640, 390),
		Vector2i(1728, 460),
		Vector2i(3072, 520),
	]
	for probe in probes:
		var a: Dictionary = generator.get_underground_generation_metadata_at_tile(probe.x, probe.y)
		var b: Dictionary = generator.get_underground_generation_metadata_at_tile(probe.x, probe.y)
		_assert(a == b, "Non-deterministic metadata at probe %s" % [str(probe)])

func _validate_entrance_discoverability(generator: Node) -> void:
	var discovered := 0
	var sample_count := 0
	for x in range(0, 4096, 16):
		var surface_y = int(floor(generator.get_surface_height_at(x)))
		var metadata: Dictionary = generator.get_underground_generation_metadata_at_tile(x, surface_y + 2)
		sample_count += 1
		if String(metadata.get("entrance_type", "none")) != "none":
			discovered += 1
	_assert(discovered >= 10, "Surface entrance discoverability too low (%d/%d)" % [discovered, sample_count])

func _validate_deep_cavern_diversity(generator: Node) -> void:
	var archetypes := {}
	for x in range(0, 4096, 12):
		var surface_y = generator.get_surface_height_at(x)
		var deep_y := int(floor(surface_y + 220.0))
		var metadata: Dictionary = generator.get_underground_generation_metadata_at_tile(x, deep_y)
		if bool(metadata.get("reachable", false)):
			archetypes[String(metadata.get("cave_archetype_id", ""))] = true
	_assert(archetypes.size() >= 3, "Deep cavern archetype diversity too low (%d)" % archetypes.size())

func _validate_long_connector_presence(generator: Node) -> void:
	var connector_hits := 0
	for x in range(0, 4096, 8):
		var surface_y = generator.get_surface_height_at(x)
		for y_off in [96, 128, 160, 192]:
			var metadata: Dictionary = generator.get_underground_generation_metadata_at_tile(x, int(floor(surface_y + y_off)))
			if String(metadata.get("cave_archetype_id", "")) == "long_connector_route" and bool(metadata.get("reachable", false)):
				connector_hits += 1
				break
	_assert(connector_hits >= 24, "Long connector route coverage too low (%d)" % connector_hits)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
