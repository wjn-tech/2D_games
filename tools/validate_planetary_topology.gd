@tool
extends SceneTree

const WorldTopologyScript = preload("res://src/systems/world/world_topology.gd")

func _init() -> void:
	var topology = WorldTopologyScript.new()
	_validate_planetary_presets(topology)
	_validate_legacy_mode(topology)
	print("Planetary topology validation passed.")
	quit()

func _validate_planetary_presets(topology: Node) -> void:
	var expected_sizes = {
		"small": 256,
		"medium": 384,
		"large": 512,
	}
	for preset in expected_sizes.keys():
		var metadata: Dictionary = topology.create_new_world(123456, preset, topology.TOPOLOGY_MODE_PLANETARY)
		_assert(int(metadata.get("horizontal_circumference_in_chunks", 0)) == int(expected_sizes[preset]), "Unexpected circumference for preset %s" % preset)
		_assert(topology.wrap_chunk_x(int(expected_sizes[preset])) == 0, "Chunk wrap failed for preset %s" % preset)
		_assert(topology.shortest_wrapped_chunk_distance(0, int(expected_sizes[preset]) - 1) == 1, "Wrapped distance failed for preset %s" % preset)
		_assert(topology.is_spawn_safe_tile_x(topology.get_spawn_anchor_tile()), "Spawn safe band missing for preset %s" % preset)

		var surface_regions: Array = topology.world_plan.get("surface_regions", [])
		_assert(not surface_regions.is_empty(), "Surface regions missing for preset %s" % preset)

		var landmarks: Array = topology.world_plan.get("landmarks", [])
		var unique_ids := {}
		for landmark in landmarks:
			var landmark_id := String(landmark.get("id", ""))
			_assert(not unique_ids.has(landmark_id), "Duplicate landmark id %s" % landmark_id)
			unique_ids[landmark_id] = true
		_assert(unique_ids.has("spawn_village"), "Spawn village landmark missing for preset %s" % preset)
		_assert(unique_ids.has("core_ruin"), "Core ruin landmark missing for preset %s" % preset)

		var prefix := String(topology.get_world_storage_prefix())
		_assert(prefix.find(preset) != -1, "Storage prefix does not include preset %s" % preset)

func _validate_legacy_mode(topology: Node) -> void:
	topology.load_world_metadata({
		"primary_seed": 77,
		"topology_mode": "legacy_infinite",
	})
	_assert(not topology.is_planetary(), "Legacy mode should not be planetary")
	_assert(topology.wrap_chunk_x(300) == 300, "Legacy mode should not wrap chunk coordinates")
	_assert(String(topology.get_world_storage_prefix()).begins_with("legacy_infinite"), "Legacy storage prefix missing")

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
		
	push_error(message)
	quit(1)