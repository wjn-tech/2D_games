extends Node

class LiquidOverlay:
	extends Node2D

	var cells: Dictionary = {}
	var packets: Array = []
	var tile_size_px: float = 16.0

	func configure(p_tile_size_px: float) -> void:
		tile_size_px = maxf(1.0, p_tile_size_px)

	func set_frame_data(next_cells: Dictionary, next_packets: Array) -> void:
		cells = next_cells.duplicate(true)
		packets = next_packets.duplicate(true)
		queue_redraw()

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
			var fill_h := maxf(1.0, floorf(amount * tile_size_px))
			fill_h = minf(fill_h, tile_size_px)
			var px := float(world_pos.x) * tile_size_px
			var py := float(world_pos.y) * tile_size_px + (tile_size_px - fill_h)

			var body_color := Color(0.18, 0.56, 0.72, 0.78)
			var edge_color := Color(0.62, 0.86, 0.98, 0.92)
			if liquid_type == "lava":
				body_color = Color(0.88, 0.34, 0.10, 0.82)
				edge_color = Color(1.0, 0.72, 0.35, 0.92)

			draw_rect(Rect2(px, py, tile_size_px, fill_h), body_color, true)
			var above_entry_variant = cells.get(world_pos + Vector2i(0, -1), null)
			var has_same_liquid_above := false
			if above_entry_variant is Dictionary:
				var above_entry: Dictionary = above_entry_variant
				has_same_liquid_above = String(above_entry.get("type", "")) == liquid_type and float(above_entry.get("amount", 0.0)) > 0.02
			if fill_h < tile_size_px and not has_same_liquid_above:
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
const MAX_ACTIVE_STEPS_PER_FRAME := 56
const SIMULATION_BUDGET_MS := 0.75
const LIQUID_EPSILON := 0.01
const RENDER_EPSILON := 0.06
const SOURCE_SUPPORT_MIN := 0.42
const SIDE_SUPPORT_MIN := 0.42
const MAX_DOWN_FLOW_PER_STEP := 0.03125
const MAX_SIDE_FLOW_PER_STEP := 0.07
const DOWN_FLOW_QUANTUM := 0.03125
const SIDE_FLOW_QUANTUM := 0.015625
const WATER_FALL_DELAY_MS := 45
const LAVA_FALL_DELAY_MS := 75
const WATER_FALL_TRAVEL_MS := 60
const LAVA_FALL_TRAVEL_MS := 90
const RENDER_LEVEL_HIGH := 0.78
const RENDER_LEVEL_MID := 0.42

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
		"quick_settle_budget": _quick_settle_budget,
		"registered_families": get_registered_liquid_families(),
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
	_active_queue.clear()
	_active_set.clear()
	_quick_settle_budget = 0
	_settle_chunk_cursor = 0

func on_chunk_loaded(coord: Vector2i, chunk: Resource) -> void:
	var canonical := _canonical_chunk_coord(coord)
	var chunk_cells: Dictionary = {}
	if chunk != null and "liquid_cells" in chunk:
		var saved_cells = chunk.get("liquid_cells")
		if saved_cells is Dictionary and not saved_cells.is_empty():
			chunk_cells = saved_cells.duplicate(true)

	_chunk_liquids[canonical] = chunk_cells
	if not chunk_cells.is_empty():
		_enqueue_chunk_cells(canonical)
		_request_quick_settle(1)
		_sync_chunk_render(canonical)

func ingest_generated_liquids(coord: Vector2i, cells: Dictionary, chunk: Resource) -> void:
	var seeds = cells.get("_liquid_seeds", [])
	if not (seeds is Array) or seeds.is_empty():
		return

	var canonical := _canonical_chunk_coord(coord)
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
	_enqueue_chunk_cells(canonical)
	_request_quick_settle(1)
	_sync_chunk_render(canonical)

func on_chunk_unloaded(coord: Vector2i, chunk: Resource) -> void:
	var canonical := _canonical_chunk_coord(coord)
	if not _chunk_liquids.has(canonical):
		return

	var chunk_cells = _chunk_liquids.get(canonical, {})
	if chunk != null and "liquid_cells" in chunk and chunk_cells is Dictionary:
		chunk.set("liquid_cells", chunk_cells.duplicate(true))
	_clear_rendered_chunk(canonical)

	_chunk_liquids.erase(canonical)
	_prune_active_for_chunk(canonical)

func notify_world_cell_changed(world_pos: Vector2i) -> void:
	_wake_neighborhood(world_pos)

func _request_quick_settle(pass_count: int) -> void:
	if pass_count <= 0:
		return
	_quick_settle_budget = maxi(_quick_settle_budget, pass_count)

func _quantize_transfer(flow: float, available: float, quantum: float) -> float:
	var q := maxf(quantum, LIQUID_EPSILON)
	var capped := minf(flow, available)
	if capped < q:
		return 0.0
	var steps := floorf(capped / q)
	return steps * q

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

func _arm_fall_cooldown(world_pos: Vector2i, liquid_type: String) -> void:
	var delay_ms := _fall_delay_ms_for(liquid_type)
	if delay_ms <= 0:
		return
	_fall_next_ms[_world_key(world_pos)] = Time.get_ticks_msec() + delay_ms

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
	
	if _fall_next_ms.is_empty():
		return
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

	if _fall_packets.is_empty():
		return
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

	# Downward preference (gravity first)
	if not _is_downward_blocked(world_pos.y + 1):
		var below_pos := world_pos + Vector2i(0, 1)
		if _chunk_liquids.has(_canonical_chunk_coord(_world_to_chunk_coord(below_pos))) and not _is_world_cell_solid(below_pos):
			var below_entry_variant = _get_cell_entry(below_pos)
			var below_amount := 0.0
			var below_same_type := false
			if below_entry_variant is Dictionary:
				var below_entry: Dictionary = below_entry_variant
				if String(below_entry.get("type", "")) != liquid_type:
					below_entry_variant = null
				else:
					below_same_type = true
					below_amount = clampf(float(below_entry.get("amount", 0.0)), 0.0, 1.0)
			below_amount_for_support = below_amount

			if below_entry_variant == null or below_entry_variant is Dictionary:
				# Keep per-step fall small so a mined cavity drains progressively.
				var gravity_budget := minf(amount, 0.05 + (1.0 - viscosity) * 0.04)
				gravity_budget = minf(gravity_budget, MAX_DOWN_FLOW_PER_STEP)
				var capacity := maxf(0.0, 1.0 - below_amount)
				var down_flow := minf(gravity_budget, capacity)
				if below_same_type:
					# Allow smooth merge into existing liquid column near the end.
					down_flow = minf(down_flow, minf(amount, capacity))
				else:
					down_flow = _quantize_transfer(down_flow, minf(amount, capacity), DOWN_FLOW_QUANTUM)

				if down_flow > LIQUID_EPSILON and _can_fall_now(world_pos) and (below_same_type or not _has_inflight_fall(world_pos)):
					amount -= down_flow
					if below_same_type:
						below_amount_after = below_amount + down_flow
						_set_cell_entry(below_pos, liquid_type, below_amount_after, changed_chunks)
					else:
						below_amount_after = below_amount
						_spawn_fall_packet(world_pos, below_pos, liquid_type, down_flow)
					moved = true
					_arm_fall_cooldown(world_pos, liquid_type)
					_wake_neighborhood(below_pos)
				elif down_flow > LIQUID_EPSILON:
					fall_blocked_by_cooldown = true
				elif capacity <= LIQUID_EPSILON and not _is_world_cell_solid(below_pos):
					# Below cell may free space later in this frame (after its own fall step),
					# so keep this source active for vertical cascade behavior.
					fall_waiting_for_downstream = true

	# Lateral pressure spread: only when source is supported enough.
	var source_below_pos := world_pos + Vector2i(0, 1)
	var source_supported := _is_world_cell_solid(source_below_pos) or maxf(below_amount_after, below_amount_for_support) >= SOURCE_SUPPORT_MIN

	var spread_threshold := 0.08
	var allow_edge_spill := amount >= 0.58
	if amount > spread_threshold and (source_supported or allow_edge_spill):
		var dirs := [1, -1]
		if ((world_pos.x + world_pos.y) & 1) == 0:
			dirs = [-1, 1]

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
			var side_capacity := maxf(0.0, 0.92 - side_amount)
			var side_flow := minf(maxf(0.0, amount - spread_target), side_capacity)
			side_flow = minf(side_flow, 0.04 + (1.0 - viscosity) * 0.03)
			side_flow = minf(side_flow, MAX_SIDE_FLOW_PER_STEP)
			if spill_edge:
				side_flow *= 0.35
				# Ensure ledge spill is not quantized to zero.
				if side_flow > LIQUID_EPSILON:
					side_flow = maxf(side_flow, SIDE_FLOW_QUANTUM)
			side_flow = _quantize_transfer(side_flow, minf(amount, side_capacity), SIDE_FLOW_QUANTUM)
			if side_flow <= LIQUID_EPSILON:
				continue

			amount -= side_flow
			_set_cell_entry(side_pos, liquid_type, side_amount + side_flow, changed_chunks)
			moved = true
			_wake_neighborhood(side_pos)

	if amount <= LIQUID_EPSILON:
		_set_cell_entry(world_pos, "", 0.0, changed_chunks)
	else:
		_set_cell_entry(world_pos, liquid_type, amount, changed_chunks)

	if fall_blocked_by_cooldown:
		# Keep this cell alive in active queue so cooldown-based falling resumes.
		_enqueue_active(world_pos)
	elif fall_waiting_for_downstream:
		# Prioritize downstream progress to avoid local requeue starvation.
		_enqueue_active(world_pos + Vector2i(0, 1))

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

	if amount <= LIQUID_EPSILON:
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

func _is_local_pos_valid(local_pos: Vector2i) -> bool:
	return local_pos.x >= 0 and local_pos.x < CHUNK_SIZE and local_pos.y >= 0 and local_pos.y < CHUNK_SIZE

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
	return get_node_or_null("/root/WorldTopology")

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
		return _runtime_liquid_layer

	if not ("layer_1" in generator):
		return null
	var base_layer = generator.layer_1
	if not (base_layer is TileMapLayer):
		return null

	var existing = generator.get_node_or_null("LiquidRuntimeLayer")
	if existing is TileMapLayer:
		_runtime_liquid_layer = existing
		return _runtime_liquid_layer

	var runtime_layer := TileMapLayer.new()
	runtime_layer.name = "LiquidRuntimeLayer"
	runtime_layer.tile_set = base_layer.tile_set
	runtime_layer.collision_enabled = false
	runtime_layer.y_sort_enabled = false
	runtime_layer.z_index = base_layer.z_index + 1
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
		return _runtime_liquid_overlay

	var overlay := LiquidOverlay.new()
	overlay.name = "LiquidOverlay"
	var base_layer := _get_liquid_layer()
	if base_layer != null:
		overlay.z_index = base_layer.z_index + 2
		if base_layer.tile_set != null:
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
