extends Node

## SettlementManager (Autoload)
## 管理城邦、招募的 NPC 及其职业分配。

signal npc_recruited(npc_data: CharacterData)
signal job_assigned(npc_data: CharacterData, job_id: String)

# 存储已招募的 NPC 数据
var recruited_npcs: Array[CharacterData] = []
# 存储职业分配: { npc_name: job_id }
var job_assignments: Dictionary = {}
# 存储 NPC 住所: { npc_name: house_node }
var npc_homes: Dictionary = {}

# 存储已建造的建筑: { node: BuildingResource }
var buildings: Dictionary = {}

# 城邦统计数据
var stats = {
	"population_current": 0,
	"population_max": 5, # 基础人口上限
	"food_production": 0.0,
	"defense": 0,
	"level": 1,
	"prosperity": 0,
	"territory_radius": 300.0 # 基础领土半径
}

signal stats_changed(new_stats: Dictionary)
signal night_toggled(is_night: bool)

var is_night: bool = false:
	set(value):
		is_night = value
		night_toggled.emit(is_night)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 初始计算
	_recalculate_stats()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_N:
		is_night = !is_night
		print("SettlementManager: 切换昼夜 (快捷键 N): ", "夜晚" if is_night else "白天")

func get_settlement_center() -> Vector2:
	if buildings.is_empty():
		var player = get_tree().get_first_node_in_group("player")
		return player.global_position if player else Vector2.ZERO
	
	# 简单起见，取第一个建筑的位置作为中心
	return buildings.keys()[0].global_position

## 注册新建筑
func register_building(node: Node2D, resource: BuildingResource) -> void:
	buildings[node] = resource
	_recalculate_stats()
	
	# 尝试为无家可归的 NPC 分配住所
	_assign_homes_to_homeless()
	
	# 如果建筑被销毁，自动移除
	node.tree_exited.connect(func(): unregister_building(node))

## 移除建筑
func unregister_building(node: Node2D) -> void:
	if node in buildings:
		# 如果是住所，移除相关 NPC 的分配
		for npc_name in npc_homes.keys():
			if npc_homes[npc_name] == node:
				npc_homes.erase(npc_name)
				# 通知 NPC 失去住所
				_notify_npc_lost_home(npc_name)
				
		buildings.erase(node)
		_recalculate_stats()

# 城镇 NPC 到达规则
var town_npc_pool = [
	{
		"name": "商人",
		"scene": "res://scenes/npc/merchant.tscn",
		"condition": func(): return GameState.player_data.gold >= 50,
		"recruited": false
	},
	{
		"name": "向导",
		"scene": "res://scenes/npc/guide.tscn",
		"condition": func(): return true, # 默认存在
		"recruited": false
	}
]

# 迁徙系统变量
var migration_queue: Array = []
var _arrival_check_timer: float = 0.0

func _process(delta: float) -> void:
	_arrival_check_timer += delta
	if _arrival_check_timer >= 30.0: # 每 30 秒进行一次迁徙检查
		_arrival_check_timer = 0
		_process_migration_logic()

## 新增：自然迁徙逻辑 (Migration System)
func _process_migration_logic() -> void:
	# 1. 评估当前城镇的吸引力 (Housing Suitability)
	var available_houses = _get_available_suitable_houses()
	if available_houses.is_empty(): return
	
	# 2. 检查潜在 NPC 模板
	for npc_template in town_npc_pool:
		if npc_template["recruited"]: continue
		
		# 检查硬性条件
		if npc_template["condition"].call():
			# NPC 不会瞬间出现，而是先加入“听闻-迁徙”队列
			if not migration_queue.has(npc_template["name"]):
				print("SettlementManager: [", npc_template["name"], "] 听闻了你的城镇，正在路上...")
				migration_queue.append(npc_template["name"])
				
				# 延迟执行真实生成，模拟 NPC “走”到城镇的过程
				_schedule_npc_arrival(npc_template, available_houses[0])

func _get_available_suitable_houses() -> Array:
	var list = []
	for b_node in buildings:
		var res = buildings[b_node]
		# 只有 House 类型的建筑且未被占用才可入住
		if res.building_name == "住宅" or res.building_name == "House":
			var is_occupied = false
			for home in npc_homes.values():
				if home == b_node:
					is_occupied = true
					break
			if not is_occupied:
				list.append(b_node)
	return list

func _schedule_npc_arrival(template: Dictionary, target_house: Node2D) -> void:
	# 模拟几天后的迁入 (这里用 15 秒演示)
	await get_tree().create_timer(15.0).timeout
	
	# 双重检查：如果期间已被招募，则取消
	if template["recruited"]: return
	
	# 寻找城镇入口 (寻找合法的地面生成点)
	var dir = 1 if randf() > 0.5 else -1
	var spawn_x = get_settlement_center().x + (1600 * dir)
	var spawn_pos = _find_valid_ground_pos(spawn_x, get_settlement_center().y)
	
	# 确保不在屏幕上，防止“凭空出现”的突兀感
	var try_count = 0
	while _is_pos_on_screen(spawn_pos) and try_count < 8:
		spawn_x += 600 * dir
		spawn_pos = _find_valid_ground_pos(spawn_x, get_settlement_center().y)
		try_count += 1
	
	var scene = load(template["scene"])
	if scene:
		var npc = scene.instantiate()
		npc.global_position = spawn_pos
		
		# 加入场景
		get_tree().current_scene.add_child(npc)
		template["recruited"] = true
		migration_queue.erase(template["name"])
		
		# 分配住所
		if npc.has_method("sync_data_to_blackboard"):
			npc_homes[template["name"]] = target_house
			print("SettlementManager: [", template["name"], "] 已抵达！入住: ", target_house.name)
			
			# 设置 AI 状态
			if npc.bt_player and npc.bt_player.blackboard:
				npc.bt_player.blackboard.set_var("home_pos", target_house.global_position)
				# 可以在这里触发一个 "MoveToHome" 行为
				
func _find_valid_ground_pos(target_x: float, search_start_y: float) -> Vector2:
	# 垂直射线寻找地面
	var space_state = get_tree().root.get_world_2d().direct_space_state
	# 从高空向下扫描
	var query = PhysicsRayQueryParameters2D.create(Vector2(target_x, search_start_y - 500), Vector2(target_x, search_start_y + 500))
	query.collision_mask = LayerManager.LAYER_WORLD_0 # World Layer
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.position - Vector2(0, 32) # 地面之上
	
	# 如果找不到，返回一个相对安全的备份位置
	return Vector2(target_x, search_start_y)

func _is_pos_on_screen(pos: Vector2) -> bool:
	var viewport = get_viewport()
	if not viewport: return false
	var camera = viewport.get_camera_2d()
	if not camera: return false
	
	var screen_center = camera.get_screen_center_position()
	var screen_size = viewport.get_visible_rect().size / camera.zoom
	var view_rect = Rect2(screen_center - screen_size / 2.0, screen_size)
	return view_rect.grow(250.0).has_point(pos)

func _recalculate_stats() -> void:
	stats.population_max = 5 # 重置为基础值
	stats.food_production = 0.0
	stats.defense = 0
	stats.population_current = recruited_npcs.size()
	
	var total_influence = 300.0
	
	for resource in buildings.values():
		stats.population_max += resource.population_bonus
		stats.food_production += resource.food_production
		stats.defense += resource.defense_bonus
		total_influence = max(total_influence, resource.influence_radius)
	
	stats.territory_radius = total_influence
	
	# 计算繁荣度 (公式: 建筑*10 + 人口*5 + 食物*2 + 防御)
	stats.prosperity = buildings.size() * 10 + stats.population_current * 5 + int(stats.food_production * 2) + stats.defense
	
	# 计算等级
	var old_level = stats.level
	if stats.prosperity < 100: stats.level = 1
	elif stats.prosperity < 500: stats.level = 2
	else: stats.level = 3
	
	if old_level != stats.level:
		print("SettlementManager: 城邦等级提升至: ", stats.level)
	
	stats_changed.emit(stats)
	print("SettlementManager: 城邦数据更新: ", stats)

func _assign_homes_to_homeless() -> void:
	for npc_data in recruited_npcs:
		if not npc_homes.has(npc_data.display_name):
			var house = _find_available_house()
			if house:
				npc_homes[npc_data.display_name] = house
				_notify_npc_of_home(npc_data.display_name, house.global_position)

func _find_available_house() -> Node2D:
	for node in buildings.keys():
		var res = buildings[node]
		# 假设 population_bonus > 0 的建筑可以住人
		if res.population_bonus > 0:
			var count = 0
			for home_node in npc_homes.values():
				if home_node == node:
					count += 1
			if count < res.population_bonus:
				return node
	return null

func _notify_npc_of_home(npc_name: String, pos: Vector2) -> void:
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc.has_method("update_home_position") and npc.npc_data.display_name == npc_name:
			npc.update_home_position(pos)
			break

func _notify_npc_lost_home(npc_name: String) -> void:
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc is BaseNPC and npc.npc_data.display_name == npc_name:
			npc.update_home_position(Vector2.ZERO)
			# 如果正在回家途中，取消任务
			if npc.bt_player and npc.bt_player.blackboard:
				npc.bt_player.blackboard.set_var("home_pos", Vector2.ZERO)
			break

## 尝试招募 NPC
func recruit_npc(npc_data: CharacterData) -> bool:
	# 检查人口上限
	if recruited_npcs.size() >= stats.population_max:
		print("SettlementManager: 人口已达上限，无法招募")
		return false
		
	# 只有好感度/忠诚度达到 50 才能招募
	if npc_data.loyalty >= 50 and not npc_data in recruited_npcs:
		recruited_npcs.append(npc_data)
		npc_data.alignment = "Friendly"
		_recalculate_stats()
		_assign_homes_to_homeless()
		npc_recruited.emit(npc_data)
		print("SettlementManager: 成功招募 NPC: ", npc_data.display_name)
		return true
	return false

## 分配职业
func assign_job(npc_data: CharacterData, job_id: String) -> void:
	if not npc_data in recruited_npcs:
		push_warning("SettlementManager: 无法为未招募的 NPC 分配职业")
		return
		
	job_assignments[npc_data.display_name] = job_id
	job_assigned.emit(npc_data, job_id)
	print("SettlementManager: 为 ", npc_data.display_name, " 分配职业: ", job_id)

## 获取 NPC 当前职业
func get_npc_job(npc_data: CharacterData) -> String:
	return job_assignments.get(npc_data.display_name, "None")

## 获取位置附近的效率加成 (0.0 - 1.0)
func get_efficiency_bonus(global_pos: Vector2) -> float:
	var total_bonus = 0.0
	for b_node in buildings.keys():
		if b_node.has_method("_apply_buffs"): 
			var dist = b_node.global_position.distance_to(global_pos)
			var radius = b_node.get("buff_radius") if "buff_radius" in b_node else 0.0
			if dist <= radius:
				total_bonus += b_node.get("efficiency_bonus") if "efficiency_bonus" in b_node else 0.0
	return clamp(total_bonus, 0.0, 1.0)
