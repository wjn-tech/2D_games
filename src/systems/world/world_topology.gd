extends Node

const TOPOLOGY_MODE_LEGACY := "legacy_infinite"
const TOPOLOGY_MODE_PLANETARY := "planetary_v1"
const TOPOLOGY_VERSION := 1
const DEFAULT_WORLD_SIZE_PRESET := "medium"
const CHUNK_SIZE := 64
const TILE_SIZE := 16

const WORLD_SIZE_PRESETS := {
	"small": {
		"circumference_chunks": 256,
		"spawn_safe_radius_chunks": 12,
		"seam_buffer_chunks": 16,
		"transition_chunks": 6,
		"surface_landmark_budget": 4,
		"underground_landmark_budget": 4,
	},
	"medium": {
		"circumference_chunks": 384,
		"spawn_safe_radius_chunks": 16,
		"seam_buffer_chunks": 20,
		"transition_chunks": 8,
		"surface_landmark_budget": 6,
		"underground_landmark_budget": 6,
	},
	"large": {
		"circumference_chunks": 512,
		"spawn_safe_radius_chunks": 20,
		"seam_buffer_chunks": 24,
		"transition_chunks": 10,
		"surface_landmark_budget": 8,
		"underground_landmark_budget": 8,
	},
}

const DEPTH_BANDS := [
	{"id": "surface", "min_depth": -1000000.0, "max_depth": 28.0},
	{"id": "shallow_underground", "min_depth": 28.0, "max_depth": 120.0},
	{"id": "mid_cavern", "min_depth": 120.0, "max_depth": 260.0},
	{"id": "deep", "min_depth": 260.0, "max_depth": 420.0},
	{"id": "terminal", "min_depth": 420.0, "max_depth": 1000000.0},
]

var current_metadata: Dictionary = {}
var world_plan: Dictionary = {}

func _ready() -> void:
	reset_to_legacy()

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
	}
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

	current_metadata = incoming
	world_plan = _build_world_plan(current_metadata)

func get_current_metadata() -> Dictionary:
	return current_metadata.duplicate(true)

func get_save_metadata() -> Dictionary:
	return get_current_metadata()

func is_planetary() -> bool:
	return String(current_metadata.get("topology_mode", TOPOLOGY_MODE_LEGACY)) == TOPOLOGY_MODE_PLANETARY

func get_world_size_preset() -> String:
	return String(current_metadata.get("world_size_preset", "legacy"))

func get_circumference_chunks() -> int:
	return int(current_metadata.get("horizontal_circumference_in_chunks", 0))

func get_circumference_tiles() -> int:
	return get_circumference_chunks() * CHUNK_SIZE

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

func wrap_chunk_x(chunk_x: int) -> int:
	if not is_planetary():
		return chunk_x
	var circumference := get_circumference_chunks()
	if circumference <= 0:
		return chunk_x
	return posmod(chunk_x, circumference)

func wrap_tile_x(tile_x: int) -> int:
	if not is_planetary():
		return tile_x
	var circumference_tiles := get_circumference_tiles()
	if circumference_tiles <= 0:
		return tile_x
	return posmod(tile_x, circumference_tiles)

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
	var wrapped_chunk_x := wrap_chunk_x(chunk_x)
	for region in world_plan.get("surface_regions", []):
		if _arc_contains_chunk(wrapped_chunk_x, int(region.get("start_chunk", 0)), int(region.get("length", 0))):
			return region.duplicate(true)
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
		return "%s_%s_%d_%d" % [
			String(current_metadata.get("topology_mode", TOPOLOGY_MODE_PLANETARY)),
			String(current_metadata.get("world_size_preset", DEFAULT_WORLD_SIZE_PRESET)),
			int(current_metadata.get("horizontal_circumference_in_chunks", 0)),
			seed,
		]
	return "%s_%d" % [String(current_metadata.get("topology_mode", TOPOLOGY_MODE_LEGACY)), seed]

func _get_world_size_preset_info(world_size_preset: String) -> Dictionary:
	if WORLD_SIZE_PRESETS.has(world_size_preset):
		var info: Dictionary = WORLD_SIZE_PRESETS[world_size_preset].duplicate(true)
		info["id"] = world_size_preset
		return info
	var fallback: Dictionary = WORLD_SIZE_PRESETS[DEFAULT_WORLD_SIZE_PRESET].duplicate(true)
	fallback["id"] = DEFAULT_WORLD_SIZE_PRESET
	return fallback

func _build_world_plan(metadata: Dictionary) -> Dictionary:
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
