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
	"population_max": 5, 
	"food_production": 0.0,
	"defense": 0,
	"level": 1,
	"prosperity": 0,
	"territory_radius": 300.0 
}

# 缓存的房屋检测结果: { anchor_map_pos: HousingData }
var housing_cache: Dictionary = {}

# 晶塔相关
var active_pylons: Dictionary = {} # { biome_name: global_pos }

var is_night: bool = false
signal night_toggled(is_night: bool)
signal stats_changed(new_stats: Dictionary)
# ... 其他信号

func _ready() -> void:
# ... Existing _ready ...
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 初始计算
	_recalculate_stats()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_N:
		is_night = !is_night
		night_toggled.emit(is_night)
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

## 标记房屋需要重新检测
func mark_housing_dirty(global_pos: Vector2):
	# 简单做法：清空该位置附近的缓存或全量标记
	# 临时：全量清空 (后续优化)
	housing_cache.clear()
	print("SettlementManager: 建筑变动，房屋缓存已清空")

## 自动结算：寻找无家可归的 NPC 并分配房屋
func _process_settlement_tick():
	# 遍历所有城镇 NPC
	var npcs = get_tree().get_nodes_in_group("town_npcs")
	for npc in npcs:
		if not npc.get("npc_data"): continue
		var data = npc.npc_data
		if not data.is_settled:
			_try_assign_home(npc)

func _try_assign_home(npc: Node):
	# 扫描附近已建成的、为空的有效房屋
	for room_id in housing_cache.keys():
		var info = housing_cache[room_id]
		if info.get("occupied_by") == "":
			info["occupied_by"] = npc.name
			npc.npc_data.is_settled = true
			npc.npc_data.home_pos = info.interior[0] # 取填充点作为家
			print("SettlementManager: NPC ", npc.name, " 入住房屋 ", room_id)
			return

## 房屋检测核心逻辑 (基于单个区块 64x64)
func check_house(global_pos: Vector2) -> Dictionary:
	var lm = get_node_or_null("/root/LayerManager")
	if not lm: return {"is_valid": false, "error": "System Error"}
	
	var l0 = lm.layer_nodes.get(0)
	var l2 = lm.layer_nodes.get(2)
	if not l0 or not l2: return {"is_valid": false, "error": "Layer Error"}
	
	var start_map_pos = l0.local_to_map(l0.to_local(global_pos))
	
	# 1. 泛洪填充 (Flood Fill)
	var stack = [start_map_pos]
	var interior = {}
	var max_tiles = 750
	
	# 区块边界判定
	var icm = get_node_or_null("/root/InfiniteChunkManager")
	var chunk_coord = icm.get_chunk_coord(global_pos) if icm else Vector2i.ZERO
	var chunk_origin = chunk_coord * 64
	
	while stack.size() > 0:
		var p = stack.pop_back()
		if interior.has(p): continue
		
		# 是否超出单个区块边界
		if p.x < chunk_origin.x or p.x >= chunk_origin.x + 64 or \
		   p.y < chunk_origin.y or p.y >= chunk_origin.y + 64:
			return {"is_valid": false, "error": "超出区块边界 (Max 64x64)"}
		
		# 是否遇到 Layer 0 实心块
		if l0.get_cell_source_id(p) != -1: continue
		
		interior[p] = true
		if interior.size() > max_tiles:
			return {"is_valid": false, "error": "房屋太大 (Max 749)"}
		
		for off in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			stack.push_back(p + off)
	
	if interior.size() < 30:
		return {"is_valid": false, "error": "房太小 (Min 30)"}
	
	# 2. 检查背景墙 (Layer 2) 覆盖度与空洞
	var wall_count = 0
	for p in interior:
		if l2.get_cell_source_id(p) != -1:
			wall_count += 1
	
	if float(wall_count) / interior.size() < 0.9:
		return {"is_valid": false, "error": "背景墙不完整"}
	
	# 3. 检查必备家具 (基于群组)
	var found_light = false
	var found_comfort = false
	var found_table = false
	var found_door = false
	
	var space = l0.get_world_2d().direct_space_state
	for p in interior:
		var query = PhysicsPointQueryParameters2D.new()
		query.position = l0.to_global(l0.map_to_local(p))
		# 寻找物体
		var results = space.intersect_point(query)
		for res in results:
			var obj = res.collider
			if obj.is_in_group("housing_light"): found_light = true
			if obj.is_in_group("housing_comfort"): found_comfort = true
			if obj.is_in_group("housing_table"): found_table = true
			if obj.is_in_group("housing_door") or obj.is_in_group("interactive_door"): found_door = true
	
	if not found_light: return {"is_valid": false, "error": "缺少光源"}
	if not found_table: return {"is_valid": false, "error": "缺少桌/台"}
	if not found_comfort: return {"is_valid": false, "error": "缺少舒适家具(椅/凳)"}
	if not found_door: return {"is_valid": false, "error": "缺少入口(门/平台)"}

	return {"is_valid": true, "interior": interior.keys(), "error": "该房屋已符合入住条件！"}

## 房屋检查指令 (由 UI 调用)
func inspect_housing(global_pos: Vector2) -> String:
	var result = check_house(global_pos)
	if result.is_valid:
		return result.error
	else:
		return "此房屋无效：" + result.error

## 全量扫描附近的房屋 (用于 UI 显示)
func scan_all_housing() -> Dictionary:
	var player = get_tree().get_first_node_in_group("player")
	if not player: return {}
	
	housing_cache.clear()
	
	# 扫描玩家周围 200x200 瓦片的范围
	var center_p = player.global_position
	var range_px = 800
	
	# 为了性能，我们在这个范围内每隔 32 像素尝试进行一次 Flood Fill
	# 找到一个空气格就开始填充
	var lm = get_node_or_null("/root/LayerManager")
	var l0 = lm.layer_nodes.get(0) if lm else null
	if not l0: return {}
	
	var seen_tiles = {}
	
	for x in range(center_p.x - range_px, center_p.x + range_px, 32):
		for y in range(center_p.y - range_px, center_p.y + range_px, 32):
			var pos = Vector2(x, y)
			var map_p = l0.local_to_map(l0.to_local(pos))
			
			if seen_tiles.has(map_p): continue
			if l0.get_cell_source_id(map_p) == -1: # 空气
				var result = check_house(pos)
				if result.has("interior"):
					for p in result.interior:
						seen_tiles[p] = true
					
					var rid = "house_%d_%d" % [map_p.x, map_p.y]
					housing_cache[rid] = result
					
					# 寻找当前居住者
					housing_cache[rid]["occupied_by"] = ""
					for nname in npc_homes.keys():
						if npc_homes[nname] == rid:
							housing_cache[rid]["occupied_by"] = nname
	
	return housing_cache

func assign_npc_to_house(npc_name: String, house_id: String) -> void:
	# 先解除该 NPC 之前的绑定
	for rid in housing_cache.keys():
		if housing_cache[rid].get("occupied_by") == npc_name:
			housing_cache[rid]["occupied_by"] = ""
	
	# 解除该房屋之前的绑定
	if npc_homes.values().has(house_id):
		for nname in npc_homes.keys():
			if npc_homes[nname] == house_id:
				npc_homes.erase(nname)
				_notify_npc_lost_home(nname)
	
	# 新绑定
	npc_homes[npc_name] = house_id
	if housing_cache.has(house_id):
		housing_cache[house_id]["occupied_by"] = npc_name
		
	print("SettlementManager: 手动分配 ", npc_name, " 到房间 ", house_id)
	
	# 更新 NPC 行为
	var npcs = get_tree().get_nodes_in_group("town_npcs")
	for npc in npcs:
		if npc.name == npc_name:
			var bb = npc.get_node("BTPlayer").blackboard if npc.get_node_or_null("BTPlayer") else null
			if bb and housing_cache.has(house_id):
				bb.set_var("home_pos", housing_cache[house_id].interior[0] * 16.0)

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
	# 使用新的房屋缓存系统
	for room_id in housing_cache.keys():
		var info = housing_cache[room_id]
		if info.get("is_valid", false) and info.get("occupied_by", "") == "":
			list.append(room_id)
	return list

func _schedule_npc_arrival(template: Dictionary, target_room_id: String) -> void:
	# 模拟 NPC 从城镇边缘走过来
	var player = get_tree().get_first_node_in_group("player")
	var dir = 1 if randf() > 0.5 else -1
	var spawn_x = player.global_position.x + 1200 * dir if player else 1200 * dir
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
		npc_homes[template["name"]] = target_room_id # 这里暂存 ID
		print("SettlementManager: [", template["name"], "] 已抵达！入住: ", target_room_id)
		
		# 设置 AI 状态
		if npc.has_method("sync_data_to_blackboard") or npc.get("bt_player"):
			var bb = npc.get_node("BTPlayer").blackboard if npc.get_node_or_null("BTPlayer") else null
			if bb:
				# 获取房屋位置
				var room_info = housing_cache.get(target_room_id)
				if room_info:
					bb.set_var("home_pos", room_info.interior[0] * 16.0) # 假设 16 像素/格

## --- Phase 5: 快乐度与社交系统 ---

## 计算 NPC 当前的快乐度 (0.0 - 2.0, 1.0 为基准)
func get_npc_happiness(npc_name: String) -> float:
	var happiness = 1.0
	
	# 1. 寻找该 NPC 的住所
	var home_info = null
	for rid in housing_cache.keys():
		if housing_cache[rid].get("occupied_by") == npc_name:
			home_info = housing_cache[rid]
			break
	
	if not home_info: return 0.5 # 无家可归者不快乐
	
	# 2. 邻近度检查 (拥挤度)
	var neighbor_count = 0
	var home_pos = home_info.interior[0]
	for rid in housing_cache.keys():
		var other = housing_cache[rid]
		if other.get("occupied_by") != "" and other.get("occupied_by") != npc_name:
			var dist = Vector2(home_pos).distance_to(Vector2(other.interior[0]))
			if dist < 50: # 非常近的邻居
				neighbor_count += 1
	
	if neighbor_count > 2:
		happiness -= 0.1 * (neighbor_count - 2) # 拥挤减成
	elif neighbor_count == 0:
		happiness += 0.05 # 独居小加成
		
	return clamp(happiness, 0.0, 2.0)

## 注册晶塔 (只有当区域内有 2 个以上开心的 NPC 时才可使用)
func register_pylon(pylon_name: String, global_pos: Vector2):
	active_pylons[pylon_name] = global_pos
	print("SettlementManager: 晶塔 [", pylon_name, "] 已激活")

## 晶塔传送
func travel_pylon(to_pylon_name: String):
	if not active_pylons.has(to_pylon_name): return
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# 只有在另一个晶塔附近时才能传送 (泰拉瑞亚规则)
		var near_any = false
		for p_pos in active_pylons.values():
			if player.global_position.distance_to(p_pos) < 100:
				near_any = true
				break
				
		if near_any:
			player.global_position = active_pylons[to_pylon_name]
			print("SettlementManager: 传送至 ", to_pylon_name)
		else:
			print("SettlementManager: 你需要靠近一个晶塔才能进行传送")

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
