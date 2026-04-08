extends SceneTree

var _failures: Array[String] = []

const MAX_ROOM_WIDTH := 1400.0
const MAX_ROOM_HEIGHT := 700.0
const REQUIRED_ENTRY_ATTEMPTS := 30

const REQUIRED_ITEM_RESOURCES := [
	"res://data/items/boss/slime_king_sigil.tres",
	"res://data/items/boss/skeleton_king_sigil.tres",
	"res://data/items/boss/eye_king_sigil.tres",
	"res://data/items/boss/slime_king_core.tres",
	"res://data/items/boss/skeleton_king_core.tres",
	"res://data/items/boss/eye_king_core.tres",
	"res://data/items/boss/forbidden_key.tres",
]

const REQUIRED_ENCOUNTER_SCENES := [
	"res://scenes/worlds/encounters/boss_slime_king.tscn",
	"res://scenes/worlds/encounters/boss_skeleton_king.tscn",
	"res://scenes/worlds/encounters/boss_eye_king.tscn",
	"res://scenes/worlds/encounters/boss_mina_finale.tscn",
]

func _init() -> void:
	_run_all()
	if _failures.is_empty():
		print("PASS: boss progression contracts")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _run_all() -> void:
	_test_required_resources_exist()
	_test_item_contracts()
	_test_recipe_contracts_in_crafting_manager()
	_test_encounter_scene_baseline()
	_test_encounter_manager_config()
	_test_encounter_compact_room_thresholds()
	_test_intro_focus_duration_contract()
	_test_entry_mapping_stability_contract()
	_test_localization_keys_present()

func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

func _test_required_resources_exist() -> void:
	for path in REQUIRED_ITEM_RESOURCES:
		_assert_true(ResourceLoader.exists(path), "missing required boss item resource: %s" % path)
	for path in REQUIRED_ENCOUNTER_SCENES:
		_assert_true(ResourceLoader.exists(path), "missing required encounter scene: %s" % path)

func _test_item_contracts() -> void:
	for path in REQUIRED_ITEM_RESOURCES:
		if not ResourceLoader.exists(path):
			continue
		var item = load(path)
		_assert_true(item is BaseItem, "resource must be BaseItem: %s" % path)
		if not (item is BaseItem):
			continue
		var item_id := String(item.id)
		_assert_true(not item_id.is_empty(), "boss item id should not be empty: %s" % path)
		if item_id.ends_with("_sigil") or item_id == "forbidden_key":
			_assert_true(not item.stackable, "trigger item should not be stackable: %s" % item_id)
			_assert_true(item.max_stack == 1, "trigger item max_stack should be 1: %s" % item_id)

func _test_recipe_contracts_in_crafting_manager() -> void:
	var script_text := _read_text("res://src/systems/crafting/crafting_manager.gd")
	_assert_true(script_text.find("slime_essence\": 10") != -1, "missing slime sigil recipe ingredient contract")
	_assert_true(script_text.find("bone_fragment\": 10") != -1, "missing skeleton sigil recipe ingredient contract")
	_assert_true(script_text.find("void_eyeball\": 10") != -1, "missing eye sigil recipe ingredient contract")
	_assert_true(script_text.find("arcane_dust\": 10") != -1, "missing forbidden key dust requirement")
	_assert_true(script_text.find("slime_king_core\": 1") != -1, "missing forbidden key slime core requirement")
	_assert_true(script_text.find("skeleton_king_core\": 1") != -1, "missing forbidden key skeleton core requirement")
	_assert_true(script_text.find("eye_king_core\": 1") != -1, "missing forbidden key eye core requirement")

func _test_encounter_scene_baseline() -> void:
	for scene_path in REQUIRED_ENCOUNTER_SCENES:
		if not ResourceLoader.exists(scene_path):
			continue
		var packed: PackedScene = load(scene_path)
		var runtime = packed.instantiate()
		_assert_true(runtime != null, "failed to instantiate encounter scene: %s" % scene_path)
		if runtime == null:
			continue
		_assert_true(runtime.has_method("validate_tutorial_style_baseline"), "encounter scene missing tutorial baseline validator: %s" % scene_path)
		if runtime.has_method("validate_tutorial_style_baseline"):
			_assert_true(runtime.validate_tutorial_style_baseline(), "encounter scene baseline nodes incomplete: %s" % scene_path)
		runtime.free()

func _test_encounter_manager_config() -> void:
	var script_text := _read_text("res://src/systems/boss/boss_encounter_manager.gd")
	_assert_true(script_text.find("slime_king_sigil") != -1, "encounter manager config missing slime sigil")
	_assert_true(script_text.find("skeleton_king_sigil") != -1, "encounter manager config missing skeleton sigil")
	_assert_true(script_text.find("eye_king_sigil") != -1, "encounter manager config missing eye sigil")
	_assert_true(script_text.find("forbidden_key") != -1, "encounter manager config missing forbidden key")
	_assert_true(script_text.find("mina_finale_completed") != -1, "encounter manager missing finale persistence write")

func _test_encounter_compact_room_thresholds() -> void:
	for scene_path in REQUIRED_ENCOUNTER_SCENES:
		if not ResourceLoader.exists(scene_path):
			continue
		var packed: PackedScene = load(scene_path)
		var runtime = packed.instantiate()
		_assert_true(runtime != null, "failed to instantiate encounter scene for room threshold check: %s" % scene_path)
		if runtime == null:
			continue
		_assert_true(runtime.has_method("get_compact_room_size"), "encounter scene missing compact size method: %s" % scene_path)
		if runtime.has_method("get_compact_room_size"):
			var room_size: Vector2 = runtime.get_compact_room_size()
			_assert_true(room_size.x > 0.0 and room_size.y > 0.0, "encounter scene room size should be measurable: %s" % scene_path)
			_assert_true(room_size.x <= MAX_ROOM_WIDTH, "encounter scene width exceeds compact threshold: %s" % scene_path)
			_assert_true(room_size.y <= MAX_ROOM_HEIGHT, "encounter scene height exceeds compact threshold: %s" % scene_path)
		runtime.free()

func _test_intro_focus_duration_contract() -> void:
	var script_text := _read_text("res://src/systems/boss/boss_encounter_manager.gd")
	_assert_true(script_text.find("INTRO_FOCUS_DURATION := 1.2") != -1, "encounter intro focus duration contract should be fixed at 1.2 seconds")

func _test_entry_mapping_stability_contract() -> void:
	var manager_script = load("res://src/systems/boss/boss_encounter_manager.gd")
	_assert_true(manager_script != null, "failed to load boss encounter manager script")
	if manager_script == null:
		return
	var manager = manager_script.new()
	_assert_true(manager != null, "failed to instantiate boss encounter manager script")
	if manager == null:
		return
	_assert_true(manager.has_method("run_entry_mapping_self_check"), "encounter manager missing mapping self-check method")
	if manager.has_method("run_entry_mapping_self_check"):
		var report: Dictionary = manager.run_entry_mapping_self_check(REQUIRED_ENTRY_ATTEMPTS)
		for item_id in ["slime_king_sigil", "skeleton_king_sigil", "eye_king_sigil", "forbidden_key"]:
			_assert_true(report.has(item_id), "mapping self-check missing item id: %s" % item_id)
			if not report.has(item_id):
				continue
			var entry: Dictionary = report[item_id]
			var attempts := int(entry.get("attempts", 0))
			var success := int(entry.get("success", 0))
			_assert_true(attempts == REQUIRED_ENTRY_ATTEMPTS, "mapping self-check attempts mismatch for %s" % item_id)
			_assert_true(success == REQUIRED_ENTRY_ATTEMPTS, "mapping self-check success should be 100%% for %s" % item_id)

func _test_localization_keys_present() -> void:
	var csv_text := _read_text("res://assets/translations.csv")
	for key in [
		"ITEM_BOSS_SLIME_KING_SIGIL",
		"ITEM_BOSS_SKELETON_KING_SIGIL",
		"ITEM_BOSS_EYE_KING_SIGIL",
		"ITEM_BOSS_SLIME_KING_CORE",
		"ITEM_BOSS_SKELETON_KING_CORE",
		"ITEM_BOSS_EYE_KING_CORE",
		"ITEM_BOSS_FORBIDDEN_KEY",
	]:
		_assert_true(csv_text.find(key) != -1, "missing translation key: %s" % key)
