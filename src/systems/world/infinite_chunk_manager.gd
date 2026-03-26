extends Node

## InfiniteChunkManager (Autoload)
## 负责地图区块的生命周期管理、坐标转换和异步加载。

const CHUNK_SIZE = 64
const TILE_SIZE = 16
const LOAD_RADIUS = 2 # 加载半径（区块单位）
const LOAD_RADIUS_VERTICAL = 1
const STARTUP_LOAD_RADIUS = 1
const UNLOAD_RADIUS_MARGIN = 1
const UNLOAD_RADIUS_MARGIN_VERTICAL = 1
const ENABLE_TILE_HOUSE_STRUCTURES := false
const CRITICAL_CHUNK_BUDGET_MS := 5.0
const ENRICHMENT_CHUNK_BUDGET_MS := 3.0
const UNLOAD_CHUNK_BUDGET_MS := 2.5
const ENTITY_SPAWN_BUDGET_MS := 2.0
const DIRTY_FLUSH_BUDGET_MS := 2.5
const MAX_CRITICAL_BURST_BEFORE_ENRICHMENT := 3
const ENRICHMENT_BACKOFF_FRAMES_ON_BUDGET_HIT := 2
const CRITICAL_BACKOFF_FRAMES_ON_BUDGET_HIT := 1
const ENRICHMENT_COOLDOWN_FRAMES_WHILE_MOVING := 10
const ENRICHMENT_COOLDOWN_FRAMES_IDLE_REFRESH := 3
const TELEMETRY_BUFFER_MAX := 320
const PRELOAD_BATCH_BUDGET_MS := 32.0
const PRELOAD_CHECKPOINT_SAVE_INTERVAL_BATCHES := 8
const PRELOAD_CHECKPOINT_SAVE_INTERVAL_MS := 2500
const PRELOAD_ADAPTIVE_BATCH_MIN := 24
const PRELOAD_ADAPTIVE_BATCH_MAX := 512
const PRELOAD_FRAME_YIELD_INTERVAL_BATCHES := 3
const PRELOAD_PROGRESS_EMIT_INTERVAL_BATCHES := 2
const PRELOAD_PROGRESS_EMIT_INTERVAL_MS := 450
const PRELOAD_TIMEOUT_SOFT_EXTENSION_SEC := 240.0
const PRELOAD_TIMEOUT_HARD_CAP_SEC := 10800.0
const PRELOAD_CHECKPOINT_DIR := "user://saves/preload_checkpoints/"
const PRELOAD_COMPLETED_DIR := "user://saves/preload_completed/"
const PRECOMPUTED_CHUNK_ROOT_DIR := "user://saves/precomputed_chunks/"
const PRELOAD_READINESS_VIOLATION_BUFFER_MAX := 128

var active_save_root: String = "user://saves/world_deltas/"

# 内存中的区块缓存: { Vector2i: WorldChunk }
var loaded_chunks: Dictionary = {}
# 当前区块内已实例化的节点容器: { Vector2i: Node2D }
var chunk_entity_containers: Dictionary = {}
# 所有的 Delta 数据（即使区块被卸载也保留）: { Vector2i: WorldChunk }
var world_delta_data: Dictionary = {}

var current_session_id: int = 0
const TransformHelper = preload("res://src/utils/transform_helper.gd")

signal chunk_loaded(coord: Vector2i)
signal chunk_unloaded(coord: Vector2i)
signal preload_progress(snapshot: Dictionary)
signal preload_finished(result: Dictionary)

var _loading_queue: Dictionary = {}
var _pending_chunk_requests: Array = []
var _enrichment_queue: Dictionary = {}
var _pending_enrichment_requests: Array = []
var _unload_queue: Dictionary = {}
var _pending_unload_requests: Array = []
var _enrichment_backoff_frames: int = 0
var _critical_backoff_frames: int = 0
var _critical_burst_count: int = 0
var _enrichment_cooldown_frames: int = 0
var _entity_spawn_queue: Array = []
var _dirty_chunk_coords: Dictionary = {}
var _dirty_flush_queue: Dictionary = {}
var _pending_dirty_flush_requests: Array = []
var _runtime_stage_telemetry: Array = []
var _startup_streaming_mode: bool = false
var _enrichment_suppressed: bool = false
# 每区块仅缓存生成过的坐标快照（不缓存完整瓦片字典），用于 enrichment 增量清理。
var _chunk_generated_cells: Dictionary = {}
var _preload_active_domain_signature: String = ""
var _preload_active_domain_identity: Dictionary = {}
var _preload_in_domain_lookup: Dictionary = {}
var _loaded_from_precomputed: Dictionary = {}
var _precomputed_enrichment_cells: Dictionary = {}
var _post_preload_readiness_violations: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	# 默认路径初始化，实际应由 SaveManager 设置
	_ensure_save_dir()
	_ensure_preload_dirs()

func _process(_delta: float) -> void:
	if _enrichment_backoff_frames > 0:
		_enrichment_backoff_frames -= 1
	if _critical_backoff_frames > 0:
		_critical_backoff_frames -= 1
	if _enrichment_cooldown_frames > 0:
		_enrichment_cooldown_frames -= 1
	var did_stream_work := false

	if _critical_backoff_frames <= 0 and not _pending_chunk_requests.is_empty() and (
		_pending_enrichment_requests.is_empty() or _critical_burst_count < MAX_CRITICAL_BURST_BEFORE_ENRICHMENT
	):
		var coord = _pending_chunk_requests.pop_front()
		if _loading_queue.has(coord):
			var critical_start := Time.get_ticks_usec()
			_build_chunk_on_main_thread(coord, current_session_id)
			var critical_elapsed_ms := float(Time.get_ticks_usec() - critical_start) / 1000.0
			_record_stage_telemetry("critical_load", coord, critical_elapsed_ms, {
				"pending_critical": _pending_chunk_requests.size(),
				"pending_enrichment": _pending_enrichment_requests.size(),
				"pending_unload": _pending_unload_requests.size(),
			})
			if critical_elapsed_ms > CRITICAL_CHUNK_BUDGET_MS:
				_enrichment_backoff_frames = max(_enrichment_backoff_frames, ENRICHMENT_BACKOFF_FRAMES_ON_BUDGET_HIT)
				_critical_backoff_frames = max(_critical_backoff_frames, CRITICAL_BACKOFF_FRAMES_ON_BUDGET_HIT)
				push_warning("InfiniteChunkManager: critical chunk build %.2fms exceeded budget %.2fms at %s" % [critical_elapsed_ms, CRITICAL_CHUNK_BUDGET_MS, str(coord)])
			_critical_burst_count += 1
			did_stream_work = true

	if not did_stream_work and not _startup_streaming_mode and not _enrichment_suppressed and not _pending_enrichment_requests.is_empty() and _enrichment_backoff_frames <= 0 and _enrichment_cooldown_frames <= 0:
		var enrich_coord = _pending_enrichment_requests.pop_front()
		if _enrichment_queue.has(enrich_coord):
			_enrichment_queue.erase(enrich_coord)
			var enrichment_start := Time.get_ticks_usec()
			_build_chunk_enrichment_on_main_thread(enrich_coord, current_session_id)
			var enrichment_elapsed_ms := float(Time.get_ticks_usec() - enrichment_start) / 1000.0
			_record_stage_telemetry("enrichment", enrich_coord, enrichment_elapsed_ms, {
				"pending_critical": _pending_chunk_requests.size(),
				"pending_enrichment": _pending_enrichment_requests.size(),
				"pending_unload": _pending_unload_requests.size(),
			})
			if enrichment_elapsed_ms > ENRICHMENT_CHUNK_BUDGET_MS:
				_enrichment_backoff_frames = max(_enrichment_backoff_frames, ENRICHMENT_BACKOFF_FRAMES_ON_BUDGET_HIT)
				push_warning("InfiniteChunkManager: enrichment chunk build %.2fms exceeded budget %.2fms at %s" % [enrichment_elapsed_ms, ENRICHMENT_CHUNK_BUDGET_MS, str(enrich_coord)])
			did_stream_work = true
		_critical_burst_count = 0

	if not did_stream_work:
		_critical_burst_count = 0

	_process_unload_budget()
	_process_entity_spawn_budget()
	_process_dirty_flush_budget()

func _budget_for_stage(stage: String) -> float:
	match stage:
		"critical_load":
			return CRITICAL_CHUNK_BUDGET_MS
		"enrichment":
			return ENRICHMENT_CHUNK_BUDGET_MS
		"unload":
			return UNLOAD_CHUNK_BUDGET_MS
		"entity_spawn":
			return ENTITY_SPAWN_BUDGET_MS
		"dirty_flush":
			return DIRTY_FLUSH_BUDGET_MS
		"preload_batch":
			return PRELOAD_BATCH_BUDGET_MS
		"preload_readiness_violation":
			return 0.0
		_:
			return -1.0

func _record_stage_telemetry(stage: String, coord: Variant, elapsed_ms: float, meta: Dictionary = {}) -> void:
	var budget := _budget_for_stage(stage)
	var event := {
		"timestamp_msec": Time.get_ticks_msec(),
		"stage": stage,
		"coord": coord,
		"elapsed_ms": elapsed_ms,
		"budget_ms": budget,
		"breach": budget > 0.0 and elapsed_ms > budget,
		"meta": meta,
	}
	_runtime_stage_telemetry.append(event)
	if _runtime_stage_telemetry.size() > TELEMETRY_BUFFER_MAX:
		_runtime_stage_telemetry.pop_front()

func _build_cells_presence_snapshot(cells: Dictionary) -> Dictionary:
	var snapshot := {}
	for layer_idx in cells.keys():
		if not (layer_idx is int):
			continue
		var layer_cells = cells.get(layer_idx, {})
		if not (layer_cells is Dictionary):
			continue
		snapshot[layer_idx] = layer_cells.keys()
	return snapshot

func _sanitize_storage_token(raw: String) -> String:
	var token := raw.strip_edges()
	if token == "":
		token = "default"
	for marker in ["|", "/", "\\", ":", ";", ",", ".", " ", "\t", "\n", "\r"]:
		token = token.replace(marker, "_")
	return token

func _chunk_coord_key(coord: Vector2i) -> String:
	return "%d,%d" % [coord.x, coord.y]

func _parse_chunk_coord_key(key: String) -> Variant:
	var parts := key.split(",")
	if parts.size() != 2:
		return null
	return Vector2i(int(parts[0]), int(parts[1]))

func _ensure_preload_dirs() -> void:
	if not DirAccess.dir_exists_absolute(PRELOAD_CHECKPOINT_DIR):
		DirAccess.make_dir_recursive_absolute(PRELOAD_CHECKPOINT_DIR)
	if not DirAccess.dir_exists_absolute(PRELOAD_COMPLETED_DIR):
		DirAccess.make_dir_recursive_absolute(PRELOAD_COMPLETED_DIR)
	if not DirAccess.dir_exists_absolute(PRECOMPUTED_CHUNK_ROOT_DIR):
		DirAccess.make_dir_recursive_absolute(PRECOMPUTED_CHUNK_ROOT_DIR)

func _get_preload_checkpoint_path(signature: String) -> String:
	var token := _sanitize_storage_token(signature)
	return PRELOAD_CHECKPOINT_DIR + "checkpoint_%s.bin" % token

func _get_preload_completed_path(signature: String) -> String:
	var token := _sanitize_storage_token(signature)
	return PRELOAD_COMPLETED_DIR + "completed_%s.bin" % token

func _get_precomputed_chunk_root(signature: String) -> String:
	var token := _sanitize_storage_token(signature)
	return PRECOMPUTED_CHUNK_ROOT_DIR + token + "/"

func _get_precomputed_chunk_path(signature: String, coord: Vector2i) -> String:
	var canonical := _canonical_chunk_coord(coord)
	return _get_precomputed_chunk_root(signature) + "chunk_%d_%d.bin" % [canonical.x, canonical.y]

func _save_preload_checkpoint(signature: String, payload: Dictionary) -> bool:
	_ensure_preload_dirs()
	var checkpoint_path := _get_preload_checkpoint_path(signature)
	var file := FileAccess.open(checkpoint_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_var(payload, true)
	file.close()
	return true

func _load_preload_checkpoint(signature: String) -> Dictionary:
	var checkpoint_path := _get_preload_checkpoint_path(signature)
	if not FileAccess.file_exists(checkpoint_path):
		return {}
	var file := FileAccess.open(checkpoint_path, FileAccess.READ)
	if file == null:
		return {}
	var payload: Variant = file.get_var(true)
	file.close()
	if payload is Dictionary:
		return payload
	return {}

func _clear_preload_checkpoint(signature: String) -> void:
	var checkpoint_path := _get_preload_checkpoint_path(signature)
	if FileAccess.file_exists(checkpoint_path):
		DirAccess.remove_absolute(checkpoint_path)

func _save_preload_completed_marker(signature: String, payload: Dictionary) -> bool:
	_ensure_preload_dirs()
	var marker_path := _get_preload_completed_path(signature)
	var file := FileAccess.open(marker_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_var(payload, true)
	file.close()
	return true

func _load_preload_completed_marker(signature: String) -> Dictionary:
	var marker_path := _get_preload_completed_path(signature)
	if not FileAccess.file_exists(marker_path):
		return {}
	var file := FileAccess.open(marker_path, FileAccess.READ)
	if file == null:
		return {}
	var payload: Variant = file.get_var(true)
	file.close()
	if payload is Dictionary:
		return payload
	return {}

func _identity_matches(expected_identity: Dictionary, candidate_identity: Dictionary) -> bool:
	for key in expected_identity.keys():
		if candidate_identity.get(key, null) != expected_identity.get(key, null):
			return false
	for key in candidate_identity.keys():
		if expected_identity.get(key, null) != candidate_identity.get(key, null):
			return false
	return true

func _is_checkpoint_usable(checkpoint: Dictionary, signature: String, identity: Dictionary) -> bool:
	if checkpoint.is_empty():
		return false
	if String(checkpoint.get("signature", "")) != signature:
		return false
	var stored_identity: Dictionary = checkpoint.get("identity", {})
	if not _identity_matches(identity, stored_identity):
		return false
	return checkpoint.has("cursor")

func _is_completed_marker_usable(marker: Dictionary, signature: String, identity: Dictionary) -> bool:
	if marker.is_empty():
		return false
	if String(marker.get("signature", "")) != signature:
		return false
	var stored_identity: Dictionary = marker.get("identity", {})
	if not _identity_matches(identity, stored_identity):
		return false
	return bool(marker.get("completed", false))

func _save_precomputed_chunk_cells(signature: String, coord: Vector2i, cells: Dictionary) -> bool:
	var root := _get_precomputed_chunk_root(signature)
	if not DirAccess.dir_exists_absolute(root):
		DirAccess.make_dir_recursive_absolute(root)
	var path := _get_precomputed_chunk_path(signature, coord)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_var({
		"coord": _canonical_chunk_coord(coord),
		"cells": cells,
		"saved_msec": Time.get_ticks_msec(),
	}, true)
	file.close()
	return true

func _load_precomputed_chunk_cells(signature: String, coord: Vector2i) -> Dictionary:
	var path := _get_precomputed_chunk_path(signature, coord)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var payload: Variant = file.get_var(true)
	file.close()
	if payload is Dictionary:
		var cells: Variant = payload.get("cells", {})
		if cells is Dictionary:
			return cells
	return {}

func _has_precomputed_chunk_cells(signature: String, coord: Vector2i) -> bool:
	return FileAccess.file_exists(_get_precomputed_chunk_path(signature, coord))

func _collect_precomputed_chunk_lookup(signature: String) -> Dictionary:
	var lookup := {}
	var root := _get_precomputed_chunk_root(signature)
	if not DirAccess.dir_exists_absolute(root):
		return lookup
	var dir := DirAccess.open(root)
	if dir == null:
		return lookup
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			entry = dir.get_next()
			continue
		if not entry.begins_with("chunk_") or not entry.ends_with(".bin"):
			entry = dir.get_next()
			continue
		var coord_token := entry.trim_prefix("chunk_").trim_suffix(".bin")
		var parts := coord_token.split("_")
		if parts.size() != 2:
			entry = dir.get_next()
			continue
		var parsed := Vector2i(int(parts[0]), int(parts[1]))
		var canonical := _canonical_chunk_coord(parsed)
		lookup[_chunk_coord_key(canonical)] = true
		entry = dir.get_next()
	dir.list_dir_end()
	return lookup

func _build_preload_domain_coords(domain: Dictionary) -> Array:
	var coords: Array = []
	var dedupe := {}
	var min_chunk_y := int(domain.get("min_chunk_y", 0))
	var max_chunk_y := int(domain.get("max_chunk_y", 0))
	var x_start := int(domain.get("x_start", 0))
	var x_count := int(domain.get("x_count", 0))

	for chunk_y in range(min_chunk_y, max_chunk_y + 1):
		for raw_x in range(x_start, x_start + x_count):
			var canonical := _canonical_chunk_coord(Vector2i(raw_x, chunk_y))
			if _is_chunk_request_blocked_by_depth_boundary(canonical):
				continue
			var key := _chunk_coord_key(canonical)
			if dedupe.has(key):
				continue
			dedupe[key] = true
			coords.append(canonical)
	return coords

func _reset_preload_runtime_state() -> void:
	_preload_active_domain_signature = ""
	_preload_active_domain_identity = {}
	_preload_in_domain_lookup.clear()
	_loaded_from_precomputed.clear()
	_post_preload_readiness_violations.clear()

func _activate_preload_runtime_state(signature: String, identity: Dictionary, domain_coords: Array) -> void:
	_preload_active_domain_signature = signature
	_preload_active_domain_identity = identity.duplicate(true)
	_preload_in_domain_lookup.clear()
	for raw_coord in domain_coords:
		if not (raw_coord is Vector2i):
			continue
		var canonical := _canonical_chunk_coord(raw_coord)
		_preload_in_domain_lookup[_chunk_coord_key(canonical)] = true

func _is_coord_in_active_preload_domain(coord: Vector2i) -> bool:
	if _preload_active_domain_signature == "":
		return false
	var canonical := _canonical_chunk_coord(coord)
	return _preload_in_domain_lookup.has(_chunk_coord_key(canonical))

func _record_preload_readiness_violation(coord: Vector2i, cause: String) -> void:
	var event := {
		"timestamp_msec": Time.get_ticks_msec(),
		"coord": _canonical_chunk_coord(coord),
		"cause": cause,
	}
	_post_preload_readiness_violations.append(event)
	if _post_preload_readiness_violations.size() > PRELOAD_READINESS_VIOLATION_BUFFER_MAX:
		_post_preload_readiness_violations.pop_front()
	_record_stage_telemetry("preload_readiness_violation", coord, 0.0, {
		"cause": cause,
	})

func get_preload_readiness_violations() -> Array:
	return _post_preload_readiness_violations.duplicate(true)

func clear_preload_readiness_violations() -> void:
	_post_preload_readiness_violations.clear()

func get_preload_runtime_state() -> Dictionary:
	return {
		"active_signature": _preload_active_domain_signature,
		"active_identity": _preload_active_domain_identity.duplicate(true),
		"in_domain_chunk_count": _preload_in_domain_lookup.size(),
		"readiness_violation_count": _post_preload_readiness_violations.size(),
	}

func get_runtime_stage_telemetry() -> Array:
	return _runtime_stage_telemetry.duplicate(true)

func clear_runtime_stage_telemetry() -> void:
	_runtime_stage_telemetry.clear()

func get_streaming_queue_snapshot() -> Dictionary:
	return {
		"pending_critical": _pending_chunk_requests.size(),
		"pending_enrichment": _pending_enrichment_requests.size(),
		"pending_unload": _pending_unload_requests.size(),
		"pending_entity_spawn": _entity_spawn_queue.size(),
		"pending_dirty_flush": _pending_dirty_flush_requests.size(),
		"dirty_coords": _dirty_chunk_coords.size(),
	}

func set_startup_streaming_mode(enabled: bool, release_backoff_frames: int = 0) -> void:
	_startup_streaming_mode = enabled
	if not enabled and release_backoff_frames > 0:
		_enrichment_backoff_frames = max(_enrichment_backoff_frames, release_backoff_frames)

func set_enrichment_suppressed(enabled: bool) -> void:
	_enrichment_suppressed = enabled

func get_canonical_chunk_coord(coord: Vector2i) -> Vector2i:
	return _canonical_chunk_coord(coord)
	
func restart() -> void:
	print("InfiniteChunkManager: Restarting world state...")
	current_session_id += 1 # 增加 Session ID 以使旧的异步任务失效
	_clear_loaded_world_visuals()
	loaded_chunks.clear()
	_loading_queue.clear()
	_pending_chunk_requests.clear()
	_enrichment_queue.clear()
	_pending_enrichment_requests.clear()
	_unload_queue.clear()
	_pending_unload_requests.clear()
	_entity_spawn_queue.clear()
	_dirty_flush_queue.clear()
	_pending_dirty_flush_requests.clear()
	_dirty_chunk_coords.clear()
	_chunk_generated_cells.clear()
	_precomputed_enrichment_cells.clear()
	_reset_preload_runtime_state()
	_runtime_stage_telemetry.clear()
	_enrichment_backoff_frames = 0
	_critical_backoff_frames = 0
	_critical_burst_count = 0
	_enrichment_cooldown_frames = 0
	if LiquidManager and LiquidManager.has_method("clear_runtime_state"):
		LiquidManager.clear_runtime_state()
	
	# Fix: Explicitly destroy old entity containers (since they are on Main scene, not WorldGenerator)
	for container in chunk_entity_containers.values():
		if is_instance_valid(container):
			container.queue_free()
	chunk_entity_containers.clear()
	
	# 如果是新游戏，我们必须清空之前保存的所有区块 Delta
	world_delta_data.clear()
	
	# 删除危险的 _wipe_save_data_debug() 调用，防止存档被误删
	print("InfiniteChunkManager: restart() called, memory deltas cleared.")

func set_save_root(path_root: String, preserve_current_data: bool = false) -> void:
	# 确保路径以斜杠结尾
	var final_path = path_root
	if not final_path.ends_with("/"):
		final_path += "/"
		
	if active_save_root == final_path:
		return 
		
	active_save_root = final_path
	_ensure_save_dir()
	print("InfiniteChunkManager: 存档路径已切换至 ", active_save_root)
	
	if preserve_current_data:
		return

	_clear_loaded_world_visuals()
	for container in chunk_entity_containers.values():
		if is_instance_valid(container):
			container.queue_free()
	chunk_entity_containers.clear()
	world_delta_data.clear()
	loaded_chunks.clear()
	_loading_queue.clear()
	_pending_chunk_requests.clear()
	_enrichment_queue.clear()
	_pending_enrichment_requests.clear()
	_unload_queue.clear()
	_pending_unload_requests.clear()
	_entity_spawn_queue.clear()
	_dirty_flush_queue.clear()
	_pending_dirty_flush_requests.clear()
	_dirty_chunk_coords.clear()
	_chunk_generated_cells.clear()
	_precomputed_enrichment_cells.clear()
	_reset_preload_runtime_state()
	_runtime_stage_telemetry.clear()
	_enrichment_backoff_frames = 0
	_critical_backoff_frames = 0
	_critical_burst_count = 0
	_enrichment_cooldown_frames = 0
	if LiquidManager and LiquidManager.has_method("clear_runtime_state"):
		LiquidManager.clear_runtime_state()
	
	# 预加载新路径下的修改数据
	_preload_all_deltas()

func _preload_all_deltas() -> void:
	if not DirAccess.dir_exists_absolute(active_save_root):
		return
		
	var dir = DirAccess.open(active_save_root)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") and file_name.begins_with("chunk_"):
				var path = active_save_root + file_name
				var chunk = ResourceLoader.load(path)
				if chunk is WorldChunk:
					world_delta_data[chunk.coord] = chunk
			file_name = dir.get_next()
		dir.list_dir_end()
		print("InfiniteChunkManager: 预加载了 %d 个区块修改数据。" % world_delta_data.size())

func _chunk_has_persistable_changes(chunk: WorldChunk) -> bool:
	if chunk == null:
		return false
	if not chunk.entities.is_empty():
		return true
	for l in [0, 1, 2]:
		if not chunk.deltas.get(l, {}).is_empty():
			return true
	return false

func _mark_chunk_dirty(coord: Vector2i) -> void:
	var canonical := _canonical_chunk_coord(coord)
	_dirty_chunk_coords[canonical] = true

func _request_dirty_flush(coord: Vector2i) -> void:
	var canonical := _canonical_chunk_coord(coord)
	if _dirty_flush_queue.has(canonical):
		return
	_dirty_flush_queue[canonical] = true
	_pending_dirty_flush_requests.append(canonical)

func request_dirty_flush_all() -> void:
	for coord in _dirty_chunk_coords.keys():
		_request_dirty_flush(coord)

func has_pending_dirty_flushes() -> bool:
	return not _pending_dirty_flush_requests.is_empty() or not _dirty_flush_queue.is_empty()

func _flush_dirty_chunk(coord: Vector2i) -> bool:
	var canonical := _canonical_chunk_coord(coord)
	if not _dirty_chunk_coords.has(canonical):
		return true
	if not world_delta_data.has(canonical):
		_dirty_chunk_coords.erase(canonical)
		return true

	var chunk: WorldChunk = world_delta_data[canonical]
	if not _chunk_has_persistable_changes(chunk):
		_dirty_chunk_coords.erase(canonical)
		return true

	var err := ResourceSaver.save(chunk, _get_save_path(canonical))
	if err == OK:
		_dirty_chunk_coords.erase(canonical)
		return true

	push_warning("InfiniteChunkManager: dirty flush failed for chunk %s with error %d" % [str(canonical), err])
	return false

func _process_dirty_flush_budget() -> void:
	if _pending_dirty_flush_requests.is_empty():
		return

	var stage_start := Time.get_ticks_usec()
	var flushed_count := 0
	while not _pending_dirty_flush_requests.is_empty():
		var coord = _pending_dirty_flush_requests.pop_front()
		if not _dirty_flush_queue.has(coord):
			continue
		_dirty_flush_queue.erase(coord)
		_flush_dirty_chunk(coord)
		flushed_count += 1

		var elapsed_ms := float(Time.get_ticks_usec() - stage_start) / 1000.0
		if elapsed_ms >= DIRTY_FLUSH_BUDGET_MS:
			break

	if flushed_count > 0:
		var elapsed_ms := float(Time.get_ticks_usec() - stage_start) / 1000.0
		_record_stage_telemetry("dirty_flush", "all", elapsed_ms, {
			"flushed_chunks": flushed_count,
			"remaining": _pending_dirty_flush_requests.size(),
		})

func flush_pending_dirty_writes_sync() -> void:
	request_dirty_flush_all()
	while not _pending_dirty_flush_requests.is_empty():
		var coord = _pending_dirty_flush_requests.pop_front()
		if _dirty_flush_queue.has(coord):
			_dirty_flush_queue.erase(coord)
		_flush_dirty_chunk(coord)

func save_all_deltas(force_all: bool = false, synchronous: bool = true) -> void:
	if force_all:
		for coord in world_delta_data.keys():
			var chunk: WorldChunk = world_delta_data[coord]
			if _chunk_has_persistable_changes(chunk):
				_mark_chunk_dirty(coord)

	if synchronous:
		flush_pending_dirty_writes_sync()
	else:
		request_dirty_flush_all()

func _wipe_save_data_debug() -> void:
	# 简单暴力的清理
	var dir = DirAccess.open(active_save_root)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		print("InfiniteChunkManager: 已强制清理旧区块存档。")

func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(active_save_root):
		DirAccess.make_dir_recursive_absolute(active_save_root)

func clear_save_root_data(path_root: String = "") -> void:
	var target_root := active_save_root if path_root == "" else path_root
	if not target_root.ends_with("/"):
		target_root += "/"
	if not DirAccess.dir_exists_absolute(target_root):
		return

	var dir := DirAccess.open(target_root)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with("chunk_") and file_name.ends_with(".tres"):
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

func _get_save_path(coord: Vector2i) -> String:
	var canonical := _canonical_chunk_coord(coord)
	return active_save_root + "chunk_%d_%d.tres" % [canonical.x, canonical.y]

func _parse_delta_local_pos_key(key: Variant) -> Variant:
	if key is Vector2i:
		return key
	if key is Vector2:
		return Vector2i(int(key.x), int(key.y))
	if key is String:
		var parts = key.split(",")
		if parts.size() == 2:
			return Vector2i(int(parts[0]), int(parts[1]))
	return null

func _get_world_topology() -> Node:
	return get_node_or_null("/root/WorldTopology")

func _canonical_chunk_coord(coord: Vector2i) -> Vector2i:
	var world_topology = _get_world_topology()
	if world_topology and world_topology.has_method("canonical_chunk_coord"):
		return world_topology.canonical_chunk_coord(coord)
	return coord

func _get_hard_floor_global_y() -> int:
	var world_topology = _get_world_topology()
	if world_topology and world_topology.has_method("get_bedrock_hard_floor_global_y"):
		return int(world_topology.get_bedrock_hard_floor_global_y())
	return 2147483647

func _is_chunk_request_blocked_by_depth_boundary(coord: Vector2i) -> bool:
	var world_topology = _get_world_topology()
	if not world_topology:
		return false
	if world_topology.has_method("is_chunk_below_hard_floor"):
		return bool(world_topology.is_chunk_below_hard_floor(coord))
	return false

func _clamp_chunk_coord_to_hard_floor(coord: Vector2i) -> Vector2i:
	var world_topology = _get_world_topology()
	if not world_topology:
		return coord
	if not world_topology.has_method("is_depth_boundary_enabled"):
		return coord
	if not bool(world_topology.is_depth_boundary_enabled()):
		return coord
	if not world_topology.has_method("get_bedrock_hard_floor_global_y"):
		return coord

	var hard_floor_global_y := int(world_topology.get_bedrock_hard_floor_global_y())
	var max_chunk_y := int(floor(float(hard_floor_global_y) / float(CHUNK_SIZE)))
	if coord.y > max_chunk_y:
		return Vector2i(coord.x, max_chunk_y)
	return coord

func _canonical_tile_x(tile_x: int) -> int:
	var world_topology = _get_world_topology()
	if world_topology and world_topology.has_method("wrap_tile_x"):
		return int(world_topology.wrap_tile_x(tile_x))
	return tile_x

## 获取世界坐标所属的区块坐标
func get_chunk_coord(world_pos: Vector2) -> Vector2i:
	var tile_pos := Vector2i((world_pos / TILE_SIZE).floor())
	tile_pos.x = _canonical_tile_x(tile_pos.x)
	var coord := Vector2i((Vector2(tile_pos) / CHUNK_SIZE).floor())
	return _canonical_chunk_coord(coord)

## 获取区块内局部坐标
func get_local_tile_pos(world_pos: Vector2) -> Vector2i:
	var tile_pos := Vector2i((world_pos / TILE_SIZE).floor())
	tile_pos.x = _canonical_tile_x(tile_pos.x)
	return Vector2i(
		posmod(tile_pos.x, CHUNK_SIZE),
		posmod(tile_pos.y, CHUNK_SIZE)
	)

## 记录玩家修改
func record_delta(world_pos: Vector2, layer_idx: int, source_id: int, atlas_coords: Vector2i = Vector2i.ZERO) -> void:
	var c_coord = get_chunk_coord(world_pos)
	var l_pos = get_local_tile_pos(world_pos)
	
	if not world_delta_data.has(c_coord):
		# 尝试从磁盘加载
		var path = _get_save_path(c_coord)
		if FileAccess.file_exists(path):
			world_delta_data[c_coord] = ResourceLoader.load(path)
		else:
			world_delta_data[c_coord] = WorldChunk.new()
			world_delta_data[c_coord].coord = c_coord
	
	world_delta_data[c_coord].add_delta(layer_idx, l_pos, source_id, atlas_coords)
	_mark_chunk_dirty(c_coord)
	
	# 同步更新小地图
	if MinimapManager and MinimapManager.has_method("update_tile_at_pos"):
		MinimapManager.update_tile_at_pos(world_pos, source_id, atlas_coords)

## 更新玩家周边的区块加载状态
func update_player_vicinity(player_pos: Vector2, custom_radius: int = -1, allow_unload: bool = true, travel_bias_x: int = 0, vertical_radius: int = -1) -> void:
	if travel_bias_x != 0 or not allow_unload:
		_enrichment_cooldown_frames = max(_enrichment_cooldown_frames, ENRICHMENT_COOLDOWN_FRAMES_WHILE_MOVING)
	else:
		_enrichment_cooldown_frames = max(_enrichment_cooldown_frames, ENRICHMENT_COOLDOWN_FRAMES_IDLE_REFRESH)

	var needed_chunk_lookup: Dictionary = {}
	var needed_chunks_ordered: Array = []
	var effective_radius_x := custom_radius if custom_radius >= 0 else (STARTUP_LOAD_RADIUS if _startup_streaming_mode else LOAD_RADIUS)
	var effective_radius_y := vertical_radius if vertical_radius >= 0 else (STARTUP_LOAD_RADIUS if _startup_streaming_mode else LOAD_RADIUS_VERTICAL)
	if custom_radius >= 0 and vertical_radius < 0:
		effective_radius_y = custom_radius
	
	# 增加对 0 点附近的检查，并确保玩家位置发生显著变化再更新
	var center_chunk = get_chunk_coord(player_pos)
	var max_manhattan_distance := effective_radius_x + effective_radius_y
	var distance_buckets: Array = []
	distance_buckets.resize(max_manhattan_distance + 1)
	for idx in range(distance_buckets.size()):
		distance_buckets[idx] = []

	var x_min: int = center_chunk.x - effective_radius_x
	var x_max: int = center_chunk.x + effective_radius_x
	var x_sequence: Array = []
	if travel_bias_x > 0:
		for x in range(x_max, x_min - 1, -1):
			x_sequence.append(x)
	else:
		for x in range(x_min, x_max + 1):
			x_sequence.append(x)

	for x in x_sequence:
		for y in range(center_chunk.y - effective_radius_y, center_chunk.y + effective_radius_y + 1):
			var canonical := _canonical_chunk_coord(Vector2i(x, y))
			if _is_chunk_request_blocked_by_depth_boundary(canonical):
				continue
			if needed_chunk_lookup.has(canonical):
				continue
			needed_chunk_lookup[canonical] = true
			var manhattan_distance: int = int(abs(x - center_chunk.x) + abs(y - center_chunk.y))
			distance_buckets[manhattan_distance].append(canonical)
	for bucket in distance_buckets:
		if bucket is Array and not bucket.is_empty():
			needed_chunks_ordered.append_array(bucket)

	_prune_pending_streaming_requests(needed_chunk_lookup)
	
	# 卸载不再需要的区块（允许在特殊阶段临时关闭，以避免卸载/重载抖动）
	if allow_unload:
		var unload_radius_x: int = effective_radius_x + UNLOAD_RADIUS_MARGIN
		var unload_radius_y: int = effective_radius_y + UNLOAD_RADIUS_MARGIN_VERTICAL
		var to_unload = []
		for coord in loaded_chunks.keys():
			if not (coord is Vector2i):
				continue
			var dx: int = abs(coord.x - center_chunk.x)
			var dy: int = abs(coord.y - center_chunk.y)
			if dx > unload_radius_x or dy > unload_radius_y:
				to_unload.append(coord)
		
		for coord in to_unload:
			_request_chunk_unload(coord)
	else:
		# 移动冲刺阶段暂停卸载，避免清区块与加载抢占主线程造成行走卡顿。
		_unload_queue.clear()
		_pending_unload_requests.clear()
		
	# 加载新区块
	for coord in needed_chunks_ordered:
		if not loaded_chunks.has(coord) and not _loading_queue.has(coord):
			_request_chunk_load(coord)

func _prune_pending_streaming_requests(needed_chunk_lookup: Dictionary) -> void:
	if needed_chunk_lookup.is_empty():
		_pending_chunk_requests.clear()
		_loading_queue.clear()
		_pending_enrichment_requests.clear()
		_enrichment_queue.clear()
		return

	var pruned_pending_chunk_requests: Array = []
	var pruned_loading_queue: Dictionary = {}
	for raw_coord in _pending_chunk_requests:
		if not (raw_coord is Vector2i):
			continue
		var coord: Vector2i = _canonical_chunk_coord(raw_coord)
		if _is_chunk_request_blocked_by_depth_boundary(coord):
			continue
		if loaded_chunks.has(coord):
			continue
		if not needed_chunk_lookup.has(coord):
			continue
		if pruned_loading_queue.has(coord):
			continue
		pruned_loading_queue[coord] = true
		pruned_pending_chunk_requests.append(coord)
	_pending_chunk_requests = pruned_pending_chunk_requests
	_loading_queue = pruned_loading_queue

	var pruned_pending_enrichment_requests: Array = []
	var pruned_enrichment_queue: Dictionary = {}
	for raw_coord in _pending_enrichment_requests:
		if not (raw_coord is Vector2i):
			continue
		var coord: Vector2i = _canonical_chunk_coord(raw_coord)
		if _is_chunk_request_blocked_by_depth_boundary(coord):
			continue
		if not loaded_chunks.has(coord):
			continue
		if not needed_chunk_lookup.has(coord):
			continue
		if pruned_enrichment_queue.has(coord):
			continue
		pruned_enrichment_queue[coord] = true
		pruned_pending_enrichment_requests.append(coord)
	_pending_enrichment_requests = pruned_pending_enrichment_requests
	_enrichment_queue = pruned_enrichment_queue

func prime_required_chunks(coords: Array) -> void:
	for raw_coord in coords:
		if not (raw_coord is Vector2i):
			continue
		var coord := _canonical_chunk_coord(raw_coord)
		if _is_chunk_request_blocked_by_depth_boundary(coord):
			continue
		if not loaded_chunks.has(coord) and not _loading_queue.has(coord):
			_request_chunk_load(coord)

func _verify_precomputed_domain_complete(domain_keys: Array, precomputed_lookup: Dictionary) -> bool:
	for raw_key in domain_keys:
		var key := String(raw_key)
		if key == "":
			return false
		if not precomputed_lookup.has(key):
			return false
	return true

func run_planetary_full_preload(options: Dictionary = {}) -> Dictionary:
	_ensure_preload_dirs()
	var world_topology := _get_world_topology()
	if not world_topology:
		return {
			"required": false,
			"completed": true,
			"failure_reason": "WORLD_TOPOLOGY_UNAVAILABLE",
			"domain_type": "legacy_spawn_warmup_fallback",
		}

	if not world_topology.has_method("get_preload_domain_definition"):
		return {
			"required": false,
			"completed": true,
			"failure_reason": "PRELOAD_DOMAIN_UNSUPPORTED",
			"domain_type": "legacy_spawn_warmup_fallback",
		}

	var domain: Dictionary = world_topology.get_preload_domain_definition()
	var required := bool(domain.get("required", false))
	if not required:
		_reset_preload_runtime_state()
		return {
			"required": false,
			"completed": true,
			"failure_reason": "",
			"domain_type": String(domain.get("domain_type", "legacy_spawn_warmup_fallback")),
			"legacy_fallback": true,
		}

	var domain_identity: Dictionary = world_topology.get_preload_domain_identity() if world_topology.has_method("get_preload_domain_identity") else {}
	var signature := ""
	if world_topology.has_method("get_preload_domain_signature"):
		signature = String(world_topology.get_preload_domain_signature())
	else:
		signature = "planetary_%s" % str(domain_identity)

	var domain_coords := _build_preload_domain_coords(domain)
	var total_chunks := domain_coords.size()
	if total_chunks <= 0:
		return {
			"required": true,
			"completed": false,
			"failure_reason": "EMPTY_PRELOAD_DOMAIN",
			"domain_type": String(domain.get("domain_type", "planetary_full_world")),
			"total_chunks": total_chunks,
		}

	var domain_keys: Array = []
	for raw_coord in domain_coords:
		if not (raw_coord is Vector2i):
			continue
		domain_keys.append(_chunk_coord_key(raw_coord))
	var precomputed_lookup := _collect_precomputed_chunk_lookup(signature)

	var generator = get_tree().get_first_node_in_group("world_generator")
	if not is_instance_valid(generator):
		return {
			"required": true,
			"completed": false,
			"failure_reason": "MISSING_WORLD_GENERATOR",
			"domain_type": String(domain.get("domain_type", "planetary_full_world")),
			"total_chunks": total_chunks,
		}

	var timeout_sec := float(options.get("timeout_sec", 0.0))
	if timeout_sec <= 0.0 and world_topology.has_method("get_preload_timeout_seconds"):
		timeout_sec = float(world_topology.get_preload_timeout_seconds())
	if timeout_sec <= 0.0:
		timeout_sec = 600.0
	var minimum_timeout_sec := clampf(float(total_chunks) * 0.08, 180.0, 1800.0)
	if timeout_sec < minimum_timeout_sec:
		timeout_sec = minimum_timeout_sec

	var batch_size := int(options.get("batch_size", 0))
	if batch_size <= 0 and world_topology.has_method("get_preload_batch_size"):
		batch_size = int(world_topology.get_preload_batch_size())
	if batch_size <= 0:
		batch_size = 64
	batch_size = clampi(batch_size, PRELOAD_ADAPTIVE_BATCH_MIN, PRELOAD_ADAPTIVE_BATCH_MAX)

	var completed_marker := _load_preload_completed_marker(signature)
	if _is_completed_marker_usable(completed_marker, signature, domain_identity):
		if _verify_precomputed_domain_complete(domain_keys, precomputed_lookup):
			_activate_preload_runtime_state(signature, domain_identity, domain_coords)
			var cached_result := {
				"required": true,
				"completed": true,
				"resumed_from_checkpoint": false,
				"reused_completed_cache": true,
				"failure_reason": "",
				"domain_type": String(domain.get("domain_type", "planetary_full_world")),
				"total_chunks": total_chunks,
				"processed_chunks": total_chunks,
				"remaining_chunks": 0,
				"signature": signature,
			}
			preload_finished.emit(cached_result)
			return cached_result

	var completed_lookup := {}
	var cursor := 0
	var batch_index := 0
	var resumed_from_checkpoint := false
	var reused_precomputed_chunks := 0

	var checkpoint := _load_preload_checkpoint(signature)
	if _is_checkpoint_usable(checkpoint, signature, domain_identity):
		resumed_from_checkpoint = true
		cursor = clampi(int(checkpoint.get("cursor", 0)), 0, total_chunks)
		batch_index = maxi(int(checkpoint.get("batch_index", 0)), 0)
	else:
		_clear_preload_checkpoint(signature)

	for raw_key in domain_keys:
		var key := String(raw_key)
		if key == "":
			continue
		if not precomputed_lookup.has(key):
			continue
		if completed_lookup.has(key):
			continue
		completed_lookup[key] = true
		reused_precomputed_chunks += 1

	var preload_start_msec := Time.get_ticks_msec()
	var adaptive_batch_size := batch_size
	var checkpoint_interval_batches := int(options.get("checkpoint_interval_batches", PRELOAD_CHECKPOINT_SAVE_INTERVAL_BATCHES))
	if checkpoint_interval_batches <= 0:
		checkpoint_interval_batches = PRELOAD_CHECKPOINT_SAVE_INTERVAL_BATCHES
	var checkpoint_interval_msec := int(options.get("checkpoint_interval_msec", PRELOAD_CHECKPOINT_SAVE_INTERVAL_MS))
	if checkpoint_interval_msec <= 0:
		checkpoint_interval_msec = PRELOAD_CHECKPOINT_SAVE_INTERVAL_MS
	var last_checkpoint_save_msec := preload_start_msec
	var last_progress_emit_msec := preload_start_msec
	var failure_reason := ""
	var timeout_snapshot := {}

	while completed_lookup.size() < total_chunks:
		var elapsed_sec := float(Time.get_ticks_msec() - preload_start_msec) / 1000.0
		if timeout_sec > 0.0 and elapsed_sec > timeout_sec:
			var processed_now := completed_lookup.size()
			if processed_now > 0 and timeout_sec < PRELOAD_TIMEOUT_HARD_CAP_SEC:
				var throughput_chunks_per_sec := float(processed_now) / maxf(elapsed_sec, 0.001)
				var remaining_now := maxi(total_chunks - processed_now, 0)
				var estimated_remaining_sec := float(remaining_now) / maxf(throughput_chunks_per_sec, 0.001)
				var extended_timeout := maxf(timeout_sec + PRELOAD_TIMEOUT_SOFT_EXTENSION_SEC, elapsed_sec + estimated_remaining_sec * 1.20 + 20.0)
				timeout_sec = minf(extended_timeout, PRELOAD_TIMEOUT_HARD_CAP_SEC)
			if elapsed_sec > timeout_sec:
				failure_reason = "PRELOAD_TIMEOUT"
				timeout_snapshot = {
					"elapsed_sec": elapsed_sec,
					"timeout_sec": timeout_sec,
					"processed_chunks": completed_lookup.size(),
					"remaining_chunks": maxi(total_chunks - completed_lookup.size(), 0),
					"batch_index": batch_index,
				}
				break

		if cursor >= total_chunks and completed_lookup.size() < total_chunks:
			# 从头重扫一次，拾取可能因 checkpoint 跳转导致遗漏的坐标。
			cursor = 0

		var batch_start_usec := Time.get_ticks_usec()
		var processed_this_batch := 0
		while cursor < total_chunks and processed_this_batch < adaptive_batch_size:
			var coord: Vector2i = domain_coords[cursor]
			var key := String(domain_keys[cursor])
			cursor += 1
			if completed_lookup.has(key):
				continue

			var cells: Dictionary = generator.generate_chunk_cells(coord, false)
			if not _save_precomputed_chunk_cells(signature, coord, cells):
				failure_reason = "PRELOAD_PERSISTENCE_FAILED"
				timeout_snapshot = {
					"coord": coord,
					"processed_chunks": completed_lookup.size(),
					"remaining_chunks": maxi(total_chunks - completed_lookup.size(), 0),
					"batch_index": batch_index,
					"timeout_sec": timeout_sec,
				}
				break

			completed_lookup[key] = true
			precomputed_lookup[key] = true
			processed_this_batch += 1

			var batch_elapsed_ms := float(Time.get_ticks_usec() - batch_start_usec) / 1000.0
			if batch_elapsed_ms >= PRELOAD_BATCH_BUDGET_MS:
				break

		var batch_elapsed_ms := float(Time.get_ticks_usec() - batch_start_usec) / 1000.0
		var processed_total := completed_lookup.size()
		var remaining_chunks := maxi(total_chunks - processed_total, 0)
		var progress := float(processed_total) / maxf(float(total_chunks), 1.0)
		if processed_this_batch >= adaptive_batch_size and batch_elapsed_ms < PRELOAD_BATCH_BUDGET_MS * 0.55:
			adaptive_batch_size = mini(adaptive_batch_size + 8, PRELOAD_ADAPTIVE_BATCH_MAX)
		elif batch_elapsed_ms > PRELOAD_BATCH_BUDGET_MS * 1.15:
			adaptive_batch_size = maxi(adaptive_batch_size - 8, PRELOAD_ADAPTIVE_BATCH_MIN)
		var snapshot := {
			"signature": signature,
			"batch_index": batch_index,
			"processed_in_batch": processed_this_batch,
			"processed_chunks": processed_total,
			"remaining_chunks": remaining_chunks,
			"progress": progress,
			"elapsed_ms": batch_elapsed_ms,
			"timeout_sec": timeout_sec,
			"adaptive_batch_size": adaptive_batch_size,
			"reused_precomputed_chunks": reused_precomputed_chunks,
		}
		var now_msec := Time.get_ticks_msec()
		var should_emit_progress := false
		if failure_reason != "":
			should_emit_progress = true
		elif processed_total >= total_chunks:
			should_emit_progress = true
		elif batch_index == 0:
			should_emit_progress = true
		elif PRELOAD_PROGRESS_EMIT_INTERVAL_BATCHES > 0 and ((batch_index + 1) % PRELOAD_PROGRESS_EMIT_INTERVAL_BATCHES) == 0:
			should_emit_progress = true
		elif PRELOAD_PROGRESS_EMIT_INTERVAL_MS > 0 and now_msec - last_progress_emit_msec >= PRELOAD_PROGRESS_EMIT_INTERVAL_MS:
			should_emit_progress = true

		if should_emit_progress:
			_record_stage_telemetry("preload_batch", "planetary_full", batch_elapsed_ms, {
				"batch_index": batch_index,
				"processed_in_batch": processed_this_batch,
				"processed_chunks": processed_total,
				"remaining_chunks": remaining_chunks,
				"progress": progress,
				"adaptive_batch_size": adaptive_batch_size,
			})
			preload_progress.emit(snapshot)
			last_progress_emit_msec = now_msec

		var should_save_checkpoint := false
		if failure_reason != "":
			should_save_checkpoint = true
		elif processed_total >= total_chunks:
			should_save_checkpoint = true
		elif batch_index == 0:
			should_save_checkpoint = true
		elif checkpoint_interval_batches > 0 and ((batch_index + 1) % checkpoint_interval_batches) == 0:
			should_save_checkpoint = true
		elif checkpoint_interval_msec > 0 and now_msec - last_checkpoint_save_msec >= checkpoint_interval_msec:
			should_save_checkpoint = true

		if should_save_checkpoint:
			var checkpoint_payload := {
				"signature": signature,
				"identity": domain_identity,
				"cursor": cursor,
				"batch_index": batch_index + 1,
				"processed_chunks": processed_total,
				"total_chunks": total_chunks,
				"remaining_chunks": remaining_chunks,
				"progress": progress,
				"adaptive_batch_size": adaptive_batch_size,
				"reused_precomputed_chunks": reused_precomputed_chunks,
				"updated_msec": now_msec,
			}
			_save_preload_checkpoint(signature, checkpoint_payload)
			last_checkpoint_save_msec = now_msec

		if failure_reason != "":
			break

		batch_index += 1
		if processed_total < total_chunks and (
			((batch_index + 1) % PRELOAD_FRAME_YIELD_INTERVAL_BATCHES) == 0
			or batch_elapsed_ms >= PRELOAD_BATCH_BUDGET_MS * 1.25
		):
			await get_tree().process_frame

	if failure_reason != "":
		var failure_result := {
			"required": true,
			"completed": false,
			"resumed_from_checkpoint": resumed_from_checkpoint,
			"reused_completed_cache": false,
			"failure_reason": failure_reason,
			"domain_type": String(domain.get("domain_type", "planetary_full_world")),
			"total_chunks": total_chunks,
			"processed_chunks": completed_lookup.size(),
			"remaining_chunks": maxi(total_chunks - completed_lookup.size(), 0),
			"signature": signature,
			"reused_precomputed_chunks": reused_precomputed_chunks,
			"progress_snapshot": timeout_snapshot,
		}
		preload_finished.emit(failure_result)
		return failure_result

	var marker_payload := {
		"signature": signature,
		"identity": domain_identity,
		"completed": true,
		"total_chunks": total_chunks,
		"completed_msec": Time.get_ticks_msec(),
	}
	if not _save_preload_completed_marker(signature, marker_payload):
		var marker_failure := {
			"required": true,
			"completed": false,
			"resumed_from_checkpoint": resumed_from_checkpoint,
			"reused_completed_cache": false,
			"failure_reason": "PRELOAD_COMPLETION_MARKER_FAILED",
			"domain_type": String(domain.get("domain_type", "planetary_full_world")),
			"total_chunks": total_chunks,
			"processed_chunks": completed_lookup.size(),
			"remaining_chunks": maxi(total_chunks - completed_lookup.size(), 0),
			"signature": signature,
		}
		preload_finished.emit(marker_failure)
		return marker_failure

	_clear_preload_checkpoint(signature)
	_activate_preload_runtime_state(signature, domain_identity, domain_coords)

	var success_result := {
		"required": true,
		"completed": true,
		"resumed_from_checkpoint": resumed_from_checkpoint,
		"reused_completed_cache": false,
		"failure_reason": "",
		"domain_type": String(domain.get("domain_type", "planetary_full_world")),
		"total_chunks": total_chunks,
		"processed_chunks": completed_lookup.size(),
		"remaining_chunks": 0,
		"signature": signature,
		"reused_precomputed_chunks": reused_precomputed_chunks,
		"elapsed_sec": float(Time.get_ticks_msec() - preload_start_msec) / 1000.0,
	}
	preload_finished.emit(success_result)
	return success_result

func _request_chunk_load(coord: Vector2i) -> void:
	var canonical := _canonical_chunk_coord(coord)
	if _is_chunk_request_blocked_by_depth_boundary(canonical):
		return
	_unload_queue.erase(canonical)
	_pending_unload_requests.erase(canonical)
	_loading_queue[canonical] = true
	_pending_chunk_requests.append(canonical)

func _request_chunk_enrichment(coord: Vector2i) -> void:
	var canonical := _canonical_chunk_coord(coord)
	if _enrichment_queue.has(canonical):
		return
	_enrichment_queue[canonical] = true
	_pending_enrichment_requests.append(canonical)

func _request_chunk_unload(coord: Vector2i) -> void:
	var canonical := _canonical_chunk_coord(coord)
	if _unload_queue.has(canonical):
		return
	_unload_queue[canonical] = true
	_pending_unload_requests.append(canonical)

func _process_unload_budget() -> void:
	if _pending_unload_requests.is_empty():
		return
	# 让卸载在关键加载/补全过程空闲后再做，减少跨区块移动时的帧峰值。
	if not _pending_chunk_requests.is_empty() or not _pending_enrichment_requests.is_empty():
		return

	var stage_start := Time.get_ticks_usec()
	var unloaded_count := 0
	while not _pending_unload_requests.is_empty():
		var coord = _pending_unload_requests.pop_front()
		if not _unload_queue.has(coord):
			continue
		_unload_queue.erase(coord)
		var unload_start := Time.get_ticks_usec()
		_unload_chunk(coord)
		var unload_elapsed_ms := float(Time.get_ticks_usec() - unload_start) / 1000.0
		_record_stage_telemetry("unload", coord, unload_elapsed_ms, {
			"remaining": _pending_unload_requests.size(),
		})
		unloaded_count += 1

		var elapsed_ms := float(Time.get_ticks_usec() - stage_start) / 1000.0
		if elapsed_ms >= UNLOAD_CHUNK_BUDGET_MS:
			break

	if unloaded_count > 0:
		var elapsed_ms := float(Time.get_ticks_usec() - stage_start) / 1000.0
		_record_stage_telemetry("unload", "batch", elapsed_ms, {
			"unloaded_chunks": unloaded_count,
			"remaining": _pending_unload_requests.size(),
		})

func _build_chunk_on_main_thread(coord: Vector2i, session_id: int) -> void:
	coord = _canonical_chunk_coord(coord)
	if _is_chunk_request_blocked_by_depth_boundary(coord):
		_loading_queue.erase(coord)
		return
	# 彻底移除工作线程中的 SceneTree/Node 访问，改为主线程逐块构建。
	if session_id != current_session_id:
		_loading_queue.erase(coord)
		return
	if loaded_chunks.has(coord) or chunk_entity_containers.has(coord):
		_loading_queue.erase(coord)
		return

	var generator = get_tree().get_first_node_in_group("world_generator")
	if not is_instance_valid(generator):
		_loading_queue.erase(coord)
		return

	if _preload_active_domain_signature != "":
		var precomputed_cells := _load_precomputed_chunk_cells(_preload_active_domain_signature, coord)
		if not precomputed_cells.is_empty():
			var critical_precomputed_cells := _extract_critical_cells(precomputed_cells)
			_finalize_chunk_load(coord, critical_precomputed_cells, [], false, true)
			_precomputed_enrichment_cells[coord] = precomputed_cells
			_request_chunk_enrichment(coord)
			return
		if _is_coord_in_active_preload_domain(coord):
			_record_preload_readiness_violation(coord, "missing_precomputed_chunk")

	# 阶段 1：先生成可通行地形与核心洞穴，保证区块尽快可玩。
	var critical_cells = generator.generate_chunk_cells(coord, true)
	_finalize_chunk_load(coord, critical_cells, [])
	_request_chunk_enrichment(coord)

func _build_chunk_enrichment_on_main_thread(coord: Vector2i, session_id: int) -> void:
	coord = _canonical_chunk_coord(coord)
	if _is_chunk_request_blocked_by_depth_boundary(coord):
		return
	if session_id != current_session_id:
		return
	if not loaded_chunks.has(coord):
		return
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not is_instance_valid(generator):
		return

	if _precomputed_enrichment_cells.has(coord):
		var cached_cells: Variant = _precomputed_enrichment_cells.get(coord, {})
		_precomputed_enrichment_cells.erase(coord)
		if cached_cells is Dictionary and not cached_cells.is_empty():
			_apply_chunk_enrichment(coord, cached_cells, [])
			return

	# 阶段 2：补齐次要内容（矿物、地表装饰、树木和结构）。
	var cells = generator.generate_chunk_cells(coord)
	var spawned_entities = []
	var natural_ground_y: Array = []
	# 地表扫描只在地表附近区块执行，深层区块跳过该额外开销。
	if coord.y >= 4 and coord.y <= 6:
		for x in range(64):
			natural_ground_y.append(_get_top_tile_y(cells, x))

	_apply_structures(coord, cells, spawned_entities)
	if not natural_ground_y.is_empty():
		_apply_trees(coord, cells, natural_ground_y)
	_apply_chunk_enrichment(coord, cells, spawned_entities)

func _get_top_tile_y(cells: Dictionary, local_x: int) -> int:
	# 在 Layer 0 中寻找该 X 坐标的“真正的”地面 (非空且上方为空)
	if not cells.has(0): return -1
	for y in range(1, 64):
		var pos = Vector2i(local_x, y)
		var pos_above = Vector2i(local_x, y - 1)
		
		# 规则：当前格有瓦片，且上方格没有瓦片 (或者是空气)
		if cells[0].has(pos) and not cells[0].has(pos_above):
			return y
	# 边界情况：如果第 0 行就是地面
	if cells[0].has(Vector2i(local_x, 0)): return 0
	return -1

func get_chunk_hash(c_coord: Vector2i) -> int:
	# 引入世界种子作为额外的盐值，确保每局游戏的结构位置都不同
	var seed_salt = 0
	var gen = get_tree().get_first_node_in_group("world_generator")
	if gen and "seed_value" in gen:
		seed_salt = gen.seed_value
	
	var x = c_coord.x + 12345 + (seed_salt % 9999)
	var y = c_coord.y + 67890 + (seed_salt / 9999)
	return abs((x * 73856093) ^ (y * 19349663) ^ 5381 ^ seed_salt)

func _get_surface_structure_score(chunk_x: int) -> float:
	var hash_probe := get_chunk_hash(Vector2i(chunk_x, 5))
	var hash_component := float((hash_probe >> 5) & 1023) / 1023.0
	var noise_component := 0.5
	var generator = get_tree().get_first_node_in_group("world_generator")
	if generator and ("noise_surface_feature" in generator) and generator.noise_surface_feature:
		noise_component = (generator.noise_surface_feature.get_noise_1d(float(chunk_x) * 0.41 + 27.0) + 1.0) * 0.5
	return hash_component * 0.46 + noise_component * 0.54

func _is_surface_structure_anchor(chunk_x: int) -> bool:
	var score := _get_surface_structure_score(chunk_x)
	if score < 0.86:
		return false
	if score <= _get_surface_structure_score(chunk_x - 1):
		return false
	if score < _get_surface_structure_score(chunk_x + 1):
		return false
	return true

func _get_chunk_world_origin(c_coord: Vector2i) -> Vector2:
	return Vector2(c_coord.x * CHUNK_SIZE * TILE_SIZE, c_coord.y * CHUNK_SIZE * TILE_SIZE)

func _apply_structures(coord: Vector2i, chunk_data: Dictionary, entities_out: Array) -> void:
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not generator: return

	chunk_data["_coord"] = coord
	
	for dx in range(-2, 3): # 扩大检测范围，确保较宽的房屋能完整跨区块
		var check_coord = coord + Vector2i(dx, 0)
		var hash_val = get_chunk_hash(check_coord)
		
		if not ENABLE_TILE_HOUSE_STRUCTURES:
			continue
		if not _is_surface_structure_anchor(check_coord.x):
			continue

		var center_x_local = hash_val % 30 + 15
		# 严格使用整数像素偏差
		var global_house_x_tiles = check_coord.x * 64 + center_x_local

		# 安全保护：在世界原点附近 (Spawn Point) ±120 格范围内禁止生成结构，防止出生点被房子卡住
		if abs(global_house_x_tiles) < 120:
			continue

		# 高度扫描：扫描房子宽度的地面高度，取全宽度内的最高点（Y值最小）作为基准
		# 防止房子门口被埋在地下
		var house_half_width = 18 # 约 35/2
		var min_y_in_range = 99999
		for scan_x in range(global_house_x_tiles - house_half_width, global_house_x_tiles + house_half_width):
			var gy = _get_stable_ground_y(scan_x)
			if gy < min_y_in_range:
				min_y_in_range = gy

		# 稍微抬高一格，确保不切土
		var global_base_y = min_y_in_range
		var base_chunk_y = int(floor(float(global_base_y) / 64.0))

		# 只在靠近地基所在的区块带生成，避免高空区块出现孤立屋顶碎片
		# 房屋上方约 21 格，下方可能因地基补齐再延伸 10-20 格，预留 2 个 chunk 的带宽
		if abs(coord.y - base_chunk_y) > 2:
			continue

		var local_x = global_house_x_tiles - (coord.x * 64)
		var local_y = global_base_y - (coord.y * 64)

		# 只要房屋的一部分可能在该区块内，就调用生成逻辑
		# 房屋宽度约 35，高度约 20
		if local_x > -40 and local_x < 100 and local_y > -40 and local_y < 100:
			_generate_tile_house(chunk_data, Vector2i(local_x, local_y), entities_out)

		# 彻底移除随机矿井生成，防止地平线出现垂直空洞大坑
		# if dx == 0 and hash_val % 100 == 0:
		# 	_apply_shaft(chunk_data, hash_val)

	# 情况 3: 埋没遗迹
	if coord.y > 6 and get_chunk_hash(coord) % 15 == 0:
		_apply_ruins(coord, chunk_data, get_chunk_hash(coord))

func _get_stable_ground_y(global_x: int) -> int:
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not generator: return 300

	# 始终复用 WorldGenerator 的当前地表高度逻辑，避免与 terrain 迭代脱节导致漂浮结构。
	var surface_base = 300.0
	if generator.has_method("get_surface_height_at"):
		surface_base = generator.get_surface_height_at(global_x)
	elif generator.has_method("get_biome_at") and generator.has_variable("noise_continental"):
		# 兼容兜底：尽量保持旧行为，防止方法缺失时报错。
		var primary_biome = generator.get_biome_at(global_x, 0)
		var biome_amp = 60.0
		if generator.biome_params.has(primary_biome):
			biome_amp = generator.biome_params[primary_biome]["amp"]
		var cont_val = generator.noise_continental.get_noise_1d(global_x)
		surface_base = 300.0 + (cont_val * biome_amp)

	return int(floor(surface_base)) + 1

func _apply_shaft(chunk_data: Dictionary, hash_val: int) -> void:
	var start_x = hash_val % 40 + 10
	for y in range(64):
		for x in range(start_x, start_x + 6):
			var p = Vector2i(x,y)
			for l in [0,1,2]:
				if chunk_data.has(l): chunk_data[l][p] = {"source": -1, "atlas": Vector2i(-1,-1)}

# --- 建筑设计师模式：在此定义您的精美房屋蓝图 ---
# 您可以使用任何字符，并在下方的 _generate_tile_house 中定义它们的含义
const MY_CUSTOM_HOUSE_DESIGN = [
	"             AAAAAAAAA             ",
	"     AAAAAAAAAAAAAAAAAAAAAAAAA     ",
	"      A   AAAAA     AAAAA   A      ",
	"       A AAAA         AAAA A       ",
	"        ###################        ",
	"        #.................#        ",
	"        #.................#        ",
	"        #.................#        ",
	"        #.................#        ",
	"        #.................#        ",
	"        #.................#        ",
	"        #.................#        ",
	"        #.................#        ",
	"        #.................#        ",
	"        D.................D        ",
	"        D.................D        ",
	"        D.................D        ",
	"        D...........CCC...D        ",
	"        D.......M...CCC...D        ",
	"        ###################        ",
	"        ###################        "
]

func _generate_tile_house(chunk_data: Dictionary, base_pos: Vector2i, entities_out: Array) -> void:
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not generator: return
	
	var s_id = generator.tile_source_id
	var palette = {
		"#": {"type": "tile", "layer": 0, "source": s_id, "atlas": generator.stone_tile},
		"A": {"type": "tile", "layer": 0, "source": s_id, "atlas": generator.hard_rock_tile}, # 屋顶
		".": {"type": "tile", "layer": 1, "source": s_id, "atlas": generator.dirt_tile},      # 室内背景
		"+": {"type": "tile", "layer": 0, "source": s_id, "atlas": generator.hard_rock_tile}, # 梁柱 (有碰撞)
		"D": {"type": "special", "tag": "door", "bg": generator.dirt_tile},                  # 门及其背景
		"C": {"type": "special", "tag": "chest", "bg": generator.dirt_tile},                 # 箱子及其背景
		"M": {"type": "special", "tag": "merchant", "bg": generator.dirt_tile},              # 商人
		" ": {"type": "air"}
	}
	
	var design = MY_CUSTOM_HOUSE_DESIGN
	var house_height = design.size()
	var house_width = design[0].length()
	var processed_positions = {}
	
	var my_coord = chunk_data.get("_coord", Vector2i.ZERO)
	
	for row_idx in range(house_height):
		var y_offset = house_height - 1 - row_idx
		for x_idx in range(house_width):
			if processed_positions.has(Vector2i(x_idx, row_idx)): continue
			
			var char = design[row_idx][x_idx]
			# base_pos 现在被视为房屋底座所在 Tile
			var p = base_pos + Vector2i(x_idx, -y_offset)
			
			var item = palette.get(char, {"type": "air"})
			if item.get("type") == "air": continue
			
			# 严格计算全局坐标（Tile单位）
			var global_tile_x = my_coord.x * 64 + p.x
			var global_tile_y = my_coord.y * 64 + p.y
			
			var is_in_this_chunk = (
				global_tile_x >= my_coord.x * 64 and global_tile_x < (my_coord.x + 1) * 64 and
				global_tile_y >= my_coord.y * 64 and global_tile_y < (my_coord.y + 1) * 64
			)
			
			var local_p = Vector2i(
				global_tile_x - my_coord.x * 64,
				global_tile_y - my_coord.y * 64
			)
			
			if is_in_this_chunk:
				if not chunk_data.has(0): chunk_data[0] = {}
				if not chunk_data.has(1): chunk_data[1] = {}
				
				# 仅在非空气位置进行挖掘。如果 design 是 ' '，保留原地形。
				if item["type"] != "air":
					# 基础挖掘
					chunk_data[0][local_p] = {"source": -1, "atlas": Vector2i(-1,-1)}
					chunk_data[1][local_p] = {"source": -1, "atlas": Vector2i(-1,-1)}
					
					if item["type"] == "tile":
						chunk_data[item["layer"]][local_p] = {"source": item["source"], "atlas": item["atlas"]}
					elif item["type"] == "special":
						# 特殊实体通常需要一个背景方块，否则看起来是空洞
						if item.has("bg"):
							chunk_data[1][local_p] = {"source": s_id, "atlas": item["bg"]}

			# 实体判定逻辑
			if item["type"] == "special":
				var is_owner = false
				var entity_data = {}
				
				if item["tag"] == "door":
					var door_h = 0
					var cr = row_idx
					while cr < house_height and design[cr][x_idx] == "D":
						processed_positions[Vector2i(x_idx, cr)] = true
						cr += 1
						door_h += 1
					
					var bottom_tile_y = global_tile_y + door_h - 1
					var owner_x = int(floor(float(global_tile_x) / 64.0))
					var owner_y = int(floor(float(bottom_tile_y) / 64.0))
					
					if owner_x == my_coord.x and owner_y == my_coord.y:
						is_owner = true
						entity_data = {
							"scene_path": "res://scenes/world/interactive_door.tscn",
							"pos": Vector2(global_tile_x * TILE_SIZE, (bottom_tile_y + 1) * TILE_SIZE),
							"data": {"height": door_h}
						}
				elif item["tag"] == "chest":
					var owner_x = int(floor(float(global_tile_x) / 64.0))
					var owner_y = int(floor(float(global_tile_y) / 64.0))
					if owner_x == my_coord.x and owner_y == my_coord.y:
						is_owner = true
						entity_data = {
							"scene_path": generator.chest_scene.resource_path,
							"pos": Vector2(global_tile_x * TILE_SIZE, global_tile_y * TILE_SIZE),
							"data": {}
						}
					processed_positions[Vector2i(x_idx, row_idx)] = true
				
				elif item["tag"] == "merchant":
					var owner_x = int(floor(float(global_tile_x) / 64.0))
					var owner_y = int(floor(float(global_tile_y) / 64.0))
					if owner_x == my_coord.x and owner_y == my_coord.y:
						is_owner = true
						# 尝试查找已配置的 merchant 场景或使用通用 NPC
						var merch_scene = "res://scenes/npc/merchant.tscn"
						entity_data = {
							"scene_path": merch_scene,
							"pos": Vector2(global_tile_x * TILE_SIZE + 8, (global_tile_y + 1) * TILE_SIZE - 2), # 稍微对齐到地面
							"data": {"npc_name": "Merchant", "role": "Merchant"}
						}
					processed_positions[Vector2i(x_idx, row_idx)] = true

				if is_owner:
					entities_out.append(entity_data)

	# --- 自动地基填充：防止房子悬空 ---
	for x_idx in range(house_width):
		# 检查设计图的最底层是否为实体（非空气）
		var bottom_char = design[house_height - 1][x_idx]
		if bottom_char == " ": continue
		
		var global_tile_x = my_coord.x * 64 + base_pos.x + x_idx
		var real_ground_index = _get_stable_ground_y(global_tile_x) # 地面其实是这个值-1，但这个值是首个实心块，正好对接
		var global_base_y = my_coord.y * 64 + base_pos.y
		
		# 如果房子底部 (BaseY) 高于 真实地面 (RealGroundY)，中间需要填充
		# 填充范围：(BaseY + 1) -> RealGroundIndex
		if real_ground_index > global_base_y:
			for f_y in range(global_base_y + 1, real_ground_index + 1):
				# 检查该高度是否在本 Chunk 范围内
				if f_y >= my_coord.y * 64 and f_y < (my_coord.y + 1) * 64:
					var g_x = global_tile_x
					
					# 检查 X 是否在本 Chunk 范围内
					if g_x >= my_coord.x * 64 and g_x < (my_coord.x + 1) * 64:
						var local_p = Vector2i(g_x - my_coord.x * 64, f_y - my_coord.y * 64)
						
						if not chunk_data.has(0): chunk_data[0] = {}
						if not chunk_data.has(1): chunk_data[1] = {}
						
						# 地基填充石块
						chunk_data[0][local_p] = {"source": s_id, "atlas": generator.stone_tile}
						# 必须填充背景，防止露出天空
						chunk_data[1][local_p] = {"source": s_id, "atlas": generator.dirt_tile}

func _apply_ruins(coord: Vector2i, chunk_data: Dictionary, hash_val: int) -> void:
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not generator: return
	
	# 情况 3: 埋没遗迹 (Layer 1)
	if coord.y > 6 and hash_val % 15 == 0:
		var rx = hash_val % 30 + 15
		var ry = hash_val % 30 + 15
		for ox in range(-5, 6):
			for oy in range(-4, 5):
				var p = Vector2i(rx + ox, ry + oy)
				if p.x >=0 and p.x < 64 and p.y >=0 and p.y < 64:
					if not chunk_data.has(1):
						chunk_data[1] = {}
					
					if abs(ox) == 5 or abs(oy) == 4:
						# 使用动态 Source ID (根据 WorldGenerator 设置)，确认为有效贴图且有碰撞
						chunk_data[1][p] = {"source": generator.tile_source_id, "atlas": generator.stone_tile}
					else:
						# 遗迹内部掏空
						chunk_data[1][p] = {"source": -1, "atlas": Vector2i(-1,-1)}

func _apply_trees(coord: Vector2i, cells: Dictionary, ground_y_list: Array) -> void:
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not generator: return
	
	# 树木目前只在地表层附近生成
	if coord.y < 3 or coord.y > 7: return
	
	# 使用专门的生成器以确保线程安全且确定性
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(str(generator.seed_value) + "_" + str(coord.x) + "_" + str(coord.y) + "_trees")
	
	for x in range(2, 62): # 留出边缘
		var gx = coord.x * 64 + x
		var ly = ground_y_list[x]
		if ly == -1 or ly < 5 or ly > 60: continue 
		
		# --- 垂直空间安全检测 ---
		# 检查树木上方是否有岩石或地形阻挡 (避免树冠插进天花板)
		var is_obstructed = false
		for check_y in range(1, 10):
			# 树冠宽 3 格 (x-1, x, x+1)，都要检查
			for offset_x in range(-1, 2):
				var check_pos = Vector2i(x + offset_x, ly - check_y)
				if cells.has(0) and cells[0].has(check_pos) and cells[0][check_pos]["source"] != -1:
					is_obstructed = true
					break
			if is_obstructed: break
		
		if is_obstructed: continue

		var gy = coord.y * 64 + ly
		
		if generator.should_spawn_tree_at(gx, gy):
			_generate_tree_at(cells, Vector2i(x, ly), rng)

func _generate_tree_at(cells: Dictionary, local_pos: Vector2i, rng: RandomNumberGenerator) -> void:
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not generator: return
	
	var tree_layer_idx = 10 # 地表树木层
	if not cells.has(tree_layer_idx): cells[tree_layer_idx] = {}
	
	var sid = generator.tree_source_id
	
	# 1. 树根 (3x1)
	var root_y = local_pos.y - 1
	var root_tiles = [generator.tree_root_left, generator.tree_root_mid, generator.tree_root_right]
	for dx in range(-1, 2):
		var p = Vector2i(local_pos.x + dx, root_y)
		cells[tree_layer_idx][p] = {"source": sid, "atlas": root_tiles[dx + 1]}
			
	# 2. 树干 (随机 3-5 节)
	var trunk_h = rng.randi_range(3, 5)
	# Explicitly check for wood tile at (1,2)
	var trunk_atlas = generator.tree_trunk_tile
	for i in range(1, trunk_h + 1):
		var p = Vector2i(local_pos.x, root_y - i)
		cells[tree_layer_idx][p] = {"source": sid, "atlas": trunk_atlas}
			
	# 3. 树冠 (3x3)
	var canopy_center_y = root_y - trunk_h - 1
	var canopy_tile = generator.tree_canopy_tile
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var p = Vector2i(local_pos.x + dx, canopy_center_y + dy)
			# Minimalist: Reuse single leaf tile for entire canopy
			cells[tree_layer_idx][p] = {"source": sid, "atlas": canopy_tile}

func _build_entity_spawn_key(ent: Dictionary) -> String:
	return "%s_%d_%d" % [ent.scene_path, int(round(ent.pos.x)), int(round(ent.pos.y))]

func _append_new_entities_to_chunk(chunk: WorldChunk, new_entities: Array) -> Array:
	if new_entities.is_empty():
		return []

	var seen_keys := {}
	for ent in chunk.entities:
		seen_keys[_build_entity_spawn_key(ent)] = true

	var accepted: Array = []
	for ent in new_entities:
		var key := _build_entity_spawn_key(ent)
		if seen_keys.has(key):
			continue
		seen_keys[key] = true
		accepted.append(ent)

	if not accepted.is_empty():
		chunk.entities.append_array(accepted)
	return accepted

func _finalize_chunk_load(coord: Vector2i, cells: Dictionary, new_entities: Array = [], force_immediate_refresh: bool = false, from_precomputed: bool = false) -> void:
	# 如果是异步任务触发的，清理队列。如果是强制同步加载的，可能不在队列中
	if _loading_queue.has(coord):
		_loading_queue.erase(coord)
	
	# 双重加载检查：如果此时已经有其他地方加载了该区块，直接返回
	if loaded_chunks.has(coord) or chunk_entity_containers.has(coord):
		return

	var chunk: WorldChunk
	var path = _get_save_path(coord)
	
	if world_delta_data.has(coord):
		chunk = world_delta_data[coord]
	elif FileAccess.file_exists(path):
		chunk = ResourceLoader.load(path)
		world_delta_data[coord] = chunk
	else:
		chunk = WorldChunk.new()
		chunk.coord = coord

	_append_new_entities_to_chunk(chunk, new_entities)
	
	loaded_chunks[coord] = chunk
	if from_precomputed:
		_loaded_from_precomputed[coord] = true
	else:
		_loaded_from_precomputed.erase(coord)
	if LiquidManager and LiquidManager.has_method("on_chunk_loaded"):
		LiquidManager.on_chunk_loaded(coord, chunk)
	
	var apply_stats := _apply_cells_to_layers(coord, cells, chunk, force_immediate_refresh)
	_chunk_generated_cells[coord] = _build_cells_presence_snapshot(cells)
	_record_stage_telemetry("tile_apply", coord, float(apply_stats.get("elapsed_ms", 0.0)), {
		"set_cell_count": int(apply_stats.get("set_cell_count", 0)),
		"force_refresh": force_immediate_refresh,
		"phase": "precomputed" if from_precomputed else "critical",
	})
	_spawn_chunk_entities(coord, chunk) 
	
	# 显式刷新 TileMapLayer 属性，背景层不应参与实体碰撞。
	var gen = get_tree().get_first_node_in_group("world_generator")
	if gen:
		if gen.layer_0: gen.layer_0.collision_enabled = true
		if gen.layer_1: gen.layer_1.collision_enabled = not bool(gen.layer_1.get_meta("background_only", false))
		if gen.layer_2: gen.layer_2.collision_enabled = not bool(gen.layer_2.get_meta("background_only", false))
	
	_spawn_chunk_particles(coord, cells) 
	
	# 关键路径不立即刷新小地图，避免新区块首次加载时的纹理更新尖峰。
	# 小地图在 enrichment 阶段补齐更新即可。
		
	chunk_loaded.emit(coord)

func _apply_chunk_enrichment(coord: Vector2i, cells: Dictionary, new_entities: Array) -> void:
	if not loaded_chunks.has(coord):
		return

	var chunk: WorldChunk = loaded_chunks[coord]
	var previous_cells: Dictionary = _chunk_generated_cells.get(coord, {})
	var apply_stats := _apply_cells_to_layers(coord, cells, chunk, false, previous_cells)
	_chunk_generated_cells[coord] = _build_cells_presence_snapshot(cells)
	_record_stage_telemetry("tile_apply", coord, float(apply_stats.get("elapsed_ms", 0.0)), {
		"set_cell_count": int(apply_stats.get("set_cell_count", 0)),
		"force_refresh": false,
		"phase": "enrichment",
	})

	var accepted_entities := _append_new_entities_to_chunk(chunk, new_entities)
	if not accepted_entities.is_empty():
		var container = chunk_entity_containers.get(coord)
		if not is_instance_valid(container):
			container = Node2D.new()
			container.name = "Entities_%d_%d" % [coord.x, coord.y]
			get_tree().current_scene.add_child(container)
			chunk_entity_containers[coord] = container

		for ent in accepted_entities:
			_enqueue_entity_spawn(container, ent, coord)

	if MinimapManager:
		MinimapManager.update_from_chunk(coord, cells, chunk)
	if LiquidManager and LiquidManager.has_method("ingest_generated_liquids"):
		LiquidManager.ingest_generated_liquids(coord, cells, chunk)

func _extract_critical_cells(cells: Dictionary) -> Dictionary:
	var critical := {0: {}, 1: {}, 2: {}}
	var layer0: Variant = cells.get(0, {})
	if layer0 is Dictionary:
		critical[0] = layer0.duplicate(true)
	return critical

## 强制同步加载指定位置的区块 (用于传送等紧急情况)
func force_load_at_world_pos(world_pos: Vector2) -> void:
	var coord = _clamp_chunk_coord_to_hard_floor(get_chunk_coord(world_pos))
	if loaded_chunks.has(coord): return
	
	print("InfiniteChunkManager: SYNC forcing load for chunk ", coord)
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not generator: return
	
	# 传送等紧急路径同样优先保证可行走核心层，次要补充放到下一帧。
	var critical_cells = generator.generate_chunk_cells(coord, true)
	# 传送/救援路径需要同帧可碰撞，保留强制图层内部刷新。
	_finalize_chunk_load(coord, critical_cells, [], true)
	_request_chunk_enrichment(coord)

## 寻找安全的地面位置 (用于防止掉入虚空)
## 返回有效的 Global Position (Vector2) 或 null (未找到)
func find_safe_ground(start_pos: Vector2, max_depth: float = 1200.0) -> Variant:
	# 1. 确保该区域已加载 (数据层)
	force_load_at_world_pos(start_pos)
	
	var generator = get_tree().get_first_node_in_group("world_generator")
	if not generator: return null
	
	# 这里假设 generator.layer_0 是主要的参照层
	var layer_0 = generator.layer_0
	if not layer_0: return null
	
	var map_pos = layer_0.local_to_map(start_pos)
	var hard_floor_global_y := _get_hard_floor_global_y()
	if hard_floor_global_y < 2147483647 and map_pos.y > hard_floor_global_y:
		map_pos.y = hard_floor_global_y - 1
	var max_y_offset = int(max_depth / float(TILE_SIZE))
	
	# 检查当前是否在墙里
	if _is_solid_at_map(generator, map_pos):
		# 如果卡在墙里，向上寻找空气
		for i in range(1, 20): # 向上找20格
			if not _is_solid_at_map(generator, map_pos + Vector2i(0, -i)):
				# 找到空气
				return layer_0.map_to_local(map_pos + Vector2i(0, -i))
		return start_pos # 放弃治疗，交给物理引擎挤出
		
	# 检查下方是否有地面 (防止虚空)
	for y_off in range(0, max_y_offset):
		var check_pos = map_pos + Vector2i(0, y_off)
		if _is_solid_at_map(generator, check_pos):
			# 找到地面！
			var ground_center = layer_0.map_to_local(check_pos)
			# 返回地面上方一格的位置 (防止脚嵌入地面)
			return ground_center + Vector2(0, -TILE_SIZE)
			
	return null # 下方全是虚空

func _is_solid_at_map(gen, coord: Vector2i) -> bool:
	if _is_physical_tile_present(gen.layer_0, coord): return true
	if _is_physical_tile_present(gen.layer_1, coord): return true
	if _is_physical_tile_present(gen.layer_2, coord): return true
	return false

func _is_physical_tile_present(layer: TileMapLayer, coord: Vector2i) -> bool:
	if not layer or not layer.collision_enabled:
		return false
	return layer.get_cell_source_id(coord) != -1

func _spawn_chunk_entities(coord: Vector2i, chunk: WorldChunk) -> void:
	if chunk.entities.is_empty(): return
	
	var container = Node2D.new()
	container.name = "Entities_%d_%d" % [coord.x, coord.y]
	get_tree().current_scene.add_child(container)
	chunk_entity_containers[coord] = container
	
	for entity_data in chunk.entities:
		_enqueue_entity_spawn(container, entity_data, coord)

func _enqueue_entity_spawn(parent: Node, data: Dictionary, coord: Vector2i) -> void:
	_entity_spawn_queue.append({
		"parent": parent,
		"data": data,
		"coord": coord,
	})

func _process_entity_spawn_budget() -> void:
	if _entity_spawn_queue.is_empty():
		return

	var stage_start := Time.get_ticks_usec()
	var spawned_count := 0
	while not _entity_spawn_queue.is_empty():
		var entry: Dictionary = _entity_spawn_queue.pop_front()
		var parent = entry.get("parent", null)
		if not is_instance_valid(parent):
			continue
		var data: Dictionary = entry.get("data", {})
		_instantiate_entity(parent, data)
		spawned_count += 1

		var elapsed_ms := float(Time.get_ticks_usec() - stage_start) / 1000.0
		if elapsed_ms >= ENTITY_SPAWN_BUDGET_MS:
			break

	if spawned_count > 0:
		var elapsed_ms := float(Time.get_ticks_usec() - stage_start) / 1000.0
		_record_stage_telemetry("entity_spawn", "batch", elapsed_ms, {
			"spawned_entities": spawned_count,
			"remaining": _entity_spawn_queue.size(),
		})

func _instantiate_entity(parent: Node, data: Dictionary) -> void:
	var path = data.scene_path
	# 简单修正路径（如果必要）
	if "workshop.tscn" in path and not "buildings/" in path:
		path = "res://scenes/world/buildings/workshop.tscn"
	if "ruins_stone.tscn" in path and not "buildings/" in path:
		path = "res://scenes/world/buildings/ruins_stone.tscn"
		
	var scene = load(path)
	if scene:
		var inst = scene.instantiate()
		parent.add_child(inst)
		inst.global_position = data.pos
		
		# 处理自定义数据
		if inst.has_method("load_custom_data"):
			inst.load_custom_data(data.get("data", {}))
			
		# 处理建筑内部的生成点 (ChestSpawn, NPCSpawn)
		_process_structure_spawns(inst, parent)

func _process_structure_spawns(structure: Node, container: Node) -> void:
	# 在建筑树中寻找 Marker2D
	for child in structure.get_children():
		if child is Marker2D:
			if "ChestSpawn" in child.name:
				_spawn_chest_at(child.global_position, container)
			elif "NPCSpawn" in child.name:
				_spawn_npc_at(child.global_position, container)

func _spawn_chest_at(pos: Vector2, parent: Node) -> void:
	var chest_path = "res://scenes/world/chest.tscn"
	var scene = load(chest_path)
	if scene:
		var chest = scene.instantiate()
		parent.add_child(chest)
		chest.global_position = pos

func _spawn_npc_at(pos: Vector2, parent: Node) -> void:
	# 获取 generator 以获取资源
	var generator = get_tree().get_first_node_in_group("world_generator")
	if generator and generator.npc_scene:
		# --- 数据层安全检测 (比物理检测更快更准) ---
		var tile_layer = get_tree().get_first_node_in_group("world_tiles")
		if tile_layer:
			# NPC 偏移修正：NPC 场景的原点并不是脚底，而是靠近头部，脚底大约在 Origin + 43px 处
			# 我们需要确保 脚底 (Feet) 不在墙里，且站在地上
			var npc_feet_offset = 43.0 
			
			# 将标记点的全局坐标转换为 TileMap 坐标
			# 我们关注的是 "脚底" 所在的瓦片
			var target_feet_pos_global = pos + Vector2(0, npc_feet_offset)
			var tile_pos = tile_layer.local_to_map(TransformHelper.safe_to_local(tile_layer, target_feet_pos_global))
			
			# 1. 如果脚底在实心瓦片里 -> 向上寻找空地 (卡墙修复)
			if tile_layer.get_cell_source_id(tile_pos) != -1:
				var found_air = false
				# 向上最多找 6 格 (约 96px)
				for y_up in range(1, 7):
					var check_tile = tile_pos - Vector2i(0, y_up)
					# 检查脚底是否为空 (Air) 且 头部空间也为空 (Air)
					# 假设 NPC 高 3 格 (48px)
					if tile_layer.get_cell_source_id(check_tile) == -1 and \
					   tile_layer.get_cell_source_id(check_tile - Vector2i(0, 1)) == -1 and \
					   tile_layer.get_cell_source_id(check_tile - Vector2i(0, 2)) == -1:
						
						# 找到了！新的脚底 Tile 是 coords check_tile
						# 但此时 check_tile 是空气，NPC 会掉下去？
						# 我们希望脚底踩在实心块上。
						# 刚才循环是 "如果脚底是实心，往上找"。
						# 所以我们应该找：上方是空气，下方是实心 的分界线。
						pass
				
				# 简单策略：直接从当前卡住的位置向上遍历，直到找到 "脚底是空气" 的点
				# 然后回退一格，或者就在那里 (如地面)
				for y_up in range(1, 10):
					var current_feet_tile = tile_pos - Vector2i(0, y_up)
					if tile_layer.get_cell_source_id(current_feet_tile) == -1:
						# 脚底出来了！
						# 修正 Pos: 新的 Origin = Feet_Global - Offset
						var new_feet_global = tile_layer.to_global(tile_layer.map_to_local(current_feet_tile))
						# map_to_local 返回中心点。如果 feet 是底部，因该 +8? No, usually center is fine for snap.
						# 对齐只要不穿模即可。
						pos = new_feet_global - Vector2(0, npc_feet_offset)
						found_air = true
						break
				
				if not found_air:
					print("InfiniteChunkManager: NPC 深埋无法解脱，取消: ", pos)
					return
			
			# 2. 如果脚底是悬空的 -> 向下寻找地面 (悬空修复)
			# (防止 Marker 放太高)
			elif tile_layer.get_cell_source_id(tile_pos) == -1:
				for y_down in range(1, 10):
					var check_tile = tile_pos + Vector2i(0, y_down)
					if tile_layer.get_cell_source_id(check_tile) != -1:
						# 找到地面了！地面在 check_tile
						# 脚底应该在 check_tile 的上方 -> check_tile - (0,1)
						var valid_feet_tile = check_tile - Vector2i(0, 1)
						var new_feet_global = tile_layer.to_global(tile_layer.map_to_local(valid_feet_tile))
						# 微调：贴合地面通常需要 +8 (半个Tile) ?
						# map_to_local 是中心。为了站在 tile 上，脚底应该在 tile top?
						# Tile Top = Center - 8.
						pos = new_feet_global + Vector2(0, 8) - Vector2(0, npc_feet_offset)
						break

		var npc = generator.npc_scene.instantiate()
		parent.add_child(npc)
		npc.global_position = pos
		if npc.has_method("load_custom_data"):
			npc.load_custom_data({"role": "Villager", "alignment": "Friendly"})

## 注册新实体到无限地图系统
func register_placed_entity(world_pos: Vector2, scene_path: String, custom_data: Dictionary = {}) -> void:
	var c_coord = get_chunk_coord(world_pos)
	
	# 确保数据加载
	if not world_delta_data.has(c_coord):
		var path = _get_save_path(c_coord)
		if FileAccess.file_exists(path):
			world_delta_data[c_coord] = ResourceLoader.load(path)
		else:
			world_delta_data[c_coord] = WorldChunk.new()
			world_delta_data[c_coord].coord = c_coord
			
	var entity_info = {
		"scene_path": scene_path,
		"pos": world_pos,
		"data": custom_data
	}
	world_delta_data[c_coord].entities.append(entity_info)
	_mark_chunk_dirty(c_coord)
	
	# 如果当前区块已加载，立即实例化（通过容器）
	if chunk_entity_containers.has(c_coord):
		_enqueue_entity_spawn(chunk_entity_containers[c_coord], entity_info, c_coord)

func _collect_render_layer_map() -> Dictionary:
	var generator = get_tree().get_first_node_in_group("world_generator")
	return {
		0: get_tree().get_first_node_in_group("world_tiles"),
		1: LayerManager.get_layer(1) if LayerManager else null,
		2: LayerManager.get_layer(2) if LayerManager else null,
		10: generator.tree_layer_0 if generator else null,
		11: generator.tree_layer_1 if generator else null,
		12: generator.tree_layer_2 if generator else null,
	}

func _clear_chunk_region(coord: Vector2i, chunk: WorldChunk = null) -> void:
	var origin = coord * CHUNK_SIZE
	var layer_map := _collect_render_layer_map()
	var cleared_count := 0

	# 优先按已生成快照增量清理，避免每次卸载都整块 64x64 全刷空。
	var generated_snapshot: Dictionary = _chunk_generated_cells.get(coord, {})
	for layer_idx in generated_snapshot.keys():
		if not (layer_idx is int):
			continue
		var layer = layer_map.get(layer_idx, null)
		if not layer:
			continue
		var local_positions = generated_snapshot.get(layer_idx, [])
		if not (local_positions is Array):
			continue
		for local_pos in local_positions:
			if not (local_pos is Vector2i):
				continue
			layer.set_cell(origin + local_pos, -1)
			cleared_count += 1

	# 同步清理玩家 Delta 触达过的位置，避免残留。
	if chunk != null:
		for layer_idx in [0, 1, 2]:
			var layer = layer_map.get(layer_idx, null)
			if not layer:
				continue
			var chunk_deltas = chunk.deltas.get(layer_idx, {})
			if not (chunk_deltas is Dictionary):
				continue
			for key in chunk_deltas.keys():
				var local_pos = _parse_delta_local_pos_key(key)
				if not (local_pos is Vector2i):
					continue
				layer.set_cell(origin + local_pos, -1)
				cleared_count += 1

	if cleared_count > 0:
		return

	# 兜底：若无快照（例如旧会话残留），回退到全量清理。
	for layer in layer_map.values():
		if not layer:
			continue
		for x in range(CHUNK_SIZE):
			for y in range(CHUNK_SIZE):
				layer.set_cell(origin + Vector2i(x, y), -1)

func _clear_loaded_world_visuals() -> void:
	for coord in loaded_chunks.keys():
		var chunk: WorldChunk = loaded_chunks.get(coord, null)
		_clear_chunk_region(coord, chunk)

## 在 Tile 被破坏时生成大量碎片粒子
func spawn_impact_particles(world_pos: Vector2, color: Color) -> void:
	var particles = CPUParticles2D.new()
	get_tree().current_scene.add_child(particles)
	particles.global_position = world_pos
	
	particles.amount = 30
	particles.lifetime = 0.6
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.gravity = Vector2(0, 800)
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 150.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 3.0
	particles.color = color
	
	particles.emitting = true
	particles.one_shot = true
	# 自动销毁容器
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)

func _spawn_chunk_particles(_coord: Vector2i, _cells: Dictionary) -> void:
	# 此处可扩展新区块加载时的烟雾或微尘效果
	pass

func _load_chunk(_coord: Vector2i) -> void:
	# 弃用同步加载版本
	pass

func _apply_cells_to_layers(chunk_coord: Vector2i, cells: Dictionary, chunk: WorldChunk, force_immediate_refresh: bool = false, previous_cells: Dictionary = {}) -> Dictionary:
	var stage_start := Time.get_ticks_usec()
	var set_cell_count := 0
	var generator = get_tree().get_first_node_in_group("world_generator")
	
	# 改良的图层获取逻辑：如果 LayerManager 尚未就绪，直接从 WorldGenerator 获取引用
	var l1 = LayerManager.get_layer(1) if LayerManager else null
	if not l1 and generator and "layer_1" in generator: l1 = generator.layer_1
	
	var l2 = LayerManager.get_layer(2) if LayerManager else null
	if not l2 and generator and "layer_2" in generator: l2 = generator.layer_2
	
	var l0 = get_tree().get_first_node_in_group("world_tiles")
	if not l0 and generator and "layer_0" in generator: l0 = generator.layer_0

	var layers = {
		0: l0, 
		1: l1,
		2: l2,
		10: generator.tree_layer_0 if generator else null,
		11: generator.tree_layer_1 if generator else null,
		12: generator.tree_layer_2 if generator else null
	}
	
	var origin = chunk_coord * CHUNK_SIZE
	
	# 修改：不仅遍历 cells.keys()，还要确保遍历所有可能的逻辑图层，以便应用玩家 Delta
	var all_relevant_layers = cells.keys()
	for prev_idx in previous_cells.keys():
		if prev_idx is int and not prev_idx in all_relevant_layers:
			all_relevant_layers.append(prev_idx)
	for l_idx in [0, 1, 2]: # 核心物理/背景层
		if not l_idx in all_relevant_layers:
			all_relevant_layers.append(l_idx)
	
	for layer_idx in all_relevant_layers:
		# 严格过滤：仅处理整数图层索引，忽略元数据 (如 _coord)
		if not layer_idx is int: continue
		
		var layer = layers.get(layer_idx)
		if not layer: continue
		
		# 获取该层原始数据，并确保其为字典
		var layer_cells = cells.get(layer_idx, {})
		if not (layer_cells is Dictionary):
			layer_cells = {}
		
		# 我们需要处理该层中所有可能的位置：包括生成的和 Delta 记录的
		# 首先处理 Delta（玩家修改）
		var chunk_deltas = chunk.deltas.get(layer_idx, {})
		if not (chunk_deltas is Dictionary): chunk_deltas = {}
		
		# 1. 应用生成的瓦片 (如果没有 Delta 覆盖)
		for local_pos in layer_cells:
			var key = str(local_pos.x) + "," + str(local_pos.y)
			if chunk_deltas.has(key): continue # 跳过，由 Delta 处理
			
			var data = layer_cells[local_pos]
			if not (data is Dictionary): continue
			
			var map_pos = origin + local_pos
			layer.set_cell(map_pos, data.get("source", -1), data.get("atlas", Vector2i(-1, -1)))
			set_cell_count += 1
			
		# 2. 应用玩家修改 (Delta)
		for key in chunk_deltas:
			var local_pos = _parse_delta_local_pos_key(key)
			if not (local_pos is Vector2i):
				continue
			
			var map_pos = origin + local_pos
			var delta = chunk_deltas[key]
			if not (delta is Dictionary): continue
			
			if delta.get("source", -1) == -1:
				layer.set_cell(map_pos, -1)
			else:
				layer.set_cell(map_pos, delta.get("source", -1), delta.get("atlas", Vector2i(-1, -1)))
			set_cell_count += 1

		# 3. 清理上一版存在、当前生成已移除、且没有玩家 Delta 覆盖的瓦片。
		var prev_layer_cells = previous_cells.get(layer_idx, [])
		if prev_layer_cells is Array:
			for prev_local_pos in prev_layer_cells:
				if not (prev_local_pos is Vector2i):
					continue
				if layer_cells.has(prev_local_pos):
					continue

				var prev_key = str(prev_local_pos.x) + "," + str(prev_local_pos.y)
				if chunk_deltas.has(prev_key):
					continue

				var prev_map_pos = origin + prev_local_pos
				layer.set_cell(prev_map_pos, -1)
				set_cell_count += 1
	
	# 仅在强同步路径下强制刷新，避免普通流式加载时每块都触发昂贵的内部重建导致卡顿。
	if force_immediate_refresh:
		for layer_idx in layers:
			var layer = layers[layer_idx]
			if layer is TileMapLayer:
				layer.update_internals() # 触发 Godot 内部重绘与物理刷新

	return {
		"set_cell_count": set_cell_count,
		"elapsed_ms": float(Time.get_ticks_usec() - stage_start) / 1000.0,
	}

func _unload_chunk(coord: Vector2i) -> void:
	coord = _canonical_chunk_coord(coord)
	_enrichment_queue.erase(coord)
	_pending_enrichment_requests.erase(coord)
	_loading_queue.erase(coord)
	_pending_chunk_requests.erase(coord)
	_precomputed_enrichment_cells.erase(coord)

	# 1. 如果有修改，保存到磁盘并释放内存
	if world_delta_data.has(coord):
		var chunk = world_delta_data[coord]
		var has_changes := _chunk_has_persistable_changes(chunk)

		if has_changes:
			_mark_chunk_dirty(coord)
			_request_dirty_flush(coord)
		else:
			world_delta_data.erase(coord)

	# 1.5 清理实体容器
	if chunk_entity_containers.has(coord):
		var container = chunk_entity_containers[coord]
		if is_instance_valid(container):
			container.queue_free()
		chunk_entity_containers.erase(coord)

	# 2. 清除 TileMapLayer 上的对应区域以释放渲染资源
	var loaded_chunk: WorldChunk = loaded_chunks.get(coord, null)
	if LiquidManager and LiquidManager.has_method("on_chunk_unloaded"):
		LiquidManager.on_chunk_unloaded(coord, loaded_chunk)
	_clear_chunk_region(coord, loaded_chunk)

	# 1.8 从已加载列表移除
	loaded_chunks.erase(coord)
	_chunk_generated_cells.erase(coord)
	_loaded_from_precomputed.erase(coord)
				
	chunk_unloaded.emit(coord)
