extends Node

## NPCSpawner
## 负责基于环境条件（生物群落、时间、天气）在玩家周围生成敌对 NPC。

@export var spawn_radius_min: float = 600.0
@export var spawn_radius_max: float = 1200.0
@export var max_mobs: int = 15
@export var SPAWN_STEP_THRESHOLD: float = 1000.0

var last_spawn_check_pos: Vector2 = Vector2.ZERO

# 敌对外发预制件表 (按生物群落和时间分配)
var _mob_registry = {
	"Forest": {
		"Day": ["res://scenes/npc/slime.tscn"],
		"Night": ["res://scenes/npc/zombie.tscn", "res://scenes/npc/skeleton.tscn"]
	},
	"Desert": {
		"Day": ["res://scenes/npc/antlion.tscn"],
		"Night": ["res://scenes/npc/zombie.tscn"]
	}
}

func _ready() -> void:
	add_to_group("npc_spawner")
	var player = get_tree().get_first_node_in_group("player")
	if player:
		last_spawn_check_pos = player.global_position

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var dist = player.global_position.distance_to(last_spawn_check_pos)
	if dist >= SPAWN_STEP_THRESHOLD:
		last_spawn_check_pos = player.global_position
		# 移动 1000px 后尝试生成一波 (循环几次以增加成功率)
		for i in range(3):
			_try_spawn()

func _try_spawn() -> void:
	var current_mobs = get_tree().get_nodes_in_group("hostile_npcs").size()
	if current_mobs >= max_mobs:
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	# 1. 确定生成位置 (玩家视线外)
	var spawn_pos = _get_random_spawn_pos(player.global_position)
	if spawn_pos == Vector2.ZERO: return
	
	# 2. 确定生物群落和时间
	var biome = "Forest" # 默认，后续从 WorldGenerator 获取当前位置群落
	var is_night = SettlementManager.is_night if SettlementManager else false
	var time_key = "Night" if is_night else "Day"
	
	# 3. 选择随机生物
	var pool = _mob_registry.get(biome, {}).get(time_key, [])
	if pool.is_empty(): return
	
	var mob_path = pool.pick_random()
	_spawn_mob(mob_path, spawn_pos)

func _get_random_spawn_pos(center: Vector2) -> Vector2:
	var angle = randf() * TAU
	var dist = randf_range(spawn_radius_min, spawn_radius_max)
	var pos = center + Vector2(cos(angle), sin(angle)) * dist
	
	# 简单的地面检测 (向下射线)
	var space_state = get_viewport().world_2d.direct_space_state
	var query = PhysicsRayQueryParameters2D.create(pos + Vector2(0, -500), pos + Vector2(0, 500))
	query.collision_mask = LayerManager.LAYER_WORLD_0
	
	var result = space_state.intersect_ray(query)
	if result:
		var spawn_pos = result.position - Vector2(0, 16) # 稍微抬高一点
		
		# 检查前景是否为空 (只能生成在无前景的地面上)
		if LayerManager:
			var current_layer = LayerManager.get_current_layer()
			if current_layer:
				var map_pos = current_layer.local_to_map(current_layer.to_local(spawn_pos))
				if current_layer.get_cell_source_id(map_pos) != -1:
					return Vector2.ZERO # 被前景挡住了
					
		return spawn_pos
		
	return Vector2.ZERO

func _spawn_mob(path: String, pos: Vector2) -> void:
	if not FileAccess.file_exists(path): return
	
	var scene = load(path)
	if not scene: return
	
	var mob = scene.instantiate()
	mob.global_position = pos
	
	if mob is BaseNPC:
		if not mob.npc_data:
			mob.npc_data = CharacterData.new()
		mob.npc_data.alignment = "Hostile"
		mob.add_to_group("hostile_npcs")
	
	# 挂载到 Entities 节点
	var entities = get_tree().current_scene.find_child("Entities", true, false)
	if entities:
		entities.add_child(mob)
	else:
		get_tree().current_scene.add_child(mob)
	
	if mob is BaseNPC:
		print("NPCSpawner: 生成了 ", mob.name, " 于 ", pos)
