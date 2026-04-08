extends Node

## NPCSpawner (Refactored)
## Advanced spawning system based on Biome, Depth, Time, and Wall Rules (Terraria-style).

@export var spawn_radius_min: float = 800.0
@export var spawn_radius_max: float = 1600.0
@export var max_mobs: int = 20
@export var spawn_interval: float = 1.0
@export var spawn_chance: float = 0.6 

const SPAWN_TABLE_PATH := "res://data/npcs/hostile_spawn_table.json"
const TERRAIN_TAXONOMY_PATH := "res://data/npcs/terrain_taxonomy_31.json"

var last_spawn_check_time: float = 0.0

enum Zone { SURFACE, UNDERGROUND, CAVERN, SPACE }

# 新增：生态统计与来源定义
var population_map: Dictionary = {} 
var area_capacity: int = 15 # 每个区域的最大承载力
var pending_spawns: int = 0 # 新增：正在队列中等待生成的数量
var terrain_taxonomy: Array = []

class SpawnRule:
	var rule_id: String = ""
	var monster_type: String = ""
	var scene_path: String
	var spawn_probability: float
	var terrain_priority: int = 0
	var rarity_tier: String = "common"
	var behavior_profile_id: String = ""
	var hotspot_multiplier: float = 1.0
	var hotspot_terrain_ids: Array = []
	var biomes: Array
	var map_biomes: Array = ["Any"]
	var depth_bands: Array = ["Any"]
	var underworld_regions: Array = ["none"]
	var zones: Array 
	var time_constraints: Array
	var cave_regions: Array = ["Any"]
	var feature_tags: Array = ["Any"]
	var min_openness: float = 0.0
	var requires_reachable_cave: bool = false
	var group_min: int = 1
	var group_max: int = 1
	var requires_wall: bool = false 
	var requires_no_wall: bool = false 
	var origin_type: String = "natural"
	var max_active_count: int = 5 # 默认每种怪物的最大共存数

	func _init(path: String, probability: float, _biomes: Array, _zones: Array, _times: Array, _origin: String = "natural", _max: int = 5, _rule_id: String = "", _monster_type: String = ""):
		scene_path = path
		spawn_probability = clampf(probability, 0.0, 1.0)
		biomes = _biomes
		zones = _zones
		time_constraints = _times
		origin_type = _origin
		max_active_count = _max
		rule_id = _rule_id
		monster_type = _monster_type

var spawn_table: Array[SpawnRule] = []

var active_mobs_cache: Array = [] # 缓存优化（并未实现完全缓存，保留原有逻辑）
var pending_spawns_by_path: Dictionary = {} # 新增：按类型追踪等待生成的数量

func _increment_pending(path: String) -> void:
	pending_spawns += 1
	if not pending_spawns_by_path.has(path):
		pending_spawns_by_path[path] = 1
	else:
		pending_spawns_by_path[path] += 1

func _decrement_pending(path: String) -> void:
	pending_spawns -= 1
	if pending_spawns_by_path.has(path) and pending_spawns_by_path[path] > 0:
		pending_spawns_by_path[path] -= 1

func _ready() -> void:
	add_to_group("npc_spawner")
	_load_terrain_taxonomy()
	_build_registry()

func reset() -> void:
	print("NPCSpawner: Clearing population registry...")
	population_map.clear()
	last_spawn_check_time = 0.0

func _build_registry() -> void:
	spawn_table.clear()
	if _load_spawn_table_from_json(SPAWN_TABLE_PATH):
		print("NPCSpawner: Loaded spawn table from ", SPAWN_TABLE_PATH, " (", spawn_table.size(), " rules)")
		return
	
	print("NPCSpawner: Spawn table JSON unavailable or invalid, using built-in fallback rules.")
	_build_fallback_registry()

func _load_terrain_taxonomy() -> void:
	terrain_taxonomy.clear()
	if not FileAccess.file_exists(TERRAIN_TAXONOMY_PATH):
		print("NPCSpawner: Terrain taxonomy missing: ", TERRAIN_TAXONOMY_PATH)
		return
	var file := FileAccess.open(TERRAIN_TAXONOMY_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var root: Dictionary = parsed
	var terrains_var = root.get("terrains", [])
	if terrains_var is Array:
		terrain_taxonomy = terrains_var

func _build_fallback_registry() -> void:
	# Fallback keeps gameplay functional when external table is missing.
	var slime = SpawnRule.new("res://scenes/npc/slime.tscn", 0.08, ["Forest", "Plains"], [Zone.SURFACE], ["Any"], "falling", 8)
	slime.rule_id = "slime_surface_forest_plains"
	slime.monster_type = "slime"
	slime.terrain_priority = 10
	slime.rarity_tier = "common"
	slime.behavior_profile_id = "slime_falling_basic"
	slime.map_biomes = ["FOREST", "PLAINS"]
	slime.depth_bands = ["surface"]
	slime.underworld_regions = ["none"]
	slime.cave_regions = ["Surface"]
	slime.requires_no_wall = true
	slime.group_min = 1
	slime.group_max = 2
	spawn_table.append(slime)

	var bog_slime = SpawnRule.new("res://scenes/npc/bog_slime.tscn", 0.11, ["Swamp"], [Zone.SURFACE, Zone.UNDERGROUND], ["Any"], "falling", 6)
	bog_slime.rule_id = "bog_slime_swamp_surface_underground"
	bog_slime.monster_type = "bog_slime"
	bog_slime.terrain_priority = 15
	bog_slime.rarity_tier = "uncommon"
	bog_slime.behavior_profile_id = "bog_slime_swamp_controller"
	bog_slime.map_biomes = ["SWAMP", "UNDERGROUND_SWAMP"]
	bog_slime.depth_bands = ["surface", "shallow_underground"]
	bog_slime.underworld_regions = ["none"]
	bog_slime.requires_no_wall = true
	bog_slime.feature_tags = ["MudMound", "Any"]
	bog_slime.cave_regions = ["Surface", "Pocket", "OpenCavern"]
	bog_slime.min_openness = 0.12
	bog_slime.group_min = 1
	bog_slime.group_max = 2
	spawn_table.append(bog_slime)

	var zombie = SpawnRule.new("res://scenes/npc/zombie.tscn", 0.095, ["Plains", "Forest"], [Zone.SURFACE], ["Any"], "burrow", 5)
	zombie.rule_id = "zombie_surface_forest_plains"
	zombie.monster_type = "zombie"
	zombie.terrain_priority = 12
	zombie.rarity_tier = "common"
	zombie.behavior_profile_id = "zombie_surface_brutal"
	zombie.map_biomes = ["FOREST", "PLAINS"]
	zombie.depth_bands = ["surface"]
	zombie.underworld_regions = ["none"]
	zombie.cave_regions = ["Surface"]
	zombie.requires_no_wall = true
	spawn_table.append(zombie)

	var skeleton = SpawnRule.new("res://scenes/npc/skeleton.tscn", 0.105, ["Forest", "Plains", "Desert", "Tundra", "Swamp"], [Zone.UNDERGROUND, Zone.CAVERN], ["Any"], "burrow", 6)
	skeleton.rule_id = "skeleton_underground_cavern"
	skeleton.monster_type = "skeleton"
	skeleton.terrain_priority = 20
	skeleton.rarity_tier = "uncommon"
	skeleton.behavior_profile_id = "skeleton_cave_lancer"
	skeleton.map_biomes = ["UNDERGROUND", "UNDERGROUND_DESERT", "UNDERGROUND_TUNDRA", "UNDERGROUND_SWAMP"]
	skeleton.depth_bands = ["shallow_underground", "mid_cavern", "deep", "terminal"]
	skeleton.underworld_regions = ["none"]
	skeleton.cave_regions = ["Tunnel", "Chamber", "Connector"]
	skeleton.min_openness = 0.3
	skeleton.requires_reachable_cave = true
	spawn_table.append(skeleton)

	var cave_bat = SpawnRule.new("res://scenes/npc/cave_bat.tscn", 0.115, ["Forest", "Plains", "Desert", "Tundra", "Swamp"], [Zone.UNDERGROUND, Zone.CAVERN], ["Any"], "natural", 6)
	cave_bat.rule_id = "cave_bat_underground_cavern"
	cave_bat.monster_type = "cave_bat"
	cave_bat.terrain_priority = 18
	cave_bat.rarity_tier = "common"
	cave_bat.behavior_profile_id = "cave_bat_swarm"
	cave_bat.map_biomes = ["UNDERGROUND", "UNDERGROUND_DESERT", "UNDERGROUND_TUNDRA", "UNDERGROUND_SWAMP"]
	cave_bat.depth_bands = ["shallow_underground", "mid_cavern", "deep", "terminal"]
	cave_bat.underworld_regions = ["none"]
	cave_bat.cave_regions = ["OpenCavern", "Chamber"]
	cave_bat.min_openness = 0.55
	cave_bat.requires_reachable_cave = true
	cave_bat.group_min = 2
	cave_bat.group_max = 4
	spawn_table.append(cave_bat)

	var antlion = SpawnRule.new("res://scenes/npc/antlion.tscn", 0.15, ["Desert"], [Zone.SURFACE], ["Day"], "emerging", 3)
	antlion.rule_id = "antlion_desert_surface_day"
	antlion.monster_type = "antlion"
	antlion.terrain_priority = 22
	antlion.rarity_tier = "uncommon"
	antlion.behavior_profile_id = "antlion_desert_ambush"
	antlion.map_biomes = ["DESERT"]
	antlion.depth_bands = ["surface"]
	antlion.underworld_regions = ["none"]
	antlion.cave_regions = ["Surface"]
	antlion.requires_no_wall = true
	antlion.feature_tags = ["DesertSpire", "Any"]
	spawn_table.append(antlion)

	var frost_bat = SpawnRule.new("res://scenes/npc/frost_bat.tscn", 0.09, ["Tundra"], [Zone.SURFACE, Zone.UNDERGROUND, Zone.CAVERN], ["Any"], "natural", 4)
	frost_bat.rule_id = "frost_bat_tundra_multi_depth"
	frost_bat.monster_type = "frost_bat"
	frost_bat.terrain_priority = 19
	frost_bat.rarity_tier = "uncommon"
	frost_bat.behavior_profile_id = "frost_bat_freeze_harass"
	frost_bat.map_biomes = ["TUNDRA", "UNDERGROUND_TUNDRA"]
	frost_bat.depth_bands = ["surface", "shallow_underground", "mid_cavern", "deep", "terminal"]
	frost_bat.underworld_regions = ["none"]
	frost_bat.cave_regions = ["Surface", "Tunnel", "Chamber", "OpenCavern", "Pocket", "Connector"]
	frost_bat.feature_tags = ["FrostSpire", "Any"]
	frost_bat.min_openness = 0.4
	frost_bat.group_min = 1
	frost_bat.group_max = 3
	spawn_table.append(frost_bat)

	var eye = SpawnRule.new("res://scenes/npc/demon_eye.tscn", 0.07, ["Forest", "Plains", "Desert", "Tundra", "Swamp"], [Zone.SURFACE], ["Night"], "natural", 3)
	eye.rule_id = "demon_eye_surface_night"
	eye.monster_type = "demon_eye"
	eye.terrain_priority = 16
	eye.rarity_tier = "common"
	eye.behavior_profile_id = "demon_eye_night_dive"
	eye.map_biomes = ["FOREST", "PLAINS", "DESERT", "TUNDRA", "SWAMP"]
	eye.depth_bands = ["surface"]
	eye.underworld_regions = ["none"]
	eye.cave_regions = ["Surface"]
	eye.feature_tags = ["Any"]
	spawn_table.append(eye)

func _load_spawn_table_from_json(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false

	var config: Dictionary = parsed
	var rules_value = config.get("rules", [])
	if not (rules_value is Array):
		return false

	for entry in rules_value:
		if not (entry is Dictionary):
			continue
		var item: Dictionary = entry
		var scene_path := String(item.get("enemy_scene", ""))
		var probability := clampf(float(item.get("spawn_probability", 0.0)), 0.0, 1.0)
		var map_biomes := _to_string_array(item.get("map_biomes", []), [])
		var depth_bands := _to_string_array(item.get("depth_bands", []), [])
		var cave_regions := _to_string_array(item.get("cave_regions", []), [])
		var underworld_regions := _to_string_array(item.get("underworld_regions", []), [])
		var hotspot_terrain_ids := _to_string_array(item.get("hotspot_terrain_ids", []), [])
		if scene_path.is_empty() or probability <= 0.0:
			continue
		if map_biomes.is_empty() or depth_bands.is_empty() or cave_regions.is_empty() or underworld_regions.is_empty():
			print("NPCSpawner: Skip invalid strict rule (missing terrain fields): ", item.get("id", scene_path))
			continue

		var rule = SpawnRule.new(
			scene_path,
			probability,
			_to_string_array(item.get("ecozones", ["Any"]), ["Any"]),
			_parse_zone_names(item.get("depth_zones", ["SURFACE"])),
			_to_string_array(item.get("time_phases", ["Any"]), ["Any"]),
			String(item.get("origin_type", "natural")),
			int(item.get("max_active_count", 5)),
			String(item.get("id", "")),
			""
		)

		rule.monster_type = _normalize_monster_type(String(item.get("monster_type", "")))
		if rule.monster_type.is_empty():
			rule.monster_type = _infer_monster_type_from_scene_path(scene_path)
		if rule.rule_id.is_empty():
			rule.rule_id = _infer_rule_id_from_scene_path(scene_path)

		rule.cave_regions = cave_regions
		rule.feature_tags = _to_string_array(item.get("feature_tags", ["Any"]), ["Any"])
		rule.map_biomes = map_biomes
		rule.depth_bands = depth_bands
		rule.underworld_regions = underworld_regions
		rule.terrain_priority = int(item.get("terrain_priority", 0))
		rule.rarity_tier = String(item.get("rarity_tier", "common"))
		rule.behavior_profile_id = String(item.get("behavior_profile_id", ""))
		rule.hotspot_multiplier = maxf(1.0, float(item.get("hotspot_multiplier", 1.0)))
		rule.hotspot_terrain_ids = hotspot_terrain_ids
		rule.min_openness = maxf(0.0, float(item.get("min_openness", 0.0)))
		rule.requires_reachable_cave = bool(item.get("requires_reachable_cave", false))
		rule.group_min = maxi(1, int(item.get("group_min", 1)))
		rule.group_max = maxi(rule.group_min, int(item.get("group_max", rule.group_min)))
		rule.requires_wall = bool(item.get("requires_wall", false))
		rule.requires_no_wall = bool(item.get("requires_no_wall", false))
		spawn_table.append(rule)

	_log_terrain_coverage_snapshot()

	return not spawn_table.is_empty()

func _log_terrain_coverage_snapshot() -> void:
	if not FileAccess.file_exists(TERRAIN_TAXONOMY_PATH):
		print("NPCSpawner: Terrain taxonomy file not found, skip coverage snapshot: ", TERRAIN_TAXONOMY_PATH)
		return
	var file := FileAccess.open(TERRAIN_TAXONOMY_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var root: Dictionary = parsed
	var terrains_var = root.get("terrains", [])
	if not (terrains_var is Array):
		return
	var terrains: Array = terrains_var
	var poor_coverage: Array = []
	for item in terrains:
		if not (item is Dictionary):
			continue
		var terrain: Dictionary = item
		var count := 0
		for rule in spawn_table:
			if _rule_matches_terrain_snapshot(rule, terrain):
				count += 1
		if count < 2:
			poor_coverage.append("%s(%d)" % [String(terrain.get("id", "unknown")), count])
	if poor_coverage.is_empty():
		print("NPCSpawner: Terrain coverage snapshot OK (all terrains have >=2 matching families)")
	else:
		print("NPCSpawner: Terrain coverage snapshot warnings: ", poor_coverage)

func _rule_matches_terrain_snapshot(rule: SpawnRule, terrain: Dictionary) -> bool:
	if not _terrain_dim_matches(rule.map_biomes, _to_string_array(terrain.get("map_biomes", []), [])):
		return false
	if not _terrain_dim_matches(rule.depth_bands, _to_string_array(terrain.get("depth_bands", []), [])):
		return false
	if not _terrain_dim_matches(rule.cave_regions, _to_string_array(terrain.get("cave_regions", []), [])):
		return false
	if not _terrain_dim_matches(rule.underworld_regions, _to_string_array(terrain.get("underworld_regions", []), [])):
		return false
	var terrain_features := _to_string_array(terrain.get("feature_tags", ["Any"]), ["Any"])
	if not _terrain_dim_matches(rule.feature_tags, terrain_features):
		return false
	return true

func _terrain_dim_matches(rule_values: Array, terrain_values: Array) -> bool:
	if rule_values.has("Any"):
		return true
	for value in rule_values:
		if terrain_values.has(value):
			return true
	return false

func _context_matches_terrain_snapshot(context: Dictionary, terrain: Dictionary) -> bool:
	if not _terrain_dim_matches(_to_string_array(terrain.get("map_biomes", []), []), [String(context.get("map_biome", ""))]):
		return false
	if not _terrain_dim_matches(_to_string_array(terrain.get("depth_bands", []), []), [String(context.get("depth_band", ""))]):
		return false
	if not _terrain_dim_matches(_to_string_array(terrain.get("cave_regions", []), []), [String(context.get("cave_region", ""))]):
		return false
	if not _terrain_dim_matches(_to_string_array(terrain.get("underworld_regions", []), []), [String(context.get("underworld_region", ""))]):
		return false
	return true

func _collect_matching_terrain_ids(context: Dictionary) -> Array:
	var ids: Array = []
	for terrain_var in terrain_taxonomy:
		if not (terrain_var is Dictionary):
			continue
		var terrain: Dictionary = terrain_var
		if not _context_matches_terrain_snapshot(context, terrain):
			continue
		var terrain_id: String = String(terrain.get("id", "")).strip_edges()
		if terrain_id != "":
			ids.append(terrain_id)
	return ids

func _get_effective_rule_probability(rule: SpawnRule, context: Dictionary) -> float:
	var probability: float = clampf(rule.spawn_probability, 0.0, 1.0)
	if probability <= 0.0:
		return 0.0
	var context_ids: Array = _to_string_array(context.get("terrain_ids", []), [])
	if context_ids.is_empty() or rule.hotspot_terrain_ids.is_empty():
		return probability
	for terrain_id_var in context_ids:
		if rule.hotspot_terrain_ids.has(String(terrain_id_var)):
			probability *= maxf(1.0, rule.hotspot_multiplier)
			break
	return clampf(probability, 0.0, 1.0)

func _to_string_array(value: Variant, fallback: Array) -> Array:
	var result: Array = []
	if value is Array:
		for item in value:
			var s := String(item)
			if not s.is_empty():
				result.append(s)
	if result.is_empty():
		return fallback.duplicate()
	return result

func _parse_zone_names(value: Variant) -> Array:
	var zones: Array = []
	for zone_name in _to_string_array(value, ["SURFACE"]):
		match String(zone_name).to_upper():
			"SURFACE":
				zones.append(Zone.SURFACE)
			"UNDERGROUND":
				zones.append(Zone.UNDERGROUND)
			"CAVERN":
				zones.append(Zone.CAVERN)
			"SPACE":
				zones.append(Zone.SPACE)
	if zones.is_empty():
		zones.append(Zone.SURFACE)
	return zones

func _process(delta: float) -> void:
	last_spawn_check_time += delta
	if last_spawn_check_time >= spawn_interval:
		last_spawn_check_time = 0
		_try_spawn_cycle()
		_process_despawn() # 新增：处理清理逻辑

func _process_despawn() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var active_mobs = get_tree().get_nodes_in_group("hostile_npcs")
	for mob in active_mobs:
		var dist = mob.global_position.distance_to(player.global_position)
		if dist > 1800.0:
			# 超过约1.5个屏幕清理，比之前更进场激进
			mob.queue_free()
		elif dist > 1200.0 and (active_mobs.size() + pending_spawns) > area_capacity * 0.8:
			# 如果总数接近上限，清理远处但还没跑太远的怪
			mob.queue_free()

func _count_active_mobs(scene_path: String) -> int:
	var count = 0
	# 包含等待生成的数量，防止同种怪物过度生成
	if pending_spawns_by_path.has(scene_path):
		count += pending_spawns_by_path[scene_path]
		
	var active_mobs = get_tree().get_nodes_in_group("hostile_npcs")
	for mob in active_mobs:
		# 通过比较场景文件的路径来匹配种类
		if mob.scene_file_path == scene_path:
			count += 1
	return count

func _try_spawn_cycle() -> void:
	if _is_spawn_blocked_by_boss_encounter():
		return

	# --- 种群密度控制 (Carrying Capacity) ---
	var active_mobs_count = get_tree().get_nodes_in_group("hostile_npcs").size()
	var current_mobs = active_mobs_count + pending_spawns # 修复堆叠生成问题的关键
	
	if current_mobs >= area_capacity:
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# --- 生态节奏 (Ecological Pacing) ---
	# 不再使用固定概率，而是模拟“种群恢复”式的刷新
	if randf() > 0.4:
		return

	var spawn_pos = _get_random_spawn_pos(player.global_position)
	if spawn_pos == Vector2.ZERO:
		return
	
	# --- 局部密度控制 (Localized Density Check) ---
	# 限制同一区域内的刷怪上限密度，防止刷出一堆怪堆在一起
	var local_density_radius = 600.0 # 稍微缩小检测半径以使检测更精准
	var max_local_density = 3      # 严格限制到 3 只内容
	var global_max_density_radius = 1200.0 # 新增：中等范围总数限制
	var global_max_in_range = 8
	
	var local_count = 0
	var mid_range_count = 0
	
	var active_mobs = get_tree().get_nodes_in_group("hostile_npcs")
	for mob in active_mobs:
		var dist = spawn_pos.distance_to(mob.global_position)
		if dist < local_density_radius:
			local_count += 1
		if dist < global_max_density_radius:
			mid_range_count += 1
			
		if local_count >= max_local_density or mid_range_count >= global_max_in_range:
			# 区域内怪物密度过大，放弃本次生成
			return
	
	var context = _analyze_context(spawn_pos)
	
	var candidates: Array[SpawnRule] = []
	var candidate_weights: Array[float] = []
	var total_weight: float = 0.0
	
	for rule in spawn_table:
		if _is_rule_valid(rule, context):
			# 检查该种群是否已达上限
			if _count_active_mobs(rule.scene_path) < rule.max_active_count:
				var base_probability: float = _get_effective_rule_probability(rule, context)
				if base_probability <= 0.0:
					continue
				var priority_factor: float = 1.0 + float(maxi(0, rule.terrain_priority)) * 0.35
				var weight: float = base_probability * priority_factor
				if weight <= 0.0:
					continue
				candidates.append(rule)
				candidate_weights.append(weight)
				total_weight += weight
			
	if candidates.is_empty() or total_weight <= 0.0:
		return
	
	var roll := randf() * total_weight
	var current_w := 0.0
	for i in range(candidates.size()):
		var rule := candidates[i]
		current_w += candidate_weights[i]
		if roll <= current_w:
			_execute_plausible_spawn(rule, spawn_pos)
			break

## 新增：自然生成逻辑 (Plausible Origins)
func _execute_plausible_spawn(rule: SpawnRule, pos: Vector2) -> void:
	# 立即增加 pending_spawns 计数 (按类型)，防止新的循环因为看不到实际生成的实体而过度请求生成
	var spawn_count = randi_range(rule.group_min, rule.group_max)
	for _i in range(spawn_count):
		_increment_pending(rule.scene_path)
	
	match rule.origin_type:
		"burrow":
			# 从地下钻出：在实体实际实例化之前模拟“地动”
			# 未来可在这里实例化尘土粒子特效
			print("EcologicalSpawn: [", rule.scene_path.get_file().get_basename(), "] 正在地下挖掘...")
			# 注意：await 期间 pending_spawns 保持增加，阻止新的 spawn_cycle 触发
			await get_tree().create_timer(1.0).timeout
			_spawn_group(rule.scene_path, pos, spawn_count, false, rule.rule_id, rule.monster_type)
			
		"falling":
			# 从高处跳下：用于史莱姆等，初始位置略高
			_spawn_group(rule.scene_path, pos + Vector2(0, -60), spawn_count, false, rule.rule_id, rule.monster_type)
			
		"emerging":
			# 伪装显现：用于蚁狮
			_spawn_group(rule.scene_path, pos, spawn_count, false, rule.rule_id, rule.monster_type)
			
		_:
			# 默认生成
			var spawn_pos = pos
			if rule.scene_path.contains("demon_eye"):
				# 恶魔眼属于飞行单位，默认生成点上移，避免贴地出生。
				spawn_pos += Vector2(0, -180)
			_spawn_group(rule.scene_path, spawn_pos, spawn_count, rule.scene_path.contains("eye") or rule.scene_path.contains("bat"), rule.rule_id, rule.monster_type)
			
	# 生成完成后减少 pending 计数（此时 _spawn_mob 已经将实体放入树中，active_mobs 应该增加了）
	for _i in range(spawn_count):
		_decrement_pending(rule.scene_path)

func _spawn_group(path: String, origin: Vector2, count: int, aerial: bool, rule_id: String = "", monster_type: String = "") -> void:
	for index in range(count):
		var offset_x = randf_range(-80.0, 80.0) + (index * 24.0)
		var offset_y = randf_range(-24.0, 24.0)
		if aerial:
			offset_y -= randf_range(40.0, 120.0)
		_spawn_mob(path, origin + Vector2(offset_x, offset_y), rule_id, monster_type)

func _analyze_context(pos: Vector2) -> Dictionary:
	var ctx = {}
	var tile_pos = pos / 16.0
	var tile_x := int(tile_pos.x)
	var tile_y := int(tile_pos.y)
	
	var wg = get_tree().get_first_node_in_group("world_generator")
	var surface_y = 300.0 # 默认地表高度 (瓦片单位)
	if wg and wg.has_method("get_surface_height_at"):
		surface_y = wg.get_surface_height_at(tile_x)
	
	# 计算相对于地表的深度
	var depth = tile_pos.y - surface_y
	ctx["depth_band"] = _derive_depth_band_id(depth)
	
	# 动态判定区域：优先与 world_generator 的深度带保持一致
	ctx["zone"] = _depth_band_to_zone(ctx["depth_band"])
		
	ctx["map_biome"] = "FOREST"
	ctx["biome"] = "Forest"
	if wg and wg.has_method("get_biome_at"):
		var map_biome_id := _map_world_biome_enum_to_id(int(wg.get_biome_at(tile_x, tile_y)))
		ctx["map_biome"] = map_biome_id
		ctx["biome"] = _map_world_biome_to_ecozone(map_biome_id)

	if wg and wg.has_method("get_underground_generation_metadata_at_pos"):
		var underground_meta: Dictionary = wg.get_underground_generation_metadata_at_pos(pos)
		var depth_band_id := String(underground_meta.get("depth_band_id", ""))
		if not depth_band_id.is_empty():
			ctx["depth_band"] = depth_band_id
			ctx["zone"] = _depth_band_to_zone(depth_band_id)
	
	ctx["time"] = "Day"
	var chron = get_node_or_null("/root/Chronometer")
	if chron and chron.has_method("get_time_phase"):
		ctx["time"] = "Night" if chron.get_time_phase() == "Night" else "Day"
	else:
		var sm = get_node_or_null("/root/SettlementManager")
		if sm and sm.is_night:
			ctx["time"] = "Night"
	
	ctx["has_wall"] = _has_background_wall(pos)
	ctx["feature_tag"] = "None"
	ctx["cave_region"] = "Surface"
	ctx["underworld_region"] = "none"
	ctx["cave_reachable"] = true
	ctx["cave_openness"] = 1.0
	ctx["underworld_active"] = false
	if wg and wg.has_method("get_underground_generation_metadata_at_pos"):
		var meta: Dictionary = wg.get_underground_generation_metadata_at_pos(pos)
		ctx["underworld_active"] = bool(meta.get("underworld_active", false))
		ctx["underworld_region"] = String(meta.get("underworld_region", "none"))
	if wg and wg.has_method("get_surface_feature_tag_at_pos"):
		ctx["feature_tag"] = wg.get_surface_feature_tag_at_pos(pos)
	if wg and wg.has_method("get_cave_region_info_at_pos"):
		var cave_info = wg.get_cave_region_info_at_pos(pos)
		ctx["cave_region"] = cave_info.get("region", "Surface")
		ctx["cave_reachable"] = cave_info.get("reachable", true)
		ctx["cave_openness"] = cave_info.get("openness", 1.0)
	ctx["terrain_ids"] = _collect_matching_terrain_ids(ctx)
	return ctx

func _derive_depth_band_id(depth: float) -> String:
	if depth < 28.0:
		return "surface"
	if depth < 120.0:
		return "shallow_underground"
	if depth < 420.0:
		return "mid_cavern"
	if depth < 980.0:
		return "deep"
	return "terminal"

func _depth_band_to_zone(depth_band_id: String) -> int:
	match depth_band_id:
		"surface":
			return Zone.SURFACE
		"shallow_underground":
			return Zone.UNDERGROUND
		"mid_cavern", "deep", "terminal":
			return Zone.CAVERN
		_:
			return Zone.SURFACE

func _map_world_biome_enum_to_id(val: int) -> String:
	match val:
		0:
			return "FOREST"
		1:
			return "PLAINS"
		2:
			return "DESERT"
		3:
			return "TUNDRA"
		4:
			return "SWAMP"
		5:
			return "UNDERGROUND"
		6:
			return "UNDERGROUND_DESERT"
		7:
			return "UNDERGROUND_TUNDRA"
		8:
			return "UNDERGROUND_SWAMP"
		_:
			return "FOREST"

func _map_world_biome_to_ecozone(map_biome_id: String) -> String:
	match map_biome_id:
		"FOREST":
			return "Forest"
		"PLAINS":
			return "Plains"
		"DESERT", "UNDERGROUND_DESERT":
			return "Desert"
		"TUNDRA", "UNDERGROUND_TUNDRA":
			return "Tundra"
		"SWAMP", "UNDERGROUND_SWAMP":
			return "Swamp"
		"UNDERGROUND":
			return "Forest"
		_:
			return "Forest"

func _has_background_wall(pos: Vector2) -> bool:
	if not LayerManager: return false
	var bg = LayerManager.get_layer(1)
	if bg and bg is TileMapLayer:
		# Check slightly above the floor (+16px up is -16y)
		var check_pos = pos - Vector2(0, 16)
		var mp = bg.local_to_map(bg.to_local(check_pos))
		if bg.get_cell_source_id(mp) != -1: return true
	return false

func _is_underworld_targeted_rule(rule: SpawnRule) -> bool:
	for region in rule.underworld_regions:
		var region_id := String(region)
		if region_id != "" and region_id != "none" and region_id != "Any":
			return true
	return false

func _is_rule_valid(rule: SpawnRule, ctx: Dictionary) -> bool:
	if not rule.zones.has(ctx["zone"]): return false
	if not rule.depth_bands.has("Any") and not rule.depth_bands.has(ctx["depth_band"]): return false
	if not rule.map_biomes.has("Any") and not rule.map_biomes.has(ctx["map_biome"]): return false
	if not rule.underworld_regions.has("Any") and not rule.underworld_regions.has(ctx["underworld_region"]): return false
	if not rule.biomes.has("Any") and not rule.biomes.has(ctx["biome"]): return false
	if not rule.time_constraints.has("Any") and not rule.time_constraints.has(ctx["time"]): return false
	if not rule.feature_tags.has("Any") and not rule.feature_tags.has(ctx["feature_tag"]): return false
	if not rule.cave_regions.has("Any") and not rule.cave_regions.has(ctx["cave_region"]): return false
	var underworld_active := bool(ctx.get("underworld_active", false))
	var underworld_targeted := _is_underworld_targeted_rule(rule)
	if not (underworld_active and underworld_targeted):
		if ctx["cave_openness"] < rule.min_openness: return false
		if rule.requires_reachable_cave and not ctx["cave_reachable"]: return false
	
	if rule.requires_no_wall and ctx["has_wall"]:
		if ctx["zone"] == Zone.SURFACE or ctx["zone"] == Zone.SPACE: return false
	if rule.requires_wall and not ctx["has_wall"]: return false
	
	return true

func _get_random_spawn_pos(center: Vector2) -> Vector2:
	# Vertical Strip Scan
	var dir = -1 if randf() < 0.5 else 1
	var dist_x = randf_range(spawn_radius_min, spawn_radius_max)
	var target_x = center.x + (dir * dist_x)
	
	# Broad vertical search (find floor anywhere in this column)
	var top = center.y - 1000.0
	var bottom = center.y + 1000.0
	
	var space_state = get_viewport().world_2d.direct_space_state
	var query = PhysicsRayQueryParameters2D.create(Vector2(target_x, top), Vector2(target_x, bottom))
	var active_world_mask := 1
	var all_world_masks := 1 | 2 | 4 | 64 | 128

	# 优先使用玩家当前层，失败时再回退到全层位，避免跨层后完全不刷怪。
	if LayerManager:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_meta("current_layer") and LayerManager.has_method("get_world_bit"):
			var current_layer := int(player.get_meta("current_layer"))
			active_world_mask = int(LayerManager.get_world_bit(current_layer))
		elif LayerManager.has_method("get_world_bit"):
			active_world_mask = int(LayerManager.get_world_bit(int(LayerManager.active_layer)))

	query.collision_mask = active_world_mask
	var result = space_state.intersect_ray(query)
	if not result:
		query.collision_mask = all_world_masks
		result = space_state.intersect_ray(query)
	if result:
		var pos = result.position - Vector2(0, 32)
		# 确保不在视口内
		if _is_pos_on_screen(pos):
			# 如果刚好在视口内，尝试推得更远一点
			pos.x += 400 * dir
		return pos
	return Vector2.ZERO

func _is_pos_on_screen(pos: Vector2) -> bool:
	var viewport = get_viewport()
	if not viewport: return false
	
	var camera = viewport.get_camera_2d()
	if not camera: 
		# 没相机时回退到简单的可见矩形（通常不对，但作为兜底）
		return viewport.get_visible_rect().has_point(pos)
		
	# 获取相机当前看到的全局矩形
	var screen_center = camera.get_screen_center_position()
	var screen_size = viewport.get_visible_rect().size / camera.zoom
	var view_rect = Rect2(screen_center - screen_size / 2.0, screen_size)
	
	# 增加更大的一点边距 (Buffer)，防止怪物边缘在屏幕边缘闪现
	var buffer = 250.0
	var buffered_rect = view_rect.grow(buffer)
	
	return buffered_rect.has_point(pos)


func _spawn_mob(path: String, pos: Vector2, rule_id: String = "", monster_type: String = "") -> void:
	if _is_spawn_blocked_by_boss_encounter():
		return

	# 支持打包资源路径（res://）和外部文件路径
	if not (ResourceLoader.exists(path) or FileAccess.file_exists(path)):
		print("NPCSpawner: ERROR! File not found: ", path)
		return

	var scene = null
	if ResourceLoader.exists(path):
		scene = ResourceLoader.load(path)
	elif FileAccess.file_exists(path):
		scene = load(path)
	if not scene: return
	
	var mob = scene.instantiate()
	mob.global_position = pos
	mob.set_meta("spawn_rule_id", rule_id)
	mob.set_meta("hostile_monster_type", _normalize_monster_type(monster_type))
	
	if mob is BaseNPC:
		# 修复：实例化新资源，防止所有骷髅共用同一个 npc_data 对象
		if not mob.npc_data: 
			mob.npc_data = CharacterData.new()
		else:
			mob.npc_data = mob.npc_data.duplicate()
		
		# 极重要修复：重置当前血量为最大血量。
		# 防止因为模板资源（.tres）在内存中被旧实体修改，导致新实体“继承”残血。
		mob.npc_data.health = mob.npc_data.max_health
			
		mob.npc_data.alignment = "Hostile"
		mob.npc_data.npc_type = "Hostile"
		# 根据NPC类型设置自定义display_name
		if path.contains("zombie"):
			mob.npc_data.display_name = "荒原追兵"
		elif path.contains("skeleton"):
			mob.npc_data.display_name = "洞窟骷髅"
		elif path.contains("bog_slime"):
			mob.npc_data.display_name = "沼泽史莱姆"
		elif path.contains("cave_bat"):
			mob.npc_data.display_name = "洞穴蝙蝠"
		elif path.contains("frost_bat"):
			mob.npc_data.display_name = "霜咬蝙蝠"
		elif path.contains("slime"):
			mob.npc_data.display_name = "林地史莱姆"
		elif path.contains("demon_eye"):
			mob.npc_data.display_name = "恶魔之眼"
			
		# 确保血条显示正确同步
		if mob.has_method("_update_hp_bar"):
			mob._update_hp_bar()
	
	var entities = get_tree().current_scene.find_child("Entities", true, false)
	if entities:
		entities.add_child(mob)
		print("NPCSpawner: Spawned ", mob.name, " in Entities.")
	else:
		get_tree().current_scene.add_child(mob)
		print("NPCSpawner: Spawned ", mob.name, " in Root.")

	if mob.has_method("refresh_runtime_groups"):
		mob.refresh_runtime_groups()

func _normalize_monster_type(monster_type: String) -> String:
	return monster_type.strip_edges().to_lower()

func _infer_monster_type_from_scene_path(scene_path: String) -> String:
	var path_l := scene_path.to_lower()
	if path_l.contains("bog_slime"):
		return "bog_slime"
	if path_l.contains("frost_bat"):
		return "frost_bat"
	if path_l.contains("cave_bat"):
		return "cave_bat"
	if path_l.contains("demon_eye"):
		return "demon_eye"
	if path_l.contains("antlion"):
		return "antlion"
	if path_l.contains("skeleton"):
		return "skeleton"
	if path_l.contains("zombie"):
		return "zombie"
	if path_l.contains("slime"):
		return "slime"
	return ""

func _infer_rule_id_from_scene_path(scene_path: String) -> String:
	var type_id := _infer_monster_type_from_scene_path(scene_path)
	if type_id.is_empty():
		return ""
	return "%s_fallback" % type_id

func _is_spawn_blocked_by_boss_encounter() -> bool:
	if BossEncounterManager == null:
		return false
	if not BossEncounterManager.has_method("is_encounter_active"):
		return false
	return bool(BossEncounterManager.is_encounter_active())
