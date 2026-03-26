extends SceneTree

var _failures: Array[String] = []
const WorldTopologyScript = preload("res://src/systems/world/world_topology.gd")
const LiquidManagerScript = preload("res://src/systems/world/liquid_manager.gd")

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
	_test_planetary_preload_domain_contract()
	_test_liquid_extension_interface()

func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

func _test_new_world_boundary_metadata() -> void:
	var topology = WorldTopologyScript.new()
	topology.create_new_world(12345, "medium")
	_assert_true(topology.is_depth_boundary_enabled(), "new medium world should enable depth boundary")
	_assert_eq(topology.get_bedrock_start_depth(), 3200, "medium preset bedrock_start_depth should match contract")
	_assert_eq(topology.get_bedrock_hard_floor_depth(), 3400, "medium preset bedrock_hard_floor_depth should match contract")
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
