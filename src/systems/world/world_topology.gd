extends Node

const TOPOLOGY_MODE_LEGACY := "legacy_infinite"
const TOPOLOGY_MODE_PLANETARY := "planetary_v1"
const TOPOLOGY_VERSION := 1
const WORLDGEN_CONTRACT_REVISION := 3
const DEFAULT_WORLD_SIZE_PRESET := "medium"
const CHUNK_SIZE := 64
const TILE_SIZE := 16
const DEPTH_REFERENCE_SURFACE_Y := 300
const PRELOAD_BATCH_SIZE_BY_PRESET := {
	"small": 64,
	"medium": 96,
	"large": 128,
}
const PRELOAD_TIMEOUT_SEC_BY_PRESET := {
	"small": 600.0,
	"medium": 1200.0,
	"large": 2400.0,
}

const WORLD_SIZE_PRESETS := {
	"small": {
		"circumference_chunks": 96, # ~6144 tiles (Terraria Small+ / Medium)
		"spawn_safe_radius_chunks": 4,
		"seam_buffer_chunks": 6,
		"transition_chunks": 4,
		"surface_landmark_budget": 3,
		"underground_landmark_budget": 3,
		"bedrock_start_depth": 900,
		"bedrock_hard_floor_depth": 1040,
	},
	"medium": {
		"circumference_chunks": 144, # ~9216 tiles (Terraria Large)
		"spawn_safe_radius_chunks": 6,
		"seam_buffer_chunks": 8,
		"transition_chunks": 5,
		"surface_landmark_budget": 5,
		"underground_landmark_budget": 5,
		"bedrock_start_depth": 1700,
		"bedrock_hard_floor_depth": 1900,
	},
	"large": {
		"circumference_chunks": 256, # ~16384 tiles (Huge / 2x Terraria Large)
		"spawn_safe_radius_chunks": 8,
		"seam_buffer_chunks": 12,
		"transition_chunks": 8,
		"surface_landmark_budget": 7,
		"underground_landmark_budget": 7,
		"bedrock_start_depth": 2500,
		"bedrock_hard_floor_depth": 2820,
	},
}

const DEPTH_BANDS := [
	{"id": "surface", "min_depth": -1000000.0, "max_depth": 28.0},
	{"id": "shallow_underground", "min_depth": 28.0, "max_depth": 120.0},
	{"id": "mid_cavern", "min_depth": 120.0, "max_depth": 420.0},
	{"id": "deep", "min_depth": 420.0, "max_depth": 980.0},
	{"id": "terminal", "min_depth": 980.0, "max_depth": 1000000.0},
]

const WorldStructurePlanner = preload("res://src/systems/world/world_structure_planner.gd")

var current_metadata: Dictionary = {}
var world_plan: Dictionary = {}

func _ready() -> void:
	reset_to_legacy()

# --- Topology Query API (Single Source of Truth) ---

func is_planetary() -> bool:
	return current_metadata.get("topology_mode", "") == TOPOLOGY_MODE_PLANETARY

func get_circumference_chunks() -> int:
	return int(current_metadata.get("horizontal_circumference_in_chunks", 0))

func get_circumference_tiles() -> int:
	return get_circumference_chunks() * CHUNK_SIZE

func get_circumference_pixels() -> float:
	return float(get_circumference_tiles() * TILE_SIZE)

func wrap_x(x: float) -> float:
	if not is_planetary():
		return x
	var circ = get_circumference_pixels()
	if circ <= 0: return x
	# Wrap logic: fposmod behaves correctly for negative numbers
	return fposmod(x, circ)

func wrap_tile_x(tx: int) -> int:
	if not is_planetary():
		return tx
	var circ = get_circumference_tiles()
	if circ <= 0: return tx
	return posmod(tx, circ)

func wrap_chunk_x(cx: int) -> int:
	if not is_planetary():
		return cx
	var circ = get_circumference_chunks()
	if circ <= 0: return cx
	return posmod(cx, circ)

func wrap_vector(pos: Vector2) -> Vector2:
	return Vector2(wrap_x(pos.x), pos.y)

## Calculates shortest signed distance from A to B on x-axis.
## Returns positive if B is "right" of A, negative if "left".
## Range: [-circumference/2, circumference/2]
func distance_x(from_x: float, to_x: float) -> float:
	if not is_planetary():
		return to_x - from_x
	
	var circ = get_circumference_pixels()
	if circ <= 0: return to_x - from_x
	
	var diff = fposmod(to_x - from_x, circ)
	if diff > circ * 0.5:
		return diff - circ
	return diff

func get_chunk_coords_in_range(center_chunk_x: int, radius: int) -> Array[int]:
	var result: Array[int] = []
	if is_planetary():
		var circ = get_circumference_chunks()
		if circ <= 0: # Safety fallback
			for i in range(-radius, radius + 1):
				result.append(center_chunk_x + i)
			return result
			
		for i in range(-radius, radius + 1):
			result.append(wrap_chunk_x(center_chunk_x + i))
	else:
		for i in range(-radius, radius + 1):
			result.append(center_chunk_x + i)
	return result

# ---------------------------------------------------------

func reset_to_legacy(seed: int = 0) -> void:
	current_metadata = {
		"primary_seed": seed,
		"topology_mode": TOPOLOGY_MODE_LEGACY,
		"topology_version": 0,
		"horizontal_circumference_in_chunks": 0,
		"world_size_preset": "legacy",
		"spawn_anchor_chunk": 0,
		"spawn_safe_radius_chunks": 0,
		"seam_buffer_chunks": 0,
		"world_plan_revision": 0,
		"worldgen_contract_revision": 0,
		"depth_boundary_enabled": false,
		"depth_reference_surface_y": DEPTH_REFERENCE_SURFACE_Y,
		"bedrock_start_depth": 0,
		"bedrock_hard_floor_depth": 0,
		"underworld_layer_enabled": false,
		"underworld_layer_revision": 0,
	}
	world_plan = {
		"surface_regions": [],
		"landmarks": [],
		"depth_bands": DEPTH_BANDS.duplicate(true),
	}

func create_new_world(seed: int, world_size_preset: String = DEFAULT_WORLD_SIZE_PRESET, topology_mode: String = TOPOLOGY_MODE_PLANETARY) -> Dictionary:
	if topology_mode != TOPOLOGY_MODE_PLANETARY:
		reset_to_legacy(seed)
		return get_current_metadata()

	var preset_info := _get_world_size_preset_info(world_size_preset)
	var circumference_chunks := int(preset_info.get("circumference_chunks", 384))
	var spawn_safe_radius_chunks := int(preset_info.get("spawn_safe_radius_chunks", 16))
	var seam_buffer_chunks := int(preset_info.get("seam_buffer_chunks", 20))
	var spawn_anchor_chunk := int(circumference_chunks / 4)

	var metadata := {
		"primary_seed": seed,
		"topology_mode": TOPOLOGY_MODE_PLANETARY,
		"topology_version": TOPOLOGY_VERSION,
		"horizontal_circumference_in_chunks": circumference_chunks,
		"world_size_preset": String(preset_info.get("id", world_size_preset)),
		"spawn_anchor_chunk": spawn_anchor_chunk,
		"spawn_safe_radius_chunks": spawn_safe_radius_chunks,
		"seam_buffer_chunks": seam_buffer_chunks,
		"world_plan_revision": 1,
		"worldgen_contract_revision": WORLDGEN_CONTRACT_REVISION,
		"depth_boundary_enabled": true,
		"depth_reference_surface_y": DEPTH_REFERENCE_SURFACE_Y,
		"bedrock_start_depth": int(preset_info.get("bedrock_start_depth", 500)),
		"bedrock_hard_floor_depth": int(preset_info.get("bedrock_hard_floor_depth", 620)),
		"underworld_layer_enabled": true,
		"underworld_layer_revision": 2,
		"underworld_horizontal_coverage_ratio": 1.0,
		"underworld_min_vertical_span": 180,
		"underworld_ore_uplift_multiplier": 1.30,
	}
	metadata["underworld_anchor_chunk"] = posmod(spawn_anchor_chunk, circumference_chunks)
	metadata["underworld_primary_route_chunk"] = metadata["underworld_anchor_chunk"]
	
	# Generate Structure Plan (Dungeon, Jungle, Temple Locations)
	metadata["structure_plan"] = WorldStructurePlanner.generate_plan(
		seed,
		circumference_chunks,
		spawn_anchor_chunk,
		preset_info
	)
	
	load_world_metadata(metadata)
	return get_current_metadata()

func load_world_metadata(metadata: Dictionary) -> void:
	var incoming := metadata.duplicate(true)
	var topology_mode := String(incoming.get("topology_mode", TOPOLOGY_MODE_LEGACY))
	var primary_seed := int(incoming.get("primary_seed", incoming.get("world_seed", 0)))

	if topology_mode != TOPOLOGY_MODE_PLANETARY:
		reset_to_legacy(primary_seed)
		return

	var preset := String(incoming.get("world_size_preset", DEFAULT_WORLD_SIZE_PRESET))
	var preset_info := _get_world_size_preset_info(preset)
	incoming["primary_seed"] = primary_seed
	incoming["topology_mode"] = TOPOLOGY_MODE_PLANETARY
	incoming["topology_version"] = int(incoming.get("topology_version", TOPOLOGY_VERSION))
	incoming["horizontal_circumference_in_chunks"] = int(incoming.get("horizontal_circumference_in_chunks", preset_info.get("circumference_chunks", 384)))
	incoming["world_size_preset"] = String(preset_info.get("id", DEFAULT_WORLD_SIZE_PRESET))
	incoming["spawn_anchor_chunk"] = int(incoming.get("spawn_anchor_chunk", int(incoming["horizontal_circumference_in_chunks"]) / 4))
	incoming["spawn_safe_radius_chunks"] = int(incoming.get("spawn_safe_radius_chunks", preset_info.get("spawn_safe_radius_chunks", 16)))
	incoming["seam_buffer_chunks"] = int(incoming.get("seam_buffer_chunks", preset_info.get("seam_buffer_chunks", 20)))
	incoming["world_plan_revision"] = int(incoming.get("world_plan_revision", 1))
	incoming["worldgen_contract_revision"] = int(incoming.get("worldgen_contract_revision", WORLDGEN_CONTRACT_REVISION))
	# 旧存档缺少该字段时默认关闭封底规则，保持兼容行为。
	var boundary_enabled := bool(incoming.get("depth_boundary_enabled", false))
	incoming["depth_boundary_enabled"] = boundary_enabled
	incoming["depth_reference_surface_y"] = int(incoming.get("depth_reference_surface_y", DEPTH_REFERENCE_SURFACE_Y))
	incoming["bedrock_start_depth"] = int(incoming.get("bedrock_start_depth", preset_info.get("bedrock_start_depth", 500)))
	incoming["bedrock_hard_floor_depth"] = int(incoming.get("bedrock_hard_floor_depth", preset_info.get("bedrock_hard_floor_depth", 620)))

	# Legacy compatibility: old saves without this field auto-enable underworld metadata.
	var underworld_enabled := bool(incoming.get("underworld_layer_enabled", true))
	incoming["underworld_layer_enabled"] = underworld_enabled
	incoming["underworld_layer_revision"] = int(incoming.get("underworld_layer_revision", 2 if underworld_enabled else 0))
	incoming["underworld_horizontal_coverage_ratio"] = float(incoming.get("underworld_horizontal_coverage_ratio", 1.0))
	incoming["underworld_min_vertical_span"] = int(incoming.get("underworld_min_vertical_span", 180))
	incoming["underworld_ore_uplift_multiplier"] = float(incoming.get("underworld_ore_uplift_multiplier", 1.30))
	var incoming_circumference := maxi(int(incoming.get("horizontal_circumference_in_chunks", 0)), 1)
	if not incoming.has("underworld_anchor_chunk"):
		incoming["underworld_anchor_chunk"] = posmod(int(incoming["spawn_anchor_chunk"]), incoming_circumference)
	else:
		incoming["underworld_anchor_chunk"] = posmod(int(incoming["underworld_anchor_chunk"]), incoming_circumference)
	if not incoming.has("underworld_primary_route_chunk"):
		incoming["underworld_primary_route_chunk"] = incoming["underworld_anchor_chunk"]
	else:
		incoming["underworld_primary_route_chunk"] = posmod(int(incoming["underworld_primary_route_chunk"]), incoming_circumference)

	# Migration guard: normalize pre-v2 underworld placement to spawn-side full coverage.
	if underworld_enabled and int(incoming.get("underworld_layer_revision", 0)) < 2:
		incoming["underworld_layer_revision"] = 2
		incoming["underworld_horizontal_coverage_ratio"] = 1.0
		incoming["underworld_anchor_chunk"] = posmod(int(incoming["spawn_anchor_chunk"]), incoming_circumference)
		incoming["underworld_primary_route_chunk"] = incoming["underworld_anchor_chunk"]

	current_metadata = incoming
	world_plan = _build_world_plan(current_metadata)
	_rebuild_region_fast_lookup()

var _region_lookup_table: Array = []
var _lookup_table_circumference: int = -1

func _rebuild_region_fast_lookup() -> void:
	if not is_planetary():
		_region_lookup_table.clear()
		_lookup_table_circumference = -1
		return
		
	var circumference := get_circumference_chunks()
	if circumference <= 0:
		_region_lookup_table.clear()
		return
		
	_lookup_table_circumference = circumference
	_region_lookup_table.clear()
	_region_lookup_table.resize(circumference)
	# Initialize with empty dictionaries
	for i in range(circumference):
		_region_lookup_table[i] = {}
	
	# Populate based on priority. Sort regions by priority first to update in order?
	# Or simpler: just overwrite if priority is higher.
	var regions = world_plan.get("surface_regions", [])
	
	for region in regions:
		var start := int(region.get("start", -1))
		var end := int(region.get("end", -1))
		var prio := int(region.get("priority", 0))
		
		# Handle regular and wrapped ranges
		var length := 0
		if end >= start:
			length = end - start + 1
		else:
			length = (circumference - start) + end + 1
			
		for i in range(length):
			var idx := (start + i) % circumference
			# Check existing
			var existing = _region_lookup_table[idx]
			if existing.is_empty() or int(existing.get("priority", -1)) < prio:
				_region_lookup_table[idx] = region

func get_current_metadata() -> Dictionary:
	return current_metadata.duplicate(true)

func get_save_metadata() -> Dictionary:
	return get_current_metadata()

func get_world_size_preset() -> String:
	return String(current_metadata.get("world_size_preset", "legacy"))

func get_spawn_anchor_chunk() -> int:
	return int(current_metadata.get("spawn_anchor_chunk", 0))

func get_spawn_anchor_tile() -> int:
	return get_spawn_anchor_chunk() * CHUNK_SIZE + int(CHUNK_SIZE / 2)

func get_spawn_safe_radius_chunks() -> int:
	return int(current_metadata.get("spawn_safe_radius_chunks", 0))

func get_depth_bands() -> Array:
	return DEPTH_BANDS.duplicate(true)

func get_depth_band_for_depth(depth: float) -> Dictionary:
	for band in DEPTH_BANDS:
		if depth >= float(band.get("min_depth", -1000000.0)) and depth < float(band.get("max_depth", 1000000.0)):
			return band.duplicate(true)
	return DEPTH_BANDS[DEPTH_BANDS.size() - 1].duplicate(true)

func get_depth_band_id_for_depth(depth: float) -> String:
	return String(get_depth_band_for_depth(depth).get("id", "surface"))

func is_depth_boundary_enabled() -> bool:
	# Force enabled for planetary mode, even if metadata lags
	if is_planetary():
		return true
	return bool(current_metadata.get("depth_boundary_enabled", false))

func get_depth_reference_surface_y() -> int:
	return int(current_metadata.get("depth_reference_surface_y", DEPTH_REFERENCE_SURFACE_Y))

func _get_default_bedrock_depth(key: String, default: int) -> int:
	var preset = String(current_metadata.get("world_size_preset", DEFAULT_WORLD_SIZE_PRESET))
	if WORLD_SIZE_PRESETS.has(preset):
		return int(WORLD_SIZE_PRESETS[preset].get(key, default))
	return default

func get_bedrock_start_depth() -> int:
	var depth = int(current_metadata.get("bedrock_start_depth", 0))
	if depth <= 0 and is_planetary():
		return _get_default_bedrock_depth("bedrock_start_depth", 500)
	return depth

func get_bedrock_hard_floor_depth() -> int:
	var depth = int(current_metadata.get("bedrock_hard_floor_depth", 0))
	if depth <= 0 and is_planetary():
		return _get_default_bedrock_depth("bedrock_hard_floor_depth", 620)
	return depth

func get_bedrock_start_global_y() -> int:
	return get_depth_reference_surface_y() + get_bedrock_start_depth()

func get_bedrock_hard_floor_global_y() -> int:
	return get_depth_reference_surface_y() + get_bedrock_hard_floor_depth()

func is_global_y_at_or_below_hard_floor(global_y: int) -> bool:
	if not is_depth_boundary_enabled():
		return false
	return global_y >= get_bedrock_hard_floor_global_y()

func is_chunk_below_hard_floor(coord: Vector2i) -> bool:
	if not is_depth_boundary_enabled():
		return false
	var chunk_top_global_y := coord.y * CHUNK_SIZE
	return chunk_top_global_y > get_bedrock_hard_floor_global_y()

func get_bedrock_transition_ratio_for_depth(depth: float) -> float:
	if not is_depth_boundary_enabled():
		return 0.0
	var start_depth := float(get_bedrock_start_depth())
	var hard_floor_depth := float(get_bedrock_hard_floor_depth())
	if hard_floor_depth <= start_depth:
		return 1.0 if depth >= hard_floor_depth else 0.0
	return clampf((depth - start_depth) / (hard_floor_depth - start_depth), 0.0, 1.0)

func get_bedrock_boundary_config() -> Dictionary:
	return {
		"enabled": is_depth_boundary_enabled(),
		"depth_reference_surface_y": get_depth_reference_surface_y(),
		"bedrock_start_depth": get_bedrock_start_depth(),
		"bedrock_hard_floor_depth": get_bedrock_hard_floor_depth(),
		"bedrock_start_global_y": get_bedrock_start_global_y(),
		"bedrock_hard_floor_global_y": get_bedrock_hard_floor_global_y(),
	}

func is_underworld_layer_enabled() -> bool:
	return bool(current_metadata.get("underworld_layer_enabled", false))

func get_underworld_generation_config() -> Dictionary:
	if not is_planetary():
		return {
			"enabled": false,
		}
	var circumference_chunks := get_circumference_chunks()
	var anchor_chunk := wrap_chunk_x(int(current_metadata.get("underworld_anchor_chunk", int(circumference_chunks / 2))))
	var route_chunk := wrap_chunk_x(int(current_metadata.get("underworld_primary_route_chunk", anchor_chunk)))
	return {
		"enabled": is_underworld_layer_enabled(),
		"revision": int(current_metadata.get("underworld_layer_revision", 0)),
		"anchor_chunk": anchor_chunk,
		"anchor_tile": anchor_chunk * CHUNK_SIZE + int(CHUNK_SIZE / 2),
		"primary_route_chunk": route_chunk,
		"primary_route_tile": route_chunk * CHUNK_SIZE + int(CHUNK_SIZE / 2),
		"horizontal_coverage_ratio": clampf(float(current_metadata.get("underworld_horizontal_coverage_ratio", 1.0)), 0.50, 1.0),
		"min_vertical_span": maxi(int(current_metadata.get("underworld_min_vertical_span", 180)), 180),
		"ore_uplift_multiplier": maxf(float(current_metadata.get("underworld_ore_uplift_multiplier", 1.30)), 1.0),
	}

func canonical_chunk_coord(coord: Vector2i) -> Vector2i:
	if not is_planetary():
		return coord
	return Vector2i(wrap_chunk_x(coord.x), coord.y)

func canonical_chunk_key(coord: Vector2i) -> String:
	var canonical := canonical_chunk_coord(coord)
	return "%d,%d" % [canonical.x, canonical.y]

func shortest_wrapped_chunk_distance(a: int, b: int) -> int:
	if not is_planetary():
		return absi(a - b)
	var circumference := get_circumference_chunks()
	if circumference <= 0:
		return absi(a - b)
	var diff := posmod(a - b, circumference)
	return mini(diff, circumference - diff)

func shortest_wrapped_tile_distance(a: int, b: int) -> int:
	if not is_planetary():
		return absi(a - b)
	var circumference_tiles := get_circumference_tiles()
	if circumference_tiles <= 0:
		return absi(a - b)
	var diff := posmod(a - b, circumference_tiles)
	return mini(diff, circumference_tiles - diff)

func is_spawn_safe_tile_x(tile_x: int) -> bool:
	if not is_planetary():
		return absi(tile_x) < CHUNK_SIZE * 2
	var chunk_x := int(floor(float(tile_x) / CHUNK_SIZE))
	return shortest_wrapped_chunk_distance(chunk_x, get_spawn_anchor_chunk()) <= get_spawn_safe_radius_chunks()

func get_surface_region_for_tile_x(tile_x: int) -> Dictionary:
	if not is_planetary():
		return {}
	var chunk_x := wrap_chunk_x(int(floor(float(tile_x) / CHUNK_SIZE)))
	return get_surface_region_for_chunk(chunk_x)


func get_surface_region_for_chunk(chunk_x: int) -> Dictionary:
	if not is_planetary():
		return {}

	# Fast path: O(1) Lookup
	var wrapped_chunk_x := wrap_chunk_x(chunk_x)
	var circumference := get_circumference_chunks()
	
	if _region_lookup_table.size() == circumference and _lookup_table_circumference == circumference:
		var cached = _region_lookup_table[wrapped_chunk_x]
		if typeof(cached) == TYPE_DICTIONARY and not cached.is_empty():
			return cached # Return REFERENCE. Do not duplicate.
		return {}

	# Fallback (Slow Path) - if cache invalid or empty region
	# Linear search is fine for < 100 regions. For massive worlds, spatial partitioning needed.
	var best_region := {}
	var best_prio := -1
	
	for region in world_plan.get("surface_regions", []):
		# Planner provides "start" and "end" (inclusive)
		var r_start := int(region.get("start", -1))
		var r_end := int(region.get("end", -1))
		
		if r_start == -1 or r_end == -1:
			continue
			
		if wrapped_chunk_x >= r_start and wrapped_chunk_x <= r_end:
			var prio := int(region.get("priority", 0))
			if prio > best_prio:
				best_prio = prio
				best_region = region
	
	if not best_region.is_empty():
		return best_region # Return REFERENCE.
		
	return {}

func get_surface_biome_name_at_tile_x(tile_x: int) -> String:
	var region := get_surface_region_for_tile_x(tile_x)
	if region.is_empty():
		return ""
	return String(region.get("biome", "forest"))

func get_underground_theme_at_tile_x(tile_x: int) -> String:
	var region := get_surface_region_for_tile_x(tile_x)
	if region.is_empty():
		return "temperate"
	return String(region.get("underground_theme", "temperate"))

func get_hazard_bias_at_tile_x(tile_x: int) -> String:
	var region := get_surface_region_for_tile_x(tile_x)
	if region.is_empty():
		return "low"
	return String(region.get("hazard_bias", "low"))

func get_landmarks_for_display_chunk(display_coord: Vector2i) -> Array:
	var results: Array = []
	if not is_planetary():
		return results

	var canonical := canonical_chunk_coord(display_coord)
	var loop_offset := display_coord.x - canonical.x
	for landmark in world_plan.get("landmarks", []):
		if int(landmark.get("chunk_x", -99999)) != canonical.x:
			continue
		var min_chunk_y := int(landmark.get("min_chunk_y", -99999))
		var max_chunk_y := int(landmark.get("max_chunk_y", 99999))
		if display_coord.y < min_chunk_y or display_coord.y > max_chunk_y:
			continue
		var resolved: Dictionary = landmark.duplicate(true)
		resolved["display_chunk_x"] = int(landmark.get("chunk_x", 0)) + loop_offset
		resolved["display_world_tile_x"] = int(resolved.get("display_chunk_x", 0)) * CHUNK_SIZE + int(landmark.get("local_x", int(CHUNK_SIZE / 2)))
		results.append(resolved)
	return results

func get_nearest_landmark(tile_x: int, kind_filter: String = "") -> Dictionary:
	if not is_planetary():
		return {}
	var wrapped_tile_x := wrap_tile_x(tile_x)
	var nearest: Dictionary = {}
	var nearest_distance := 2147483647
	for landmark in world_plan.get("landmarks", []):
		if kind_filter != "" and String(landmark.get("kind", "")) != kind_filter:
			continue
		var landmark_tile_x := int(landmark.get("chunk_x", 0)) * CHUNK_SIZE + int(landmark.get("local_x", int(CHUNK_SIZE / 2)))
		var distance := shortest_wrapped_tile_distance(wrapped_tile_x, landmark_tile_x)
		if distance < nearest_distance:
			nearest = landmark.duplicate(true)
			nearest["distance_tiles"] = distance
			nearest_distance = distance
	return nearest

func get_underground_generation_rules() -> Dictionary:
	if not is_planetary():
		return {
			"planned_hazards": [],
			"local_generated": ["noise_caves", "noise_ores"],
		}
	return world_plan.get("underground_rules", {}).duplicate(true)

func get_world_storage_prefix() -> String:
	var seed := int(current_metadata.get("primary_seed", 0))
	if is_planetary():
		return "%s_%s_%d_%d_%d_%d" % [
			String(current_metadata.get("topology_mode", TOPOLOGY_MODE_PLANETARY)),
			String(current_metadata.get("world_size_preset", DEFAULT_WORLD_SIZE_PRESET)),
			int(current_metadata.get("horizontal_circumference_in_chunks", 0)),
			int(current_metadata.get("topology_version", TOPOLOGY_VERSION)),
			int(current_metadata.get("world_plan_revision", 1)),
			seed,
		]
	return "%s_%d" % [String(current_metadata.get("topology_mode", TOPOLOGY_MODE_LEGACY)), seed]

func get_preload_timeout_seconds() -> float:
	if not is_planetary():
		return 0.0
	var preset := get_world_size_preset()
	if PRELOAD_TIMEOUT_SEC_BY_PRESET.has(preset):
		return float(PRELOAD_TIMEOUT_SEC_BY_PRESET.get(preset, 1200.0))
	return float(PRELOAD_TIMEOUT_SEC_BY_PRESET.get(DEFAULT_WORLD_SIZE_PRESET, 1200.0))

func get_preload_batch_size() -> int:
	if not is_planetary():
		return 0
	var preset := get_world_size_preset()
	if PRELOAD_BATCH_SIZE_BY_PRESET.has(preset):
		return int(PRELOAD_BATCH_SIZE_BY_PRESET.get(preset, 96))
	return int(PRELOAD_BATCH_SIZE_BY_PRESET.get(DEFAULT_WORLD_SIZE_PRESET, 96))

func get_preload_domain_definition() -> Dictionary:
	if not is_planetary():
		return {
			"required": false,
			"domain_type": "legacy_spawn_warmup_fallback",
			"topology_mode": TOPOLOGY_MODE_LEGACY,
			"min_chunk_y": 0,
			"max_chunk_y": 0,
			"x_start": 0,
			"x_count": 0,
			"mandatory_chunk_total": 0,
			"identity": get_preload_domain_identity(),
		}

	var circumference := maxi(get_circumference_chunks(), 0)
	var hard_floor_global_y := get_bedrock_hard_floor_global_y()
	
	# [Fix] Limit preload depth to avoid excessive loading on deep presets
	# Clamp to ~12 chunks (768 tiles) below surface reference = ~1068 total Y
	var preload_limit_y_tiles := get_depth_reference_surface_y() + (12 * CHUNK_SIZE)
	var effective_max_y := mini(hard_floor_global_y, preload_limit_y_tiles)
	
	var min_chunk_y := 0
	var max_chunk_y := int(floor(float(effective_max_y) / float(CHUNK_SIZE)))
	if max_chunk_y < min_chunk_y:
		max_chunk_y = min_chunk_y
	var mandatory_chunk_total := circumference * (max_chunk_y - min_chunk_y + 1)

	return {
		"required": true,
		"domain_type": "planetary_full_world",
		"topology_mode": TOPOLOGY_MODE_PLANETARY,
		"min_chunk_y": min_chunk_y,
		"max_chunk_y": max_chunk_y,
		"x_start": 0,
		"x_count": circumference,
		"mandatory_chunk_total": mandatory_chunk_total,
		"identity": get_preload_domain_identity(),
	}

func get_preload_domain_identity() -> Dictionary:
	var min_chunk_y := 0
	var max_chunk_y := 0
	var x_count := 0
	if is_planetary():
		x_count = maxi(get_circumference_chunks(), 0)
		max_chunk_y = int(floor(float(get_bedrock_hard_floor_global_y()) / float(CHUNK_SIZE)))
		if max_chunk_y < min_chunk_y:
			max_chunk_y = min_chunk_y

	var preload_domain := {
		"topology_mode": String(current_metadata.get("topology_mode", TOPOLOGY_MODE_LEGACY)),
		"world_size_preset": String(current_metadata.get("world_size_preset", "legacy")),
		"topology_version": int(current_metadata.get("topology_version", 0)),
		"world_plan_revision": int(current_metadata.get("world_plan_revision", 0)),
		"worldgen_contract_revision": int(current_metadata.get("worldgen_contract_revision", WORLDGEN_CONTRACT_REVISION)),
		"primary_seed": int(current_metadata.get("primary_seed", 0)),
		"horizontal_circumference_in_chunks": int(current_metadata.get("horizontal_circumference_in_chunks", 0)),
		"depth_boundary_enabled": bool(current_metadata.get("depth_boundary_enabled", false)),
		"bedrock_hard_floor_depth": int(current_metadata.get("bedrock_hard_floor_depth", 0)),
		"min_chunk_y": min_chunk_y,
		"max_chunk_y": max_chunk_y,
		"x_count": x_count,
	}
	return preload_domain

func get_preload_domain_signature() -> String:
	var identity := get_preload_domain_identity()
	return "%s|%s|%d|%d|%d|%d|%d|%d|%d|%d" % [
		String(identity.get("topology_mode", TOPOLOGY_MODE_LEGACY)),
		String(identity.get("world_size_preset", "legacy")),
		int(identity.get("topology_version", 0)),
		int(identity.get("world_plan_revision", 0)),
		int(identity.get("worldgen_contract_revision", WORLDGEN_CONTRACT_REVISION)),
		int(identity.get("primary_seed", 0)),
		int(identity.get("horizontal_circumference_in_chunks", 0)),
		int(identity.get("min_chunk_y", 0)),
		int(identity.get("max_chunk_y", 0)),
		int(identity.get("bedrock_hard_floor_depth", 0)),
	]

func _get_world_size_preset_info(world_size_preset: String) -> Dictionary:
	if WORLD_SIZE_PRESETS.has(world_size_preset):
		var info: Dictionary = WORLD_SIZE_PRESETS[world_size_preset].duplicate(true)
		info["id"] = world_size_preset
		return info
	var fallback: Dictionary = WORLD_SIZE_PRESETS[DEFAULT_WORLD_SIZE_PRESET].duplicate(true)
	fallback["id"] = DEFAULT_WORLD_SIZE_PRESET
	return fallback

func _build_world_plan(metadata: Dictionary) -> Dictionary:
	# If a structure plan exists in metadata (from WorldStructurePlanner), use it.
	if metadata.has("structure_plan"):
		var sp = metadata["structure_plan"].duplicate(true)
		# Ensure required fields exist
		if not sp.has("depth_bands"):
			sp["depth_bands"] = DEPTH_BANDS.duplicate(true)
		if not sp.has("underground_rules"):
			sp["underground_rules"] = {}
		return sp

	# Fallback for old saves or initialization without planner
	var plan := {
		"surface_regions": [],
		"landmarks": [],
		"depth_bands": DEPTH_BANDS.duplicate(true),
		"underground_rules": {},
	}
	if String(metadata.get("topology_mode", TOPOLOGY_MODE_LEGACY)) != TOPOLOGY_MODE_PLANETARY:
		return plan

	var preset_info := _get_world_size_preset_info(String(metadata.get("world_size_preset", DEFAULT_WORLD_SIZE_PRESET)))
	var circumference_chunks := int(metadata.get("horizontal_circumference_in_chunks", preset_info.get("circumference_chunks", 384)))
	var spawn_anchor_chunk := int(metadata.get("spawn_anchor_chunk", int(circumference_chunks / 4)))
	var spawn_safe_radius_chunks := int(metadata.get("spawn_safe_radius_chunks", preset_info.get("spawn_safe_radius_chunks", 16)))
	var transition_chunks := int(preset_info.get("transition_chunks", 8))
	var spawn_length := spawn_safe_radius_chunks * 2 + 1
	var spawn_start := wrap_chunk_x(spawn_anchor_chunk - spawn_safe_radius_chunks)
	var cursor := spawn_start
	var surface_regions: Array = []

	surface_regions.append(_make_region(cursor, spawn_length, "forest", "temperate", "low", "major", true))
	cursor = wrap_chunk_x(cursor + spawn_length)

	var biome_sequence := ["plains", "desert", "swamp", "tundra", "plains"]
	biome_sequence = _rotate_biome_sequence(biome_sequence, int(metadata.get("primary_seed", 0)))
	var remaining_chunks := circumference_chunks - spawn_length - transition_chunks * biome_sequence.size()
	var major_base_length := maxi(20, int(floor(float(maxi(remaining_chunks, biome_sequence.size())) / float(biome_sequence.size()))))
	var leftover := maxi(0, remaining_chunks - major_base_length * biome_sequence.size())

	for biome_name in biome_sequence:
		surface_regions.append(_make_region(cursor, transition_chunks, biome_name, _get_underground_theme_for_biome(biome_name), "medium", "transition", false))
		cursor = wrap_chunk_x(cursor + transition_chunks)
		var region_length := major_base_length
		if leftover > 0:
			region_length += 1
			leftover -= 1
		surface_regions.append(_make_region(cursor, region_length, biome_name, _get_underground_theme_for_biome(biome_name), _get_hazard_bias_for_biome(biome_name), "major", false))
		cursor = wrap_chunk_x(cursor + region_length)

	plan["surface_regions"] = surface_regions
	plan["landmarks"] = _build_landmarks(metadata, surface_regions, preset_info)
	plan["underground_rules"] = {
		"planned_hazards": ["core_ruin"],
		"local_generated": ["cave_pockets", "resource_clusters", "regional_hazard_bias"],
		"terminal_band_behavior": "hard_rock_boundary_with_sparse_pockets",
	}
	return plan

func _build_landmarks(metadata: Dictionary, surface_regions: Array, preset_info: Dictionary) -> Array:
	var landmarks: Array = []
	var circumference_chunks := int(metadata.get("horizontal_circumference_in_chunks", preset_info.get("circumference_chunks", 384)))
	var spawn_anchor_chunk := int(metadata.get("spawn_anchor_chunk", int(circumference_chunks / 4)))
	var spawn_safe_radius_chunks := int(metadata.get("spawn_safe_radius_chunks", preset_info.get("spawn_safe_radius_chunks", 16)))
	var seam_buffer_chunks := int(metadata.get("seam_buffer_chunks", preset_info.get("seam_buffer_chunks", 20)))

	var surface_center := wrap_chunk_x(spawn_anchor_chunk + maxi(4, int(spawn_safe_radius_chunks / 2)))
	landmarks.append({
		"id": "spawn_village",
		"category": "unique",
		"kind": "surface_village",
		"chunk_x": surface_center,
		"local_x": 32,
		"min_chunk_y": 4,
		"max_chunk_y": 7,
	})

	var opposite_chunk := wrap_chunk_x(spawn_anchor_chunk + int(circumference_chunks / 2))
	landmarks.append({
		"id": "core_ruin",
		"category": "unique",
		"kind": "buried_ruin",
		"chunk_x": opposite_chunk,
		"local_x": 28,
		"local_y": 26,
		"min_chunk_y": 8,
		"max_chunk_y": 12,
	})

	for region in surface_regions:
		if String(region.get("region_type", "major")) != "major":
			continue
		if bool(region.get("spawn_safe", false)):
			continue
		var region_length := int(region.get("length", 0))
		if region_length < 24:
			continue
		var region_center := wrap_chunk_x(int(region.get("start_chunk", 0)) + int(region_length / 2))
		if shortest_wrapped_chunk_distance(region_center, spawn_anchor_chunk) <= spawn_safe_radius_chunks + 4:
			continue
		if shortest_wrapped_chunk_distance(region_center, 0) < seam_buffer_chunks:
			continue

		var biome_name := String(region.get("biome", "forest"))
		if biome_name == "forest" or biome_name == "plains":
			landmarks.append({
				"id": "surface_outpost_%d" % landmarks.size(),
				"category": "regional_rare",
				"kind": "surface_outpost",
				"chunk_x": region_center,
				"local_x": 24 + (region_center % 16),
				"min_chunk_y": 4,
				"max_chunk_y": 7,
			})
		else:
			landmarks.append({
				"id": "buried_ruin_%d" % landmarks.size(),
				"category": "regional_rare",
				"kind": "buried_ruin",
				"chunk_x": region_center,
				"local_x": 18 + (region_center % 20),
				"local_y": 18 + (region_center % 14),
				"min_chunk_y": 8,
				"max_chunk_y": 12,
			})

	return landmarks

func _make_region(start_chunk: int, length: int, biome: String, underground_theme: String, hazard_bias: String, region_type: String, spawn_safe: bool) -> Dictionary:
	return {
		"start_chunk": wrap_chunk_x(start_chunk),
		"length": maxi(length, 1),
		"biome": biome,
		"underground_theme": underground_theme,
		"hazard_bias": hazard_bias,
		"region_type": region_type,
		"spawn_safe": spawn_safe,
	}

func _rotate_biome_sequence(sequence: Array, seed: int) -> Array:
	if sequence.is_empty():
		return []
	var offset := posmod(seed, sequence.size())
	var rotated: Array = []
	for index in range(sequence.size()):
		rotated.append(sequence[(index + offset) % sequence.size()])
	return rotated

func _get_underground_theme_for_biome(biome_name: String) -> String:
	match biome_name:
		"desert":
			return "desert"
		"tundra":
			return "frozen"
		"swamp":
			return "sodden"
		"plains":
			return "open_cavern"
		_:
			return "temperate"

func _get_hazard_bias_for_biome(biome_name: String) -> String:
	match biome_name:
		"desert":
			return "heat"
		"tundra":
			return "cold"
		"swamp":
			return "toxic"
		"plains":
			return "medium"
		_:
			return "low"

func _arc_contains_chunk(chunk_x: int, start_chunk: int, length: int) -> bool:
	if length <= 0:
		return false
	if not is_planetary():
		return chunk_x >= start_chunk and chunk_x < start_chunk + length
	var circumference := get_circumference_chunks()
	if circumference <= 0:
		return false
	var relative := posmod(chunk_x - start_chunk, circumference)
	return relative >= 0 and relative < length
