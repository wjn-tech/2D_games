extends Node

## SaveManager (Autoload)
## 负责管理多槽位存档、元数据读取以及这一系列复杂系统的序列化。

const SAVE_ROOT = "user://saves/"
const DATA_FILENAME = "data.dat"
const THUMBNAIL_FILENAME = "preview.jpg"
const WORLD_DELTAS_DIRNAME = "world_deltas"
const MAX_SAVE_SLOTS = 3

# 临时存储从文件恢复的玩家数据，用于场景重载后同步
var _cached_player_data: Dictionary = {}

# 存档元数据结构
var save_metadata: Dictionary = {}
var current_slot_id: int = -1
var auto_save_timer: Timer
var _autosave_pending: bool = false
var _autosave_running: bool = false
var _autosave_requested_slot: int = -1
var _autosave_world_path: String = ""
var _autosave_data: Dictionary = {}
var _bound_world_storage_prefix: String = ""
var _bound_world_metadata: Dictionary = {}

func _ready() -> void:
	_ensure_root_dir()
	_load_metadata()
	_init_autosave()
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	call_deferred("_reconcile_orphan_world_caches")

func _init_autosave() -> void:
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = 300.0 # 5 minutes
	auto_save_timer.one_shot = false
	# Don't autostart immediately, only after load/new game
	auto_save_timer.timeout.connect(_on_autosave_timeout)
	add_child(auto_save_timer)

func _on_autosave_timeout() -> void:
	if current_slot_id >= 0:
		_request_autosave(current_slot_id)

func _process(_delta: float) -> void:
	if not _autosave_running and _autosave_pending:
		_start_autosave_pipeline(_autosave_requested_slot)

	if _autosave_running:
		_continue_autosave_pipeline()

func _request_autosave(slot_id: int) -> void:
	if slot_id < 0:
		return
	_autosave_requested_slot = slot_id
	_autosave_pending = true

func clear_world_binding() -> void:
	_bound_world_storage_prefix = ""
	_bound_world_metadata.clear()

func _bind_world_context(world_metadata: Dictionary, world_storage_prefix: String) -> void:
	_bound_world_storage_prefix = _sanitize_world_storage_prefix(world_storage_prefix)
	_bound_world_metadata = world_metadata.duplicate(true)

func _resolve_world_context_for_slot(slot_id: int) -> Dictionary:
	var world_metadata := _get_world_metadata()
	var runtime_world_storage_prefix := _extract_world_storage_prefix_from_metadata(world_metadata)
	var world_storage_prefix := runtime_world_storage_prefix

	if slot_id >= 0 and slot_id == current_slot_id and _bound_world_storage_prefix != "":
		if runtime_world_storage_prefix != "" and runtime_world_storage_prefix != _bound_world_storage_prefix:
			push_warning("SaveManager: runtime world prefix drift detected for slot %d, keep bound prefix %s (runtime=%s)" % [slot_id, _bound_world_storage_prefix, runtime_world_storage_prefix])
		world_storage_prefix = _bound_world_storage_prefix
		if not _bound_world_metadata.is_empty():
			world_metadata = _bound_world_metadata.duplicate(true)

	if world_storage_prefix != "":
		_bind_world_context(world_metadata, world_storage_prefix)

	return {
		"world_metadata": world_metadata,
		"world_storage_prefix": world_storage_prefix,
	}

func _start_autosave_pipeline(slot_id: int) -> void:
	if slot_id < 0:
		return
	_autosave_pending = false
	_autosave_running = true

	var slot_dir := _get_slot_dir(slot_id)
	if not DirAccess.dir_exists_absolute(slot_dir):
		DirAccess.make_dir_recursive_absolute(slot_dir)

	var world_context := _resolve_world_context_for_slot(slot_id)
	var world_storage_prefix := String(world_context.get("world_storage_prefix", ""))
	_autosave_world_path = _build_slot_world_deltas_path(slot_dir, world_storage_prefix)
	_autosave_data = {}

	if InfiniteChunkManager:
		InfiniteChunkManager.set_save_root(_autosave_world_path, true)
		InfiniteChunkManager.save_all_deltas(false, false)

func _continue_autosave_pipeline() -> void:
	if InfiniteChunkManager and InfiniteChunkManager.has_method("has_pending_dirty_flushes"):
		if InfiniteChunkManager.has_pending_dirty_flushes():
			return

	if _autosave_data.is_empty():
		_autosave_data = _build_save_data(_resolve_world_context_for_slot(_autosave_requested_slot))
		# Autosave skips thumbnail capture to avoid periodic frame spikes.
		var final_path := _get_data_path(_autosave_requested_slot)
		if not _write_atomic_compressed(final_path, _autosave_data):
			push_warning("SaveManager: Autosave write failed for slot %d" % _autosave_requested_slot)
			_end_autosave_pipeline()
			return
		_update_slot_metadata(_autosave_requested_slot, _autosave_data)
		print("SaveManager: Autosave executed for slot %d" % _autosave_requested_slot)
		_end_autosave_pipeline()

func _end_autosave_pipeline() -> void:
	_autosave_running = false
	_autosave_world_path = ""
	_autosave_data = {}

func flush_save_pipeline_sync() -> void:
	if _autosave_running:
		if InfiniteChunkManager:
			InfiniteChunkManager.flush_pending_dirty_writes_sync()
		if not _autosave_data.is_empty() and _autosave_requested_slot >= 0:
			var final_path := _get_data_path(_autosave_requested_slot)
			if _write_atomic_compressed(final_path, _autosave_data):
				_update_slot_metadata(_autosave_requested_slot, _autosave_data)
		_end_autosave_pipeline()

	if InfiniteChunkManager:
		InfiniteChunkManager.flush_pending_dirty_writes_sync()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		flush_save_pipeline_sync()

func start_autosave() -> void:
	if auto_save_timer:
		auto_save_timer.start()

func stop_autosave() -> void:
	if auto_save_timer:
		auto_save_timer.stop()
	_autosave_pending = false

func _ensure_root_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_ROOT):
		DirAccess.make_dir_recursive_absolute(SAVE_ROOT)

func _get_slot_dir(slot_id: int) -> String:
	return SAVE_ROOT + "slot_%d/" % slot_id

func _get_data_path(slot_id: int) -> String:
	return _get_slot_dir(slot_id) + DATA_FILENAME

func _sanitize_world_storage_prefix(prefix: String) -> String:
	var token := prefix.strip_edges()
	if token == "":
		return ""
	for marker in ["|", "/", "\\", ":", ";", ",", ".", " ", "\t", "\n", "\r"]:
		token = token.replace(marker, "_")
	return token

func _extract_world_storage_prefix_from_metadata(metadata: Dictionary) -> String:
	var explicit_prefix := String(metadata.get("world_storage_prefix", "")).strip_edges()
	if explicit_prefix != "":
		return _sanitize_world_storage_prefix(explicit_prefix)

	var topology_mode := String(metadata.get("topology_mode", "legacy_infinite"))
	var primary_seed := int(metadata.get("primary_seed", metadata.get("world_seed", 0)))
	if topology_mode != "planetary_v1":
		return _sanitize_world_storage_prefix("%s_%d" % [topology_mode, primary_seed])

	return _sanitize_world_storage_prefix("%s_%s_%d_%d_%d_%d" % [
		topology_mode,
		String(metadata.get("world_size_preset", "medium")),
		int(metadata.get("horizontal_circumference_in_chunks", 0)),
		int(metadata.get("topology_version", 1)),
		int(metadata.get("world_plan_revision", 1)),
		primary_seed,
	])

func _extract_world_storage_prefix_from_save_data(data: Dictionary) -> String:
	var explicit_prefix := String(data.get("world_storage_prefix", "")).strip_edges()
	if explicit_prefix != "":
		return _sanitize_world_storage_prefix(explicit_prefix)
	var metadata: Dictionary = data.get("world_metadata", {})
	return _extract_world_storage_prefix_from_metadata(metadata)

func _get_slot_world_deltas_legacy_path(slot_dir: String) -> String:
	return slot_dir + WORLD_DELTAS_DIRNAME + "/"

func _build_slot_world_deltas_path(slot_dir: String, world_storage_prefix: String) -> String:
	var base_path := _get_slot_world_deltas_legacy_path(slot_dir)
	var token := _sanitize_world_storage_prefix(world_storage_prefix)
	if token == "":
		return base_path
	return base_path + token + "/"

func _parse_slot_id_from_key(raw_key: String) -> int:
	if not raw_key.begins_with("slot_"):
		return -1
	var suffix := raw_key.substr(5, raw_key.length() - 5)
	if suffix == "":
		return -1
	var slot_id := int(suffix)
	return slot_id if slot_id > 0 else -1

func _collect_known_slot_ids() -> Array:
	var lookup := {}
	for slot_id in range(1, MAX_SAVE_SLOTS + 1):
		lookup[slot_id] = true

	for key_var in save_metadata.keys():
		var slot_id_from_metadata := _parse_slot_id_from_key(String(key_var))
		if slot_id_from_metadata > 0:
			lookup[slot_id_from_metadata] = true

	var saves_dir := DirAccess.open(SAVE_ROOT)
	if saves_dir != null:
		saves_dir.list_dir_begin()
		var entry := saves_dir.get_next()
		while entry != "":
			if saves_dir.current_is_dir() and String(entry).begins_with("slot_"):
				var slot_id_from_disk := _parse_slot_id_from_key(String(entry))
				if slot_id_from_disk > 0:
					lookup[slot_id_from_disk] = true
			entry = saves_dir.get_next()
		saves_dir.list_dir_end()

	var slot_ids: Array = lookup.keys()
	slot_ids.sort()
	return slot_ids

func _get_file_size_bytes(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	var length := int(file.get_length())
	file.close()
	return maxi(length, 0)

func _remove_file_with_stats(path: String, stats: Dictionary) -> void:
	var reclaimed := _get_file_size_bytes(path)
	if DirAccess.remove_absolute(path) == OK:
		stats["removed_files"] = int(stats.get("removed_files", 0)) + 1
		stats["reclaimed_bytes"] = int(stats.get("reclaimed_bytes", 0)) + reclaimed

func _remove_directory_recursive(path: String, stats: Dictionary) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return

	var dir := DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var child_path := path + entry
		if dir.current_is_dir():
			_remove_directory_recursive(child_path + "/", stats)
		elif FileAccess.file_exists(child_path):
			_remove_file_with_stats(child_path, stats)
		entry = dir.get_next()
	dir.list_dir_end()

	if DirAccess.remove_absolute(path.trim_suffix("/")) == OK:
		stats["removed_dirs"] = int(stats.get("removed_dirs", 0)) + 1

func _cleanup_slot_world_deltas_for_slot(slot_id: int, keep_world_storage_prefix: String = "", remove_legacy_root_files: bool = false) -> Dictionary:
	var stats := {
		"removed_files": 0,
		"removed_dirs": 0,
		"reclaimed_bytes": 0,
	}
	var slot_dir := _get_slot_dir(slot_id)
	var base_dir := _get_slot_world_deltas_legacy_path(slot_dir)
	if not DirAccess.dir_exists_absolute(base_dir):
		return stats

	var keep_token := _sanitize_world_storage_prefix(keep_world_storage_prefix)
	var dir := DirAccess.open(base_dir)
	if dir == null:
		return stats

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var entry_name := String(entry)
		var entry_path := base_dir + entry_name
		if dir.current_is_dir():
			if keep_token != "" and entry_name == keep_token:
				entry = dir.get_next()
				continue
			_remove_directory_recursive(entry_path + "/", stats)
		elif FileAccess.file_exists(entry_path):
			if entry_name.begins_with("chunk_") and entry_name.ends_with(".tres"):
				if remove_legacy_root_files or keep_token != "":
					_remove_file_with_stats(entry_path, stats)
		entry = dir.get_next()
	dir.list_dir_end()
	return stats

func _collect_referenced_precomputed_signatures() -> Array:
	var dedupe := {}
	for slot_id_var in _collect_known_slot_ids():
		var slot_id := int(slot_id_var)
		var slot_data := _try_load_slot_data_for_metadata(slot_id)
		if slot_data.is_empty():
			continue
		var world_metadata_variant: Variant = slot_data.get("world_metadata", {})
		if not (world_metadata_variant is Dictionary):
			continue
		if not InfiniteChunkManager or not InfiniteChunkManager.has_method("build_precomputed_signature_from_world_metadata"):
			continue
		var signature := String(InfiniteChunkManager.call("build_precomputed_signature_from_world_metadata", world_metadata_variant)).strip_edges()
		if signature == "":
			continue
		dedupe[signature] = true
	return dedupe.keys()

func _reconcile_orphan_world_caches() -> void:
	var slot_cleanup_stats := {
		"removed_files": 0,
		"removed_dirs": 0,
		"reclaimed_bytes": 0,
	}

	for slot_id_var in _collect_known_slot_ids():
		var slot_id := int(slot_id_var)
		var slot_data := _try_load_slot_data_for_metadata(slot_id)
		if not slot_data.is_empty():
			continue
		var slot_snapshot := _cleanup_slot_world_deltas_for_slot(slot_id, "", true)
		slot_cleanup_stats["removed_files"] = int(slot_cleanup_stats.get("removed_files", 0)) + int(slot_snapshot.get("removed_files", 0))
		slot_cleanup_stats["removed_dirs"] = int(slot_cleanup_stats.get("removed_dirs", 0)) + int(slot_snapshot.get("removed_dirs", 0))
		slot_cleanup_stats["reclaimed_bytes"] = int(slot_cleanup_stats.get("reclaimed_bytes", 0)) + int(slot_snapshot.get("reclaimed_bytes", 0))

	var precomputed_snapshot := {}
	if InfiniteChunkManager and InfiniteChunkManager.has_method("prune_precomputed_domains"):
		var keep_signatures := _collect_referenced_precomputed_signatures()
		var prune_result = InfiniteChunkManager.call("prune_precomputed_domains", keep_signatures)
		if typeof(prune_result) == TYPE_DICTIONARY:
			precomputed_snapshot = prune_result

	var slot_removed_files := int(slot_cleanup_stats.get("removed_files", 0))
	var slot_removed_dirs := int(slot_cleanup_stats.get("removed_dirs", 0))
	var slot_reclaimed_bytes := int(slot_cleanup_stats.get("reclaimed_bytes", 0))
	var removed_domains := int(precomputed_snapshot.get("removed_domains", 0))
	var removed_markers := int(precomputed_snapshot.get("removed_markers", 0))
	var precomputed_reclaimed := int(precomputed_snapshot.get("reclaimed_bytes", 0))
	if slot_removed_files > 0 or slot_removed_dirs > 0 or removed_domains > 0 or removed_markers > 0:
		print("SaveManager: Reconciled orphan world cache (slot_files=%d, slot_dirs=%d, precomputed_domains=%d, preload_markers=%d, reclaimed_bytes=%d)" % [
			slot_removed_files,
			slot_removed_dirs,
			removed_domains,
			removed_markers,
			slot_reclaimed_bytes + precomputed_reclaimed,
		])

func _directory_contains_chunk_deltas(path: String) -> bool:
	if not DirAccess.dir_exists_absolute(path):
		return false
	var dir := DirAccess.open(path)
	if dir == null:
		return false
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.begins_with("chunk_") and entry.ends_with(".tres"):
			dir.list_dir_end()
			return true
		entry = dir.get_next()
	dir.list_dir_end()
	return false

func _count_chunk_delta_files(path: String) -> int:
	if not DirAccess.dir_exists_absolute(path):
		return 0
	var dir := DirAccess.open(path)
	if dir == null:
		return 0
	var count := 0
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.begins_with("chunk_") and entry.ends_with(".tres"):
			count += 1
		entry = dir.get_next()
	dir.list_dir_end()
	return count

func _find_slot_world_delta_seed_candidates(slot_dir: String, primary_seed: int) -> Array:
	var candidates: Array = []
	var base_dir := _get_slot_world_deltas_legacy_path(slot_dir)
	if not DirAccess.dir_exists_absolute(base_dir):
		return candidates

	var dir := DirAccess.open(base_dir)
	if dir == null:
		return candidates

	var seed_suffix := "_%d" % primary_seed
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			var token := String(entry).strip_edges()
			if token != "" and (primary_seed == 0 or token.ends_with(seed_suffix)):
				candidates.append(base_dir + token + "/")
		entry = dir.get_next()
	dir.list_dir_end()
	return candidates

func _select_best_world_deltas_path(slot_dir: String, resolved_world_path: String, legacy_world_path: String, primary_seed: int) -> String:
	var best_path := resolved_world_path
	var best_count := _count_chunk_delta_files(resolved_world_path)

	var candidate_paths: Array = [legacy_world_path]
	candidate_paths.append_array(_find_slot_world_delta_seed_candidates(slot_dir, primary_seed))

	for path_var in candidate_paths:
		var candidate_path := String(path_var)
		if candidate_path == "" or candidate_path == best_path:
			continue
		var candidate_count := _count_chunk_delta_files(candidate_path)
		if candidate_count > best_count:
			best_count = candidate_count
			best_path = candidate_path

	if best_path != resolved_world_path and best_count > 0:
		push_warning("SaveManager: world delta path recovered from compatible candidate: %s (resolved=%s, files=%d)" % [best_path, resolved_world_path, best_count])

	return best_path

func _slot_file_candidates(slot_id: int) -> Array:
	var data_path := _get_data_path(slot_id)
	return [data_path, data_path + ".bak"]

func _slot_has_new_format_data(slot_id: int) -> bool:
	for candidate_var in _slot_file_candidates(slot_id):
		var candidate := String(candidate_var)
		if FileAccess.file_exists(candidate):
			return true
	return false

func _try_load_slot_data_for_metadata(slot_id: int) -> Dictionary:
	for candidate_var in _slot_file_candidates(slot_id):
		var candidate := String(candidate_var)
		var loaded = _load_binary_data(candidate)
		if typeof(loaded) == TYPE_DICTIONARY:
			return loaded
	return {}

func _fallback_slot_info_from_files(slot_id: int) -> Dictionary:
	var loaded := _try_load_slot_data_for_metadata(slot_id)
	if not loaded.is_empty():
		var p_name := "Player"
		var p_gen := 1
		var p_lineage := "L-%d" % slot_id

		if loaded.has("player") and typeof(loaded.get("player")) == TYPE_DICTIONARY:
			var player_block: Dictionary = loaded.get("player", {})
			if player_block.has("data") and typeof(player_block.get("data")) == TYPE_DICTIONARY:
				var p_data: Dictionary = player_block.get("data", {})
				p_name = String(p_data.get("display_name", p_name))
				p_gen = int(p_data.get("generation", p_gen))
				p_lineage = String(p_data.get("lineage_id", p_lineage))

		var timestamp := float(loaded.get("timestamp", 0.0))
		var display_time := "（恢复存档）"
		if timestamp > 0.0:
			display_time = Time.get_datetime_string_from_unix_time(int(timestamp))

		var world_meta: Dictionary = loaded.get("world_metadata", {})
		return {
			"timestamp": timestamp,
			"player_name": p_name,
			"generation": p_gen,
			"lineage_id": p_lineage,
			"display_time": display_time,
			"topology_mode": String(world_meta.get("topology_mode", "legacy_infinite")),
			"world_size_preset": String(world_meta.get("world_size_preset", "legacy"))
		}

	if _slot_has_new_format_data(slot_id):
		return {
			"timestamp": 0.0,
			"player_name": "可读取存档",
			"generation": 1,
			"lineage_id": "L-%d" % slot_id,
			"display_time": "（元数据损坏）",
			"topology_mode": "legacy_infinite",
			"world_size_preset": "legacy"
		}

	return {}

func _rebuild_metadata_from_slot_files() -> void:
	var rebuilt := false
	for slot_id in range(1, MAX_SAVE_SLOTS + 1):
		var key := "slot_%d" % slot_id
		if save_metadata.has(key):
			continue
		var fallback_info := _fallback_slot_info_from_files(slot_id)
		if not fallback_info.is_empty():
			save_metadata[key] = fallback_info
			rebuilt = true

	if rebuilt:
		push_warning("SaveManager: metadata.json invalid or incomplete, rebuilt slot metadata from save files.")
		_save_metadata_to_disk()

func _load_metadata() -> void:
	save_metadata = {}
	var metadata_path := SAVE_ROOT + "metadata.json"
	var file = FileAccess.open(metadata_path, FileAccess.READ)
	if file:
		var raw := file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(raw)
		if typeof(parsed) == TYPE_DICTIONARY:
			save_metadata = parsed
		else:
			push_warning("SaveManager: metadata.json parse failed, fallback rebuild enabled.")

	_rebuild_metadata_from_slot_files()

	if not save_metadata:
		save_metadata = {}

func _save_metadata_to_disk() -> void:
	var file = FileAccess.open(SAVE_ROOT + "metadata.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_metadata, "\t"))

# 获取某个槽位的显示信息
func get_slot_info(slot_id: int) -> Dictionary:
	var key = "slot_%d" % slot_id
	if save_metadata.has(key):
		return save_metadata[key]

	var fallback_info := _fallback_slot_info_from_files(slot_id)
	if not fallback_info.is_empty():
		save_metadata[key] = fallback_info
		_save_metadata_to_disk()
		return fallback_info
	
	# 后备：如果有旧格式存盘文件，则认为该槽位有遗留数据
	if FileAccess.file_exists("user://saves/slot_%d/data.dat" % slot_id) or FileAccess.file_exists("user://saves/slot_%d/data.dat.bak" % slot_id):
		return {
			"player_name": "可读取存档",
			"display_time": "（检测到磁盘存档）",
			"topology_mode": "legacy_infinite",
			"world_size_preset": "legacy",
			"progress": 0
		}

	if FileAccess.file_exists("user://save_%d.save" % slot_id):
		return {
			"player_name": "旧版存档 (遗留)",
			"display_time": "（需载入确认）",
			"topology_mode": "legacy_infinite",
			"world_size_preset": "legacy",
			"progress": 0
		}
	
	return {}

# --- 核心保存逻辑 ---

func _build_save_data(world_context: Dictionary = {}) -> Dictionary:
	var world_metadata: Dictionary = world_context.get("world_metadata", {})
	if world_metadata.is_empty():
		world_metadata = _get_world_metadata()
	var world_storage_prefix := String(world_context.get("world_storage_prefix", "")).strip_edges()
	if world_storage_prefix == "":
		world_storage_prefix = _extract_world_storage_prefix_from_metadata(world_metadata)
	else:
		world_storage_prefix = _sanitize_world_storage_prefix(world_storage_prefix)
	return {
		"version": "2.0",
		"timestamp": Time.get_unix_time_from_system(),
		"scene_path": get_tree().current_scene.scene_file_path, # 保存当前场景路径
		"game_time": GameState.current_time,
		"world_metadata": world_metadata,
		"world_storage_prefix": world_storage_prefix,
		"player": _pack_player_data(),
		"inventory": _pack_inventory(),
		"buildings": _pack_buildings(),
		"pickups": _pack_pickups(),
		"weather": _pack_weather(),
		"minimap": _pack_minimap(),
		"persist_group": _pack_persist_group(),
		"hostiles": _pack_hostiles(),
		"descendants": _pack_descendants(), # 新增：保存子嗣列表
		"unlocked_spells": GameState.unlocked_spells,
		"world_seed": _get_world_seed()
	}

func _update_slot_metadata(slot_id: int, data: Dictionary) -> void:
	var key = "slot_%d" % slot_id
	var p_name = "Unknown"
	var p_gen = 1
	var p_lineage = "unknown"

	if data.player and data.player.data:
		p_name = data.player.data.get("display_name", "Player")
		p_gen = data.player.data.get("generation", 1)
		p_lineage = data.player.data.get("lineage_id", "L-%d" % slot_id)

	save_metadata[key] = {
		"timestamp": data.timestamp,
		"player_name": p_name,
		"generation": p_gen,
		"lineage_id": p_lineage,
		"display_time": Time.get_datetime_string_from_system(),
		"topology_mode": String(data.world_metadata.get("topology_mode", "legacy_infinite")),
		"world_size_preset": String(data.world_metadata.get("world_size_preset", "legacy"))
	}
	_save_metadata_to_disk()

func save_game(slot_id: int, force_sync_flush: bool = true) -> void:
	if slot_id != current_slot_id:
		clear_world_binding()
	current_slot_id = slot_id
	if _autosave_running:
		flush_save_pipeline_sync()

	# Reset autosave timer on manual save
	if auto_save_timer and not auto_save_timer.is_stopped():
		auto_save_timer.start()
		
	var slot_dir = _get_slot_dir(slot_id)
	if not DirAccess.dir_exists_absolute(slot_dir):
		DirAccess.make_dir_recursive_absolute(slot_dir)
	
	# 1. 切换无限地图管理器的目标目录并同步保存最新的内存修改
	var world_context := _resolve_world_context_for_slot(slot_id)
	var data_preview := _build_save_data(world_context)
	var world_path := _build_slot_world_deltas_path(slot_dir, String(data_preview.get("world_storage_prefix", "")))
	if InfiniteChunkManager:
		InfiniteChunkManager.set_save_root(world_path, true)
		InfiniteChunkManager.save_all_deltas(true, force_sync_flush) # 强制物块修改写盘
		if force_sync_flush and InfiniteChunkManager.has_method("flush_pending_dirty_writes_sync"):
			InfiniteChunkManager.flush_pending_dirty_writes_sync()
	
	# 2. 收集核心游戏数据
	var data = data_preview
	
	# 3. 写入数据文件 (Atomic & Compressed)
	var final_path = _get_data_path(slot_id)
	
	# Capture Thumbnail
	_capture_screenshot(slot_id)

	if not _write_atomic_compressed(final_path, data):
		push_error("SaveManager: Failed to save game data atomically.")
		return
		
	# 4. 更新元数据
	_update_slot_metadata(slot_id, data)
	_cleanup_slot_world_deltas_for_slot(slot_id, String(data.get("world_storage_prefix", "")), false)
	_reconcile_orphan_world_caches()
	
	print("SaveManager: 存档 %d 保存成功 (Binary/Atomic)" % slot_id)

func delete_save_slot(slot_id: int) -> bool:
	if slot_id <= 0:
		return false

	if slot_id == current_slot_id:
		if _autosave_running:
			flush_save_pipeline_sync()
		if auto_save_timer and not auto_save_timer.is_stopped():
			auto_save_timer.stop()
		current_slot_id = -1
		clear_world_binding()

	if _autosave_requested_slot == slot_id:
		_autosave_requested_slot = -1
		_autosave_pending = false

	var cleanup_stats := {
		"removed_files": 0,
		"removed_dirs": 0,
		"reclaimed_bytes": 0,
	}
	_remove_directory_recursive(_get_slot_dir(slot_id), cleanup_stats)

	var legacy_path := "user://save_%d.save" % slot_id
	if FileAccess.file_exists(legacy_path):
		_remove_file_with_stats(legacy_path, cleanup_stats)

	var key := "slot_%d" % slot_id
	if save_metadata.has(key):
		save_metadata.erase(key)
		_save_metadata_to_disk()

	_reconcile_orphan_world_caches()
	return true

func delete_game(slot_id: int) -> bool:
	return delete_save_slot(slot_id)

func _write_atomic_compressed(path: String, data: Variant) -> bool:
	var tmp_path = path + ".tmp"
	var bak_path = path + ".bak"
	
	# 首先尝试使用压缩写入（ZSTD）。若导出平台不支持 ZSTD 或 open_compressed 返回 null，
	# 回退到普通的无压缩写入，保证导出运行时也能保存。
	var file = FileAccess.open_compressed(tmp_path, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	var used_compressed := true
	if not file:
		# 回退：普通写入（向后兼容导出环境）
		file = FileAccess.open(tmp_path, FileAccess.WRITE)
		used_compressed = false
	if not file:
		return false
	file.store_var(data, true) # Ensure full object (Resource) serialization
	file.close()
	if not used_compressed:
		print("SaveManager: Compression not available; saved uncompressed: ", tmp_path)
	
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(bak_path)
		DirAccess.rename_absolute(path, bak_path)
	
	var err = DirAccess.rename_absolute(tmp_path, path)
	return err == OK

func _pack_player_data() -> Dictionary:
	var player = get_tree().get_first_node_in_group("player")
	var pos = Vector2.ZERO
	if player: pos = player.global_position
	
	var p_data = GameState.player_data
	return {
		"position": pos,
		"data": {
			"display_name": p_data.display_name,
			"health": p_data.health,
			"max_health": p_data.max_health,
			"strength": p_data.strength,
			"agility": p_data.agility,
			"intelligence": p_data.intelligence,
			"constitution": p_data.constitution,
			# Lineage System Data
			"stat_levels": p_data.stat_levels,
			"attributes": p_data.attributes, # Save dynamic attributes (bonuses, money)
			"mutations": p_data.mutations,
			"spouse_id": p_data.spouse_id,
			"generation": p_data.generation,
			"age": p_data.current_age, # Use current_age to prevent reset to 0
			"growth_stage": p_data.growth_stage,
			"imprint_quality": p_data.imprint_quality,
			# Tutorial State
			"tutorial_completed": p_data.tutorial_completed,
			"tutorial_step": p_data.tutorial_step
		}
	}

func _pack_inventory() -> Dictionary:
	var result = {"backpack": [], "hotbar": []}
	if GameState.inventory:
		var mgr = GameState.inventory # InventoryManager
		if mgr.has_method("serialize_inventory"):
			return mgr.serialize_inventory()
		if "backpack" in mgr and mgr.backpack:
			result.backpack = mgr.backpack.slots
		if "hotbar" in mgr and mgr.hotbar:
			result.hotbar = mgr.hotbar.slots
	return result

func _pack_buildings() -> Array:
	var list = []
	var container = get_tree().get_first_node_in_group("buildings_container")
	if container:
		for child in container.get_children():
			if child.scene_file_path.is_empty(): continue
			
			var b_data = {
				"scene_path": child.scene_file_path,
				"position": child.global_position,
				"rotation": child.rotation
			}
			# 暂不处理自定义数据，除非有 save_data() 接口
			if child.has_method("save_data"):
				b_data["custom_data"] = child.save_data()
			list.append(b_data)
	return list

# --- 核心加载逻辑 ---

func _load_binary_data(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	
	# Try compressed first (new format)
	var file = FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if not file:
		# Fallback to uncompressed (legacy)
		file = FileAccess.open(path, FileAccess.READ)
	
	if not file: return null
	
	var data = file.get_var(true) # Use allow_objects=true to support Resource serialization
	file.close()
	return data

func load_game(slot_id: int) -> bool:
	clear_world_binding()
	# 只要加载存档，就意味着这绝对不是新游戏
	if GameManager:
		GameManager.is_new_game = false
		
	current_slot_id = slot_id
	start_autosave()
	
	var path = _get_data_path(slot_id)
	
	var data = _load_binary_data(path)
	if data == null:
		# Try Backup
		var backup_path = path + ".bak"
		data = _load_binary_data(backup_path)
		if data != null:
			push_warning("SaveManager: Main save corrupted, loaded from backup.")

	var legacy_path = "user://save_%d.save" % slot_id
	if data == null and FileAccess.file_exists(legacy_path):
		# Try Legacy format
		data = _load_binary_data(legacy_path)
		if data != null:
			push_warning("SaveManager: Loaded legacy save file from " + legacy_path)

	if data == null:
		# Only check if path missing if backup also failed
		if not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".bak") and not FileAccess.file_exists(legacy_path):
			push_error("SaveManager: 存档文件不存在 " + path + " 或 " + legacy_path)
		else:
			push_error("SaveManager: 存档文件损坏且无备份 " + path)
		return false

	var loaded_world_metadata: Dictionary = data.get("world_metadata", {})
	var loaded_world_storage_prefix := _extract_world_storage_prefix_from_save_data(data)
	_bind_world_context(loaded_world_metadata, loaded_world_storage_prefix)
	
	# 1. 设定地图路径（按世界前缀隔离，避免不同地图串档）
	var slot_dir = _get_slot_dir(slot_id)
	var legacy_world_path := _get_slot_world_deltas_legacy_path(slot_dir)
	var resolved_world_path := _build_slot_world_deltas_path(slot_dir, _bound_world_storage_prefix)
	var primary_seed := int(loaded_world_metadata.get("primary_seed", data.get("world_seed", 0)))
	var world_path := _select_best_world_deltas_path(slot_dir, resolved_world_path, legacy_world_path, primary_seed)
	if InfiniteChunkManager:
		InfiniteChunkManager.set_save_root(world_path)

	# 2. 恢复全局状态
	GameState.current_time = data.get("game_time", 0.0)
	
	if data.has("unlocked_spells"):
		GameState.unlocked_spells.assign(data.unlocked_spells)
	else:
		GameState.unlocked_spells.clear()
	
	if data.has("world_seed"):
		# Store the seed in GameState meta so GameManager can pick it up 
		# when initializing the WorldGenerator later.
		GameState.set_meta("pending_new_seed", data.world_seed)
		print("SaveManager: Loaded World Seed: ", data.world_seed)

	if data.has("world_metadata"):
		GameState.set_meta("pending_world_metadata", data.world_metadata)
	
	if data.has("scene_path"):
		GameState.set_meta("pending_scene_path", data.scene_path)
	
	# 3. 恢复玩家数据 (缓存，待 GameManager 应用)
	if data.has("player"):
		_cached_player_data = data.player.data
		# 将位置存储在 Meta 中，供 GameManager 生成玩家时读取
		GameState.set_meta("load_spawn_pos", data.player.position)
		
		# 确保玩家数据对象存在，避免空指针访问
		if not GameState.player_data:
			GameState.player_data = CharacterData.new()
			
		var p_data = GameState.player_data
		var saved_stats = _cached_player_data
		
		p_data.display_name = saved_stats.get("display_name", "NPC_PLAYER_DEFAULT")
		
		# 强制手动缓存教程状态，防止 GameManager 漏读
		# 注意：这些属性会被 GameManager 再次从 _cached_player_data 覆盖，但这里先设个底
		p_data.tutorial_completed = saved_stats.get("tutorial_completed", false)
		p_data.tutorial_step = saved_stats.get("tutorial_step", 0)

		# 3.1 Lineage System Data Restoration
		if saved_stats.has("stat_levels"):
			p_data.stat_levels = saved_stats.stat_levels
			p_data.mutations = saved_stats.get("mutations", {"patrilineal":0, "matrilineal":0})
			p_data.spouse_id = saved_stats.get("spouse_id", -1)
			p_data.generation = saved_stats.get("generation", 1)
			p_data.age = saved_stats.get("age", 0.0)
			p_data.growth_stage = saved_stats.get("growth_stage", 0)
			p_data.imprint_quality = saved_stats.get("imprint_quality", 0.0)
		else:
			# Legacy Save Fallback
			p_data.max_health = saved_stats.get("max_health", 100)
			p_data.strength = saved_stats.get("strength", 10)
			p_data.agility = saved_stats.get("agility", 10)
			p_data.intelligence = saved_stats.get("intelligence", 10)
			p_data.constitution = saved_stats.get("constitution", 10)

		p_data.health = saved_stats.get("health", 100)
		
		# 将位置存储在 Meta 中，供 GameManager 生成玩家时读取
		if data.player.has("position"):
			GameState.set_meta("load_spawn_pos", data.player.position)

	# 4. 恢复背包
	if data.has("inventory") and GameState.inventory:
		var inv_mgr = GameState.inventory
		if inv_mgr.has_method("load_inventory_data"):
			inv_mgr.load_inventory_data(data.inventory)
		else:
			if "backpack" in inv_mgr and inv_mgr.backpack:
				inv_mgr.backpack.slots = data.inventory.get("backpack", [])
				inv_mgr.backpack.content_changed.emit(-1)
			if "hotbar" in inv_mgr and inv_mgr.hotbar:
				inv_mgr.hotbar.slots = data.inventory.get("hotbar", [])
				inv_mgr.hotbar.content_changed.emit(-1)
		
	# 5. 恢复建筑列表
	GameState.set_meta("load_buildings", data.get("buildings", []))
	
	# 6. Restore Extended Systems (Pickups, Weather, Minimap)
	if data.has("pickups"): _unpack_pickups(data.pickups)
	if data.has("weather"): _unpack_weather(data.weather)
	if data.has("minimap"): _unpack_minimap(data.minimap)
	
	if data.has("persist_group"): _unpack_persist_group(data.persist_group)
	if data.has("hostiles"): _unpack_hostiles(data.hostiles)
	if data.has("descendants"): _unpack_descendants(data.descendants) # 新增：恢复子嗣列表
	
	print("SaveManager: 存档 %d 数据已载入内存预备" % slot_id)
	return true

func _capture_screenshot(slot_id: int) -> void:
	var viewport = get_tree().root.get_viewport()
	if not viewport: return
	
	var texture = viewport.get_texture()
	var image = texture.get_image()
	
	# Resize to thumbnail size (e.g. 480x270)
	image.resize(480, 270, Image.INTERPOLATE_BILINEAR)
	
	var path = _get_slot_dir(slot_id) + THUMBNAIL_FILENAME
	image.save_jpg(path, 0.70)

# --- Extended Persistence Helpers ---

func _pack_pickups() -> Array:
	var list = []
	var nodes = get_tree().get_nodes_in_group('pickups')
	for node in nodes:
		if node.has_method('get_save_data'):
			list.append(node.get_save_data())
	return list

func _unpack_pickups(list: Array) -> void:
	get_tree().call_group('pickups', 'queue_free')
	var root = get_tree().current_scene
	
	for info in list:
		if not info.get('file'): continue
		var scn = load(info.file)
		if scn:
			var node = scn.instantiate()
			node.global_position = info.get('pos', Vector2.ZERO)
			root.add_child(node)
			if node.has_method('setup') and info.get('item_res'):
				var res = load(info.item_res)
				if res: node.setup(res, info.get('amount', 1))

func _pack_weather() -> Dictionary:
	return WeatherManager.get_save_data() if WeatherManager.has_method('get_save_data') else {}

func _unpack_weather(data: Dictionary) -> void:
	if WeatherManager.has_method('load_save_data'): WeatherManager.load_save_data(data)

func _pack_minimap() -> Dictionary:
	return MinimapManager.get_save_data() if MinimapManager.has_method('get_save_data') else {}

func _unpack_minimap(data: Dictionary) -> void:
	if MinimapManager.has_method('load_save_data'): MinimapManager.load_save_data(data)

# --- Generic Persist Group ---
func _pack_persist_group() -> Dictionary:
	var gathered = {}
	var nodes = get_tree().get_nodes_in_group('persist')
	for node in nodes:
		if node.has_method('get_save_data'):
			gathered[str(node.get_path())] = node.get_save_data()
	return gathered

func _unpack_persist_group(data: Dictionary) -> void:
	for node_path in data:
		if has_node(node_path):
			var node = get_node(node_path)
			if node.has_method('load_save_data'):
				node.load_save_data(data[node_path])

# --- Specific Enemy Persistence ---

func _get_world_seed() -> int:
	# Try to find the active WorldGenerator
	var world_gen = get_tree().get_first_node_in_group("world_generator")
	if not world_gen:
		var root = get_tree().current_scene
		if root: world_gen = root.find_child("WorldGenerator", true, false)
	if not world_gen:
		world_gen = get_tree().get_first_node_in_group("world_generators")
	
	if world_gen and "seed_value" in world_gen:
		return world_gen.seed_value
	return 0

func _get_world_metadata() -> Dictionary:
	if WorldTopology and WorldTopology.has_method("get_save_metadata"):
		return WorldTopology.get_save_metadata()
	return {}

func _pack_hostiles() -> Array:
	var list = []
	var mobs = get_tree().get_nodes_in_group("hostile_npcs")
	for mob in mobs:
		if mob.scene_file_path.is_empty(): continue
		if mob.get("health") != null and mob.health <= 0: continue # Don't save dead
		
		# 识别是否是子嗣
		var is_descendant = false
		if "npc_data" in mob and mob.npc_data:
			if LineageManager.descendants.has(mob.npc_data):
				is_descendant = true
		
		var data = {
			"scene_path": mob.scene_file_path,
			"pos": mob.global_position,
			"hp": mob.get("health") if mob.get("health") != null else 100,
			"max_hp": mob.get("max_health") if mob.get("max_health") != null else 100,
			"is_descendant": is_descendant # 记录是否是子嗣
		}
		
		# If using CharacterData resource system
		if "npc_data" in mob and mob.npc_data:
			data["hp"] = mob.npc_data.health
			data["max_hp"] = mob.npc_data.max_health
			data["display_name"] = mob.npc_data.display_name
			# 存入完整的 CharacterData 字典表示，确保属性（如 age, growth_stage, npc_type）不丢失
			data["character_full_data"] = _resource_to_dict(mob.npc_data)
			
		list.append(data)
	return list

func _unpack_hostiles(list: Array) -> void:
	# Clean up existing hostiles to avoid duplicates if reloading scene
	get_tree().call_group("hostile_npcs", "queue_free")
	
	var entities_layer = get_tree().current_scene.find_child("Entities", true, false)
	if not entities_layer:
		entities_layer = get_tree().current_scene # Fallback
	
	for info in list:
		if not ResourceLoader.exists(info.scene_path): continue
		
		var scn = ResourceLoader.load(info.scene_path)
		if scn:
			var mob = scn.instantiate()
			mob.global_position = info.pos
			
			# Restore Data
			if "npc_data" in mob and mob.npc_data:
				# Ensure data uniqueness
				mob.npc_data = mob.npc_data.duplicate()
				
				# 如果有完整数据字典，则恢复所有属性
				if info.has("character_full_data"):
					_dict_to_resource(info.character_full_data, mob.npc_data)
				
				mob.npc_data.health = info.hp
				mob.npc_data.max_health = info.max_hp
				if info.has("display_name"):
					mob.npc_data.display_name = info.display_name
					
				# 如果是子嗣，将其加入全局列表（如果列表中还没有该对象）
				if info.get("is_descendant", false):
					if not LineageManager.descendants.has(mob.npc_data):
						LineageManager.descendants.append(mob.npc_data)
						
			elif "health" in mob:
				mob.health = info.hp
				if "max_health" in mob: mob.max_health = info.max_hp

			entities_layer.add_child(mob)
			if mob.has_method("refresh_runtime_groups"):
				mob.refresh_runtime_groups()
			
			if mob.has_method("_update_hp_bar"):
				mob._update_hp_bar()

# 辅助函数：将 Resource 转换为字典（通用版，针对 CharacterData 优化）
func _resource_to_dict(res: Resource) -> Dictionary:
	var dict = {}
	# 获取所有可保存的属性（脚本中的变量名）
	var props = res.get_property_list()
	for p in props:
		# 过滤掉内置属性和只读属性，只保留脚本定义的变量 (PROPERTY_USAGE_STORAGE)
		if p.usage & PROPERTY_USAGE_STORAGE and p.name != "script" and p.name != "Built-in Script":
			dict[p.name] = res.get(p.name)
	return dict

# 辅助函数：将字典应用回 Resource
func _dict_to_resource(dict: Dictionary, res: Resource) -> void:
	for key in dict.keys():
		res.set(key, dict[key])

func _pack_descendants() -> Array:
	var list = []
	for d in LineageManager.descendants:
		list.append(_resource_to_dict(d))
	return list

func _unpack_descendants(list: Array) -> void:
	# 仅作为保险，如果场景中已经加载了（通过 _unpack_hostiles），此处不应重复
	# 但为了防止某些子嗣没在场景树中，这里做一次清理和恢复
	LineageManager.descendants.clear()
	for dict in list:
		var d = CharacterData.new()
		_dict_to_resource(dict, d)
		
		# 打印调试信息，确认恢复后的状态
		print("SaveManager: 恢复子嗣 %s, UUID: %d, 成长阶段: %d" % [d.display_name, d.uuid, d.growth_stage])
		
		# 只有当列表中还没有同名/同UUID的对象时才添加
		var exists = false
		for existing in LineageManager.descendants:
			if existing.get("uuid") == d.get("uuid"):
				exists = true
				break
		if not exists:
			LineageManager.descendants.append(d)
