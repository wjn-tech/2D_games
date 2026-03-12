extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	_run_all()
	if _failures.is_empty():
		print("PASS: recursive wand execution semantics")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _run_all() -> void:
	_test_single_route_modifier_to_projectile()
	_test_long_linear_modifier_chain_compiles_projectile()
	_test_parallel_branch_inherits_modifier_load()
	_test_trigger_payload_delay_and_recharge()
	_test_negative_delay_recharge_and_mana()
	_test_multiple_root_sources_share_cycle_only()
	_test_nested_trigger_continuations()

func _make_wand() -> WandData:
	var wand = WandData.new()
	wand.id = "test_wand"
	wand.current_mana = 1000.0
	var embryo = WandEmbryo.new()
	embryo.base_mana_cost = 0.0
	embryo.cast_delay = 0.0
	embryo.recharge_time = 0.5
	embryo.mana_capacity = 1000.0
	wand.embryo = embryo
	return wand

func _add_node(wand: WandData, node_id: int, node_type: String, params: Dictionary = {}, pos: Vector2 = Vector2.ZERO) -> void:
	wand.logic_nodes.append({
		"id": node_id,
		"wand_logic_type": node_type,
		"value": params,
		"position": pos,
	})

func _connect(wand: WandData, from_id: int, from_port: int, to_id: int) -> void:
	wand.logic_connections.append({
		"from_id": from_id,
		"from_port": from_port,
		"to_id": to_id,
		"to_port": 0,
	})

func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

func _assert_float(actual: float, expected: float, message: String, epsilon: float = 0.001) -> void:
	if abs(actual - expected) > epsilon:
		_failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

func _record_modifier_types(record: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for mod in record.get("applied_modifiers", []):
		if mod is SpellInstruction and mod.params is Dictionary:
			result.append(str(mod.params.get("type", "")))
	return result

func _test_single_route_modifier_to_projectile() -> void:
	var wand = _make_wand()
	_add_node(wand, 1, "generator", {}, Vector2(0, 0))
	_add_node(wand, 2, "modifier_damage", {"mana_cost": 10.0, "delay": 0.05, "recharge": 0.2, "damage_add": 5.0}, Vector2(32, 0))
	_add_node(wand, 3, "action_projectile", {"mana_cost": 5.0, "delay": 0.1, "damage": 10.0}, Vector2(64, 0))
	_connect(wand, 1, 0, 2)
	_connect(wand, 2, 0, 3)

	var plan = SpellProcessor.debug_build_cast_plan(wand)
	_assert_true(plan.get("is_valid", false), "single-route plan should be valid")
	var emissions = plan.get("emissions", [])
	_assert_eq(emissions.size(), 1, "single-route should compile one emission")
	if emissions.size() == 1:
		var record = emissions[0]
		_assert_eq(_record_modifier_types(record), ["modifier_damage"], "single-route should attach modifier to projectile")
		_assert_float(float(record.get("fire_delay", 0.0)), 0.15, "single-route fire delay should include modifier and projectile delay")
	_assert_float(float(plan.get("total_mana_cost", 0.0)), 15.0, "single-route total mana should include modifier and projectile")
	_assert_float(float(plan.get("recharge_time", 0.0)), 0.7, "single-route recharge should include modifier recharge once")

func _test_long_linear_modifier_chain_compiles_projectile() -> void:
	var wand = _make_wand()
	_add_node(wand, 1, "generator", {}, Vector2(0, 0))

	var previous_id = 1
	for index in range(2, 26):
		_add_node(wand, index, "modifier_delay", {"mana_cost": 0.0, "delay": -0.05, "recharge": -0.15}, Vector2(index * 32, 0))
		_connect(wand, previous_id, 0, index)
		previous_id = index

	_add_node(wand, 26, "action_projectile", {"projectile_id": "blackhole", "mana_cost": 180.0, "damage": 5.0, "lifetime": 8.0, "speed": 50.0, "delay": 0.8}, Vector2(26 * 32, 0))
	_connect(wand, previous_id, 0, 26)

	var plan = SpellProcessor.debug_build_cast_plan(wand)
	_assert_true(plan.get("is_valid", false), "long linear chain should still compile as valid")
	var emissions = plan.get("emissions", [])
	_assert_eq(emissions.size(), 1, "long linear modifier chain should compile one projectile emission")
	if emissions.size() == 1:
		var record = emissions[0]
		_assert_eq(str(record.get("instruction").params.get("projectile_id", "")), "blackhole", "long linear chain should keep the terminal projectile")
		_assert_float(float(record.get("fire_delay", 0.0)), 0.0, "negative modifier chain should clamp final projectile delay to zero")

func _test_parallel_branch_inherits_modifier_load() -> void:
	var wand = _make_wand()
	_add_node(wand, 1, "generator", {}, Vector2(0, 0))
	_add_node(wand, 2, "modifier_damage", {"mana_cost": 10.0, "delay": 0.05, "recharge": 0.2, "damage_add": 5.0}, Vector2(32, 0))
	_add_node(wand, 3, "splitter", {}, Vector2(64, 0))
	_add_node(wand, 4, "action_projectile", {"mana_cost": 4.0, "delay": 0.1, "damage": 6.0}, Vector2(96, -16))
	_add_node(wand, 5, "action_projectile", {"mana_cost": 6.0, "delay": 0.2, "damage": 8.0}, Vector2(96, 16))
	_connect(wand, 1, 0, 2)
	_connect(wand, 2, 0, 3)
	_connect(wand, 3, 0, 4)
	_connect(wand, 3, 1, 5)

	var plan = SpellProcessor.debug_build_cast_plan(wand)
	var emissions = plan.get("emissions", [])
	_assert_eq(emissions.size(), 2, "parallel branch should compile two emissions")
	for record in emissions:
		_assert_eq(_record_modifier_types(record), ["modifier_damage"], "parallel branches should inherit parent modifier exactly once")
	_assert_float(float(plan.get("total_mana_cost", 0.0)), 20.0, "parallel branch mana should count shared modifier once and each projectile once")
	_assert_float(float(plan.get("recharge_time", 0.0)), 0.7, "parallel branch recharge should count shared modifier once")

func _test_trigger_payload_delay_and_recharge() -> void:
	var wand = _make_wand()
	_add_node(wand, 1, "generator", {}, Vector2(0, 0))
	_add_node(wand, 2, "modifier_damage", {"mana_cost": 3.0, "delay": 0.2, "recharge": 0.1, "damage_add": 2.0}, Vector2(32, 0))
	_add_node(wand, 3, "trigger", {"mana_cost": 5.0, "trigger_type": "timer", "delay": 0.1, "duration": 0.5}, Vector2(64, 0))
	_add_node(wand, 4, "modifier_speed", {"mana_cost": 7.0, "delay": 0.5, "recharge": 0.4, "speed_add": 100.0}, Vector2(96, 0))
	_add_node(wand, 5, "action_projectile", {"mana_cost": 11.0, "delay": 0.3, "damage": 10.0}, Vector2(128, 0))
	_connect(wand, 1, 0, 2)
	_connect(wand, 2, 0, 3)
	_connect(wand, 3, 0, 4)
	_connect(wand, 4, 0, 5)

	var plan = SpellProcessor.debug_build_cast_plan(wand)
	var emissions = plan.get("emissions", [])
	_assert_eq(emissions.size(), 1, "trigger path should emit one root trigger")
	if emissions.size() == 1:
		var root_record = emissions[0]
		_assert_float(float(root_record.get("fire_delay", 0.0)), 0.3, "trigger root delay should include pre-trigger modifier and trigger delay")
		var continuation = root_record.get("continuation", {})
		var payload = continuation.get("emissions", []) if continuation is Dictionary else []
		_assert_eq(payload.size(), 1, "trigger should carry one payload emission")
		if payload.size() == 1:
			var payload_record = payload[0]
			_assert_eq(_record_modifier_types(payload_record), ["modifier_speed"], "payload should carry only payload-local modifier")
			_assert_float(float(payload_record.get("fire_delay", 0.0)), 0.3, "payload delay should ignore downstream modifier delay when delay_enable=false")
	_assert_float(float(plan.get("total_mana_cost", 0.0)), 26.0, "trigger path mana should commit root and payload costs at compile time")
	_assert_float(float(plan.get("recharge_time", 0.0)), 1.0, "trigger path recharge should include payload modifier recharge")

func _test_negative_delay_recharge_and_mana() -> void:
	var wand = _make_wand()
	_add_node(wand, 1, "generator", {}, Vector2(0, 0))
	_add_node(wand, 2, "modifier_add_mana", {"mana_cost": -30.0, "delay": -0.2, "recharge": -0.1}, Vector2(32, 0))
	_add_node(wand, 3, "action_projectile", {"mana_cost": 10.0, "delay": 0.05, "damage": 4.0}, Vector2(64, 0))
	_connect(wand, 1, 0, 2)
	_connect(wand, 2, 0, 3)

	var plan = SpellProcessor.debug_build_cast_plan(wand)
	var emissions = plan.get("emissions", [])
	_assert_eq(emissions.size(), 1, "negative edge case should still emit one projectile")
	if emissions.size() == 1:
		_assert_float(float(emissions[0].get("fire_delay", 0.0)), 0.0, "negative delay should clamp projectile fire time to zero")
	_assert_float(float(plan.get("total_mana_cost", 0.0)), -20.0, "negative mana modifier should reduce total cycle mana")
	_assert_float(float(plan.get("recharge_time", 0.0)), 0.4, "negative recharge modifier should reduce recharge time")

func _test_multiple_root_sources_share_cycle_only() -> void:
	var wand = _make_wand()
	_add_node(wand, 1, "generator", {}, Vector2(0, 0))
	_add_node(wand, 2, "modifier_damage", {"mana_cost": 2.0, "recharge": 0.2, "damage_add": 1.0}, Vector2(32, 0))
	_add_node(wand, 3, "action_projectile", {"mana_cost": 4.0, "delay": 0.1, "damage": 5.0}, Vector2(64, 0))
	_add_node(wand, 10, "generator", {}, Vector2(0, 64))
	_add_node(wand, 11, "modifier_speed", {"mana_cost": 3.0, "recharge": 0.3, "speed_add": 50.0}, Vector2(32, 64))
	_add_node(wand, 12, "action_projectile", {"mana_cost": 6.0, "delay": 0.2, "damage": 7.0}, Vector2(64, 64))
	_connect(wand, 1, 0, 2)
	_connect(wand, 2, 0, 3)
	_connect(wand, 10, 0, 11)
	_connect(wand, 11, 0, 12)

	var plan = SpellProcessor.debug_build_cast_plan(wand)
	var emissions = plan.get("emissions", [])
	_assert_eq(emissions.size(), 2, "two root sources should share one cast cycle with two emissions")
	if emissions.size() == 2:
		_assert_eq(_record_modifier_types(emissions[0]).size(), 1, "first root source should keep only its own local modifier")
		_assert_eq(_record_modifier_types(emissions[1]).size(), 1, "second root source should keep only its own local modifier")
	_assert_float(float(plan.get("recharge_time", 0.0)), 1.0, "multiple root sources should sum recharge contributions into one cycle")

func _test_nested_trigger_continuations() -> void:
	var wand = _make_wand()
	_add_node(wand, 1, "generator", {}, Vector2(0, 0))
	_add_node(wand, 2, "trigger", {"mana_cost": 3.0, "trigger_type": "timer", "delay": 0.1, "duration": 0.5}, Vector2(32, 0))
	_add_node(wand, 3, "trigger", {"mana_cost": 4.0, "trigger_type": "collision", "delay": 0.2}, Vector2(64, 0))
	_add_node(wand, 4, "action_projectile", {"mana_cost": 5.0, "delay": 0.3, "damage": 9.0}, Vector2(96, 0))
	_connect(wand, 1, 0, 2)
	_connect(wand, 2, 0, 3)
	_connect(wand, 3, 0, 4)

	var plan = SpellProcessor.debug_build_cast_plan(wand)
	var emissions = plan.get("emissions", [])
	_assert_eq(emissions.size(), 1, "nested trigger path should emit one root trigger")
	if emissions.size() == 1:
		var first_cont = emissions[0].get("continuation", {})
		var second_level = first_cont.get("emissions", []) if first_cont is Dictionary else []
		_assert_eq(second_level.size(), 1, "first trigger should capture nested trigger continuation")
		if second_level.size() == 1:
			var nested_cont = second_level[0].get("continuation", {})
			var final_payload = nested_cont.get("emissions", []) if nested_cont is Dictionary else []
			_assert_eq(final_payload.size(), 1, "nested trigger should capture final projectile continuation during compile")