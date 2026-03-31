extends SceneTree

var _failures: Array[String] = []
const WorldTopologyScript = preload("res://src/systems/world/world_topology.gd")
const LiquidManagerScript = preload("res://src/systems/world/liquid_manager.gd")
const WorldChunkScript = preload("res://src/systems/world/world_chunk.gd")
const PlayerScript = preload("res://scenes/player.gd")

func _init() -> void:
	_run_all()
	if _failures.is_empty():
		print("PASS: worldgen bedrock/liquid integration")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _run_all() -> void:
	_test_new_world_boundary_metadata()
	_test_legacy_metadata_compatibility()
	_test_stage_alignment_thresholds()
	_test_terraria_107_catalog_contract()
	_test_underworld_legacy_metadata_backfill_contract()
	_test_underworld_fixed_layer_scale_contract()
	_test_underworld_primary_route_contract()
	_test_underworld_chunk_seam_continuity_contract()
	_test_underworld_ore_uplift_contract()
	_test_underworld_generation_performance_smoke()
	_test_underground_zone_and_cavern_diversity_contract()
	_test_underground_material_stratification_contract()
	_test_spawn_safe_early_descent_contract()
	_test_ore_cluster_generation_contract()
	_test_ore_density_floor_contract()
	_test_ore_seam_continuity_contract()
	_test_worldgen_liquid_seed_contract()
	_test_worldgen_performance_guardrail_smoke()
	_test_planetary_preload_domain_contract()
	_test_liquid_extension_interface()
	_test_liquid_downward_micro_trickle_no_deadzone()
	_test_liquid_cooldown_ready_scheduler()
	_test_liquid_downstream_wait_schedules_self_retry()
	_test_liquid_open_fall_stream_continuity()
	_test_liquid_open_fall_hysteresis_window()
	_test_liquid_open_fall_vertical_priority()
	_test_liquid_open_fall_short_cooldown_cap()
	_test_liquid_water_split_gain_guardrail()
	_test_liquid_clear_epsilon_threshold()
	_test_liquid_flow_direction_stability()
	_test_liquid_core_path_bubble_convergence()
	_test_liquid_no_upward_insertion_path()
	_test_liquid_bottom_anchor_contract()
	_test_liquid_authoritative_contact_query()
	_test_player_water_state_thresholds()
	_test_player_water_motion_profiles()
	_test_player_water_event_throttle()
	_test_liquid_persistence_seed_override_guard()
	_test_liquid_flush_runtime_to_chunk_state()

func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

func _reset_world_topology_fixture(seed: int) -> Dictionary:
	var existing = get_root().get_node_or_null("WorldTopology")
	if existing:
		existing.get_parent().remove_child(existing)
		existing.free()

	var topology = WorldTopologyScript.new()
	topology.name = "WorldTopology"
	get_root().add_child(topology)
	topology.create_new_world(seed, "medium", topology.TOPOLOGY_MODE_PLANETARY)

	var generator = WorldGenerator.new()
	generator.seed_value = seed
	generator._setup_world_params()
	generator._setup_noises()

	return {
		"topology": topology,
		"generator": generator,
	}

func _dispose_world_topology_fixture(fixture: Dictionary) -> void:
	if fixture.has("topology") and fixture["topology"] is Node:
		var topology_node: Node = fixture["topology"]
		if is_instance_valid(topology_node):
			topology_node.get_parent().remove_child(topology_node)
			topology_node.free()

func _is_ore_tile(atlas: Vector2i) -> bool:
	var ore_tiles: Array[Vector2i] = [
		Vector2i(0, 4),
		Vector2i(1, 4),
		Vector2i(4, 4),
		Vector2i(5, 4),
		Vector2i(2, 4),
		Vector2i(3, 4),
		Vector2i(0, 5),
	]
	return ore_tiles.has(atlas)

func _is_strata_rock_tile(atlas: Vector2i) -> bool:
	var rock_tiles: Array[Vector2i] = [
		Vector2i(2, 0),
		Vector2i(1, 3),
		Vector2i(0, 3),
		Vector2i(2, 3),
		Vector2i(3, 2),
	]
	return rock_tiles.has(atlas)

func _count_ore_seam_links(left_cells: Dictionary, right_cells: Dictionary) -> int:
	if not left_cells.has(0) or not right_cells.has(0):
		return 0
	var left_layer: Dictionary = left_cells.get(0, {})
	var right_layer: Dictionary = right_cells.get(0, {})
	var seam_links := 0
	for y in range(64):
		var left_pos := Vector2i(63, y)
		var right_same := Vector2i(0, y)
		var right_up := Vector2i(0, y - 1)
		var right_down := Vector2i(0, y + 1)

		if not left_layer.has(left_pos):
			continue
		var left_data_variant = left_layer[left_pos]
		if not (left_data_variant is Dictionary):
			continue
		var left_data: Dictionary = left_data_variant
		var left_atlas_variant = left_data.get("atlas", null)
		if not (left_atlas_variant is Vector2i) or not _is_ore_tile(left_atlas_variant):
			continue

		for rp in [right_same, right_up, right_down]:
			if not right_layer.has(rp):
				continue
			var right_data_variant = right_layer[rp]
			if not (right_data_variant is Dictionary):
				continue
			var right_data: Dictionary = right_data_variant
			var right_atlas_variant = right_data.get("atlas", null)
			if right_atlas_variant is Vector2i and _is_ore_tile(right_atlas_variant):
				seam_links += 1
				break
	return seam_links

func _test_new_world_boundary_metadata() -> void:
	var topology = WorldTopologyScript.new()
	topology.create_new_world(12345, "medium")
	_assert_true(topology.is_depth_boundary_enabled(), "new medium world should enable depth boundary")
	_assert_eq(topology.get_bedrock_start_depth(), 1700, "medium preset bedrock_start_depth should match contract")
	_assert_eq(topology.get_bedrock_hard_floor_depth(), 1900, "medium preset bedrock_hard_floor_depth should match contract")
	_assert_true(topology.get_bedrock_hard_floor_global_y() > topology.get_bedrock_start_global_y(), "hard floor global y should be deeper than transition start")

func _test_legacy_metadata_compatibility() -> void:
	var topology = WorldTopologyScript.new()
	topology.load_world_metadata({
		"topology_mode": "planetary_v1",
		"primary_seed": 99,
		"world_size_preset": "small"
	})
	_assert_true(not topology.is_depth_boundary_enabled(), "legacy save without boundary flag should keep boundary disabled")

func _test_stage_alignment_thresholds() -> void:
	var generator = WorldGenerator.new()
	var metrics = generator.get_stage_alignment_metrics()
	_assert_true(float(metrics.get("core_stage_coverage_rate", 0.0)) >= float(metrics.get("core_stage_coverage_threshold", 1.0)), "core stage coverage must meet threshold")
	_assert_true(float(metrics.get("step_item_coverage_rate", 0.0)) >= float(metrics.get("step_item_coverage_threshold", 1.0)), "step item coverage must meet threshold")
	var mapping = generator.get_stage_tileset_mapping()
	for required_key in [
		"surface_primary",
		"underground_primary",
		"deep_primary",
		"bedrock_transition",
		"bedrock_floor",
		"liquid_contact_water",
		"liquid_contact_lava",
	]:
		_assert_true(mapping.has(required_key), "stage tileset mapping missing key: %s" % required_key)

func _test_terraria_107_catalog_contract() -> void:
	var generator = WorldGenerator.new()
	var catalog = generator.get_terraria_step_compatibility_catalog()
	_assert_eq(catalog.size(), 107, "terraria compatibility catalog should expose 107 entries")

	var seen_indices := {}
	for entry in catalog:
		if not (entry is Dictionary):
			_failures.append("terraria catalog entry must be Dictionary")
			continue
		var step_index := int(entry.get("step_index", -1))
		_assert_true(step_index >= 1 and step_index <= 107, "catalog step index should be within [1, 107]")
		_assert_true(not seen_indices.has(step_index), "catalog should not contain duplicate step indices")
		seen_indices[step_index] = true

	var terraria_metrics = generator.get_terraria_step_alignment_metrics()
	var disposition_counts: Dictionary = terraria_metrics.get("disposition_counts", {})
	var disposition_sum := int(disposition_counts.get("implemented", 0)) + int(disposition_counts.get("adapted", 0)) + int(disposition_counts.get("skipped", 0))
	_assert_eq(disposition_sum, 107, "implemented/adapted/skipped counts should sum to 107")
	_assert_eq(int(terraria_metrics.get("unresolved_entries", -1)), 0, "terraria 107-step alignment should have zero unresolved entries")

func _test_underworld_legacy_metadata_backfill_contract() -> void:
	var topology = WorldTopologyScript.new()
	topology.create_new_world(777, "medium", topology.TOPOLOGY_MODE_PLANETARY)
	_assert_true(topology.is_underworld_layer_enabled(), "new planetary worlds should enable fixed underworld layer")

	topology.load_world_metadata({
		"topology_mode": "planetary_v1",
		"primary_seed": 777,
		"world_size_preset": "medium",
	})
	_assert_true(topology.is_underworld_layer_enabled(), "legacy saves without underworld flag should auto-enable underworld metadata")
	var under_cfg := topology.get_underworld_generation_config()
	_assert_true(float(under_cfg.get("horizontal_coverage_ratio", 0.0)) >= 0.999, "legacy metadata backfill should normalize to full-circumference underworld coverage")
	_assert_true(int(under_cfg.get("revision", 0)) >= 2, "legacy metadata backfill should upgrade underworld revision to v2")

func _test_underworld_fixed_layer_scale_contract() -> void:
	var fixture = _reset_world_topology_fixture(902311)
	var topology = fixture.get("topology", null)
	var generator = fixture.get("generator", null)
	if topology == null or generator == null:
		_failures.append("fixture topology/generator missing in underworld scale contract")
		_dispose_world_topology_fixture(fixture)
		return

	var under_cfg_variant = topology.get_underworld_generation_config()
	_assert_true(under_cfg_variant is Dictionary, "underworld config should be exposed as dictionary")
	if not (under_cfg_variant is Dictionary):
		_dispose_world_topology_fixture(fixture)
		return
	var under_cfg: Dictionary = under_cfg_variant
	_assert_true(bool(under_cfg.get("enabled", false)), "underworld config should be enabled for new worlds")

	var circumference := int(topology.get_circumference_tiles())
	var sample_count := 96
	var active_count := 0
	for i in range(sample_count):
		var x := int(floor(float(i) * float(circumference) / float(sample_count)))
		var sy := int(floor(generator.get_surface_height_at(x)))
		var probe_y := sy + int(topology.get_bedrock_start_depth()) - 120
		var meta = generator.get_underground_generation_metadata_at_tile(x, probe_y)
		if bool(meta.get("underworld_active", false)):
			active_count += 1

	var active_ratio := float(active_count) / float(sample_count)
	_assert_true(active_ratio >= 0.88, "underworld should provide near full-circumference horizontal coverage")

	var anchor_x := int(under_cfg.get("anchor_tile", 0))
	var anchor_sy := int(floor(generator.get_surface_height_at(anchor_x)))
	var start_depth := int(topology.get_bedrock_start_depth())
	var hard_depth := int(topology.get_bedrock_hard_floor_depth())
	var min_hit_depth := 1000000
	var max_hit_depth := -1
	for depth_probe in range(maxi(240, start_depth - 420), hard_depth + 1, 4):
		var meta = generator.get_underground_generation_metadata_at_tile(anchor_x, anchor_sy + depth_probe)
		if bool(meta.get("underworld_active", false)):
			min_hit_depth = mini(min_hit_depth, depth_probe)
			max_hit_depth = maxi(max_hit_depth, depth_probe)

	_assert_true(max_hit_depth > min_hit_depth, "underworld depth envelope should be discoverable at anchor column")
	if max_hit_depth > min_hit_depth:
		_assert_true((max_hit_depth - min_hit_depth) >= 176, "underworld vertical span should be at least 180 tiles (4-tile probe tolerance)")

	_dispose_world_topology_fixture(fixture)

func _test_underworld_primary_route_contract() -> void:
	var fixture = _reset_world_topology_fixture(902311)
	var topology = fixture.get("topology", null)
	var generator = fixture.get("generator", null)
	if topology == null or generator == null:
		_failures.append("fixture topology/generator missing in underworld route contract")
		_dispose_world_topology_fixture(fixture)
		return

	var under_cfg: Dictionary = topology.get_underworld_generation_config()
	var route_x := int(under_cfg.get("primary_route_tile", 0))
	var sy := int(floor(generator.get_surface_height_at(route_x)))
	var route_end_depth := maxi(420, int(topology.get_bedrock_start_depth()) - 220)
	var sample_total := 0
	var route_hits := 0
	for depth_probe in range(320, route_end_depth + 1, 12):
		sample_total += 1
		var found := false
		for dx in range(-8, 9):
			var x := topology.wrap_tile_x(route_x + dx)
			var local_sy := int(floor(generator.get_surface_height_at(x)))
			var meta = generator.get_underground_generation_metadata_at_tile(x, local_sy + depth_probe)
			if String(meta.get("underworld_region", "")) == "route":
				found = true
				break
		if found:
			route_hits += 1

	_assert_true(sample_total > 0, "underworld route contract should collect route samples")
	if sample_total > 0:
		var hit_ratio := float(route_hits) / float(sample_total)
		_assert_true(hit_ratio >= 0.65, "underworld primary natural route should remain continuous through representative depth window")

	_dispose_world_topology_fixture(fixture)

func _test_underworld_chunk_seam_continuity_contract() -> void:
	var fixture = _reset_world_topology_fixture(902311)
	var topology = fixture.get("topology", null)
	var generator = fixture.get("generator", null)
	if topology == null or generator == null:
		_failures.append("fixture topology/generator missing in underworld seam continuity contract")
		_dispose_world_topology_fixture(fixture)
		return

	var under_cfg: Dictionary = topology.get_underworld_generation_config()
	var anchor_x := int(under_cfg.get("anchor_tile", 0))
	var start_depth := int(topology.get_bedrock_start_depth())
	var sample_pairs := 0
	var mismatch_pairs := 0

	for seam_offset in [-128, -64, 0, 64, 128]:
		var seam_x := topology.wrap_tile_x(anchor_x + seam_offset)
		for depth_probe in [start_depth - 150, start_depth - 120, start_depth - 90]:
			var left_x := topology.wrap_tile_x(seam_x - 1)
			var right_x := topology.wrap_tile_x(seam_x)
			var left_sy := int(floor(generator.get_surface_height_at(left_x)))
			var right_sy := int(floor(generator.get_surface_height_at(right_x)))
			var left_meta = generator.get_underground_generation_metadata_at_tile(left_x, left_sy + depth_probe)
			var right_meta = generator.get_underground_generation_metadata_at_tile(right_x, right_sy + depth_probe)
			var left_active := bool(left_meta.get("underworld_active", false))
			var right_active := bool(right_meta.get("underworld_active", false))
			if left_active or right_active:
				sample_pairs += 1
				if left_active != right_active:
					mismatch_pairs += 1

	_assert_true(sample_pairs > 0, "underworld seam continuity should collect active seam-adjacent samples")
	if sample_pairs > 0:
		var mismatch_ratio := float(mismatch_pairs) / float(sample_pairs)
		_assert_true(mismatch_ratio <= 0.20, "underworld geometry should remain largely continuous across chunk seams")

	_dispose_world_topology_fixture(fixture)

func _test_underworld_ore_uplift_contract() -> void:
	var fixture = _reset_world_topology_fixture(902311)
	var topology = fixture.get("topology", null)
	var generator = fixture.get("generator", null)
	if topology == null or generator == null:
		_failures.append("fixture topology/generator missing in underworld ore uplift contract")
		_dispose_world_topology_fixture(fixture)
		return

	var under_cfg: Dictionary = topology.get_underworld_generation_config()
	var anchor_x := int(under_cfg.get("anchor_tile", 0))
	var start_depth := int(topology.get_bedrock_start_depth())
	var near_sy := int(floor(generator.get_surface_height_at(anchor_x)))
	var near_meta = generator.get_underground_generation_metadata_at_tile(anchor_x, near_sy + start_depth - 90)
	_assert_true(float(near_meta.get("underworld_ore_density_multiplier", 1.0)) >= 1.29, "underworld-adjacent zones should expose +30% ore density uplift")

	var far_x := topology.wrap_tile_x(anchor_x + int(topology.get_circumference_tiles() / 2))
	var far_sy := int(floor(generator.get_surface_height_at(far_x)))
	var far_meta = generator.get_underground_generation_metadata_at_tile(far_x, far_sy + start_depth - 90)
	_assert_true(float(far_meta.get("underworld_ore_density_multiplier", 1.0)) <= 1.01, "far non-underworld regions should not receive underworld ore uplift")

	var probe_chunk := Vector2i(int(floor(float(anchor_x) / 64.0)), int(floor(float(near_sy + start_depth - 80) / 64.0)))
	var cells = generator.generate_chunk_cells(probe_chunk, false)
	var ore_diag_variant = cells.get("_ore_generation", {})
	_assert_true(ore_diag_variant is Dictionary, "underworld ore uplift contract should emit ore diagnostics")
	if ore_diag_variant is Dictionary:
		var ore_diag: Dictionary = ore_diag_variant
		_assert_true(int(ore_diag.get("underworld_uplift_hits", 0)) > 0, "underworld-adjacent chunk should sample ore uplift candidates")

	_dispose_world_topology_fixture(fixture)

func _test_underworld_generation_performance_smoke() -> void:
	var fixture = _reset_world_topology_fixture(902311)
	var topology = fixture.get("topology", null)
	var generator = fixture.get("generator", null)
	if topology == null or generator == null:
		_failures.append("fixture topology/generator missing in underworld performance smoke")
		_dispose_world_topology_fixture(fixture)
		return

	var under_cfg: Dictionary = topology.get_underworld_generation_config()
	var anchor_x := int(under_cfg.get("anchor_tile", 0))
	var anchor_sy := int(floor(generator.get_surface_height_at(anchor_x)))
	var start_depth := int(topology.get_bedrock_start_depth())
	var probe_chunk_y := int(floor(float(anchor_sy + start_depth - 120) / 64.0))
	var probe_chunk_x := int(floor(float(anchor_x) / 64.0))

	var start_ms := Time.get_ticks_msec()
	for ox in [-1, 0, 1]:
		generator.generate_chunk_cells(Vector2i(probe_chunk_x + ox, probe_chunk_y), true)
	var elapsed_ms := Time.get_ticks_msec() - start_ms
	_assert_true(elapsed_ms < 7000, "underworld traversal-critical generation smoke budget should remain bounded")

	_dispose_world_topology_fixture(fixture)

func _test_underground_zone_and_cavern_diversity_contract() -> void:
	var fixture = _reset_world_topology_fixture(902311)
	var generator = fixture.get("generator", null)
	if generator == null:
		_failures.append("fixture generator missing in underground diversity contract")
		_dispose_world_topology_fixture(fixture)
		return

	var zone_ids := {}
	var open_cavern_hits := 0
	var connector_hits := 0

	for x in range(96, 96 + 1024, 16):
		var sy := int(floor(generator.get_surface_height_at(x)))
		for depth_probe in [96, 136, 176, 216]:
			var meta = generator.get_underground_generation_metadata_at_tile(x, sy + depth_probe)
			var zone_id := String(meta.get("underground_zone_id", ""))
			if zone_id != "":
				zone_ids[zone_id] = true
			var cave_region := String(meta.get("cave_region", ""))
			if cave_region == "OpenCavern":
				open_cavern_hits += 1
			elif cave_region == "Connector":
				connector_hits += 1

	_assert_true(zone_ids.size() >= 4, "underground zoning should provide at least four distinct zone ids in representative sample")
	_assert_true(open_cavern_hits >= 4, "representative sample should include budgeted open cavern hits")
	_assert_true(connector_hits >= 4, "representative sample should include connector-route hits")
	_dispose_world_topology_fixture(fixture)

func _test_underground_material_stratification_contract() -> void:
	var fixture = _reset_world_topology_fixture(902311)
	var generator = fixture.get("generator", null)
	if generator == null:
		_failures.append("fixture generator missing in underground material stratification contract")
		_dispose_world_topology_fixture(fixture)
		return

	var strata_tiles := {}
	for coord in [Vector2i(6, 9), Vector2i(10, 12), Vector2i(14, 16)]:
		var cells = generator.generate_chunk_cells(coord, false)
		if not cells.has(0):
			continue
		var layer0: Dictionary = cells.get(0, {})
		for pos_variant in layer0.keys():
			if not (pos_variant is Vector2i):
				continue
			var local_pos: Vector2i = pos_variant
			var tile_variant = layer0.get(local_pos, {})
			if not (tile_variant is Dictionary):
				continue
			var tile_data: Dictionary = tile_variant
			var atlas_variant = tile_data.get("atlas", null)
			if not (atlas_variant is Vector2i):
				continue
			var atlas: Vector2i = atlas_variant
			if not _is_strata_rock_tile(atlas):
				continue

			var global_x := coord.x * 64 + local_pos.x
			var global_y := coord.y * 64 + local_pos.y
			var depth := float(global_y) - float(generator.get_surface_height_at(global_x))
			if depth < 70.0:
				continue
			strata_tiles[atlas] = true

	_assert_true(strata_tiles.size() >= 3, "underground generation should expose at least three distinct deep rock strata tiles")
	_dispose_world_topology_fixture(fixture)

func _test_spawn_safe_early_descent_contract() -> void:
	var fixture = _reset_world_topology_fixture(902311)
	var topology = fixture.get("topology", null)
	var generator = fixture.get("generator", null)
	if topology == null or generator == null:
		_failures.append("fixture topology/generator missing in spawn descent contract")
		_dispose_world_topology_fixture(fixture)
		return

	var anchor_tile := int(topology.get_spawn_anchor_tile())
	var found := false
	var nearest_dist := 999999
	for dx in range(-224, 225, 4):
		var x := anchor_tile + dx
		var sy := int(floor(generator.get_surface_height_at(x)))
		var meta = generator.get_underground_generation_metadata_at_tile(x, sy + 4)
		if String(meta.get("entrance_type", "none")) != "none":
			found = true
			nearest_dist = mini(nearest_dist, absi(dx))

	_assert_true(found, "spawn-safe exploration window should expose at least one discoverable descent entrance")
	_assert_true(nearest_dist <= 160, "early descent entrance should appear within bounded spawn travel distance")
	_dispose_world_topology_fixture(fixture)

func _test_ore_cluster_generation_contract() -> void:
	var fixture = _reset_world_topology_fixture(902311)
	var generator = fixture.get("generator", null)
	if generator == null:
		_failures.append("fixture generator missing in ore cluster contract")
		_dispose_world_topology_fixture(fixture)
		return

	var cells = generator.generate_chunk_cells(Vector2i(10, 14), false)
	var ore_diag_variant = cells.get("_ore_generation", {})
	_assert_true(ore_diag_variant is Dictionary, "resource stage should expose ore generation diagnostics")
	if ore_diag_variant is Dictionary:
		var ore_diag: Dictionary = ore_diag_variant
		_assert_eq(String(ore_diag.get("family", "")), "cluster", "ore generation should declare cluster family")
		_assert_true(int(ore_diag.get("cluster_count", 0)) > 0, "deep chunk should generate at least one ore cluster")
		var metrics_variant = ore_diag.get("component_metrics", {})
		_assert_true(metrics_variant is Dictionary, "ore generation diagnostics should include component metrics")
		if metrics_variant is Dictionary:
			var metrics: Dictionary = metrics_variant
			_assert_true(float(metrics.get("avg_component_size", 0.0)) > 1.1, "ore components should be connected beyond single-cell scatter")
			_assert_true(float(metrics.get("single_cell_ratio", 1.0)) < 0.85, "ore single-cell ratio should remain bounded")

	_dispose_world_topology_fixture(fixture)

func _test_ore_density_floor_contract() -> void:
	var fixture = _reset_world_topology_fixture(902311)
	var generator = fixture.get("generator", null)
	if generator == null:
		_failures.append("fixture generator missing in ore density floor contract")
		_dispose_world_topology_fixture(fixture)
		return

	var ore_ratios: Array[float] = []
	for coord in [Vector2i(8, 12), Vector2i(10, 14), Vector2i(12, 16), Vector2i(14, 18)]:
		var cells = generator.generate_chunk_cells(coord, false)
		if not cells.has(0):
			continue
		var layer0: Dictionary = cells.get(0, {})
		var deep_rock_cells := 0
		var ore_cells := 0
		for pos_variant in layer0.keys():
			if not (pos_variant is Vector2i):
				continue
			var local_pos: Vector2i = pos_variant
			var tile_variant = layer0.get(local_pos, {})
			if not (tile_variant is Dictionary):
				continue
			var tile_data: Dictionary = tile_variant
			var atlas_variant = tile_data.get("atlas", null)
			if not (atlas_variant is Vector2i):
				continue
			var atlas: Vector2i = atlas_variant

			var global_x := coord.x * 64 + local_pos.x
			var global_y := coord.y * 64 + local_pos.y
			var depth := float(global_y) - float(generator.get_surface_height_at(global_x))
			if depth < 90.0:
				continue

			if _is_ore_tile(atlas):
				ore_cells += 1
			elif _is_strata_rock_tile(atlas):
				deep_rock_cells += 1

		var total_host := deep_rock_cells + ore_cells
		if total_host > 0:
			ore_ratios.append(float(ore_cells) / float(total_host))

	if ore_ratios.is_empty():
		_failures.append("ore density floor contract collected no valid deep host samples")
		_dispose_world_topology_fixture(fixture)
		return

	var sum_ratio := 0.0
	var peak_ratio := 0.0
	for ratio in ore_ratios:
		sum_ratio += ratio
		peak_ratio = maxf(peak_ratio, ratio)
	var avg_ratio := sum_ratio / float(ore_ratios.size())

	_assert_true(avg_ratio >= 0.014, "deep underground average ore density should stay above minimum floor")
	_assert_true(peak_ratio >= 0.020, "representative deep chunks should contain visible ore pockets")
	_dispose_world_topology_fixture(fixture)

func _test_ore_seam_continuity_contract() -> void:
	var fixture = _reset_world_topology_fixture(902311)
	var generator = fixture.get("generator", null)
	if generator == null:
		_failures.append("fixture generator missing in ore seam contract")
		_dispose_world_topology_fixture(fixture)
		return

	var seam_links_total := 0
	for left_chunk_x in [8, 10, 12, 14]:
		var left_cells = generator.generate_chunk_cells(Vector2i(left_chunk_x, 14), false)
		var right_cells = generator.generate_chunk_cells(Vector2i(left_chunk_x + 1, 14), false)
		seam_links_total += _count_ore_seam_links(left_cells, right_cells)

	_assert_true(seam_links_total > 0, "ore deposits should preserve at least some cross-chunk seam continuity")
	_dispose_world_topology_fixture(fixture)

func _test_worldgen_liquid_seed_contract() -> void:
	var fixture = _reset_world_topology_fixture(902311)
	var generator = fixture.get("generator", null)
	if generator == null:
		_failures.append("fixture generator missing in liquid seed contract")
		_dispose_world_topology_fixture(fixture)
		return

	var has_water := false
	var has_lava := false
	for coord in [Vector2i(6, 10), Vector2i(10, 14), Vector2i(14, 20)]:
		var cells = generator.generate_chunk_cells(coord, false)
		var seeds_variant = cells.get("_liquid_seeds", [])
		if not (seeds_variant is Array):
			continue
		for entry_variant in seeds_variant:
			if not (entry_variant is Dictionary):
				continue
			var entry: Dictionary = entry_variant
			var t := String(entry.get("type", ""))
			if t == "water":
				has_water = true
			elif t == "lava":
				has_lava = true

	_assert_true(has_water, "worldgen liquid seeding should continue to produce water seeds")
	_assert_true(has_lava, "worldgen liquid seeding should continue to produce lava seeds")
	_dispose_world_topology_fixture(fixture)

func _test_worldgen_performance_guardrail_smoke() -> void:
	var fixture = _reset_world_topology_fixture(902311)
	var generator = fixture.get("generator", null)
	if generator == null:
		_failures.append("fixture generator missing in performance guardrail smoke")
		_dispose_world_topology_fixture(fixture)
		return

	var start_ms := Time.get_ticks_msec()
	for coord in [Vector2i(8, 12), Vector2i(9, 12), Vector2i(10, 12)]:
		generator.generate_chunk_cells(coord, true)
	var elapsed_ms := Time.get_ticks_msec() - start_ms
	_assert_true(elapsed_ms < 5000, "critical chunk generation smoke budget should remain bounded")
	_dispose_world_topology_fixture(fixture)

func _test_planetary_preload_domain_contract() -> void:
	var topology = WorldTopologyScript.new()
	topology.create_new_world(12345, "medium")
	var domain = topology.get_preload_domain_definition()
	_assert_true(bool(domain.get("required", false)), "planetary topology should require full preload domain")
	_assert_true(int(domain.get("x_count", 0)) > 0, "planetary preload domain should contain horizontal chunk range")
	_assert_true(int(domain.get("mandatory_chunk_total", 0)) > 0, "planetary preload domain should include mandatory chunks")

	var identity_a = topology.get_preload_domain_identity()
	var identity_b = topology.get_preload_domain_identity()
	_assert_eq(identity_a, identity_b, "preload domain identity should be deterministic for same metadata")

	topology.reset_to_legacy(12345)
	var legacy_domain = topology.get_preload_domain_definition()
	_assert_true(not bool(legacy_domain.get("required", true)), "legacy topology should fallback without mandatory full preload")

func _test_liquid_extension_interface() -> void:
	var manager = LiquidManagerScript.new()
	manager._ready()
	manager.register_liquid_family("honey", {
		"viscosity": 0.90,
		"fall_gate": 0.93,
	})
	_assert_true(manager.has_liquid_family("water"), "phase-1 liquid family water should exist")
	_assert_true(manager.has_liquid_family("lava"), "phase-1 liquid family lava should exist")
	_assert_true(manager.has_liquid_family("honey"), "liquid extension interface should allow registering honey")

func _sum_chunk_liquid_amount(manager, coord: Vector2i) -> float:
	var total := 0.0
	var chunk_cells_variant = manager._chunk_liquids.get(coord, {})
	if not (chunk_cells_variant is Dictionary):
		return total
	for cell_variant in (chunk_cells_variant as Dictionary).values():
		if cell_variant is Dictionary:
			total += float((cell_variant as Dictionary).get("amount", 0.0))
	return total

func _simulate_core_steps(manager, world_positions: Array[Vector2i], steps: int) -> void:
	if steps <= 0:
		return
	var changed: Dictionary = {}
	for _step in range(steps):
		for pos in world_positions:
			manager._simulate_active_cell(pos, changed)

func _test_liquid_core_path_bubble_convergence() -> void:
	var manager = LiquidManagerScript.new()
	manager._ready()
	var coord := Vector2i.ZERO
	manager._chunk_liquids[coord] = {
		"9,10": {"type": "water", "amount": 1.0},
		"10,10": {"type": "water", "amount": 1.0},
		"11,10": {"type": "water", "amount": 1.0},
		"9,11": {"type": "water", "amount": 1.0},
		"11,11": {"type": "water", "amount": 1.0},
		"9,12": {"type": "water", "amount": 1.0},
		"10,12": {"type": "water", "amount": 1.0},
		"11,12": {"type": "water", "amount": 1.0},
	}

	var before_total := _sum_chunk_liquid_amount(manager, coord)
	_simulate_core_steps(manager, [
		Vector2i(9, 11),
		Vector2i(11, 11),
		Vector2i(10, 10),
		Vector2i(10, 12),
		Vector2i(10, 11),
	], 24)

	var center_entry = manager._get_cell_entry(Vector2i(10, 11))
	_assert_true(center_entry is Dictionary, "core path should converge one-cell enclosed bubble without repair pass")
	if center_entry is Dictionary:
		var center_amount := float((center_entry as Dictionary).get("amount", 0.0))
		_assert_true(center_amount > manager.LIQUID_EPSILON, "core path bubble convergence should leave visible mass in center cell")

	var after_total := _sum_chunk_liquid_amount(manager, coord)
	_assert_true(absf(before_total - after_total) < 0.0001, "core path bubble convergence should conserve mass")

func _test_liquid_no_upward_insertion_path() -> void:
	var manager = LiquidManagerScript.new()
	manager._ready()
	var coord := Vector2i.ZERO
	manager._chunk_liquids[coord] = {
		"10,20": {"type": "water", "amount": 1.0},
		"10,21": {"type": "water", "amount": 1.0},
		"9,21": {"type": "water", "amount": 1.0},
		"11,21": {"type": "water", "amount": 1.0},
	}

	_simulate_core_steps(manager, [
		Vector2i(10, 20),
		Vector2i(10, 21),
		Vector2i(9, 21),
		Vector2i(11, 21),
	], 40)

	var chunk_cells_variant = manager._chunk_liquids.get(coord, {})
	if chunk_cells_variant is Dictionary:
		for key in (chunk_cells_variant as Dictionary).keys():
			var local_pos_variant = manager._parse_local_key(key)
			if local_pos_variant is Vector2i:
				var local_pos: Vector2i = local_pos_variant
				_assert_true(local_pos.y >= 20, "runtime should not create upward insertion above source layer")

func _test_liquid_bottom_anchor_contract() -> void:
	var overlay = LiquidManagerScript.LiquidOverlay.new()
	overlay.configure(16.0)

	var quarter = overlay.debug_bottom_anchor_metrics(0.25)
	var quarter_fill := float(quarter.get("fill_h", 0.0))
	var quarter_offset := float(quarter.get("y_offset", -1.0))
	_assert_true(quarter_fill > 0.0, "bottom-anchor metrics should produce a positive fill height")
	_assert_true(absf((quarter_offset + quarter_fill) - 16.0) < 0.001, "bottom-anchor contract should keep fill attached to cell bottom")

	var thin = overlay.debug_bottom_anchor_metrics(0.02)
	var thin_fill := float(thin.get("fill_h", 0.0))
	var thin_offset := float(thin.get("y_offset", -1.0))
	_assert_true(thin_fill >= 1.0, "thin film should still render with minimum visible bottom-anchored slice")
	_assert_true(absf((thin_offset + thin_fill) - 16.0) < 0.001, "thin film should remain bottom-anchored")

func _test_liquid_downward_micro_trickle_no_deadzone() -> void:
	var manager = LiquidManagerScript.new()
	manager._ready()
	var coord := Vector2i.ZERO
	manager._chunk_liquids[coord] = {
		"10,10": {"type": "water", "amount": 0.02},
	}

	var changed: Dictionary = {}
	var simulated := bool(manager._simulate_active_cell(Vector2i(10, 10), changed))
	_assert_true(simulated, "micro-trickle dead-zone setup should be simulated")

	var below_entry = manager._get_cell_entry(Vector2i(10, 11))
	_assert_true(below_entry is Dictionary, "sub-quantum film should still transfer downward instead of suspending")

func _test_liquid_cooldown_ready_scheduler() -> void:
	var manager = LiquidManagerScript.new()
	manager._ready()
	var world_pos := Vector2i(6, 6)
	var world_key := String(manager._world_key(world_pos))
	manager._fall_next_ms[world_key] = Time.get_ticks_msec() - 1

	manager._enqueue_cooldown_ready_cells(16, 16)
	_assert_true(not manager._fall_next_ms.has(world_key), "ready cooldown key should be consumed by scheduler")
	_assert_true(manager._active_set.has(world_key), "ready cooldown cell should be enqueued to active set")

func _test_liquid_downstream_wait_schedules_self_retry() -> void:
	var manager = LiquidManagerScript.new()
	manager._ready()
	var coord := Vector2i.ZERO
	var source := Vector2i(10, 10)
	var below := Vector2i(10, 11)
	manager._chunk_liquids[coord] = {
		"10,10": {"type": "water", "amount": 0.8},
		"10,11": {"type": "water", "amount": 1.0},
	}

	var changed: Dictionary = {}
	var simulated := bool(manager._simulate_active_cell(source, changed))
	_assert_true(simulated, "downstream-wait setup should be simulated")

	var source_key := String(manager._world_key(source))
	var below_key := String(manager._world_key(below))
	_assert_true(manager._active_set.has(below_key), "downstream-wait should prioritize waking the below cell")
	_assert_true(not manager._active_set.has(source_key), "downstream-wait should avoid immediate busy requeue on source")
	_assert_true(manager._fall_next_ms.has(source_key), "downstream-wait should schedule delayed self retry for source")

	var left_entry = manager._get_cell_entry(Vector2i(9, 10))
	var right_entry = manager._get_cell_entry(Vector2i(11, 10))
	_assert_true(not (left_entry is Dictionary), "downstream-wait should not produce uphill-looking side spill while vertical path is blocked by full downstream")
	_assert_true(not (right_entry is Dictionary), "downstream-wait should not produce uphill-looking side spill while vertical path is blocked by full downstream")

	var retry_ms := int(manager._fall_next_ms.get(source_key, 0))
	_assert_true(retry_ms >= Time.get_ticks_msec(), "delayed self retry should target a future timestamp")

func _test_liquid_open_fall_stream_continuity() -> void:
	var manager = LiquidManagerScript.new()
	manager._ready()
	var coord := Vector2i.ZERO
	manager._chunk_liquids[coord] = {
		"10,10": {"type": "water", "amount": 1.0},
	}

	var changed: Dictionary = {}
	var simulated := manager._simulate_active_cell(Vector2i(10, 10), changed)
	_assert_true(simulated, "open-column water source should be simulated")

	var below_entry = manager._get_cell_entry(Vector2i(10, 11))
	_assert_true(below_entry is Dictionary, "open-column waterfall should create direct liquid in cell below")
	_assert_true(manager._fall_packets.is_empty(), "open-column waterfall should avoid packet-only gaps")

func _test_liquid_open_fall_hysteresis_window() -> void:
	var manager = LiquidManagerScript.new()
	manager._ready()
	var coord := Vector2i.ZERO
	manager._chunk_liquids[coord] = {
		"10,10": {"type": "water", "amount": 0.9},
	}

	var source := Vector2i(10, 10)
	var below := Vector2i(10, 11)
	var first := bool(manager._should_use_open_fall_stream(source, "water", 0.9, false, below))
	_assert_true(first, "first open-column decision should enter direct-fall mode")

	# Block deeper probe cell to force _is_open_fall_column false and rely on hysteresis.
	manager._set_cell_entry(Vector2i(10, 12), "water", 0.6, {})
	var held := bool(manager._should_use_open_fall_stream(source, "water", 0.9, false, below))
	_assert_true(held, "open-fall mode should hold briefly to avoid packet/direct flicker")

	var world_key := String(manager._world_key(source))
	manager._open_fall_mode_until_ms[world_key] = Time.get_ticks_msec() - 1
	var after_expire := bool(manager._should_use_open_fall_stream(source, "water", 0.9, false, below))
	_assert_true(not after_expire, "open-fall mode should expire when hysteresis window elapses")

func _test_liquid_open_fall_vertical_priority() -> void:
	var manager = LiquidManagerScript.new()
	manager._ready()
	var coord := Vector2i.ZERO
	manager._chunk_liquids[coord] = {
		"10,10": {"type": "water", "amount": 1.0},
		"9,11": {"type": "water", "amount": 1.0},
		"11,11": {"type": "water", "amount": 1.0},
	}

	var changed: Dictionary = {}
	var simulated := bool(manager._simulate_active_cell(Vector2i(10, 10), changed))
	_assert_true(simulated, "open-fall vertical-priority setup should be simulated")

	var below_entry = manager._get_cell_entry(Vector2i(10, 11))
	var below_amount := 0.0
	if below_entry is Dictionary:
		below_amount = float((below_entry as Dictionary).get("amount", 0.0))
	_assert_true(below_amount >= 0.06, "open-fall vertical priority should move a visible downward slice")

	var left_entry = manager._get_cell_entry(Vector2i(9, 10))
	var right_entry = manager._get_cell_entry(Vector2i(11, 10))
	var side_total := 0.0
	if left_entry is Dictionary:
		side_total += float((left_entry as Dictionary).get("amount", 0.0))
	if right_entry is Dictionary:
		side_total += float((right_entry as Dictionary).get("amount", 0.0))
	_assert_true(side_total <= 0.05, "open-fall vertical priority should suppress obvious side bleed")

func _test_liquid_open_fall_short_cooldown_cap() -> void:
	var manager = LiquidManagerScript.new()
	manager._ready()

	var open_delay := int(manager._adaptive_fall_delay_ms("water", 0.12, 0.8, true))
	_assert_true(open_delay <= manager.WATER_OPEN_FALL_COOLDOWN_MAX_MS, "water open-fall cooldown should be capped for smoother cascade")

	var regular_delay := int(manager._adaptive_fall_delay_ms("water", 0.12, 0.8, false))
	_assert_true(regular_delay >= open_delay, "regular water fall cooldown should not be shorter than open-fall cap")

	var lava_delay := int(manager._adaptive_fall_delay_ms("lava", 0.12, 0.8, true))
	_assert_true(lava_delay > manager.WATER_OPEN_FALL_COOLDOWN_MAX_MS, "lava should not use water open-fall cooldown cap")

func _test_liquid_water_split_gain_guardrail() -> void:
	var manager = LiquidManagerScript.new()
	manager._ready()

	var boosted := float(manager._apply_water_lateral_split_gain("water", 0.05, 0.2, 0.2))
	_assert_true(absf(boosted - 0.0505) < 0.000001, "water split gain should apply 1% lateral boost")

	var lava_unchanged := float(manager._apply_water_lateral_split_gain("lava", 0.05, 0.2, 0.2))
	_assert_true(absf(lava_unchanged - 0.05) < 0.000001, "non-water liquids should not receive split gain")

	var capped := float(manager._apply_water_lateral_split_gain("water", 0.05, 0.0502, 0.0502))
	_assert_true(absf(capped - 0.0502) < 0.000001, "water split gain should remain capped by source/capacity")

func _test_liquid_clear_epsilon_threshold() -> void:
	var manager = LiquidManagerScript.new()
	manager._ready()
	var coord := Vector2i.ZERO
	manager._chunk_liquids[coord] = {}

	var changed: Dictionary = {}
	manager._set_cell_entry(Vector2i(2, 2), "water", 0.30, changed)
	manager._set_cell_entry(Vector2i(2, 2), "water", 0.002, changed)
	_assert_true(not (manager._get_cell_entry(Vector2i(2, 2)) is Dictionary), "amount at clear epsilon should be removed")

	manager._set_cell_entry(Vector2i(3, 2), "water", 0.0021, changed)
	var kept_entry = manager._get_cell_entry(Vector2i(3, 2))
	_assert_true(kept_entry is Dictionary, "amount above clear epsilon should remain persisted")

func _test_liquid_flow_direction_stability() -> void:
	var manager = LiquidManagerScript.new()
	manager._ready()
	var coord := Vector2i.ZERO
	manager._chunk_liquids[coord] = {
		"10,10": {"type": "water", "amount": 0.8},
		"9,10": {"type": "water", "amount": 0.4},
		"11,10": {"type": "water", "amount": 0.4},
	}
	manager._record_lateral_direction(Vector2i(10, 10), -1)
	var dirs: Array[int] = manager._compute_lateral_dirs(Vector2i(10, 10), "water")
	_assert_true(not dirs.is_empty(), "direction list should not be empty")
	if not dirs.is_empty():
		_assert_eq(dirs[0], -1, "near-equal side capacity should honor short-lived remembered direction")

func _test_liquid_persistence_seed_override_guard() -> void:
	var manager = LiquidManagerScript.new()
	manager._ready()
	var coord := Vector2i.ZERO
	var chunk = WorldChunkScript.new()
	chunk.coord = coord
	chunk.liquid_state_initialized = true
	chunk.liquid_cells = {}

	manager.on_chunk_loaded(coord, chunk)
	manager.ingest_generated_liquids(coord, {
		"_liquid_seeds": [
			{"local_pos": Vector2i(4, 4), "type": "water", "amount": 1.0},
		]
	}, chunk)

	var cells_variant = manager._chunk_liquids.get(coord, {})
	_assert_true(cells_variant is Dictionary, "runtime chunk liquid map should remain a dictionary")
	if cells_variant is Dictionary:
		_assert_true((cells_variant as Dictionary).is_empty(), "initialized empty liquid chunk must not be reseeded on ingest")

func _test_liquid_flush_runtime_to_chunk_state() -> void:
	var manager = LiquidManagerScript.new()
	manager._ready()
	var coord := Vector2i.ZERO
	var chunk = WorldChunkScript.new()
	chunk.coord = coord
	chunk.liquid_state_initialized = false
	chunk.liquid_cells = {}

	manager._chunk_liquids[coord] = {
		"1,1": {"type": "water", "amount": 0.75},
	}
	var chunks := {coord: chunk}
	var touched: Array = manager.flush_runtime_to_chunks(chunks)
	_assert_true(touched.has(coord), "runtime flush should mark touched chunk when liquid state changes")
	_assert_true(chunk.liquid_cells.has("1,1"), "runtime flush should copy authoritative liquid cells into chunk resource")
	_assert_true(chunk.liquid_state_initialized, "runtime flush should set liquid_state_initialized")

func _test_liquid_authoritative_contact_query() -> void:
	var manager = LiquidManagerScript.new()
	manager._ready()
	var coord := Vector2i.ZERO
	manager._chunk_liquids[coord] = {
		"5,5": {"type": "water", "amount": 0.65},
	}

	var entry = manager.get_liquid_cell_entry(Vector2i(5, 5))
	_assert_true(entry is Dictionary and not (entry as Dictionary).is_empty(), "authoritative liquid entry query should return dictionary for filled cell")
	if entry is Dictionary:
		_assert_eq(String((entry as Dictionary).get("type", "")), "water", "authoritative liquid entry should preserve liquid type")
		_assert_true(absf(float((entry as Dictionary).get("amount", 0.0)) - 0.65) < 0.0001, "authoritative liquid entry should preserve amount")

	var filtered_amount := manager.get_liquid_amount_at_world_cell(Vector2i(5, 5), "lava")
	_assert_true(absf(filtered_amount) < 0.0001, "type-filtered amount query should return zero on type mismatch")

	var contact = manager.get_liquid_contact_at_global_position(Vector2(81.0, 81.0))
	_assert_true(bool(contact.get("in_liquid", false)), "global-position contact query should report in-liquid for mapped filled cell")
	_assert_true(absf(float(contact.get("amount", 0.0)) - 0.65) < 0.0001, "global-position contact query should preserve authoritative amount")

	var dry_contact = manager.get_liquid_contact_at_global_position(Vector2(16.0, 16.0))
	_assert_true(not bool(dry_contact.get("in_liquid", true)), "global-position contact query should report dry cell as out-of-liquid")

func _test_player_water_state_thresholds() -> void:
	var player = PlayerScript.new()

	var to_wading := player._resolve_water_state_from_probes(player.WATER_STATE_DRY, 0.12, 0.0, 0.0, 0.10)
	_assert_eq(to_wading, player.WATER_STATE_WADING, "water state should enter wading when foot probe crosses threshold")

	var to_swimming := player._resolve_water_state_from_probes(player.WATER_STATE_WADING, 0.20, 0.30, 0.0, 0.50)
	_assert_eq(to_swimming, player.WATER_STATE_SWIMMING, "water state should enter swimming when torso probe crosses threshold")

	var to_submerged := player._resolve_water_state_from_probes(player.WATER_STATE_SWIMMING, 0.20, 0.30, 0.35, 0.86)
	_assert_eq(to_submerged, player.WATER_STATE_SUBMERGED, "water state should enter submerged when head probe crosses threshold")

	var hold_submerged := player._resolve_water_state_from_probes(player.WATER_STATE_SUBMERGED, 0.10, 0.22, 0.20, 0.60)
	_assert_eq(hold_submerged, player.WATER_STATE_SUBMERGED, "submerged state should honor hysteresis before exiting")

	var to_dry := player._resolve_water_state_from_probes(player.WATER_STATE_SUBMERGED, 0.0, 0.0, 0.0, 0.0)
	_assert_eq(to_dry, player.WATER_STATE_DRY, "water state should recover to dry when all probes clear")

func _test_player_water_motion_profiles() -> void:
	var player = PlayerScript.new()

	var dry_profile = player._water_motion_profile_for_state(player.WATER_STATE_DRY, 0.0)
	var swim_profile = player._water_motion_profile_for_state(player.WATER_STATE_SWIMMING, 0.7)
	var submerged_profile = player._water_motion_profile_for_state(player.WATER_STATE_SUBMERGED, 0.9)

	_assert_true(float(dry_profile.get("speed_scale", 0.0)) >= 0.99, "dry profile should keep near-default horizontal speed")
	_assert_true(float(swim_profile.get("speed_scale", 1.0)) < float(dry_profile.get("speed_scale", 1.0)), "swimming profile should reduce speed compared with dry")
	_assert_true(float(swim_profile.get("buoyancy", 0.0)) > 0.0, "swimming profile should add positive buoyancy")
	_assert_true(float(submerged_profile.get("max_fall_speed", 0.0)) < float(swim_profile.get("max_fall_speed", 0.0)), "submerged profile should clamp fall speed harder than swimming")

func _test_player_water_event_throttle() -> void:
	var player = PlayerScript.new()
	var events: Array[String] = []
	player.water_interaction_event.connect(func(event_name: String, _immersion: float) -> void:
		events.append(event_name)
	)

	player._water_immersion = 0.7
	player._emit_water_event("underwater_loop")
	player._emit_water_event("underwater_loop")

	_assert_eq(events.size(), 1, "underwater loop event should be throttled within cooldown window")
