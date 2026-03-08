extends Node

## SaveManager (Autoload)
## 负责管理多槽位存档、元数据读取以及这一系列复杂系统的序列化。

const SAVE_ROOT = "user://saves/"
const DATA_FILENAME = "data.dat"
const THUMBNAIL_FILENAME = "preview.jpg"

# 临时存储从文件恢复的玩家数据，用于场景重载后同步
var _cached_player_data: Dictionary = {}

# 存档元数据结构
var save_metadata: Dictionary = {}
var current_slot_id: int = -1
var auto_save_timer: Timer

func _ready() -> void:
	_ensure_root_dir()
	_load_metadata()
	_init_autosave()

func _init_autosave() -> void:
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = 300.0 # 5 minutes
	auto_save_timer.one_shot = false
	# Don't autostart immediately, only after load/new game
	auto_save_timer.timeout.connect(_on_autosave_timeout)
	add_child(auto_save_timer)

func _on_autosave_timeout() -> void:
	if current_slot_id >= 0:
		# Use a background thread or sliced logic? No, synchronous for now per spec.
		save_game(current_slot_id)
		print("SaveManager: Autosave executed for slot %d" % current_slot_id)

func start_autosave() -> void:
	if auto_save_timer: auto_save_timer.start()

func stop_autosave() -> void:
	if auto_save_timer: auto_save_timer.stop()

func _ensure_root_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_ROOT):
		DirAccess.make_dir_recursive_absolute(SAVE_ROOT)

func _get_slot_dir(slot_id: int) -> String:
	return SAVE_ROOT + "slot_%d/" % slot_id

func _get_data_path(slot_id: int) -> String:
	return _get_slot_dir(slot_id) + DATA_FILENAME

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
	current_slot_id = slot_id
	# Reset autosave timer on manual save
	if auto_save_timer and not auto_save_timer.is_stopped():
		auto_save_timer.start()
		
	var slot_dir = _get_slot_dir(slot_id)
	if not DirAccess.dir_exists_absolute(slot_dir):
		DirAccess.make_dir_recursive_absolute(slot_dir)
	
	# 1. 切换无限地图管理器的目标目录并同步保存最新的内存修改
	var world_path = slot_dir + "world_deltas/"
	if InfiniteChunkManager:
		InfiniteChunkManager.set_save_root(world_path)
		InfiniteChunkManager.save_all_deltas() # 强制物块修改写盘
	
	# 2. 收集核心游戏数据
	var data = {
		"version": "2.0",
		"timestamp": Time.get_unix_time_from_system(),
		"scene_path": get_tree().current_scene.scene_file_path, # 保存当前场景路径
		"game_time": GameState.current_time,
		"player": _pack_player_data(),
		"inventory": _pack_inventory(),
		"buildings": _pack_buildings(),
		"pickups": _pack_pickups(),
		"weather": _pack_weather(),
		"minimap": _pack_minimap(),
		"persist_group": _pack_persist_group(),
		"hostiles": _pack_hostiles(),
		"descendants": _pack_descendants(), # 新增：保存子嗣列表
		"world_seed": _get_world_seed()
	}
	
	# 3. 写入数据文件 (Atomic & Compressed)
	var final_path = _get_data_path(slot_id)
	
	# Capture Thumbnail
	_capture_screenshot(slot_id)

	if not _write_atomic_compressed(final_path, data):
		push_error("SaveManager: Failed to save game data atomically.")
		return
		
	# 4. 更新元数据
	var key = "slot_%d" % slot_id
	var p_name = "Unknown"
	var p_gen = 1
	var p_lineage = "unknown"
	
	if data.player and data.player.data:
		p_name = data.player.data.get("display_name", "Player")
		p_gen = data.player.data.get("generation", 1)
		p_lineage = data.player.data.get("lineage_id", "L-%d" % slot_id)
		
	save_metadata[key] = {
		"timestamp": data.timestamp,
		"player_name": p_name,
		"generation": p_gen,
		"lineage_id": p_lineage,
		"display_time": Time.get_datetime_string_from_system()
	}
	_save_metadata_to_disk()
	
	print("SaveManager: 存档 %d 保存成功 (Binary/Atomic)" % slot_id)

func _write_atomic_compressed(path: String, data: Variant) -> bool:
	var tmp_path = path + ".tmp"
	var bak_path = path + ".bak"
	
	var file = FileAccess.open_compressed(tmp_path, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if not file:
		return false
	file.store_var(data, true) # Ensure full object (Resource) serialization
	file.close()
	
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(bak_path)
		DirAccess.rename_absolute(path, bak_path)
	
	var err = DirAccess.rename_absolute(tmp_path, path)
	return err == OK

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
			"imprint_quality": p_data.imprint_quality,
			# Tutorial State
			"tutorial_completed": p_data.tutorial_completed,
			"tutorial_step": p_data.tutorial_step
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

func _load_binary_data(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	
	# Try compressed first (new format)
	var file = FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if not file:
		# Fallback to uncompressed (legacy)
		file = FileAccess.open(path, FileAccess.READ)
	
	if not file: return null
	
	var data = file.get_var(true) # Use allow_objects=true to support Resource serialization
	file.close()
	return data

func load_game(slot_id: int) -> bool:
	# 只要加载存档，就意味着这绝对不是新游戏
	if GameManager:
		GameManager.is_new_game = false
		
	current_slot_id = slot_id
	start_autosave()
	
	var path = _get_data_path(slot_id)
	
	var data = _load_binary_data(path)
	if data == null:
		# Try Backup
		data = _load_binary_data(path + ".bak")
		if data != null:
			push_warning("SaveManager: Main save corrupted, loaded from backup.")

	if data == null:
		# Only check if path missing if backup also failed
		if not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".bak"):
			push_error("SaveManager: 存档文件不存在 " + path)
		else:
			push_error("SaveManager: 存档文件损坏且无备份 " + path)
		return false
	
	# 1. 设定地图路径
	var slot_dir = _get_slot_dir(slot_id)
	if InfiniteChunkManager:
		InfiniteChunkManager.set_save_root(slot_dir + "world_deltas/")
		InfiniteChunkManager.world_delta_data.clear()
		InfiniteChunkManager.loaded_chunks.clear()

	# 2. 恢复全局状态
	GameState.current_time = data.get("game_time", 0.0)
	
	if data.has("world_seed"):
		# Store the seed in GameState meta so GameManager can pick it up 
		# when initializing the WorldGenerator later.
		GameState.set_meta("pending_new_seed", data.world_seed)
		print("SaveManager: Loaded World Seed: ", data.world_seed)
	
	if data.has("scene_path"):
		GameState.set_meta("pending_scene_path", data.scene_path)
	
	# 3. 恢复玩家数据 (缓存，待 GameManager 应用)
	if data.has("player"):
		_cached_player_data = data.player.data
		# 将位置存储在 Meta 中，供 GameManager 生成玩家时读取
		GameState.set_meta("load_spawn_pos", data.player.position)
		
		# 确保玩家数据对象存在，避免空指针访问
		if not GameState.player_data:
			GameState.player_data = CharacterData.new()
			
		var p_data = GameState.player_data
		var saved_stats = _cached_player_data
		
		p_data.display_name = saved_stats.get("display_name", "NPC_PLAYER_DEFAULT")
		
		# 强制手动缓存教程状态，防止 GameManager 漏读
		# 注意：这些属性会被 GameManager 再次从 _cached_player_data 覆盖，但这里先设个底
		p_data.tutorial_completed = saved_stats.get("tutorial_completed", false)
		p_data.tutorial_step = saved_stats.get("tutorial_step", 0)

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
		if data.player.has("position"):
			GameState.set_meta("load_spawn_pos", data.player.position)

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
	
	# 6. Restore Extended Systems (Pickups, Weather, Minimap)
	if data.has("pickups"): _unpack_pickups(data.pickups)
	if data.has("weather"): _unpack_weather(data.weather)
	if data.has("minimap"): _unpack_minimap(data.minimap)
	
	if data.has("persist_group"): _unpack_persist_group(data.persist_group)
	if data.has("hostiles"): _unpack_hostiles(data.hostiles)
	if data.has("descendants"): _unpack_descendants(data.descendants) # 新增：恢复子嗣列表
	
	print("SaveManager: 存档 %d 数据已载入内存预备" % slot_id)
	return true

func _capture_screenshot(slot_id: int) -> void:
	var viewport = get_tree().root.get_viewport()
	if not viewport: return
	
	var texture = viewport.get_texture()
	var image = texture.get_image()
	
	# Resize to thumbnail size (e.g. 480x270)
	image.resize(480, 270, Image.INTERPOLATE_BILINEAR)
	
	var path = _get_slot_dir(slot_id) + THUMBNAIL_FILENAME
	image.save_jpg(path, 0.70)

# --- Extended Persistence Helpers ---

func _pack_pickups() -> Array:
	var list = []
	var nodes = get_tree().get_nodes_in_group('pickups')
	for node in nodes:
		if node.has_method('get_save_data'):
			list.append(node.get_save_data())
	return list

func _unpack_pickups(list: Array) -> void:
	get_tree().call_group('pickups', 'queue_free')
	var root = get_tree().current_scene
	
	for info in list:
		if not info.get('file'): continue
		var scn = load(info.file)
		if scn:
			var node = scn.instantiate()
			node.global_position = info.get('pos', Vector2.ZERO)
			root.add_child(node)
			if node.has_method('setup') and info.get('item_res'):
				var res = load(info.item_res)
				if res: node.setup(res, info.get('amount', 1))

func _pack_weather() -> Dictionary:
	return WeatherManager.get_save_data() if WeatherManager.has_method('get_save_data') else {}

func _unpack_weather(data: Dictionary) -> void:
	if WeatherManager.has_method('load_save_data'): WeatherManager.load_save_data(data)

func _pack_minimap() -> Dictionary:
	return MinimapManager.get_save_data() if MinimapManager.has_method('get_save_data') else {}

func _unpack_minimap(data: Dictionary) -> void:
	if MinimapManager.has_method('load_save_data'): MinimapManager.load_save_data(data)

# --- Generic Persist Group ---
func _pack_persist_group() -> Dictionary:
	var gathered = {}
	var nodes = get_tree().get_nodes_in_group('persist')
	for node in nodes:
		if node.has_method('get_save_data'):
			gathered[str(node.get_path())] = node.get_save_data()
	return gathered

func _unpack_persist_group(data: Dictionary) -> void:
	for node_path in data:
		if has_node(node_path):
			var node = get_node(node_path)
			if node.has_method('load_save_data'):
				node.load_save_data(data[node_path])

# --- Specific Enemy Persistence ---

func _get_world_seed() -> int:
	# Try to find the active WorldGenerator
	var world_gen = get_tree().get_first_node_in_group("world_generators")
	if not world_gen:
		var root = get_tree().current_scene
		if root: world_gen = root.find_child("WorldGenerator", true, false)
	
	if world_gen and "seed_value" in world_gen:
		return world_gen.seed_value
	return 0

func _pack_hostiles() -> Array:
	var list = []
	var mobs = get_tree().get_nodes_in_group("hostile_npcs")
	for mob in mobs:
		if mob.scene_file_path.is_empty(): continue
		if mob.get("health") != null and mob.health <= 0: continue # Don't save dead
		
		# 识别是否是子嗣
		var is_descendant = false
		if "npc_data" in mob and mob.npc_data:
			if LineageManager.descendants.has(mob.npc_data):
				is_descendant = true
		
		var data = {
			"scene_path": mob.scene_file_path,
			"pos": mob.global_position,
			"hp": mob.get("health") if mob.get("health") != null else 100,
			"max_hp": mob.get("max_health") if mob.get("max_health") != null else 100,
			"is_descendant": is_descendant # 记录是否是子嗣
		}
		
		# If using CharacterData resource system
		if "npc_data" in mob and mob.npc_data:
			data["hp"] = mob.npc_data.health
			data["max_hp"] = mob.npc_data.max_health
			data["display_name"] = mob.npc_data.display_name
			# 存入完整的 CharacterData 字典表示，确保属性（如 age, growth_stage, npc_type）不丢失
			data["character_full_data"] = _resource_to_dict(mob.npc_data)
			
		list.append(data)
	return list

func _unpack_hostiles(list: Array) -> void:
	# Clean up existing hostiles to avoid duplicates if reloading scene
	get_tree().call_group("hostile_npcs", "queue_free")
	
	var entities_layer = get_tree().current_scene.find_child("Entities", true, false)
	if not entities_layer:
		entities_layer = get_tree().current_scene # Fallback
	
	for info in list:
		if not FileAccess.file_exists(info.scene_path): continue
		
		var scn = load(info.scene_path)
		if scn:
			var mob = scn.instantiate()
			mob.global_position = info.pos
			
			# Restore Data
			if "npc_data" in mob and mob.npc_data:
				# Ensure data uniqueness
				mob.npc_data = mob.npc_data.duplicate()
				
				# 如果有完整数据字典，则恢复所有属性
				if info.has("character_full_data"):
					_dict_to_resource(info.character_full_data, mob.npc_data)
				
				mob.npc_data.health = info.hp
				mob.npc_data.max_health = info.max_hp
				if info.has("display_name"):
					mob.npc_data.display_name = info.display_name
					
				# 如果是子嗣，将其加入全局列表（如果列表中还没有该对象）
				if info.get("is_descendant", false):
					if not LineageManager.descendants.has(mob.npc_data):
						LineageManager.descendants.append(mob.npc_data)
						
			elif "health" in mob:
				mob.health = info.hp
				if "max_health" in mob: mob.max_health = info.max_hp
			
			mob.add_to_group("hostile_npcs") # Ensure in group
			entities_layer.add_child(mob)
			
			if mob.has_method("_update_hp_bar"):
				mob._update_hp_bar()

# 辅助函数：将 Resource 转换为字典（通用版，针对 CharacterData 优化）
func _resource_to_dict(res: Resource) -> Dictionary:
	var dict = {}
	# 获取所有可保存的属性（脚本中的变量名）
	var props = res.get_property_list()
	for p in props:
		# 过滤掉内置属性和只读属性，只保留脚本定义的变量 (PROPERTY_USAGE_STORAGE)
		if p.usage & PROPERTY_USAGE_STORAGE and p.name != "script" and p.name != "Built-in Script":
			dict[p.name] = res.get(p.name)
	return dict

# 辅助函数：将字典应用回 Resource
func _dict_to_resource(dict: Dictionary, res: Resource) -> void:
	for key in dict.keys():
		res.set(key, dict[key])

func _pack_descendants() -> Array:
	var list = []
	for d in LineageManager.descendants:
		list.append(_resource_to_dict(d))
	return list

func _unpack_descendants(list: Array) -> void:
	# 仅作为保险，如果场景中已经加载了（通过 _unpack_hostiles），此处不应重复
	# 但为了防止某些子嗣没在场景树中，这里做一次清理和恢复
	LineageManager.descendants.clear()
	for dict in list:
		var d = CharacterData.new()
		_dict_to_resource(dict, d)
		
		# 打印调试信息，确认恢复后的状态
		print("SaveManager: 恢复子嗣 %s, UUID: %d, 成长阶段: %d" % [d.display_name, d.uuid, d.growth_stage])
		
		# 只有当列表中还没有同名/同UUID的对象时才添加
		var exists = false
		for existing in LineageManager.descendants:
			if existing.get("uuid") == d.get("uuid"):
				exists = true
				break
		if not exists:
			LineageManager.descendants.append(d)
