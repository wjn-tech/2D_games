extends Node

class LiquidOverlay:
	extends Node2D

	const STREAM_LINK_EPSILON := 0.002
	const WATER_STREAM_SHEET_MAX_AMOUNT := 0.24

	var cells: Dictionary = {}
	var packets: Array = []
	var tile_size_px: float = 16.0

	func configure(p_tile_size_px: float) -> void:
		tile_size_px = maxf(1.0, p_tile_size_px)

	func set_frame_data(next_cells: Dictionary, next_packets: Array) -> void:
		cells = next_cells.duplicate(true)
		packets = next_packets.duplicate(true)
		queue_redraw()

	func _bottom_anchored_fill_metrics(amount: float) -> Dictionary:
		var clamped_amount := clampf(amount, 0.0, 1.0)
		var fill_h := maxf(1.0, floorf(clamped_amount * tile_size_px))
		fill_h = minf(fill_h, tile_size_px)
		var y_offset := tile_size_px - fill_h
		assert(y_offset >= -0.001 and y_offset <= tile_size_px + 0.001)
		return {
			"fill_h": fill_h,
			"y_offset": y_offset,
		}

	func debug_bottom_anchor_metrics(amount: float) -> Dictionary:
		return _bottom_anchored_fill_metrics(amount)

	func _draw() -> void:
		for world_pos_variant in cells.keys():
			if not (world_pos_variant is Vector2i):
				continue
			var world_pos: Vector2i = world_pos_variant
			var entry_variant = cells.get(world_pos_variant, null)
			if not (entry_variant is Dictionary):
				continue
			var entry: Dictionary = entry_variant
			var amount := clampf(float(entry.get("amount", 0.0)), 0.0, 1.0)
			if amount <= 0.0:
				continue

			var liquid_type := String(entry.get("type", "water"))
			var fill_metrics := _bottom_anchored_fill_metrics(amount)
			var fill_h := float(fill_metrics.get("fill_h", 1.0))
			var px := float(world_pos.x) * tile_size_px
			var cell_top := float(world_pos.y) * tile_size_px
			var py := cell_top + float(fill_metrics.get("y_offset", 0.0))
			var cell_bottom := float(world_pos.y + 1) * tile_size_px
			assert(absf((py + fill_h) - cell_bottom) <= 0.001)

			var body_color := Color(0.18, 0.56, 0.72, 0.78)
			var edge_color := Color(0.62, 0.86, 0.98, 0.92)
			if liquid_type == "lava":
				body_color = Color(0.88, 0.34, 0.10, 0.82)
				edge_color = Color(1.0, 0.72, 0.35, 0.92)

			var above_entry_variant = cells.get(world_pos + Vector2i(0, -1), null)
			var has_same_liquid_above := false
			if above_entry_variant is Dictionary:
				var above_entry: Dictionary = above_entry_variant
				has_same_liquid_above = String(above_entry.get("type", "")) == liquid_type and float(above_entry.get("amount", 0.0)) > STREAM_LINK_EPSILON
			var below_entry_variant = cells.get(world_pos + Vector2i(0, 1), null)
			var has_same_liquid_below := false
			if below_entry_variant is Dictionary:
				var below_entry: Dictionary = below_entry_variant
				has_same_liquid_below = String(below_entry.get("type", "")) == liquid_type and float(below_entry.get("amount", 0.0)) > STREAM_LINK_EPSILON

			var is_vertical_water_stream := liquid_type == "water" and amount <= WATER_STREAM_SHEET_MAX_AMOUNT and (has_same_liquid_above or has_same_liquid_below)
			var draw_color := body_color
			if is_vertical_water_stream:
				draw_color = Color(body_color.r, body_color.g, body_color.b, minf(0.90, body_color.a + 0.10))
			draw_rect(Rect2(px, py, tile_size_px, fill_h), draw_color, true)
			if not is_vertical_water_stream and fill_h < tile_size_px and not has_same_liquid_above:
				draw_line(Vector2(px, py), Vector2(px + tile_size_px, py), edge_color, 1.0)

		var now_ms := Time.get_ticks_msec()
		for packet_variant in packets:
			if not (packet_variant is Dictionary):
				continue
			var packet: Dictionary = packet_variant
			var from_pos_variant = packet.get("from", null)
			var to_pos_variant = packet.get("to", null)
			if not (from_pos_variant is Vector2i) or not (to_pos_variant is Vector2i):
				continue
			var from_pos: Vector2i = from_pos_variant
			var to_pos: Vector2i = to_pos_variant
			var amount := clampf(float(packet.get("amount", 0.0)), 0.0, 1.0)
			if amount <= 0.0:
				continue
			var start_ms := int(packet.get("start_ms", now_ms))
			var duration_ms := maxi(1, int(packet.get("duration_ms", 1)))
			var t := clampf(float(now_ms - start_ms) / float(duration_ms), 0.0, 1.0)

			var drop_h := maxf(1.0, floorf(amount * tile_size_px))
			drop_h = minf(drop_h, tile_size_px * 0.6)
			var px := (lerpf(float(from_pos.x), float(to_pos.x), t) * tile_size_px) + tile_size_px * 0.25
			var py := (lerpf(float(from_pos.y), float(to_pos.y), t) * tile_size_px) + tile_size_px * 0.2

			var liquid_type := String(packet.get("type", "water"))
			var drop_color := Color(0.38, 0.74, 0.92, 0.9)
			if liquid_type == "lava":
				drop_color = Color(1.0, 0.58, 0.24, 0.9)

			draw_rect(Rect2(px, py, tile_size_px * 0.5, drop_h), drop_color, true)

const CHUNK_SIZE := 64
const LIQUID_RUNTIME_LAYER_RENDER_Z := 110
const LIQUID_OVERLAY_RENDER_Z := 120
const MAX_ACTIVE_STEPS_PER_FRAME := 88
const SIMULATION_BUDGET_MS := 1.10
const LIQUID_EPSILON := -0.01
const CELL_CLEAR_EPSILON := 0.002
const RENDER_EPSILON := 0.06
const SOURCE_SUPPORT_MIN := 0.42
const SIDE_SUPPORT_MIN := 0.42
const MAX_DOWN_FLOW_PER_STEP := 0.05
const MAX_SIDE_FLOW_PER_STEP := 0.10
const DOWN_FLOW_QUANTUM := 0.03125
const SIDE_FLOW_QUANTUM := 0.015625
const WATER_LATERAL_SPLIT_GAIN := 1.01
const WATER_FALL_DELAY_MS := 20
const LAVA_FALL_DELAY_MS := 34
const WATER_FALL_TRAVEL_MS := 24
const LAVA_FALL_TRAVEL_MS := 40
const WATER_OPEN_FALL_STICK_MS := 120
const WATER_OPEN_FALL_MIN_AMOUNT := 0.02
const WATER_OPEN_FALL_THIN_FILM_EPS := 0.05
const WATER_OPEN_FALL_DOWN_MIN := 0.0625
const WATER_OPEN_FALL_DOWN_MAX := 0.12
const WATER_OPEN_FALL_COOLDOWN_MAX_MS := 12
const WATER_OPEN_FALL_LATERAL_DAMP := 0.35
const DOWNWARD_MICRO_TRICKLE_MAX := 0.015625
const DOWNSTREAM_WAIT_RETRY_MS := 20
const COOLDOWN_READY_SCAN_BUDGET := 256
const COOLDOWN_READY_ENQUEUE_BUDGET := 96
const RENDER_LEVEL_HIGH := 0.78
const RENDER_LEVEL_MID := 0.42
const LATERAL_DIRECTION_MEMORY_MS := 180
const LATERAL_DIRECTION_NEAR_EQUAL_EPS := 0.08
const LATERAL_DIRECTION_PRIORITY_EPS := 0.04
const CHUNK_INITIAL_SETTLE_PASSES := 10
const CHUNK_INITIAL_SETTLE_CELL_BUDGET := 1024
const CHUNK_LOAD_QUICK_SETTLE_PASSES := 6

const LIQUID_TYPE_WATER := "water"
const LIQUID_TYPE_LAVA := "lava"

var _liquid_families: Dictionary = {}
var _chunk_liquids: Dictionary = {}
var _rendered_chunk_cells: Dictionary = {}

var _active_queue: Array = []
var _active_set: Dictionary = {}
var _quick_settle_budget: int = 0
var _settle_chunk_cursor: int = 0
var _digging_connected: bool = false
var _runtime_liquid_layer: TileMapLayer = null
var _runtime_liquid_overlay: LiquidOverlay = null
var _overlay_cells: Dictionary = {}
var _fall_next_ms: Dictionary = {}
var _fall_packets: Array = []
var _fall_inflight_from: Dictionary = {}
var _cooldown_scan_cursor: int = 0
var _lateral_direction_bias: Dictionary = {}
var _lateral_direction_until_ms: Dictionary = {}
var _open_fall_mode_until_ms: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_register_builtin_families()
	_connect_runtime_signals()

func _process(_delta: float) -> void:
	_connect_runtime_signals()
	var frame_start := Time.get_ticks_usec()
	var steps := 0
	var changed_chunks: Dictionary = {}
	var overlay_dirty := _update_fall_packets(changed_chunks)
	_enqueue_cooldown_ready_cells(COOLDOWN_READY_SCAN_BUDGET, COOLDOWN_READY_ENQUEUE_BUDGET)

	while steps < MAX_ACTIVE_STEPS_PER_FRAME and not _active_queue.is_empty():
		var elapsed_ms := float(Time.get_ticks_usec() - frame_start) / 1000.0
		if elapsed_ms >= SIMULATION_BUDGET_MS:
			break

		var world_key: String = _active_queue.pop_front()
		_active_set.erase(world_key)
		var world_pos_variant = _parse_world_key(world_key)
		if not (world_pos_variant is Vector2i):
			continue
		var world_pos: Vector2i = world_pos_variant
		if _simulate_active_cell(world_pos, changed_chunks):
			steps += 1

	if _active_queue.is_empty() and _quick_settle_budget > 0:
		_seed_settle_wave(MAX_ACTIVE_STEPS_PER_FRAME)
		_quick_settle_budget -= 1

	if not changed_chunks.is_empty():
		for coord in changed_chunks.keys():
			if coord is Vector2i:
				_sync_chunk_render(coord)
	elif overlay_dirty:
		_refresh_overlay()

func _connect_runtime_signals() -> void:
	if _digging_connected:
		return
	var digging_mgr = get_tree().get_first_node_in_group("digging_manager")
	if digging_mgr and digging_mgr.has_signal("tile_mined"):
		digging_mgr.tile_mined.connect(_on_tile_mined)
		_digging_connected = true

func _on_tile_mined(coords: Vector2i, _tile_data: Dictionary) -> void:
	notify_world_cell_changed(coords)
	# Avoid instant post-mine snap; let gravity ticks produce visible dripping.
	_request_quick_settle(0)

func register_liquid_family(type_id: String, definition: Dictionary) -> void:
	if type_id == "":
		return
	var normalized := definition.duplicate(true)
	normalized["id"] = type_id
	_liquid_families[type_id] = normalized

func has_liquid_family(type_id: String) -> bool:
	return _liquid_families.has(type_id)

func get_registered_liquid_families() -> Array:
	return _liquid_families.keys()

func get_debug_metrics() -> Dictionary:
	var total_cells := 0
	var active_chunks := 0
	for coord in _chunk_liquids.keys():
		var cells = _chunk_liquids.get(coord, {})
		if cells is Dictionary:
			total_cells += cells.size()
			if not cells.is_empty():
				active_chunks += 1
	return {
		"active_chunks": active_chunks,
		"active_cells": total_cells,
		"queued_cells": _active_queue.size(),
		"cooldown_cells": _fall_next_ms.size(),
		"quick_settle_budget": _quick_settle_budget,
		"registered_families": get_registered_liquid_families(),
	}

func get_liquid_cell_entry(world_pos: Vector2i) -> Dictionary:
	var entry_variant = _get_cell_entry(world_pos)
	if not (entry_variant is Dictionary):
		return {}
	var entry: Dictionary = entry_variant
	var amount := clampf(float(entry.get("amount", 0.0)), 0.0, 1.0)
	if amount <= LIQUID_EPSILON:
		return {}
	return {
		"type": String(entry.get("type", LIQUID_TYPE_WATER)),
		"amount": amount,
		"world_pos": world_pos,
	}

func get_liquid_amount_at_world_cell(world_pos: Vector2i, liquid_type: String = "") -> float:
	var entry := get_liquid_cell_entry(world_pos)
	if entry.is_empty():
		return 0.0
	if liquid_type != "" and String(entry.get("type", "")) != liquid_type:
		return 0.0
	return clampf(float(entry.get("amount", 0.0)), 0.0, 1.0)

func get_liquid_contact_at_global_position(global_pos: Vector2) -> Dictionary:
	var world_pos_variant = _global_to_world_cell(global_pos)
	if not (world_pos_variant is Vector2i):
		return {
			"in_liquid": false,
			"type": "",
			"amount": 0.0,
			"world_pos": Vector2i.ZERO,
		}

	var world_pos: Vector2i = world_pos_variant
	var entry := get_liquid_cell_entry(world_pos)
	if entry.is_empty():
		return {
			"in_liquid": false,
			"type": "",
			"amount": 0.0,
			"world_pos": world_pos,
		}

	return {
		"in_liquid": true,
		"type": String(entry.get("type", "")),
		"amount": float(entry.get("amount", 0.0)),
		"world_pos": world_pos,
	}

func clear_runtime_state() -> void:
	_clear_all_rendered_chunks()
	_chunk_liquids.clear()
	_rendered_chunk_cells.clear()
	_overlay_cells.clear()
	_refresh_overlay()
	_fall_next_ms.clear()
	_fall_packets.clear()
	_fall_inflight_from.clear()
	_cooldown_scan_cursor = 0
	_lateral_direction_bias.clear()
	_lateral_direction_until_ms.clear()
	_open_fall_mode_until_ms.clear()
	_active_queue.clear()
	_active_set.clear()
	_quick_settle_budget = 0
	_settle_chunk_cursor = 0

func on_chunk_loaded(coord: Vector2i, chunk: Resource) -> void:
	var canonical := _canonical_chunk_coord(coord)
	var chunk_cells: Dictionary = {}
	var has_persisted_liquid_state := false
	if chunk != null and "liquid_cells" in chunk:
		var saved_cells = chunk.get("liquid_cells")
		if saved_cells is Dictionary:
			chunk_cells = saved_cells.duplicate(true)
		if "liquid_state_initialized" in chunk:
			has_persisted_liquid_state = bool(chunk.get("liquid_state_initialized"))
		elif saved_cells is Dictionary and not saved_cells.is_empty():
			# Legacy saves without liquid_state_initialized still carry valid liquid data.
			has_persisted_liquid_state = true
			chunk.set("liquid_state_initialized", true)

	_chunk_liquids[canonical] = chunk_cells
	if has_persisted_liquid_state and chunk != null and "liquid_state_initialized" in chunk:
		chunk.set("liquid_state_initialized", true)
	if not chunk_cells.is_empty():
		_enqueue_chunk_cells(canonical)
		_request_quick_settle(CHUNK_LOAD_QUICK_SETTLE_PASSES)
	_sync_chunk_render(canonical)

func ingest_generated_liquids(coord: Vector2i, cells: Dictionary, chunk: Resource) -> void:
	var seeds = cells.get("_liquid_seeds", [])
	if not (seeds is Array) or seeds.is_empty():
		return

	var canonical := _canonical_chunk_coord(coord)

	# If the chunk resource already contains persisted liquid cells, prefer those
	# to avoid re-seeding/regenerating liquids on load.
	if chunk != null and "liquid_cells" in chunk:
		var has_persisted_liquid_state := false
		if "liquid_state_initialized" in chunk:
			has_persisted_liquid_state = bool(chunk.get("liquid_state_initialized"))
		var persisted = chunk.get("liquid_cells")
		if persisted is Dictionary and has_persisted_liquid_state:
			_chunk_liquids[canonical] = persisted.duplicate(true)
			if not persisted.is_empty():
				_enqueue_chunk_cells(canonical)
				_request_quick_settle(CHUNK_LOAD_QUICK_SETTLE_PASSES)
			_sync_chunk_render(canonical)
			return

	var chunk_cells: Dictionary = _chunk_liquids.get(canonical, {}).duplicate(true)

	for seed_entry in seeds:
		if not (seed_entry is Dictionary):
			continue
		var local_pos = seed_entry.get("local_pos", null)
		if not (local_pos is Vector2i):
			continue
		if not _is_local_pos_valid(local_pos):
			continue

		var liquid_type := String(seed_entry.get("type", LIQUID_TYPE_WATER))
		if not _liquid_families.has(liquid_type):
			continue

		var amount := clampf(float(seed_entry.get("amount", 1.0)), 0.05, 1.0)
		chunk_cells[_local_key(local_pos)] = {
			"type": liquid_type,
			"amount": amount,
		}

	if chunk_cells.is_empty():
		return

	_chunk_liquids[canonical] = chunk_cells
	if chunk != null and "liquid_cells" in chunk:
		chunk.set("liquid_cells", chunk_cells.duplicate(true))
		if "liquid_state_initialized" in chunk:
			chunk.set("liquid_state_initialized", true)
	_enqueue_chunk_cells(canonical)
	_settle_chunks_immediately([canonical], CHUNK_INITIAL_SETTLE_PASSES, CHUNK_INITIAL_SETTLE_CELL_BUDGET)
	_request_quick_settle(CHUNK_LOAD_QUICK_SETTLE_PASSES)
	_sync_chunk_render(canonical)

func on_chunk_unloaded(coord: Vector2i, chunk: Resource) -> void:
	var canonical := _canonical_chunk_coord(coord)
	if not _chunk_liquids.has(canonical):
		return

	var chunk_cells = _chunk_liquids.get(canonical, {})
	if chunk != null and "liquid_cells" in chunk and chunk_cells is Dictionary:
		chunk.set("liquid_cells", chunk_cells.duplicate(true))
		if "liquid_state_initialized" in chunk:
			chunk.set("liquid_state_initialized", true)
	_clear_rendered_chunk(canonical)

	_chunk_liquids.erase(canonical)
	_prune_active_for_chunk(canonical)

func notify_world_cell_changed(world_pos: Vector2i) -> void:
	_wake_neighborhood(world_pos)

func _request_quick_settle(pass_count: int) -> void:
	if pass_count <= 0:
		return
	_quick_settle_budget = maxi(_quick_settle_budget, pass_count)

func _enqueue_cooldown_ready_cells(scan_budget: int, enqueue_budget: int) -> void:
	if scan_budget <= 0 or enqueue_budget <= 0:
		return
	if _fall_next_ms.is_empty():
		_cooldown_scan_cursor = 0
		return

	var keys: Array = _fall_next_ms.keys()
	var total := keys.size()
	if total <= 0:
		_cooldown_scan_cursor = 0
		return
	if _cooldown_scan_cursor >= total:
		_cooldown_scan_cursor = 0

	var now_ms := Time.get_ticks_msec()
	var scanned := 0
	var enqueued := 0
	var ready_keys: Array[String] = []
	while scanned < scan_budget and scanned < total and enqueued < enqueue_budget:
		var idx := (_cooldown_scan_cursor + scanned) % total
		var world_key_variant = keys[idx]
		scanned += 1
		if not (world_key_variant is String):
			continue
		var world_key: String = world_key_variant
		if now_ms < int(_fall_next_ms.get(world_key, 0)):
			continue
		ready_keys.append(world_key)
		enqueued += 1

	_cooldown_scan_cursor = (_cooldown_scan_cursor + scanned) % maxi(1, total)
	for world_key in ready_keys:
		_fall_next_ms.erase(world_key)
		var world_pos_variant = _parse_world_key(world_key)
		if world_pos_variant is Vector2i:
			_enqueue_active(world_pos_variant)

func _quantize_transfer(flow: float, available: float, quantum: float) -> float:
	var q := maxf(quantum, LIQUID_EPSILON)
	var capped := minf(flow, available)
	if capped < q:
		return 0.0
	var steps := floorf(capped / q)
	return steps * q

func _apply_water_lateral_split_gain(liquid_type: String, transfer: float, source_available: float, target_capacity: float) -> float:
	if liquid_type != LIQUID_TYPE_WATER or transfer <= LIQUID_EPSILON:
		return transfer
	var max_transfer := minf(source_available, target_capacity)
	if max_transfer <= LIQUID_EPSILON:
		return transfer
	return minf(max_transfer, transfer * WATER_LATERAL_SPLIT_GAIN)

func _fall_delay_ms_for(liquid_type: String) -> int:
	if liquid_type == LIQUID_TYPE_LAVA:
		return LAVA_FALL_DELAY_MS
	return WATER_FALL_DELAY_MS

func _can_fall_now(world_pos: Vector2i) -> bool:
	var key := _world_key(world_pos)
	if not _fall_next_ms.has(key):
		return true
	var now_ms := Time.get_ticks_msec()
	var next_ms := int(_fall_next_ms.get(key, 0))
	return now_ms >= next_ms

func _adaptive_fall_delay_ms(liquid_type: String, moved_amount: float, head_diff: float, is_open_fall: bool = false) -> int:
	var base_delay := _fall_delay_ms_for(liquid_type)
	var move_ratio := clampf(moved_amount / maxf(MAX_DOWN_FLOW_PER_STEP, LIQUID_EPSILON), 0.0, 1.0)
	var head_ratio := clampf(head_diff, 0.0, 1.0)
	var delay_scale := lerpf(1.25, 0.62, move_ratio)
	delay_scale = lerpf(delay_scale, delay_scale * 0.82, head_ratio)
	var delay_ms := maxi(4, int(round(float(base_delay) * delay_scale)))
	if is_open_fall and liquid_type == LIQUID_TYPE_WATER:
		delay_ms = mini(delay_ms, WATER_OPEN_FALL_COOLDOWN_MAX_MS)
	return delay_ms

func _arm_fall_cooldown(world_pos: Vector2i, liquid_type: String, moved_amount: float = DOWN_FLOW_QUANTUM, head_diff: float = 0.0, is_open_fall: bool = false) -> void:
	var delay_ms := _adaptive_fall_delay_ms(liquid_type, moved_amount, head_diff, is_open_fall)
	if delay_ms <= 0:
		return
	_fall_next_ms[_world_key(world_pos)] = Time.get_ticks_msec() + delay_ms

func _schedule_delayed_retry(world_pos: Vector2i, delay_ms: int) -> void:
	if delay_ms <= 0:
		_enqueue_active(world_pos)
		return
	var key := _world_key(world_pos)
	if _fall_next_ms.has(key):
		return
	_fall_next_ms[key] = Time.get_ticks_msec() + delay_ms

func _get_same_type_amount(world_pos: Vector2i, liquid_type: String) -> float:
	var entry_variant = _get_cell_entry(world_pos)
	if not (entry_variant is Dictionary):
		return 0.0
	var entry: Dictionary = entry_variant
	if String(entry.get("type", "")) != liquid_type:
		return 0.0
	return clampf(float(entry.get("amount", 0.0)), 0.0, 1.0)

func _record_lateral_direction(world_pos: Vector2i, dir: int) -> void:
	if dir == 0:
		return
	var key := _world_key(world_pos)
	_lateral_direction_bias[key] = 1 if dir > 0 else -1
	_lateral_direction_until_ms[key] = Time.get_ticks_msec() + LATERAL_DIRECTION_MEMORY_MS

func _compute_lateral_dirs(world_pos: Vector2i, liquid_type: String) -> Array[int]:
	var parity_dirs: Array[int] = [1, -1]
	if ((world_pos.x + world_pos.y) & 1) == 0:
		parity_dirs = [-1, 1]

	var left_amount := _get_same_type_amount(world_pos + Vector2i(-1, 0), liquid_type)
	var right_amount := _get_same_type_amount(world_pos + Vector2i(1, 0), liquid_type)
	if right_amount + LATERAL_DIRECTION_PRIORITY_EPS < left_amount:
		return [1, -1]
	if left_amount + LATERAL_DIRECTION_PRIORITY_EPS < right_amount:
		return [-1, 1]

	var near_equal := absf(left_amount - right_amount) <= LATERAL_DIRECTION_NEAR_EQUAL_EPS
	if near_equal:
		var key := _world_key(world_pos)
		if _lateral_direction_until_ms.has(key):
			var now_ms := Time.get_ticks_msec()
			var until_ms := int(_lateral_direction_until_ms.get(key, 0))
			if now_ms < until_ms:
				var remembered := int(_lateral_direction_bias.get(key, 0))
				if remembered == -1:
					return [-1, 1]
				if remembered == 1:
					return [1, -1]

	return parity_dirs

func _fall_travel_ms_for(liquid_type: String) -> int:
	if liquid_type == LIQUID_TYPE_LAVA:
		return LAVA_FALL_TRAVEL_MS
	return WATER_FALL_TRAVEL_MS

func _has_inflight_fall(world_pos: Vector2i) -> bool:
	return _fall_inflight_from.has(_world_key(world_pos))

func _spawn_fall_packet(from_pos: Vector2i, to_pos: Vector2i, liquid_type: String, amount: float) -> void:
	var key := _world_key(from_pos)
	_fall_inflight_from[key] = true
	_fall_packets.append({
		"from": from_pos,
		"to": to_pos,
		"type": liquid_type,
		"amount": amount,
		"start_ms": Time.get_ticks_msec(),
		"duration_ms": _fall_travel_ms_for(liquid_type),
	})

func _update_fall_packets(changed_chunks: Dictionary) -> bool:
	if _fall_packets.is_empty():
		_fall_inflight_from.clear()
		return false

	var now_ms := Time.get_ticks_msec()
	var next_packets: Array = []
	var next_inflight: Dictionary = {}
	var changed := false

	for packet_variant in _fall_packets:
		if not (packet_variant is Dictionary):
			continue
		var packet: Dictionary = packet_variant
		var from_pos_variant = packet.get("from", null)
		var to_pos_variant = packet.get("to", null)
		if not (from_pos_variant is Vector2i) or not (to_pos_variant is Vector2i):
			continue
		var from_pos: Vector2i = from_pos_variant
		var to_pos: Vector2i = to_pos_variant
		var liquid_type := String(packet.get("type", LIQUID_TYPE_WATER))
		var amount := clampf(float(packet.get("amount", 0.0)), 0.0, 1.0)
		var start_ms := int(packet.get("start_ms", now_ms))
		var duration_ms := maxi(1, int(packet.get("duration_ms", 1)))

		if now_ms - start_ms < duration_ms:
			next_packets.append(packet)
			next_inflight[_world_key(from_pos)] = true
			continue

		var key := _world_key(from_pos)
		_fall_inflight_from.erase(key)

		if amount <= LIQUID_EPSILON:
			changed = true
			continue

		var to_coord := _canonical_chunk_coord(_world_to_chunk_coord(to_pos))
		if not _chunk_liquids.has(to_coord):
			# Destination chunk is not writable yet: return packet to source.
			var src_entry_variant0 = _get_cell_entry(from_pos)
			var src_amount0 := 0.0
			if src_entry_variant0 is Dictionary and String((src_entry_variant0 as Dictionary).get("type", "")) == liquid_type:
				src_amount0 = clampf(float((src_entry_variant0 as Dictionary).get("amount", 0.0)), 0.0, 1.0)
			_set_cell_entry(from_pos, liquid_type, src_amount0 + amount, changed_chunks)
			_enqueue_active(from_pos)
			changed = true
			continue

		if _is_world_cell_solid(to_pos):
			var src_entry_variant = _get_cell_entry(from_pos)
			var src_amount := 0.0
			if src_entry_variant is Dictionary and String((src_entry_variant as Dictionary).get("type", "")) == liquid_type:
				src_amount = clampf(float((src_entry_variant as Dictionary).get("amount", 0.0)), 0.0, 1.0)
			_set_cell_entry(from_pos, liquid_type, src_amount + amount, changed_chunks)
			_enqueue_active(from_pos)
			changed = true
			continue

		var dst_entry_variant = _get_cell_entry(to_pos)
		var dst_amount := 0.0
		if dst_entry_variant is Dictionary:
			var dst_entry: Dictionary = dst_entry_variant
			if String(dst_entry.get("type", "")) != liquid_type:
				var src_entry_variant = _get_cell_entry(from_pos)
				var src_amount := 0.0
				if src_entry_variant is Dictionary and String((src_entry_variant as Dictionary).get("type", "")) == liquid_type:
					src_amount = clampf(float((src_entry_variant as Dictionary).get("amount", 0.0)), 0.0, 1.0)
				_set_cell_entry(from_pos, liquid_type, src_amount + amount, changed_chunks)
				_enqueue_active(from_pos)
				changed = true
				continue
			dst_amount = clampf(float(dst_entry.get("amount", 0.0)), 0.0, 1.0)

		var capacity := maxf(0.0, 1.0 - dst_amount)
		var deposited := minf(amount, capacity)
		if deposited > LIQUID_EPSILON:
			_set_cell_entry(to_pos, liquid_type, dst_amount + deposited, changed_chunks)
			_wake_neighborhood(to_pos)
			changed = true

		var remainder := amount - deposited
		if remainder > LIQUID_EPSILON:
			var src_entry_variant2 = _get_cell_entry(from_pos)
			var src_amount2 := 0.0
			if src_entry_variant2 is Dictionary and String((src_entry_variant2 as Dictionary).get("type", "")) == liquid_type:
				src_amount2 = clampf(float((src_entry_variant2 as Dictionary).get("amount", 0.0)), 0.0, 1.0)
			_set_cell_entry(from_pos, liquid_type, src_amount2 + remainder, changed_chunks)
			_enqueue_active(from_pos)
			changed = true

	_fall_packets = next_packets
	_fall_inflight_from = next_inflight
	if changed:
		_refresh_overlay()
	return changed or not _fall_packets.is_empty()

func _enqueue_chunk_cells(coord: Vector2i) -> void:
	if not _chunk_liquids.has(coord):
		return
	var chunk_cells_variant = _chunk_liquids.get(coord, {})
	if not (chunk_cells_variant is Dictionary):
		return
	var chunk_cells: Dictionary = chunk_cells_variant
	for key in chunk_cells.keys():
		var local_pos_variant = _parse_local_key(key)
		if not (local_pos_variant is Vector2i):
			continue
		var local_pos: Vector2i = local_pos_variant
		var world_pos := Vector2i(coord.x * CHUNK_SIZE + local_pos.x, coord.y * CHUNK_SIZE + local_pos.y)
		_enqueue_active(world_pos)

func _prune_active_for_chunk(coord: Vector2i) -> void:
	if not _active_queue.is_empty():
		var filtered: Array = []
		for world_key_variant in _active_queue:
			if not (world_key_variant is String):
				continue
			var world_key: String = world_key_variant
			var world_pos_variant = _parse_world_key(world_key)
			if not (world_pos_variant is Vector2i):
				continue
			var world_pos: Vector2i = world_pos_variant
			if _world_to_chunk_coord(world_pos) == coord:
				_active_set.erase(world_key)
				continue
			filtered.append(world_key)
		_active_queue = filtered
	
	if not _fall_next_ms.is_empty():
		var filtered_fall: Dictionary = {}
		for world_key_variant in _fall_next_ms.keys():
			if not (world_key_variant is String):
				continue
			var world_key: String = world_key_variant
			var world_pos_variant = _parse_world_key(world_key)
			if not (world_pos_variant is Vector2i):
				continue
			var world_pos: Vector2i = world_pos_variant
			if _world_to_chunk_coord(world_pos) == coord:
				continue
			filtered_fall[world_key] = _fall_next_ms[world_key]
		_fall_next_ms = filtered_fall

	if not _fall_packets.is_empty():
		var filtered_packets: Array = []
		for packet_variant in _fall_packets:
			if not (packet_variant is Dictionary):
				continue
			var packet: Dictionary = packet_variant
			var from_pos_variant = packet.get("from", null)
			var to_pos_variant = packet.get("to", null)
			if not (from_pos_variant is Vector2i) or not (to_pos_variant is Vector2i):
				continue
			var from_pos: Vector2i = from_pos_variant
			var to_pos: Vector2i = to_pos_variant
			if _world_to_chunk_coord(from_pos) == coord or _world_to_chunk_coord(to_pos) == coord:
				_fall_inflight_from.erase(_world_key(from_pos))
				continue
			filtered_packets.append(packet)
		_fall_packets = filtered_packets

	if not _lateral_direction_until_ms.is_empty():
		var filtered_until: Dictionary = {}
		var filtered_dir: Dictionary = {}
		var now_ms := Time.get_ticks_msec()
		for world_key_variant in _lateral_direction_until_ms.keys():
			if not (world_key_variant is String):
				continue
			var world_key: String = world_key_variant
			var world_pos_variant = _parse_world_key(world_key)
			if not (world_pos_variant is Vector2i):
				continue
			var world_pos: Vector2i = world_pos_variant
			if _world_to_chunk_coord(world_pos) == coord:
				continue
			var until_ms := int(_lateral_direction_until_ms.get(world_key, 0))
			if now_ms >= until_ms:
				continue
			filtered_until[world_key] = until_ms
			if _lateral_direction_bias.has(world_key):
				filtered_dir[world_key] = _lateral_direction_bias[world_key]
		_lateral_direction_until_ms = filtered_until
		_lateral_direction_bias = filtered_dir

	if not _open_fall_mode_until_ms.is_empty():
		var filtered_open_fall: Dictionary = {}
		var now_ms := Time.get_ticks_msec()
		for world_key_variant in _open_fall_mode_until_ms.keys():
			if not (world_key_variant is String):
				continue
			var world_key: String = world_key_variant
			var world_pos_variant = _parse_world_key(world_key)
			if not (world_pos_variant is Vector2i):
				continue
			var world_pos: Vector2i = world_pos_variant
			if _world_to_chunk_coord(world_pos) == coord:
				continue
			var until_ms := int(_open_fall_mode_until_ms.get(world_key, 0))
			if now_ms >= until_ms:
				continue
			filtered_open_fall[world_key] = until_ms
		_open_fall_mode_until_ms = filtered_open_fall

func _enqueue_active(world_pos: Vector2i) -> void:
	var world_key := _world_key(world_pos)
	if _active_set.has(world_key):
		return
	_active_set[world_key] = true
	_active_queue.append(world_key)

func _wake_neighborhood(center: Vector2i) -> void:
	var offsets = [
		Vector2i.ZERO,
		Vector2i(0, -1),
		Vector2i(0, 1),
		Vector2i(-1, 0),
		Vector2i(1, 0),
	]
	for offset in offsets:
		_enqueue_active(center + offset)

func _is_open_fall_column(world_pos: Vector2i, liquid_type: String) -> bool:
	# Prefer continuous waterfall columns when the next two cells are open.
	for dy in [1, 2]:
		var probe := world_pos + Vector2i(0, dy)
		if _is_downward_blocked(probe.y):
			return false
		if _is_world_cell_solid(probe):
			return false
		var entry_variant = _get_cell_entry(probe)
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			if String(entry.get("type", "")) != liquid_type:
				return false
			var max_allowed := LIQUID_EPSILON
			if liquid_type == LIQUID_TYPE_WATER and dy == 1:
				max_allowed = WATER_OPEN_FALL_THIN_FILM_EPS
			if float(entry.get("amount", 0.0)) > max_allowed:
				return false
	return true

func _should_use_open_fall_stream(world_pos: Vector2i, liquid_type: String, source_amount: float, below_same_type: bool, below_pos: Vector2i) -> bool:
	if liquid_type != LIQUID_TYPE_WATER:
		return false
	var key := _world_key(world_pos)
	var now_ms := Time.get_ticks_msec()
	if below_same_type or source_amount < WATER_OPEN_FALL_MIN_AMOUNT:
		_open_fall_mode_until_ms.erase(key)
		return false

	if _is_open_fall_column(world_pos, liquid_type):
		_open_fall_mode_until_ms[key] = now_ms + WATER_OPEN_FALL_STICK_MS
		return true

	var until_ms := int(_open_fall_mode_until_ms.get(key, 0))
	if now_ms >= until_ms:
		_open_fall_mode_until_ms.erase(key)
		return false

	# Keep mode briefly while immediate drop conditions are still compatible.
	if _is_downward_blocked(below_pos.y) or _is_world_cell_solid(below_pos):
		_open_fall_mode_until_ms.erase(key)
		return false
	var below_entry_variant = _get_cell_entry(below_pos)
	if below_entry_variant is Dictionary:
		var below_entry: Dictionary = below_entry_variant
		if String(below_entry.get("type", "")) != liquid_type:
			_open_fall_mode_until_ms.erase(key)
			return false
		if float(below_entry.get("amount", 0.0)) > WATER_OPEN_FALL_THIN_FILM_EPS:
			_open_fall_mode_until_ms.erase(key)
			return false
	return true

func _simulate_active_cell(world_pos: Vector2i, changed_chunks: Dictionary) -> bool:
	var coord := _canonical_chunk_coord(_world_to_chunk_coord(world_pos))
	if not _chunk_liquids.has(coord):
		return false

	var source_entry_variant = _get_cell_entry(world_pos)
	if not (source_entry_variant is Dictionary):
		return false

	if _is_world_cell_solid(world_pos):
		_set_cell_entry(world_pos, "", 0.0, changed_chunks)
		_wake_neighborhood(world_pos)
		return true

	var source_entry: Dictionary = source_entry_variant
	var liquid_type := String(source_entry.get("type", LIQUID_TYPE_WATER))
	var family: Dictionary = _liquid_families.get(liquid_type, {})
	var viscosity := clampf(float(family.get("viscosity", 0.45)), 0.05, 0.95)
	var amount := clampf(float(source_entry.get("amount", 1.0)), 0.0, 1.0)
	if amount <= LIQUID_EPSILON:
		_set_cell_entry(world_pos, "", 0.0, changed_chunks)
		return true

	var moved := false
	var fall_blocked_by_cooldown := false
	var fall_waiting_for_downstream := false
	var below_amount_after := 0.0
	var below_amount_for_support := 0.0
	var waterfall_priority := false

	# Downward preference (gravity first)
	if not _is_downward_blocked(world_pos.y + 1):
		var below_pos := world_pos + Vector2i(0, 1)
		if _chunk_liquids.has(_canonical_chunk_coord(_world_to_chunk_coord(below_pos))) and not _is_world_cell_solid(below_pos):
			var below_entry_variant = _get_cell_entry(below_pos)
			var below_amount := 0.0
			var below_same_type := false
			var open_fall_stream := false
			if below_entry_variant is Dictionary:
				var below_entry: Dictionary = below_entry_variant
				if String(below_entry.get("type", "")) != liquid_type:
					below_entry_variant = null
				else:
					below_same_type = true
					below_amount = clampf(float(below_entry.get("amount", 0.0)), 0.0, 1.0)
			below_amount_for_support = below_amount

			if below_entry_variant == null or below_entry_variant is Dictionary:
				# Keep per-step fall granular, but scale by local head difference.
				var head_diff := maxf(0.0, amount - below_amount)
				var gravity_budget := minf(amount, 0.032 + (1.0 - viscosity) * 0.026 + head_diff * 0.08)
				gravity_budget = minf(gravity_budget, MAX_DOWN_FLOW_PER_STEP)
				var capacity := maxf(0.0, 1.0 - below_amount)
				var down_flow := minf(gravity_budget, capacity)
				open_fall_stream = _should_use_open_fall_stream(world_pos, liquid_type, amount, below_same_type, below_pos)
				if open_fall_stream:
					var waterfall_budget := maxf(gravity_budget + 0.02, WATER_OPEN_FALL_DOWN_MIN)
					waterfall_budget = minf(waterfall_budget, WATER_OPEN_FALL_DOWN_MAX)
					waterfall_budget = minf(waterfall_budget, amount)
					down_flow = minf(waterfall_budget, capacity)
					waterfall_priority = true
				if below_same_type:
					# Allow smooth merge into existing liquid column near the end.
					down_flow = minf(down_flow, minf(amount, capacity))
				elif open_fall_stream:
					down_flow = minf(down_flow, minf(amount, capacity))
				else:
					down_flow = _quantize_transfer(down_flow, minf(amount, capacity), DOWN_FLOW_QUANTUM)
					if down_flow <= LIQUID_EPSILON and amount > LIQUID_EPSILON and capacity > LIQUID_EPSILON:
						# Avoid downward dead-zones where sub-quantum films can never drain.
						down_flow = minf(minf(amount, capacity), DOWNWARD_MICRO_TRICKLE_MAX)

				if down_flow > LIQUID_EPSILON and _can_fall_now(world_pos) and (below_same_type or not _has_inflight_fall(world_pos)):
					amount -= down_flow
					if below_same_type or open_fall_stream:
						below_amount_after = below_amount + down_flow
						_set_cell_entry(below_pos, liquid_type, below_amount_after, changed_chunks)
					else:
						below_amount_after = below_amount
						_spawn_fall_packet(world_pos, below_pos, liquid_type, down_flow)
					moved = true
					_arm_fall_cooldown(world_pos, liquid_type, down_flow, head_diff, open_fall_stream)
					if open_fall_stream:
						_enqueue_active(world_pos)
						_enqueue_active(below_pos)
					_wake_neighborhood(below_pos)
				elif down_flow > LIQUID_EPSILON:
					fall_blocked_by_cooldown = true
				elif capacity <= LIQUID_EPSILON and not _is_world_cell_solid(below_pos):
					# Below cell may free space later in this frame (after its own fall step),
					# so keep this source active for vertical cascade behavior.
					fall_waiting_for_downstream = true
				elif amount > LIQUID_EPSILON and capacity > LIQUID_EPSILON:
					# Also retry when a small non-zero film did not move this tick.
					fall_blocked_by_cooldown = true

	# Lateral pressure spread: only when source is supported enough.
	var source_below_pos := world_pos + Vector2i(0, 1)
	var source_supported := _is_world_cell_solid(source_below_pos) or maxf(below_amount_after, below_amount_for_support) >= SOURCE_SUPPORT_MIN

	var spread_threshold := 0.08
	if waterfall_priority and liquid_type == LIQUID_TYPE_WATER:
		spread_threshold = maxf(spread_threshold, WATER_OPEN_FALL_MIN_AMOUNT)
	var allow_edge_spill := amount >= 0.58 and not fall_waiting_for_downstream
	if not fall_waiting_for_downstream and amount > spread_threshold and (source_supported or allow_edge_spill):
		var dirs: Array[int] = _compute_lateral_dirs(world_pos, liquid_type)

		for dir in dirs:
			if amount <= spread_threshold:
				break

			var side_pos := world_pos + Vector2i(int(dir), 0)
			if not _chunk_liquids.has(_canonical_chunk_coord(_world_to_chunk_coord(side_pos))):
				continue
			if _is_world_cell_solid(side_pos):
				continue

			# Prevent hanging shelves: lateral target must have support below.
			var side_below := side_pos + Vector2i(0, 1)
			var side_supported := _is_world_cell_solid(side_below)
			var spill_edge := false
			if not side_supported:
				var side_below_entry_variant = _get_cell_entry(side_below)
				if side_below_entry_variant is Dictionary:
					var side_below_entry: Dictionary = side_below_entry_variant
					if String(side_below_entry.get("type", "")) == liquid_type:
						side_supported = float(side_below_entry.get("amount", 0.0)) >= SIDE_SUPPORT_MIN
			if not side_supported:
				if allow_edge_spill and not _is_world_cell_solid(side_below):
					spill_edge = true
				else:
					continue

			var side_entry_variant = _get_cell_entry(side_pos)
			var side_amount := 0.0
			if side_entry_variant is Dictionary:
				var side_entry: Dictionary = side_entry_variant
				if String(side_entry.get("type", "")) != liquid_type:
					continue
				side_amount = clampf(float(side_entry.get("amount", 0.0)), 0.0, 1.0)

			var spread_target := (amount + side_amount) * 0.5
			var side_capacity := maxf(0.0, 1.0 - side_amount)
			var pressure_head := maxf(0.0, amount - side_amount)
			var equalize_delta := maxf(0.0, amount - spread_target)
			var side_flow := minf(equalize_delta + pressure_head * (0.12 + (1.0 - viscosity) * 0.08), side_capacity)
			side_flow = minf(side_flow, 0.026 + (1.0 - viscosity) * 0.032)
			side_flow = minf(side_flow, MAX_SIDE_FLOW_PER_STEP)
			if waterfall_priority and liquid_type == LIQUID_TYPE_WATER:
				side_flow *= WATER_OPEN_FALL_LATERAL_DAMP
			if spill_edge:
				side_flow *= 0.40
				# Ensure ledge spill is not quantized to zero.
				if side_flow > LIQUID_EPSILON:
					side_flow = maxf(side_flow, SIDE_FLOW_QUANTUM)
			side_flow = _quantize_transfer(side_flow, minf(amount, side_capacity), SIDE_FLOW_QUANTUM)
			side_flow = _apply_water_lateral_split_gain(liquid_type, side_flow, amount, side_capacity)
			if side_flow <= LIQUID_EPSILON:
				continue

			amount -= side_flow
			_set_cell_entry(side_pos, liquid_type, side_amount + side_flow, changed_chunks)
			moved = true
			_record_lateral_direction(world_pos, int(dir))
			_wake_neighborhood(side_pos)

	if amount <= LIQUID_EPSILON:
		_set_cell_entry(world_pos, "", 0.0, changed_chunks)
	else:
		_set_cell_entry(world_pos, liquid_type, amount, changed_chunks)

	if fall_blocked_by_cooldown:
		# Cooldown cells are centrally re-enqueued when their timer elapses.
		# If this block happened for non-cooldown reasons (e.g. inflight packet),
		# keep the legacy immediate retry behavior.
		if not _fall_next_ms.has(_world_key(world_pos)):
			_enqueue_active(world_pos)
	elif fall_waiting_for_downstream:
		# Prioritize downstream progress and schedule a low-frequency self-retry.
		_enqueue_active(world_pos + Vector2i(0, 1))
		_schedule_delayed_retry(world_pos, DOWNSTREAM_WAIT_RETRY_MS)

	if moved:
		_wake_neighborhood(world_pos)

	return true

func _get_cell_entry(world_pos: Vector2i) -> Variant:
	var coord := _canonical_chunk_coord(_world_to_chunk_coord(world_pos))
	if not _chunk_liquids.has(coord):
		return null
	var chunk_cells_variant = _chunk_liquids.get(coord, {})
	if not (chunk_cells_variant is Dictionary):
		return null
	var chunk_cells: Dictionary = chunk_cells_variant
	var local_pos := _world_to_local_coord(world_pos)
	return chunk_cells.get(_local_key(local_pos), null)

func _set_cell_entry(world_pos: Vector2i, liquid_type: String, amount: float, changed_chunks: Dictionary) -> void:
	var coord := _canonical_chunk_coord(_world_to_chunk_coord(world_pos))
	if not _chunk_liquids.has(coord):
		return
	var chunk_cells_variant = _chunk_liquids.get(coord, {})
	if not (chunk_cells_variant is Dictionary):
		chunk_cells_variant = {}
	var chunk_cells: Dictionary = chunk_cells_variant
	var local_pos := _world_to_local_coord(world_pos)
	var key := _local_key(local_pos)

	if amount <= CELL_CLEAR_EPSILON:
		if chunk_cells.has(key):
			chunk_cells.erase(key)
			_chunk_liquids[coord] = chunk_cells
			changed_chunks[coord] = true
		return

	var clamped_amount := clampf(amount, 0.0, 1.0)
	var previous_amount := -1.0
	if chunk_cells.has(key):
		var previous = chunk_cells.get(key, null)
		if previous is Dictionary:
			previous_amount = float(previous.get("amount", -1.0))

	chunk_cells[key] = {
		"type": liquid_type,
		"amount": clamped_amount,
	}
	_chunk_liquids[coord] = chunk_cells
	if absf(previous_amount - clamped_amount) > 0.0001:
		changed_chunks[coord] = true

func _is_downward_blocked(global_y: int) -> bool:
	var world_topology = _get_world_topology()
	if not world_topology:
		return false
	if world_topology.has_method("is_global_y_at_or_below_hard_floor"):
		return bool(world_topology.is_global_y_at_or_below_hard_floor(global_y))
	return false

func _register_builtin_families() -> void:
	register_liquid_family(LIQUID_TYPE_WATER, {
		"viscosity": 0.45,
		"fall_gate": 0.70,
	})
	register_liquid_family(LIQUID_TYPE_LAVA, {
		"viscosity": 0.72,
		"fall_gate": 0.82,
	})

func _seed_settle_wave(max_cells: int) -> void:
	if max_cells <= 0:
		return
	if _chunk_liquids.is_empty():
		return

	var chunk_keys: Array = _chunk_liquids.keys()
	if chunk_keys.is_empty():
		return
	if _settle_chunk_cursor >= chunk_keys.size():
		_settle_chunk_cursor = 0

	var budget := max_cells
	var visited := 0
	while budget > 0 and visited < chunk_keys.size():
		if _settle_chunk_cursor >= chunk_keys.size():
			_settle_chunk_cursor = 0
		var coord_variant = chunk_keys[_settle_chunk_cursor]
		_settle_chunk_cursor += 1
		visited += 1
		if not (coord_variant is Vector2i):
			continue
		var coord: Vector2i = coord_variant
		var chunk_cells_variant = _chunk_liquids.get(coord, {})
		if not (chunk_cells_variant is Dictionary):
			continue
		var chunk_cells: Dictionary = chunk_cells_variant
		if chunk_cells.is_empty():
			continue
		for key in chunk_cells.keys():
			if budget <= 0:
				break
			var local_pos_variant = _parse_local_key(key)
			if not (local_pos_variant is Vector2i):
				continue
			var local_pos: Vector2i = local_pos_variant
			_enqueue_active(Vector2i(coord.x * CHUNK_SIZE + local_pos.x, coord.y * CHUNK_SIZE + local_pos.y))
			budget -= 1

# Legacy post-simulation repair passes were removed so runtime behavior remains
# fully traceable to core active-cell simulation.

func _settle_chunks_immediately(chunk_coords: Array, max_passes: int, max_cells_per_pass: int) -> void:
	if max_passes <= 0 or max_cells_per_pass <= 0:
		return
	if chunk_coords.is_empty():
		return

	var target_chunks: Array[Vector2i] = []
	var seen_chunks: Dictionary = {}
	for coord_variant in chunk_coords:
		if not (coord_variant is Vector2i):
			continue
		var c: Vector2i = _canonical_chunk_coord(coord_variant)
		var ck := "%d,%d" % [c.x, c.y]
		if seen_chunks.has(ck):
			continue
		seen_chunks[ck] = true
		if _chunk_liquids.has(c):
			target_chunks.append(c)

	if target_chunks.is_empty():
		return

	var pass_index := 0
	while pass_index < max_passes:
		var checks := 0
		var pass_changes: Dictionary = {}

		for coord in target_chunks:
			if checks >= max_cells_per_pass:
				break
			var chunk_cells_variant = _chunk_liquids.get(coord, {})
			if not (chunk_cells_variant is Dictionary):
				continue
			var chunk_cells: Dictionary = chunk_cells_variant
			if chunk_cells.is_empty():
				continue

			var cell_keys: Array = chunk_cells.keys()
			for key in cell_keys:
				if checks >= max_cells_per_pass:
					break
				var local_pos_variant = _parse_local_key(key)
				if not (local_pos_variant is Vector2i):
					continue
				var local_pos: Vector2i = local_pos_variant
				var world_pos := Vector2i(coord.x * CHUNK_SIZE + local_pos.x, coord.y * CHUNK_SIZE + local_pos.y)
				_simulate_active_cell(world_pos, pass_changes)
				checks += 1

		if pass_changes.is_empty():
			break

		for changed_coord_variant in pass_changes.keys():
			if changed_coord_variant is Vector2i:
				_sync_chunk_render(changed_coord_variant)
		pass_index += 1

func flush_runtime_to_chunks(chunks: Dictionary) -> Array:
	# Sync current runtime liquid state back into chunk resources before save.
	var touched_coords: Array = []
	if chunks.is_empty():
		return touched_coords

	for coord_variant in _chunk_liquids.keys():
		if not (coord_variant is Vector2i):
			continue
		var coord: Vector2i = coord_variant
		if not chunks.has(coord):
			continue
		var chunk_variant = chunks.get(coord, null)
		if chunk_variant == null or not ("liquid_cells" in chunk_variant):
			continue

		var next_cells_variant = _chunk_liquids.get(coord, {})
		if not (next_cells_variant is Dictionary):
			continue
		var next_cells: Dictionary = (next_cells_variant as Dictionary).duplicate(true)

		var prev_cells := {}
		var prev_variant = chunk_variant.get("liquid_cells")
		if prev_variant is Dictionary:
			prev_cells = prev_variant

		var changed := prev_cells != next_cells
		var was_initialized := false
		if "liquid_state_initialized" in chunk_variant:
			was_initialized = bool(chunk_variant.get("liquid_state_initialized"))

		chunk_variant.set("liquid_cells", next_cells)
		if "liquid_state_initialized" in chunk_variant:
			chunk_variant.set("liquid_state_initialized", true)

		if changed or not was_initialized:
			touched_coords.append(coord)

	return touched_coords

func _is_local_pos_valid(local_pos: Vector2i) -> bool:
	return local_pos.x >= 0 and local_pos.x < CHUNK_SIZE and local_pos.y >= 0 and local_pos.y < CHUNK_SIZE

func _global_to_world_cell(global_pos: Vector2) -> Variant:
	var generator = _get_world_generator()
	if generator and "layer_0" in generator and generator.layer_0 is TileMapLayer:
		var layer: TileMapLayer = generator.layer_0
		return layer.local_to_map(layer.to_local(global_pos))
	return Vector2i(int(floor(global_pos.x / 16.0)), int(floor(global_pos.y / 16.0)))

func _world_to_chunk_coord(world_pos: Vector2i) -> Vector2i:
	var cx := int(floor(float(world_pos.x) / float(CHUNK_SIZE)))
	var cy := int(floor(float(world_pos.y) / float(CHUNK_SIZE)))
	return Vector2i(cx, cy)

func _world_to_local_coord(world_pos: Vector2i) -> Vector2i:
	var coord := _world_to_chunk_coord(world_pos)
	return Vector2i(world_pos.x - coord.x * CHUNK_SIZE, world_pos.y - coord.y * CHUNK_SIZE)

func _world_key(world_pos: Vector2i) -> String:
	return "%d,%d" % [world_pos.x, world_pos.y]

func _parse_world_key(key: Variant) -> Variant:
	if key is String:
		var key_str: String = key
		var parts: PackedStringArray = key_str.split(",")
		if parts.size() == 2:
			return Vector2i(int(parts[0]), int(parts[1]))
	return null

func _local_key(local_pos: Vector2i) -> String:
	return "%d,%d" % [local_pos.x, local_pos.y]

func _parse_local_key(key: Variant) -> Variant:
	if key is Vector2i:
		return key
	if key is String:
		var key_str: String = key
		var parts: PackedStringArray = key_str.split(",")
		if parts.size() == 2:
			return Vector2i(int(parts[0]), int(parts[1]))
	return null

func _get_world_topology() -> Node:
	var scene_tree := get_tree()
	if scene_tree == null or scene_tree.root == null:
		return null
	return scene_tree.root.get_node_or_null("WorldTopology")

func _canonical_chunk_coord(coord: Vector2i) -> Vector2i:
	var world_topology = _get_world_topology()
	if world_topology and world_topology.has_method("canonical_chunk_coord"):
		return world_topology.canonical_chunk_coord(coord)
	return coord

func _get_world_generator() -> Node:
	return get_tree().get_first_node_in_group("world_generator")

func _is_world_cell_solid(world_pos: Vector2i) -> bool:
	var generator = _get_world_generator()
	if not generator:
		return false
	if not ("layer_0" in generator):
		return false
	var layer = generator.layer_0
	if layer is TileMapLayer:
		return layer.get_cell_source_id(world_pos) != -1
	return false

func _get_liquid_layer() -> TileMapLayer:
	var generator = _get_world_generator()
	if not generator:
		return null
	if _runtime_liquid_layer != null and is_instance_valid(_runtime_liquid_layer):
		_runtime_liquid_layer.z_as_relative = false
		_runtime_liquid_layer.z_index = LIQUID_RUNTIME_LAYER_RENDER_Z
		return _runtime_liquid_layer

	if not ("layer_1" in generator):
		return null
	var base_layer = generator.layer_1
	if not (base_layer is TileMapLayer):
		return null

	var existing = generator.get_node_or_null("LiquidRuntimeLayer")
	if existing is TileMapLayer:
		_runtime_liquid_layer = existing
		_runtime_liquid_layer.z_as_relative = false
		_runtime_liquid_layer.z_index = LIQUID_RUNTIME_LAYER_RENDER_Z
		return _runtime_liquid_layer

	var runtime_layer := TileMapLayer.new()
	runtime_layer.name = "LiquidRuntimeLayer"
	runtime_layer.tile_set = base_layer.tile_set
	runtime_layer.collision_enabled = false
	runtime_layer.y_sort_enabled = false
	runtime_layer.z_as_relative = false
	runtime_layer.z_index = LIQUID_RUNTIME_LAYER_RENDER_Z
	runtime_layer.set_meta("background_only", true)
	if base_layer.has_meta("layer_index"):
		runtime_layer.set_meta("layer_index", base_layer.get_meta("layer_index"))
	generator.add_child(runtime_layer)
	_runtime_liquid_layer = runtime_layer
	return _runtime_liquid_layer

func _resolve_liquid_atlas(source_id: int, base_atlas: Vector2i, amount: float, liquid_type: String) -> Vector2i:
	var candidates: Array = [base_atlas]

	if liquid_type == LIQUID_TYPE_WATER:
		if amount < RENDER_LEVEL_MID:
			candidates.append(base_atlas + Vector2i(-1, 0))
			candidates.append(base_atlas + Vector2i(0, 1))
			candidates.append(base_atlas + Vector2i(1, 0))
		elif amount < RENDER_LEVEL_HIGH:
			candidates.append(base_atlas + Vector2i(1, 0))
			candidates.append(base_atlas + Vector2i(0, 1))
	else:
		if amount < RENDER_LEVEL_MID:
			candidates.append(base_atlas + Vector2i(-1, 0))
		elif amount < RENDER_LEVEL_HIGH:
			candidates.append(base_atlas + Vector2i(1, 0))

	for atlas_variant in candidates:
		if atlas_variant is Vector2i:
			var atlas: Vector2i = atlas_variant
			if _is_tile_available(source_id, atlas):
				return atlas

	return base_atlas

func _get_liquid_tile_for_type(liquid_type: String, amount: float) -> Dictionary:
	var generator = _get_world_generator()
	if not generator:
		return {}

	var source_id := int(generator.get("tile_source_id"))
	var atlas: Vector2i = Vector2i(3, 3)
	var fallback: Vector2i = Vector2i(2, 0)
	if generator.has_method("get_stage_tileset_mapping"):
		var mapping: Dictionary = generator.get_stage_tileset_mapping()
		if liquid_type == LIQUID_TYPE_LAVA:
			atlas = mapping.get("liquid_contact_lava", atlas)
			fallback = Vector2i(2, 0)
		else:
			atlas = mapping.get("liquid_contact_water", atlas)
			fallback = Vector2i(0, 0)

	if not _is_tile_available(source_id, atlas):
		atlas = fallback
	if not _is_tile_available(source_id, atlas):
		return {}
	atlas = _resolve_liquid_atlas(source_id, atlas, amount, liquid_type)

	return {
		"source": source_id,
		"atlas": atlas,
	}

func _is_tile_available(source_id: int, atlas: Vector2i) -> bool:
	var layer := _get_liquid_layer()
	if layer == null or layer.tile_set == null:
		return false
	if not layer.tile_set.has_source(source_id):
		return false
	var source = layer.tile_set.get_source(source_id)
	if source is TileSetAtlasSource:
		return source.has_tile(atlas)
	return false

func _get_liquid_overlay() -> LiquidOverlay:
	var generator = _get_world_generator()
	if not generator:
		return null
	if _runtime_liquid_overlay != null and is_instance_valid(_runtime_liquid_overlay):
		return _runtime_liquid_overlay

	var existing = generator.get_node_or_null("LiquidOverlay")
	if existing is LiquidOverlay:
		_runtime_liquid_overlay = existing
		_runtime_liquid_overlay.z_as_relative = false
		_runtime_liquid_overlay.z_index = LIQUID_OVERLAY_RENDER_Z
		return _runtime_liquid_overlay

	var overlay := LiquidOverlay.new()
	overlay.name = "LiquidOverlay"
	overlay.z_as_relative = false
	overlay.z_index = LIQUID_OVERLAY_RENDER_Z
	var base_layer := _get_liquid_layer()
	if base_layer != null and base_layer.tile_set != null:
		var ts: Vector2i = base_layer.tile_set.tile_size
		overlay.configure(float(maxi(ts.x, ts.y)))
	generator.add_child(overlay)
	_runtime_liquid_overlay = overlay
	return _runtime_liquid_overlay

func _refresh_overlay() -> void:
	var overlay := _get_liquid_overlay()
	if overlay == null:
		return
	overlay.set_frame_data(_overlay_cells, _fall_packets)

func _clear_all_rendered_chunks() -> void:
	for coord_variant in _rendered_chunk_cells.keys():
		if coord_variant is Vector2i:
			_clear_rendered_chunk(coord_variant)

func _clear_rendered_chunk(coord: Vector2i) -> void:
	var layer := _get_liquid_layer()
	if layer == null:
		_rendered_chunk_cells.erase(coord)
		return

	var rendered_keys_variant = _rendered_chunk_cells.get(coord, [])
	if rendered_keys_variant is Array:
		for key in rendered_keys_variant:
			var local_pos_variant = _parse_local_key(key)
			if not (local_pos_variant is Vector2i):
				continue
			var local_pos: Vector2i = local_pos_variant
			var world_pos := Vector2i(coord.x * CHUNK_SIZE + local_pos.x, coord.y * CHUNK_SIZE + local_pos.y)
			layer.set_cell(world_pos, -1)
			_overlay_cells.erase(world_pos)

	_rendered_chunk_cells.erase(coord)
	_refresh_overlay()

func _sync_chunk_render(coord: Vector2i) -> void:
	var layer := _get_liquid_layer()
	if layer == null:
		return

	_clear_rendered_chunk(coord)

	if not _chunk_liquids.has(coord):
		return

	var chunk_cells_variant = _chunk_liquids.get(coord, {})
	if not (chunk_cells_variant is Dictionary):
		return
	var chunk_cells: Dictionary = chunk_cells_variant
	if chunk_cells.is_empty():
		return

	var rendered_keys: Array = []
	var erase_keys: Array = []
	for key in chunk_cells.keys():
		var entry = chunk_cells.get(key, {})
		if not (entry is Dictionary):
			continue
		var local_pos_variant = _parse_local_key(key)
		if not (local_pos_variant is Vector2i):
			continue
		var local_pos: Vector2i = local_pos_variant
		var liquid_type := String(entry.get("type", LIQUID_TYPE_WATER))
		var amount := clampf(float(entry.get("amount", 0.0)), 0.0, 1.0)
		if amount < RENDER_EPSILON:
			continue

		var world_pos := Vector2i(coord.x * CHUNK_SIZE + local_pos.x, coord.y * CHUNK_SIZE + local_pos.y)
		if _is_world_cell_solid(world_pos):
			erase_keys.append(key)
			continue

		# Hide old tile-based liquid and render true fractional fill in overlay.
		layer.set_cell(world_pos, -1)
		_overlay_cells[world_pos] = {
			"type": liquid_type,
			"amount": amount,
		}
		rendered_keys.append(_local_key(local_pos))

	for stale_key in erase_keys:
		if chunk_cells.has(stale_key):
			chunk_cells.erase(stale_key)
	if not erase_keys.is_empty():
		_chunk_liquids[coord] = chunk_cells

	if not rendered_keys.is_empty():
		_rendered_chunk_cells[coord] = rendered_keys

	_refresh_overlay()
