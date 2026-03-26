extends Node
class_name WorldStructurePlanner

# Constants for Structure Placement
const CHUNK_SIZE = 64
const JUNGLE_WIDTH_CHUNKS_MIN = 32
const JUNGLE_WIDTH_CHUNKS_MAX = 48
const DUNGEON_ENTRANCE_WIDTH_CHUNKS = 4
const TEMPLE_WIDTH_CHUNKS = 6

# Data Structure for Plan
# {
#   "surface_regions": [
#       {"type": "spawn", "range": [100, 120], "priority": 100},
#       {"type": "jungle", "range": [200, 240], "priority": 50},
#       {"type": "dungeon", "range": [350, 354], "priority": 80}
#   ],
#   "landmarks": [
#       {"id": "dungeon_entrance", "global_x": 22450, "y": ...}
#   ]
# }

static func generate_plan(seed_val: int, circumference_chunks: int, spawn_chunk_index: int, preset_info: Dictionary = {}) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	var plan = {
		"surface_regions": [],
		"landmarks": [],
		"structures": []
	}
	
	# Budget / Preset Constraints
	var major_biome_budget = int(preset_info.get("surface_landmark_budget", 5)) # Default Medium
	# Ensure at least 3 for gameplay variety (Spawn + Jungle + Something)
	major_biome_budget = max(3, major_biome_budget)

	# 1. Define Spawn Region (Safety Zone - Forest/Purity)
	var spawn_safe_radius = int(preset_info.get("spawn_safe_radius_chunks", 12))
	var spawn_start = _wrap_chunk_index(spawn_chunk_index - spawn_safe_radius, circumference_chunks)
	var spawn_end = _wrap_chunk_index(spawn_chunk_index + spawn_safe_radius, circumference_chunks)
	
	_add_region(plan, "spawn_safe", spawn_start, spawn_end, circumference_chunks, 100, "spawn")
	
	# 2. Key Structures: Jungle & Dungeon (Guaranteed)
	# Jungle: 15-35% distance, random side
	var jungle_side = -1 if rng.randf() < 0.5 else 1
	var jungle_dist = rng.randi_range(int(circumference_chunks * 0.15), int(circumference_chunks * 0.35))
	var jungle_center = _wrap_chunk_index(spawn_chunk_index + (jungle_dist * jungle_side), circumference_chunks)
	var jungle_width = rng.randi_range(JUNGLE_WIDTH_CHUNKS_MIN, JUNGLE_WIDTH_CHUNKS_MAX)
	
	# Ensure Jungle doesn't overlap Spawn (it shouldn't given dist > safe_radius)
	_add_region(plan, "jungle", 
		_wrap_chunk_index(jungle_center - jungle_width/2, circumference_chunks),
		_wrap_chunk_index(jungle_center + jungle_width/2, circumference_chunks),
		circumference_chunks,
		80, "jungle") 

	# Dungeon: Opposite side of Jungle relative to world (or spawn)
	# Terraria: Jungle and Snow/Dungeon are usually opposite.
	var dungeon_side = -jungle_side
	var dungeon_dist_min = int(circumference_chunks * 0.30)
	var dungeon_dist_max = int(circumference_chunks * 0.45)
	var dungeon_dist = rng.randi_range(dungeon_dist_min, dungeon_dist_max)
	var dungeon_chunk = _wrap_chunk_index(spawn_chunk_index + (dungeon_dist * dungeon_side), circumference_chunks)
	
	_add_landmark(plan, "dungeon_entrance", dungeon_chunk * CHUNK_SIZE + CHUNK_SIZE/2, 0)
	_add_region(plan, "dungeon_zone", 
		_wrap_chunk_index(dungeon_chunk - 5, circumference_chunks),
		_wrap_chunk_index(dungeon_chunk + 5, circumference_chunks),
		circumference_chunks,
		90, "dungeon") 

	# Temple (Inside Jungle)
	var temple_offset = rng.randi_range(-jungle_width/4, jungle_width/4)
	var temple_x_chunk = _wrap_chunk_index(jungle_center + temple_offset, circumference_chunks)
	_add_landmark(plan, "jungle_temple", temple_x_chunk * CHUNK_SIZE, 0)

	# 3. Fill Gaps with Remaining Major Biomes
	# Priority list: Snow, Desert, Evil, Hallow (Post-Hardmode prep or just rare), Forest
	var biomes_to_place = []
	if major_biome_budget >= 3:
		biomes_to_place.append("snow") # Snow is distinct
	if major_biome_budget >= 4:
		biomes_to_place.append("desert")
	if major_biome_budget >= 5:
		biomes_to_place.append("corruption") # Evil biome
	if major_biome_budget >= 6:
		biomes_to_place.append("crimson") # Or generic "evil" 2
	if major_biome_budget >= 7:
		biomes_to_place.append("hallow") # Or resource rich forest

	# Fill gaps using explicit "Gap Filling" logic that respects major biome budget
	_fill_gaps_smartly(plan, circumference_chunks, biomes_to_place, rng)
	
	# 4. Post-Processing
	_normalize_biomes(plan)

	return plan

static func _fill_gaps_smartly(plan: Dictionary, circumference: int, priority_biomes: Array, rng: RandomNumberGenerator) -> void:
	# 1. Identify Gaps
	var regions = plan["surface_regions"]
	# We need to sort by start index
	regions.sort_custom(func(a, b): return a.start < b.start)
	
	var gaps = []
	var cursor = 0
	
	for region in regions:
		if region.start > cursor:
			gaps.append({"start": cursor, "end": region.start - 1, "len": (region.start - 1) - cursor + 1})
		cursor = max(cursor, region.end + 1)
	
	if cursor < circumference:
		gaps.append({"start": cursor, "end": circumference - 1, "len": (circumference - 1) - cursor + 1})
		
	# 2. Assign Priority Biomes to Largest Gaps
	# Sort gaps by length descending
	gaps.sort_custom(func(a, b): return a.len > b.len)
	
	for biome_name in priority_biomes:
		if gaps.is_empty(): break
		
		# Pick largest gap
		var gap = gaps.pop_front()
		var gap_len = gap.len
		
		# Decide width
		var desired_width = rng.randi_range(24, 48) # 24-48 chunks
		
		if gap_len <= desired_width + 8: 
			# Take all
			_add_region(plan, biome_name, gap.start, gap.end, circumference, 50, biome_name)
		else:
			# Split
			var offset = rng.randi_range(0, gap_len - desired_width)
			var biome_start = gap.start + offset
			var biome_end = biome_start + desired_width - 1
			
			_add_region(plan, biome_name, biome_start, biome_end, circumference, 50, biome_name)
			
			# Create new gaps
			var left_gap_len = biome_start - gap.start
			var right_gap_len = gap.end - biome_end
			
			if left_gap_len > 0:
				gaps.append({"start": gap.start, "end": biome_start - 1, "len": left_gap_len})
			if right_gap_len > 0:
				gaps.append({"start": biome_end + 1, "end": gap.end, "len": right_gap_len})
			
			gaps.sort_custom(func(a, b): return a.len > b.len)

	# 3. Fill Remaining Gaps with Transitions/Forests
	for gap in gaps:
		var len = gap.len
		if len <= 0: continue
		
		if len > 32:
			var mid = gap.start + len / 2
			_add_region(plan, "forest", gap.start, mid, circumference, 10, "forest")
			_add_region(plan, "plains", mid + 1, gap.end, circumference, 10, "plains")
		else:
			var filler = "forest" if rng.randf() > 0.4 else "plains"
			_add_region(plan, filler, gap.start, gap.end, circumference, 10, filler)
			
static func _normalize_biomes(plan: Dictionary) -> void:
	for region in plan["surface_regions"]:
		var tag = region.get("tag", "")
		var biome = "forest"
		var ug = "temperate"
		var hazard = "normal"
		
		if tag == "spawn":
			biome = "forest"
			hazard = "low"
		elif tag == "jungle":
			biome = "swamp" # Jungle assets mapped to Swamp for now
			ug = "jungle"
			hazard = "high"
		elif tag == "snow":
			biome = "tundra"
			ug = "ice"
		elif tag == "desert":
			biome = "desert"
			ug = "desert"
		elif tag == "corruption" or tag == "crimson":
			biome = "forest" 
			ug = "corruption"
			hazard = "high"
		elif tag == "dungeon":
			biome = "forest" 
			ug = "dungeon"
			hazard = "extreme"
		elif tag == "hallow":
			biome = "forest"
			hazard = "high"
		elif tag == "plains":
			biome = "plains"
			ug = "temperate"
		else:
			biome = "forest"
			ug = "temperate"
		
		plan_element_apply(region, biome, ug, hazard)

static func plan_element_apply(region: Dictionary, biome: String, ug: String, hazard: String) -> void:
	region["biome"] = biome
	region["underground_theme"] = ug
	region["hazard_bias"] = hazard
	region["region_type"] = "major" if hazard != "low" else "safe"

static func _wrap_chunk_index(idx: int, circumference: int) -> int:
	idx = idx % circumference
	if idx < 0: idx += circumference
	return idx

static func _add_region(plan: Dictionary, type: String, start_chunk: int, end_chunk: int, circumference: int, priority: int = 50, special_tag: String = "") -> void:
	if start_chunk <= end_chunk:
		plan["surface_regions"].append({
			"type": type,
			"start": start_chunk,
			"end": end_chunk,
			"priority": priority,
			"tag": special_tag
		})
	else:
		# Wraps around - Split into two
		var region_a_start = start_chunk
		var region_a_end = circumference - 1
		plan["surface_regions"].append({
			"type": type,
			"start": region_a_start,
			"end": region_a_end,
			"priority": priority,
			"tag": special_tag
		})
		
		var region_b_start = 0
		var region_b_end = end_chunk
		plan["surface_regions"].append({
			"type": type,
			"start": region_b_start,
			"end": region_b_end,
			"priority": priority,
			"tag": special_tag
		})

static func _add_landmark(plan: Dictionary, id: String, gx: int, gy: int) -> void:
	plan["landmarks"].append({
		"id": id,
		"global_x": gx,
		"global_y": gy
	})
