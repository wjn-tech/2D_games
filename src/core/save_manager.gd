extends Node

## SaveManager (Autoload)
## 负责管理多槽位存档、元数据读取以及这一系列复杂系统的序列化。

const SAVE_ROOT = "user://saves/"

# 存档元数据结构
var save_metadata: Dictionary = {}

func _ready() -> void:
	_ensure_root_dir()
	_load_metadata()

func _ensure_root_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_ROOT):
		DirAccess.make_dir_recursive_absolute(SAVE_ROOT)

func _get_slot_dir(slot_id: int) -> String:
	return SAVE_ROOT + "slot_%d/" % slot_id

func _get_data_path(slot_id: int) -> String:
	return _get_slot_dir(slot_id) + "data.tres"

func _load_metadata() -> void:
	var file = FileAccess.open(SAVE_ROOT + "metadata.json", FileAccess.READ)
	if file:
		save_metadata = JSON.parse_string(file.get_as_text())
	if not save_metadata:
		save_metadata = {}

func _save_metadata_to_disk() -> void:
	var file = FileAccess.open(SAVE_ROOT + "metadata.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_metadata, "\t"))

# 获取某个槽位的显示信息
func get_slot_info(slot_id: int) -> Dictionary:
	var key = "slot_%d" % slot_id
	if save_metadata.has(key):
		return save_metadata[key]
	return {}

# --- 核心保存逻辑 ---

func save_game(slot_id: int) -> void:
	var slot_dir = _get_slot_dir(slot_id)
	if not DirAccess.dir_exists_absolute(slot_dir):
		DirAccess.make_dir_recursive_absolute(slot_dir)
	
	# 1. 切换无限地图管理器的目标目录并保存
	var world_path = slot_dir + "world_deltas/"
	if InfiniteChunkManager:
		InfiniteChunkManager.set_save_root(world_path)
		InfiniteChunkManager.save_all_deltas()
	
	# 2. 收集核心游戏数据
	var data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"game_time": GameState.current_time,
		"player": _pack_player_data(),
		"inventory": _pack_inventory(),
		"buildings": _pack_buildings()
	}
	
	# 3. 写入数据文件
	var file = FileAccess.open(_get_data_path(slot_id), FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()
		
	# 4. 更新元数据
	var key = "slot_%d" % slot_id
	save_metadata[key] = {
		"timestamp": data.timestamp,
		"player_name": data.player.data.display_name,
		"display_time": Time.get_datetime_string_from_system()
	}
	_save_metadata_to_disk()
	
	print("SaveManager: 存档 %d 保存成功" % slot_id)

func _pack_player_data() -> Dictionary:
	var player = get_tree().get_first_node_in_group("player")
	var pos = Vector2.ZERO
	if player: pos = player.global_position
	
	var p_data = GameState.player_data
	return {
		"position": pos,
		"data": {
			"display_name": p_data.display_name,
			"health": p_data.health,
			"max_health": p_data.max_health,
			"strength": p_data.strength,
			"agility": p_data.agility,
			"intelligence": p_data.intelligence,
			"constitution": p_data.constitution,
			# Lineage System Data
			"stat_levels": p_data.stat_levels,
			"mutations": p_data.mutations,
			"spouse_id": p_data.spouse_id,
			"generation": p_data.generation,
			"age": p_data.age,
			"growth_stage": p_data.growth_stage,
			"imprint_quality": p_data.imprint_quality
		}
	}

func _pack_inventory() -> Dictionary:
	var result = {"backpack": [], "hotbar": []}
	if GameState.inventory:
		var mgr = GameState.inventory # InventoryManager
		if "backpack" in mgr and mgr.backpack: 
			result.backpack = mgr.backpack.slots
		if "hotbar" in mgr and mgr.hotbar: 
			result.hotbar = mgr.hotbar.slots
	return result

func _pack_buildings() -> Array:
	var list = []
	var container = get_tree().get_first_node_in_group("buildings_container")
	if container:
		for child in container.get_children():
			if child.scene_file_path.is_empty(): continue
			
			var b_data = {
				"scene_path": child.scene_file_path,
				"position": child.global_position,
				"rotation": child.rotation
			}
			# 暂不处理自定义数据，除非有 save_data() 接口
			if child.has_method("save_data"):
				b_data["custom_data"] = child.save_data()
			list.append(b_data)
	return list

# --- 核心加载逻辑 ---

func load_game(slot_id: int) -> bool:
	var path = _get_data_path(slot_id)
	if not FileAccess.file_exists(path):
		push_error("SaveManager: 存档文件不存在 " + path)
		return false
		
	var file = FileAccess.open(path, FileAccess.READ)
	var data = file.get_var()
	file.close()
	
	# 1. 设定地图路径
	var slot_dir = _get_slot_dir(slot_id)
	if InfiniteChunkManager:
		InfiniteChunkManager.set_save_root(slot_dir + "world_deltas/")
		InfiniteChunkManager.world_delta_data.clear()
		InfiniteChunkManager.loaded_chunks.clear()

	# 2. 恢复全局状态
	GameState.current_time = data.get("game_time", 0.0)
	
	# 3. 恢复玩家数据 (缓存，待 GameManager 应用)
	if data.has("player"):
		var p_info = data.player
		var p_data = GameState.player_data
		var saved_stats = p_info.data
		
		p_data.display_name = saved_stats.get("display_name", "Player")

		# 3.1 Lineage System Data Restoration
		if saved_stats.has("stat_levels"):
			p_data.stat_levels = saved_stats.stat_levels
			p_data.mutations = saved_stats.get("mutations", {"patrilineal":0, "matrilineal":0})
			p_data.spouse_id = saved_stats.get("spouse_id", -1)
			p_data.generation = saved_stats.get("generation", 1)
			p_data.age = saved_stats.get("age", 0.0)
			p_data.growth_stage = saved_stats.get("growth_stage", 0)
			p_data.imprint_quality = saved_stats.get("imprint_quality", 0.0)
		else:
			# Legacy Save Fallback
			p_data.max_health = saved_stats.get("max_health", 100)
			p_data.strength = saved_stats.get("strength", 10)
			p_data.agility = saved_stats.get("agility", 10)
			p_data.intelligence = saved_stats.get("intelligence", 10)
			p_data.constitution = saved_stats.get("constitution", 10)

		p_data.health = saved_stats.get("health", 100)
		
		# 将位置存储在 Meta 中，供 GameManager 生成玩家时读取
		GameState.set_meta("load_spawn_pos", p_info.position)

	# 4. 恢复背包
	if data.has("inventory") and GameState.inventory:
		var inv_mgr = GameState.inventory
		if "backpack" in inv_mgr and inv_mgr.backpack:
			inv_mgr.backpack.slots = data.inventory.get("backpack", [])
			inv_mgr.backpack.content_changed.emit(-1)
		if "hotbar" in inv_mgr and inv_mgr.hotbar:
			inv_mgr.hotbar.slots = data.inventory.get("hotbar", [])
			inv_mgr.hotbar.content_changed.emit(-1)
		
	# 5. 恢复建筑列表
	GameState.set_meta("load_buildings", data.get("buildings", []))
	
	print("SaveManager: 存档 %d 数据已载入内存预备" % slot_id)
	return true
