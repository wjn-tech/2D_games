extends Node

## NPCSpawner (Refactored)
## Advanced spawning system based on Biome, Depth, Time, and Wall Rules (Terraria-style).

@export var spawn_radius_min: float = 800.0
@export var spawn_radius_max: float = 1600.0
@export var max_mobs: int = 20
@export var spawn_interval: float = 1.0
@export var spawn_chance: float = 0.6 

var last_spawn_check_time: float = 0.0

enum Zone { SURFACE, UNDERGROUND, CAVERN, SPACE }

# 新增：生态统计与来源定义
var population_map: Dictionary = {} 
var area_capacity: int = 15 # 每个区域的最大承载力
var pending_spawns: int = 0 # 新增：正在队列中等待生成的数量

class SpawnRule:
	var scene_path: String
	var weight: int
	var biomes: Array
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

	func _init(path: String, w: int, _biomes: Array, _zones: Array, _times: Array, _origin: String = "natural", _max: int = 5):
		scene_path = path
		weight = w
		biomes = _biomes
		zones = _zones
		time_constraints = _times
		origin_type = _origin
		max_active_count = _max

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
	_build_registry()

func reset() -> void:
	print("NPCSpawner: Clearing population registry...")
	population_map.clear()
	last_spawn_check_time = 0.0

func _build_registry() -> void:
	# --- 规则现在包含 max_count ---
	# 史莱姆：种群较大
	var slime = SpawnRule.new("res://scenes/npc/slime.tscn", 80, ["Forest", "Plains", "Any"], [Zone.SURFACE], ["Any"], "falling", 8)
	slime.requires_no_wall = true 
	slime.group_min = 1
	slime.group_max = 2
	spawn_table.append(slime)

	var bog_slime = SpawnRule.new("res://scenes/npc/bog_slime.tscn", 110, ["Swamp"], [Zone.SURFACE, Zone.UNDERGROUND], ["Any"], "falling", 6)
	bog_slime.requires_no_wall = true
	bog_slime.feature_tags = ["MudMound", "Any"]
	bog_slime.cave_regions = ["Pocket", "OpenCavern", "Any"]
	bog_slime.min_openness = 0.12
	bog_slime.group_min = 1
	bog_slime.group_max = 2
	spawn_table.append(bog_slime)
	
	# 僵尸（敌国追兵）：偏向平原与林地的地表重装近战
	var zombie = SpawnRule.new("res://scenes/npc/zombie.tscn", 95, ["Plains", "Forest"], [Zone.SURFACE], ["Any"], "burrow", 5)
	zombie.requires_no_wall = true 
	spawn_table.append(zombie)
	
	# 骷髅投矛手：偏向连接洞与洞室
	var skeleton = SpawnRule.new("res://scenes/npc/skeleton.tscn", 105, ["Any"], [Zone.UNDERGROUND, Zone.CAVERN], ["Any"], "burrow", 6)
	skeleton.cave_regions = ["Tunnel", "Chamber", "Connector"]
	skeleton.min_openness = 0.3
	skeleton.requires_reachable_cave = true
	spawn_table.append(skeleton)

	var cave_bat = SpawnRule.new("res://scenes/npc/cave_bat.tscn", 115, ["Any"], [Zone.UNDERGROUND, Zone.CAVERN], ["Any"], "natural", 6)
	cave_bat.cave_regions = ["OpenCavern", "Chamber"]
	cave_bat.min_openness = 0.55
	cave_bat.requires_reachable_cave = true
	cave_bat.group_min = 2
	cave_bat.group_max = 4
	spawn_table.append(cave_bat)
	
	# 蚁狮：较少
	var antlion = SpawnRule.new("res://scenes/npc/antlion.tscn", 150, ["Desert"], [Zone.SURFACE], ["Day"], "emerging", 3)
	antlion.requires_no_wall = true
	antlion.feature_tags = ["DesertSpire", "Any"]
	spawn_table.append(antlion)

	var frost_bat = SpawnRule.new("res://scenes/npc/frost_bat.tscn", 90, ["Tundra"], [Zone.SURFACE, Zone.UNDERGROUND, Zone.CAVERN], ["Any"], "natural", 4)
	frost_bat.cave_regions = ["OpenCavern", "Chamber", "Any"]
	frost_bat.feature_tags = ["FrostSpire", "Any"]
	frost_bat.min_openness = 0.4
	frost_bat.group_min = 1
	frost_bat.group_max = 3
	spawn_table.append(frost_bat)

	# 恶魔之眼：空中单位较少
	var eye = SpawnRule.new("res://scenes/npc/demon_eye.tscn", 70, ["Any"], [Zone.SURFACE], ["Night"], "natural", 3)
	eye.feature_tags = ["Any"]
	spawn_table.append(eye)

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
	var total_weight = 0
	
	for rule in spawn_table:
		if _is_rule_valid(rule, context):
			# 检查该种群是否已达上限
			if _count_active_mobs(rule.scene_path) < rule.max_active_count:
				candidates.append(rule)
				total_weight += rule.weight
			
	if candidates.is_empty():
		return
	
	var roll = randi() % total_weight
	var current_w = 0
	for rule in candidates:
		current_w += rule.weight
		if roll < current_w:
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
			_spawn_group(rule.scene_path, pos, spawn_count, false)
			
		"falling":
			# 从高处跳下：用于史莱姆等，初始位置略高
			_spawn_group(rule.scene_path, pos + Vector2(0, -60), spawn_count, false)
			
		"emerging":
			# 伪装显现：用于蚁狮
			_spawn_group(rule.scene_path, pos, spawn_count, false)
			
		_:
			# 默认生成
			var spawn_pos = pos
			if rule.scene_path.contains("demon_eye"):
				# 恶魔眼属于飞行单位，默认生成点上移，避免贴地出生。
				spawn_pos += Vector2(0, -180)
			_spawn_group(rule.scene_path, spawn_pos, spawn_count, rule.scene_path.contains("eye") or rule.scene_path.contains("bat"))
			
	# 生成完成后减少 pending 计数（此时 _spawn_mob 已经将实体放入树中，active_mobs 应该增加了）
	for _i in range(spawn_count):
		_decrement_pending(rule.scene_path)

func _spawn_group(path: String, origin: Vector2, count: int, aerial: bool) -> void:
	for index in range(count):
		var offset_x = randf_range(-80.0, 80.0) + (index * 24.0)
		var offset_y = randf_range(-24.0, 24.0)
		if aerial:
			offset_y -= randf_range(40.0, 120.0)
		_spawn_mob(path, origin + Vector2(offset_x, offset_y))

func _analyze_context(pos: Vector2) -> Dictionary:
	var ctx = {}
	var tile_pos = pos / 16.0
	
	var wg = get_tree().get_first_node_in_group("world_generator")
	var surface_y = 300.0 # 默认地表高度 (瓦片单位)
	if wg and wg.has_method("get_surface_height_at"):
		surface_y = wg.get_surface_height_at(int(tile_pos.x))
	
	# 计算相对于地表的深度
	var depth = tile_pos.y - surface_y
	
	# 动态判定区域 (Terraria 风格)
	if depth < -60: ctx["zone"] = Zone.SPACE         # 太空/高空
	elif depth < 40: ctx["zone"] = Zone.SURFACE      # 地表及浅层
	elif depth < 250: ctx["zone"] = Zone.UNDERGROUND # 地下
	else: ctx["zone"] = Zone.CAVERN                 # 洞穴
		
	ctx["biome"] = "Forest"
	if wg and wg.has_method("get_biome_weights_at_pos"):
		var weights = wg.get_biome_weights_at_pos(pos)
		var max_w = -1.0
		for b in weights:
			if weights[b] > max_w:
				max_w = weights[b]
				ctx["biome"] = _map_biome(b)
	
	ctx["time"] = "Day"
	var chron = get_node_or_null("/root/Chronometer")
	if chron and chron.has_method("get_time_phase"):
		ctx["time"] = "Night" if chron.get_time_phase() == "Night" else "Day"
	else:
		var sm = get_node_or_null("/root/SettlementManager")
		if sm and sm.is_night:
			ctx["time"] = "Night"
	
	ctx["has_wall"] = _has_background_wall(pos)
	ctx["feature_tag"] = "Any"
	ctx["cave_region"] = "Surface"
	ctx["cave_reachable"] = true
	ctx["cave_openness"] = 1.0
	if wg and wg.has_method("get_surface_feature_tag_at_pos"):
		ctx["feature_tag"] = wg.get_surface_feature_tag_at_pos(pos)
	if wg and wg.has_method("get_cave_region_info_at_pos"):
		var cave_info = wg.get_cave_region_info_at_pos(pos)
		ctx["cave_region"] = cave_info.get("region", "Surface")
		ctx["cave_reachable"] = cave_info.get("reachable", true)
		ctx["cave_openness"] = cave_info.get("openness", 1.0)
	return ctx

func _map_biome(val: int) -> String:
	match val:
		0: return "Forest"
		1: return "Plains"
		2: return "Desert"
		3: return "Tundra"
		4: return "Swamp"
		_: return "Forest"

func _has_background_wall(pos: Vector2) -> bool:
	if not LayerManager: return false
	var bg = LayerManager.get_layer(1)
	if bg and bg is TileMapLayer:
		# Check slightly above the floor (+16px up is -16y)
		var check_pos = pos - Vector2(0, 16)
		var mp = bg.local_to_map(bg.to_local(check_pos))
		if bg.get_cell_source_id(mp) != -1: return true
	return false

func _is_rule_valid(rule: SpawnRule, ctx: Dictionary) -> bool:
	if not rule.zones.has(ctx["zone"]): return false
	if not rule.biomes.has("Any") and not rule.biomes.has(ctx["biome"]): return false
	if not rule.time_constraints.has("Any") and not rule.time_constraints.has(ctx["time"]): return false
	if not rule.feature_tags.has("Any") and not rule.feature_tags.has(ctx["feature_tag"]): return false
	if not rule.cave_regions.has("Any") and not rule.cave_regions.has(ctx["cave_region"]): return false
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
	
	# Ensure LayerManager is ready before accessing constant
	if LayerManager:
		query.collision_mask = LayerManager.LAYER_WORLD_0
	else:
		query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
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


func _spawn_mob(path: String, pos: Vector2) -> void:
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
