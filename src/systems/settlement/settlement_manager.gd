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

var _arrival_check_timer: float = 0.0

func _process(delta: float) -> void:
	_arrival_check_timer += delta
	if _arrival_check_timer >= 60.0: # 每一分钟检查一次新 NPC 入住
		_arrival_check_timer = 0
		_check_town_npc_arrival()

func _check_town_npc_arrival() -> void:
	# 检查是否有空房间
	var free_houses = _get_available_houses()
	if free_houses.is_empty(): return
	
	for entry in town_npc_pool:
		if not entry.recruited and entry.condition.call():
			_spawn_town_npc(entry, free_houses.pop_back())

func _get_available_houses() -> Array:
	var available = []
	for node in buildings.keys():
		var res = buildings[node]
		if res.population_bonus > 0: # 是住所
			var occupied = false
			for home in npc_homes.values():
				if home == node:
					occupied = true
					break
			if not occupied:
				available.append(node)
	return available

func _spawn_town_npc(entry: Dictionary, house_node: Node2D) -> void:
	if not FileAccess.file_exists(entry.scene): return
	
	var scene = load(entry.scene)
	var npc = scene.instantiate()
	
	# 设置住所
	npc.global_position = house_node.global_position
	var entities = get_tree().current_scene.getChild("Entities")
	if entities: entities.add_child(npc)
	else: get_tree().current_scene.add_child(npc)
	
	if npc is BaseNPC:
		npc.npc_data.display_name = entry.name
		npc.npc_data.npc_type = "Town"
		npc.update_home_position(house_node.global_position)
		recruited_npcs.append(npc.npc_data)
		npc_homes[entry.name] = house_node
		entry.recruited = true
		
		if UIManager:
			UIManager.show_floating_text(entry.name + " 已入住！", npc.global_position, Color.GOLD)

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
