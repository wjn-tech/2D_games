extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	_run_all()
	if _failures.is_empty():
		print("PASS: inventory save/load stacking")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _run_all() -> void:
	_test_stack_match_by_item_id()
	_test_legacy_inventory_load_merges_duplicate_stacks()
	_test_serialized_inventory_uses_stable_item_keys()
	_test_runtime_wand_survives_serialization()

func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

func _make_manager() -> InventoryManager:
	var manager = InventoryManager.new()
	manager._init_inventories()
	return manager

func _make_item(path: String) -> BaseItem:
	var item = load(path).duplicate(true)
	item.id = load(path).id
	return item

func _test_stack_match_by_item_id() -> void:
	var manager = _make_manager()
	var item_a = _make_item("res://data/items/wood.tres")
	var item_b = _make_item("res://data/items/wood.tres")

	var first_added = manager.add_item(item_a, 2)
	var second_added = manager.add_item(item_b, 3)
	_assert_true(first_added and second_added, "same-id items should be added successfully")
	_assert_eq(manager.hotbar.get_slot(0).get("count", 0), 5, "same-id items from different instances should stack together")

func _test_legacy_inventory_load_merges_duplicate_stacks() -> void:
	var manager = _make_manager()
	var item_a = _make_item("res://data/items/wood.tres")
	var item_b = _make_item("res://data/items/wood.tres")

	manager.load_inventory_data({
		"backpack": [
			{"item": item_a, "count": 2},
			{"item": item_b, "count": 4}
		],
		"hotbar": []
	})

	_assert_eq(manager.backpack.get_slot(0).get("count", 0), 6, "legacy inventory load should merge duplicate stacks into the first slot")
	_assert_true(manager.backpack.get_slot(1).get("item") == null, "merged legacy duplicate slot should be cleared")

func _test_serialized_inventory_uses_stable_item_keys() -> void:
	var manager = _make_manager()
	var item = _make_item("res://data/items/wood.tres")
	manager.add_item(item, 2)

	var saved = manager.serialize_inventory()
	var slot = saved.get("hotbar", [])[0] if saved.get("hotbar", []).size() > 0 else {}
	_assert_eq(String(slot.get("item_id", "")), "wood", "serialized inventory should persist item ids")
	_assert_true(not slot.has("item"), "serialized inventory should not persist raw Resource objects")

func _test_runtime_wand_survives_serialization() -> void:
	var manager = _make_manager()
	var wand_item = WandItem.new()
	wand_item.id = "runtime_test_wand"
	wand_item.display_name = "Runtime Test Wand"
	var wand_data = WandData.new()
	var embryo = WandEmbryo.new()
	embryo.recharge_time = 0.25
	wand_data.embryo = embryo
	wand_item.wand_data = wand_data

	manager.add_item(wand_item, 1)
	var saved = manager.serialize_inventory()
	var slot = saved.get("hotbar", [])[0] if saved.get("hotbar", []).size() > 0 else {}
	_assert_true(slot.get("item_data") is WandItem, "runtime wand should embed raw item data during serialization")

	var restored_manager = _make_manager()
	restored_manager.load_inventory_data(saved)
	var restored_item = restored_manager.hotbar.get_slot(0).get("item")
	_assert_true(restored_item is WandItem, "runtime wand should restore as WandItem after serialization")
	_assert_true(restored_item != null and restored_item.wand_data != null, "restored runtime wand should preserve wand data")
	_assert_eq(restored_item.display_name, "Runtime Test Wand", "restored runtime wand should preserve display name")

