extends Node

## NPCSpawner (Refactored)
## Advanced spawning system based on Biome, Depth, Time, and Wall Rules (Terraria-style).

@export var spawn_radius_min: float = 600.0
@export var spawn_radius_max: float = 1200.0
@export var max_mobs: int = 20
@export var spawn_interval: float = 1.0
@export var spawn_chance: float = 0.6 

var last_spawn_check_time: float = 0.0

enum Zone { SURFACE, UNDERGROUND, CAVERN, SPACE }

class SpawnRule:
	var scene_path: String
	var weight: int
	var biomes: Array
	var zones: Array 
	var time_constraints: Array
	var requires_wall: bool = false 
	var requires_no_wall: bool = false 

	func _init(path: String, w: int, _biomes: Array, _zones: Array, _times: Array):
		scene_path = path
		weight = w
		biomes = _biomes
		zones = _zones
		time_constraints = _times

var spawn_table: Array[SpawnRule] = []

func _ready() -> void:
	add_to_group("npc_spawner")
	_build_registry()

func _build_registry() -> void:
	# --- Slimes (Day/Night, Surface/Underground, Multiple Biomes) ---
	# Slimes are basic mobs found in most places.
	var slime = SpawnRule.new("res://scenes/npc/slime.tscn", 100, ["Forest", "Plains", "Desert", "Swamp", "Any"], [Zone.SURFACE, Zone.UNDERGROUND], ["Any"])
	slime.requires_no_wall = true 
	spawn_table.append(slime)
	
	# --- Zombies (Night, Surface) ---
	var zombie = SpawnRule.new("res://scenes/npc/zombie.tscn", 80, ["Any"], [Zone.SURFACE], ["Night"])
	zombie.requires_no_wall = true 
	spawn_table.append(zombie)
	
	# --- Skeletons (Underground/Cavern only) ---
	# Strictly move skeletons to the underground. They ignore time of day in caves.
	var skeleton = SpawnRule.new("res://scenes/npc/skeleton.tscn", 120, ["Any"], [Zone.UNDERGROUND, Zone.CAVERN], ["Any"])
	spawn_table.append(skeleton)
	
	# --- Antlions (Day, Surface, Desert Only) ---
	# High weight in desert to ensure they show up.
	var antlion = SpawnRule.new("res://scenes/npc/antlion.tscn", 150, ["Desert"], [Zone.SURFACE], ["Day"])
	antlion.requires_no_wall = true
	spawn_table.append(antlion)

	# --- Demon Eyes (Night, Surface) ---
	var eye = SpawnRule.new("res://scenes/npc/demon_eye.tscn", 70, ["Any"], [Zone.SURFACE], ["Night"])
	spawn_table.append(eye)

func _process(delta: float) -> void:
	last_spawn_check_time += delta
	if last_spawn_check_time >= spawn_interval:
		last_spawn_check_time = 0
		_try_spawn_cycle()

func _try_spawn_cycle() -> void:
	var current_mobs = get_tree().get_nodes_in_group("hostile_npcs").size()
	if current_mobs >= max_mobs:
		# print("NPCSpawner: Max mobs reached.")
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		# print("NPCSpawner: No player found.")
		return
	
	if randf() > spawn_chance:
		# print("NPCSpawner: Spawn chance skip.")
		return

	var spawn_pos = _get_random_spawn_pos(player.global_position)
	if spawn_pos == Vector2.ZERO:
		print("NPCSpawner: Failed to find valid floor position.")
		return
	
	var context = _analyze_context(spawn_pos)
	print("NPCSpawner: Context at ", spawn_pos, " -> ", context)
	
	var candidates: Array[SpawnRule] = []
	var total_weight = 0
	
	for rule in spawn_table:
		if _is_rule_valid(rule, context):
			candidates.append(rule)
			total_weight += rule.weight
		# else:
			# print("NPCSpawner: Rule rejected: ", rule.scene_path.get_file())
			
	if candidates.is_empty():
		print("NPCSpawner: No matching rules for context.")
		return
	
	var roll = randi() % total_weight
	var current_w = 0
	for rule in candidates:
		current_w += rule.weight
		if roll < current_w:
			print("NPCSpawner: Selected mob -> ", rule.scene_path)
			_spawn_mob(rule.scene_path, spawn_pos)
			break

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
	var sm = get_node_or_null("/root/SettlementManager")
	if sm and sm.is_night: 
		ctx["time"] = "Night"
	
	ctx["has_wall"] = _has_background_wall(pos)
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
		return result.position - Vector2(0, 32)
	return Vector2.ZERO

func _spawn_mob(path: String, pos: Vector2) -> void:
	if not FileAccess.file_exists(path):
		print("NPCSpawner: ERROR! File not found: ", path)
		return
		
	var scene = load(path)
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
		mob.add_to_group("hostile_npcs")
		# 确保血条显示正确同步
		if mob.has_method("_update_hp_bar"):
			mob._update_hp_bar()
	else:
		# Just force add to group
		mob.add_to_group("hostile_npcs")
	
	var entities = get_tree().current_scene.find_child("Entities", true, false)
	if entities:
		entities.add_child(mob)
		print("NPCSpawner: Spawned ", mob.name, " in Entities.")
	else:
		get_tree().current_scene.add_child(mob)
		print("NPCSpawner: Spawned ", mob.name, " in Root.")
