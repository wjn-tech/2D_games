extends Node

const ENCOUNTER_ORIGIN := Vector2(0.0, -3200.0)
const INTRO_FOCUS_DURATION := 1.2
const MAX_INPUT_LOCK_DURATION := 2.0
const INTRO_PREPAN_MAX_DURATION := 0.26
const INTRO_CAMERA_SHAKE_INTENSITY := 2.2
const INTRO_CAMERA_SHAKE_DURATION := 0.16
const ENTRY_STABILITY_ATTEMPTS := 30
const ENCOUNTER_RECOVERY_FALL_DISTANCE := 1400.0
const ENCOUNTER_RECOVERY_COOLDOWN := 0.35
const ENCOUNTER_RESCUE_FLOOR_OFFSET := 260.0
const ENCOUNTER_RESCUE_FLOOR_WIDTH := 2000.0
const ENCOUNTER_RESCUE_FLOOR_THICKNESS := 64.0
const ENCOUNTER_CONFIG := {
	"slime_king_sigil": {
		"encounter_id": "slime_king",
		"scene": "res://scenes/worlds/encounters/boss_slime_king.tscn",
		"title": "Slime King",
		"reward_core_id": "slime_king_core",
		"is_finale": false,
	},
	"skeleton_king_sigil": {
		"encounter_id": "skeleton_king",
		"scene": "res://scenes/worlds/encounters/boss_skeleton_king.tscn",
		"title": "Skeleton King",
		"reward_core_id": "skeleton_king_core",
		"is_finale": false,
	},
	"eye_king_sigil": {
		"encounter_id": "eye_king",
		"scene": "res://scenes/worlds/encounters/boss_eye_king.tscn",
		"title": "Eye King",
		"reward_core_id": "eye_king_core",
		"is_finale": false,
	},
	"forbidden_key": {
		"encounter_id": "mina_finale",
		"scene": "res://scenes/worlds/encounters/boss_mina_finale.tscn",
		"title": "Mina",
		"reward_core_id": "",
		"is_finale": true,
	},
}

var _active: bool = false
var _finishing: bool = false
var _active_trigger_item_id: String = ""
var _active_encounter_id: String = ""
var _entry_snapshot: Dictionary = {}
var _encounter_scene: Node = null
var _player_ref: Node2D = null
var _return_position: Vector2 = Vector2.ZERO
var _return_player_layer_index: int = 0
var _return_active_layer_index: int = 0
var _return_player_collision_layer: int = 0
var _return_player_collision_mask: int = 0
var _encounter_player_spawn_global: Vector2 = Vector2.ZERO
var _encounter_has_spawn_reference: bool = false
var _encounter_fall_rescue_cooldown: float = 0.0
var _encounter_rescue_floor: StaticBody2D = null
var _tracked_boss: Node = null

func _process(delta: float) -> void:
	if not _active or _finishing:
		return
	if not _encounter_has_spawn_reference:
		return
	if _player_ref == null or not is_instance_valid(_player_ref):
		return

	if _encounter_fall_rescue_cooldown > 0.0:
		_encounter_fall_rescue_cooldown = maxf(0.0, _encounter_fall_rescue_cooldown - delta)

	var recover_threshold_y := _encounter_player_spawn_global.y + ENCOUNTER_RECOVERY_FALL_DISTANCE
	if _encounter_fall_rescue_cooldown <= 0.0 and _player_ref.global_position.y > recover_threshold_y:
		# Encounter phase skips overworld freefall recovery; add a local rescue to prevent endless falling.
		push_warning("BossEncounterManager: rescued player from encounter freefall at y=%s (threshold=%s)" % [str(_player_ref.global_position.y), str(recover_threshold_y)])
		_player_ref.global_position = _encounter_player_spawn_global
		if _player_ref.get("velocity") != null:
			_player_ref.velocity = Vector2.ZERO
		var camera: Camera2D = _player_ref.get_node_or_null("Camera2D")
		if camera:
			camera.make_current()
			camera.global_position = _player_ref.global_position
		_encounter_fall_rescue_cooldown = ENCOUNTER_RECOVERY_COOLDOWN

func is_encounter_active() -> bool:
	return _active

func is_player_in_active_encounter(player: Node) -> bool:
	return _active and player != null and player == _player_ref

func try_start_encounter_from_player(player: Node2D) -> bool:
	if player == null or _active:
		return false
	if GameState == null or GameState.inventory == null:
		return false

	var equipped = GameState.inventory.get_equipped_item()
	if equipped == null:
		return false

	var item_id := ""
	var raw_item_id = equipped.get("id")
	if raw_item_id != null:
		item_id = String(raw_item_id).strip_edges()
	if item_id.is_empty() or not ENCOUNTER_CONFIG.has(item_id):
		if not item_id.is_empty():
			push_warning("BossEncounterManager: unsupported encounter trigger item %s" % item_id)
		return false

	if GameState.inventory.get_item_count(item_id) <= 0:
		return false

	if not GameState.inventory.remove_item_by_id(item_id, 1):
		return false

	var config: Dictionary = ENCOUNTER_CONFIG[item_id]
	if not _create_runtime_encounter(player, item_id, config):
		return false

	call_deferred("_begin_intro_and_combat")
	return true

func handle_player_death(player: Node2D) -> bool:
	if not is_player_in_active_encounter(player):
		return false
	if _encounter_scene and is_instance_valid(_encounter_scene) and _encounter_scene.has_method("on_player_defeated"):
		_encounter_scene.on_player_defeated()
	else:
		_finish_encounter(false, "")
	return true

func _create_runtime_encounter(player: Node2D, trigger_item_id: String, config: Dictionary) -> bool:
	var scene_path := String(config.get("scene", ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_warning("BossEncounterManager: missing encounter scene %s" % scene_path)
		return false

	var packed: PackedScene = load(scene_path)
	if packed == null:
		return false

	var runtime = packed.instantiate()
	if runtime == null:
		return false

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false

	if runtime is Node2D:
		runtime.global_position = ENCOUNTER_ORIGIN

	if runtime.has_method("validate_tutorial_style_baseline") and not runtime.validate_tutorial_style_baseline():
		push_warning("BossEncounterManager: scene baseline validation failed for %s" % scene_path)
		runtime.queue_free()
		return false

	current_scene.add_child(runtime)

	_entry_snapshot = _capture_entry_snapshot(player)
	_return_position = player.global_position
	_return_player_layer_index = int(player.get_meta("current_layer", 0))
	_return_active_layer_index = _return_player_layer_index
	_return_player_collision_layer = int(player.collision_layer)
	_return_player_collision_mask = int(player.collision_mask)
	if LayerManager != null and LayerManager.get("active_layer") != null:
		_return_active_layer_index = int(LayerManager.active_layer)
	_player_ref = player
	if _player_ref.has_method("clear_mina_combat_debuffs"):
		_player_ref.clear_mina_combat_debuffs()
	_active = true
	_finishing = false
	_active_trigger_item_id = trigger_item_id
	_active_encounter_id = String(config.get("encounter_id", ""))
	_encounter_scene = runtime
	_encounter_has_spawn_reference = false
	_encounter_fall_rescue_cooldown = 0.0

	# Boss arenas are authored on world layer 0; normalize player collision to avoid falling through floor.
	if LayerManager and LayerManager.has_method("move_entity_to_layer"):
		LayerManager.move_entity_to_layer(player, 0)
	if LayerManager and LayerManager.has_method("switch_to_layer"):
		LayerManager.switch_to_layer(0)

	# During isolated encounter, keep player world mask broad to avoid cross-system layer drift causing floor pass-through.
	var world_mask_all := (1 | 2 | 4 | 64 | 128)
	if LayerManager != null:
		world_mask_all = int(LayerManager.LAYER_WORLD_0) | int(LayerManager.LAYER_WORLD_1) | int(LayerManager.LAYER_WORLD_2) | int(LayerManager.LAYER_WORLD_3) | int(LayerManager.LAYER_WORLD_4)
		player.collision_layer = int(LayerManager.LAYER_PLAYER)
		player.collision_mask = world_mask_all | int(LayerManager.LAYER_INTERACTION) | int(LayerManager.LAYER_NPC)
	else:
		player.collision_mask = world_mask_all | 8 | 32

	if runtime.has_method("setup"):
		runtime.setup(player, _entry_snapshot)
	if runtime.has_signal("encounter_completed"):
		runtime.encounter_completed.connect(_on_encounter_completed)

	if runtime.has_method("get_player_spawn_global"):
		_encounter_player_spawn_global = runtime.get_player_spawn_global()
		_encounter_has_spawn_reference = true
		player.global_position = _encounter_player_spawn_global
		if player.get("velocity") != null:
			player.velocity = Vector2.ZERO
	else:
		_encounter_player_spawn_global = player.global_position
		_encounter_has_spawn_reference = true

	_ensure_encounter_rescue_floor(runtime)

	# Force camera ownership/sync after long-distance teleport to avoid rendering an empty view.
	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera:
		camera.make_current()
		camera.global_position = player.global_position
	else:
		push_warning("BossEncounterManager: player Camera2D missing at encounter entry")

	if runtime.has_method("lock_gates"):
		runtime.lock_gates(true)

	return true

func _capture_entry_snapshot(player: Node2D) -> Dictionary:
	var snapshot := {
		"player_health": 100.0,
		"inventory": {},
		"active_hotbar_index": 0,
		"wand_item_snapshot": null,
		"wand_data_snapshot": null,
		"progression": _capture_progression_snapshot(),
	}

	if player and player.get("attributes") != null and player.attributes and player.attributes.data:
		snapshot["player_health"] = float(player.attributes.data.health)
	if GameState and GameState.inventory:
		snapshot["inventory"] = GameState.inventory.serialize_inventory()
		snapshot["active_hotbar_index"] = int(GameState.inventory.active_hotbar_index)
	if player and player.has_method("get_equipped_wand"):
		var wand_item = player.get_equipped_wand()
		if wand_item:
			snapshot["wand_item_snapshot"] = wand_item.duplicate(true)
	if player and player.has_method("get_last_known_wand_snapshot"):
		var last_wand_snapshot = player.get_last_known_wand_snapshot()
		if last_wand_snapshot and last_wand_snapshot is WandData:
			snapshot["wand_data_snapshot"] = (last_wand_snapshot as WandData).duplicate(true)
	if player and player.get("current_wand") != null:
		var current_wand_variant = player.get("current_wand")
		if current_wand_variant is WandData:
			snapshot["wand_data_snapshot"] = (current_wand_variant as WandData).duplicate(true)

	return snapshot

func _capture_progression_snapshot() -> Dictionary:
	var progression := {
		"slime_king_defeated": bool(GameState.get_meta("boss_slime_king_defeated", false)),
		"skeleton_king_defeated": bool(GameState.get_meta("boss_skeleton_king_defeated", false)),
		"eye_king_defeated": bool(GameState.get_meta("boss_eye_king_defeated", false)),
		"mina_finale_completed": bool(GameState.get_meta("mina_finale_completed", false)),
	}
	return progression

func _begin_intro_and_combat() -> void:
	if not _active or _encounter_scene == null or not is_instance_valid(_encounter_scene):
		return
	if _player_ref == null or not is_instance_valid(_player_ref):
		return

	if _player_ref.has_method("set_gravity_enabled"):
		_player_ref.set_gravity_enabled(true)
	_player_ref.input_enabled = false
	_player_ref.movement_locked = true
	if _encounter_scene and _encounter_scene.has_method("set_visual_budget_mode"):
		_encounter_scene.set_visual_budget_mode("normal")

	var lock_duration := minf(INTRO_FOCUS_DURATION, MAX_INPUT_LOCK_DURATION)
	var prepan_duration := minf(INTRO_PREPAN_MAX_DURATION, lock_duration * 0.25)
	var focus_duration := maxf(0.0, lock_duration - prepan_duration)

	var camera: Camera2D = _player_ref.get_node_or_null("Camera2D")
	if camera:
		camera.make_current()
	if camera and camera.has_method("pan_to") and _encounter_scene.has_method("get_intro_focus_global"):
		var focus_pos: Vector2 = _encounter_scene.get_intro_focus_global()
		if prepan_duration > 0.0:
			var pre_pan_pos := _player_ref.global_position.lerp(focus_pos, 0.35)
			camera.pan_to(pre_pan_pos, prepan_duration)
			await get_tree().create_timer(prepan_duration).timeout
		if focus_duration > 0.0:
			camera.pan_to(focus_pos, focus_duration)
	if camera and camera.has_method("shake_screen"):
		camera.shake_screen(INTRO_CAMERA_SHAKE_INTENSITY, INTRO_CAMERA_SHAKE_DURATION)

	await get_tree().create_timer(maxf(0.0, focus_duration)).timeout

	if not _active:
		return

	if UIManager:
		var start_tpl = tr("MSG_BOSS_ENCOUNTER_START")
		if start_tpl == "MSG_BOSS_ENCOUNTER_START":
			start_tpl = "Encounter Started: %s"
		UIManager.show_floating_text(start_tpl % String(_active_encounter_id), _player_ref.global_position + Vector2(0, -40), Color(1.0, 0.8, 0.35))

	if _encounter_scene.has_method("begin_encounter"):
		_encounter_scene.begin_encounter()
	_bind_boss_health_bar()
	if _encounter_scene.has_method("activate_combat"):
		_encounter_scene.activate_combat()

	if camera and camera.has_method("restore_control"):
		camera.restore_control(0.45)

	_player_ref.input_enabled = true
	_player_ref.movement_locked = false

func _on_encounter_completed(success: bool, reward_core_id: String, encounter_id: String) -> void:
	if encounter_id != _active_encounter_id:
		return
	_finish_encounter(success, reward_core_id)

func _finish_encounter(success: bool, reward_core_id: String) -> void:
	if _finishing:
		return
	_finishing = true

	if _player_ref and is_instance_valid(_player_ref):
		_player_ref.input_enabled = false
		_player_ref.movement_locked = true

	if success:
		_apply_victory_rewards(reward_core_id)
	else:
		_restore_failure_snapshot()

	if _player_ref and is_instance_valid(_player_ref) and _player_ref.has_method("clear_mina_combat_debuffs"):
		_player_ref.clear_mina_combat_debuffs()

	if _player_ref and is_instance_valid(_player_ref):
		_player_ref.global_position = _return_position
		_player_ref.collision_layer = _return_player_collision_layer
		_player_ref.collision_mask = _return_player_collision_mask
		if LayerManager and LayerManager.has_method("move_entity_to_layer"):
			LayerManager.move_entity_to_layer(_player_ref, _return_player_layer_index)
		if LayerManager and LayerManager.has_method("switch_to_layer"):
			LayerManager.switch_to_layer(_return_active_layer_index)
		_player_ref.input_enabled = true
		_player_ref.movement_locked = false

	if _encounter_scene and is_instance_valid(_encounter_scene):
		_encounter_scene.queue_free()
	_unbind_tracked_boss_signal()
	_hide_boss_health_bar()

	_active = false
	_finishing = false
	_active_trigger_item_id = ""
	_active_encounter_id = ""
	_entry_snapshot.clear()
	_encounter_scene = null
	_player_ref = null
	_return_player_layer_index = 0
	_return_active_layer_index = 0
	_return_player_collision_layer = 0
	_return_player_collision_mask = 0
	_encounter_player_spawn_global = Vector2.ZERO
	_encounter_has_spawn_reference = false
	_encounter_fall_rescue_cooldown = 0.0
	_encounter_rescue_floor = null
	_tracked_boss = null

func _resolve_hud_node() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("hud")

func _bind_boss_health_bar() -> void:
	if _encounter_scene == null or not is_instance_valid(_encounter_scene):
		return
	if not _encounter_scene.has_method("get_active_boss"):
		return

	var boss: Node = _encounter_scene.get_active_boss()
	if boss == null or not is_instance_valid(boss):
		return
	if _tracked_boss != boss:
		_unbind_tracked_boss_signal()
	_tracked_boss = boss

	if boss.has_signal("health_changed") and not boss.health_changed.is_connected(_on_tracked_boss_health_changed):
		boss.health_changed.connect(_on_tracked_boss_health_changed)

	var hud := _resolve_hud_node()
	if hud and hud.has_method("show_boss_health_bar"):
		var boss_name := _active_encounter_id
		if boss.has_method("get_boss_display_name"):
			boss_name = String(boss.get_boss_display_name())
		var current_hp := 1.0
		var max_hp := 1.0
		if boss.has_method("get_current_health"):
			current_hp = float(boss.get_current_health())
		if boss.has_method("get_max_health"):
			max_hp = float(boss.get_max_health())
		hud.show_boss_health_bar(boss_name, max_hp, current_hp)

func _hide_boss_health_bar() -> void:
	var hud := _resolve_hud_node()
	if hud and hud.has_method("hide_boss_health_bar"):
		hud.hide_boss_health_bar()

func _unbind_tracked_boss_signal() -> void:
	if _tracked_boss == null or not is_instance_valid(_tracked_boss):
		_tracked_boss = null
		return
	if _tracked_boss.has_signal("health_changed") and _tracked_boss.health_changed.is_connected(_on_tracked_boss_health_changed):
		_tracked_boss.health_changed.disconnect(_on_tracked_boss_health_changed)
	_tracked_boss = null

func _on_tracked_boss_health_changed(current_health: float, max_health: float) -> void:
	var hud := _resolve_hud_node()
	if hud and hud.has_method("update_boss_health_bar"):
		hud.update_boss_health_bar(current_health, max_health)

func _resolve_world_layer_for_encounter_floor() -> int:
	if LayerManager != null and LayerManager.get("LAYER_WORLD_0") != null:
		return int(LayerManager.LAYER_WORLD_0)
	return 1

func _ensure_encounter_rescue_floor(runtime: Node) -> void:
	if runtime == null or not is_instance_valid(runtime):
		return
	if not (runtime is Node2D):
		return

	var floor := StaticBody2D.new()
	floor.name = "EncounterRescueFloor"
	floor.collision_layer = _resolve_world_layer_for_encounter_floor()
	floor.collision_mask = 0

	var floor_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ENCOUNTER_RESCUE_FLOOR_WIDTH, ENCOUNTER_RESCUE_FLOOR_THICKNESS)
	floor_shape.shape = rect
	floor.add_child(floor_shape)

	var runtime_root := runtime as Node2D
	runtime_root.add_child(floor)
	floor.global_position = _encounter_player_spawn_global + Vector2(0.0, ENCOUNTER_RESCUE_FLOOR_OFFSET)
	_encounter_rescue_floor = floor

func _apply_victory_rewards(reward_core_id: String) -> void:
	if reward_core_id != "" and GameState and GameState.inventory:
		var reward_item = GameState.item_db.get(reward_core_id, null)
		if reward_item and reward_item is BaseItem:
			GameState.inventory.add_item_or_drop(reward_item, 1)
			if UIManager:
				var victory_tpl = tr("MSG_BOSS_ENCOUNTER_VICTORY")
				if victory_tpl == "MSG_BOSS_ENCOUNTER_VICTORY":
					victory_tpl = "Encounter victory: gained %s"
				UIManager.show_floating_text(victory_tpl % reward_item.display_name, _return_position + Vector2(0, -30), Color.PALE_GREEN)

	match _active_encounter_id:
		"slime_king":
			GameState.set_meta("boss_slime_king_defeated", true)
		"skeleton_king":
			GameState.set_meta("boss_skeleton_king_defeated", true)
		"eye_king":
			GameState.set_meta("boss_eye_king_defeated", true)
		"mina_finale":
			GameState.set_meta("mina_finale_completed", true)
			if UIManager:
				var finale_msg = tr("MSG_BOSS_FINALE_COMPLETE")
				if finale_msg == "MSG_BOSS_FINALE_COMPLETE":
					finale_msg = "Finale complete. You can continue playing."
				UIManager.show_floating_text(finale_msg, _return_position + Vector2(0, -48), Color(1.0, 0.86, 0.4))

func _restore_failure_snapshot() -> void:
	if GameState and GameState.inventory and _entry_snapshot.has("inventory"):
		var inv_data: Dictionary = _entry_snapshot.get("inventory", {})
		if not inv_data.is_empty():
			GameState.inventory.load_inventory_data(inv_data)
			if _entry_snapshot.has("active_hotbar_index"):
				GameState.inventory.select_hotbar_slot(int(_entry_snapshot.get("active_hotbar_index", 0)))

	if _player_ref and is_instance_valid(_player_ref) and _player_ref.get("attributes") != null and _player_ref.attributes and _player_ref.attributes.data:
		_player_ref.attributes.data.health = float(_entry_snapshot.get("player_health", _player_ref.attributes.data.max_health))

	if UIManager:
		var fail_tpl = tr("MSG_BOSS_ENCOUNTER_FAIL")
		if fail_tpl == "MSG_BOSS_ENCOUNTER_FAIL":
			fail_tpl = "Encounter failed. Returned to entry point."
		UIManager.show_floating_text(fail_tpl, _return_position + Vector2(0, -24), Color(1.0, 0.55, 0.55))

func get_encounter_scene_path_for_item(item_id: String) -> String:
	if not ENCOUNTER_CONFIG.has(item_id):
		return ""
	return String((ENCOUNTER_CONFIG[item_id] as Dictionary).get("scene", ""))

func run_entry_mapping_self_check(attempts: int = ENTRY_STABILITY_ATTEMPTS) -> Dictionary:
	var normalized_attempts := maxi(1, attempts)
	var report := {}
	for item_id in ENCOUNTER_CONFIG.keys():
		var scene_path := get_encounter_scene_path_for_item(String(item_id))
		var success_count := 0
		for _i in range(normalized_attempts):
			var ok := not scene_path.is_empty() and ResourceLoader.exists(scene_path)
			if ok:
				var packed: PackedScene = load(scene_path)
				ok = packed != null
			if ok:
				success_count += 1
		report[String(item_id)] = {
			"attempts": normalized_attempts,
			"success": success_count,
			"success_rate": float(success_count) / float(normalized_attempts),
		}
	return report
