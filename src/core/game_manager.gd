extends Node

## GameManager (Autoload)
## 负责管理游戏的高层状态切换与核心流程。

enum State {
	START_MENU,
	PLAYING,
	PAUSED,
	REINCARNATING,
	GAME_OVER
}

var current_state: State = State.GAME_OVER # 初始设为非 START_MENU 状态，确保第一次切换生效
var is_new_game: bool = false # 标记是否为新游戏开始，用于触发新手教程

signal state_changed(new_state: State)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 监听寿命耗尽信号
	if LifespanManager:
		LifespanManager.lifespan_depleted.connect(_on_lifespan_ended)
		
	# 正常启动流程：进入主菜单
	call_deferred("change_state", State.START_MENU)

func _on_lifespan_ended(data: CharacterData) -> void:
	if data == GameState.player_data:
		print("GameManager: 玩家寿命耗尽，进入转生状态")
		change_state(State.REINCARNATING)

func change_state(new_state: State) -> void:
	if current_state == new_state:
		return
		
	var old_state = current_state
	current_state = new_state
	state_changed.emit(new_state)
	
	match current_state:
		State.START_MENU:
			# 确保游戏状态完全重置，避免上一局的数据（如 is_new_game, player_data）污染新会话
			reset_game_state()
			
			get_tree().paused = true
			# 关闭除了主菜单以外的所有窗口
			UIManager.close_all_windows(false, ["MainMenu"]) 
			UIManager.open_window("MainMenu", "res://scenes/ui/MainMenu.tscn")
		State.PLAYING:
			get_tree().paused = false
			# 1. 强力清理并探测 UI
			# 修复闪烁：在这里先直接把 MainMenu 隐藏，而不是等待 UIManager 的动画流程
			var root = get_tree().current_scene
			if root:
				var menu = root.find_child("MainMenu", true, false)
				if menu: menu.visible = false
				
			UIManager.close_all_windows(true) 
			UIManager.open_window("HUD", "res://scenes/ui/HUD.tscn", false)
			
			var scene_root = get_tree().current_scene
			if not scene_root:
				print("GameManager: 场景根节点尚未就绪，延迟重试 PLAYING 状态...")
				call_deferred("change_state", State.PLAYING)
				return

			print("GameManager: 进入 PLAYING 状态, 场景根节点: ", scene_root.name)
			
			# 显示实体层
			var entities = scene_root.find_child("Entities", true, false)
			if entities:
				entities.visible = true
			
			# 修复加载存档背景不显：强制显示背景层
			var background = scene_root.find_child("Background", true, false)
			if background:
				background.visible = true
			elif scene_root is ParallaxBackground:
				scene_root.visible = true
			
			# 2. 只有从菜单进入、从死亡状态恢复或转生成功时才生成/重置玩家位置
			if old_state == State.START_MENU or old_state == State.GAME_OVER or old_state == State.REINCARNATING:
				# 尝试处理世界生成
				if old_state == State.START_MENU or old_state == State.GAME_OVER:
					# 广度优先搜索世界生成器，防止嵌套过深
					var world_gen = scene_root.find_child("WorldGenerator", true, false)
					if not world_gen:
						# 最后的努力：通过组寻找
						var gens = get_tree().get_nodes_in_group("world_generators")
						if not gens.is_empty(): world_gen = gens[0]
					
					if world_gen:
						print("GameManager: 找到世界生成器，准备触发生成逻辑...")
						# 优先使用预设的种子
						if GameState.has_meta("pending_new_seed"):
							world_gen.seed_value = GameState.get_meta("pending_new_seed")
							GameState.remove_meta("pending_new_seed")
							print("GameManager: 使用 Nuclear Reset 预设种子: ", world_gen.seed_value)
						elif world_gen.get("seed_value") != null:
							randomize()
							world_gen.seed_value = randi()
							print("GameManager: 随机生成新种子: ", world_gen.seed_value)

						if world_gen.has_method("start_generation"):
							world_gen.start_generation()
						elif world_gen.has_method("generate_world"):
							world_gen.generate_world()
					else:
						push_warning("GameManager: 未在当前场景中找到 WorldGenerator！")
				
				# 3. 核心位置同步逻辑
				var player = get_tree().get_first_node_in_group("player")
				# 如果是新游戏且有教程正在进行，跳过这里的传送，让教程接管位置
				if player and not is_new_game:
					var spawn_pos = Vector2.ZERO
					var pos_restored = false
					
					if GameState.has_meta("load_spawn_pos"):
						spawn_pos = GameState.get_meta("load_spawn_pos")
						GameState.remove_meta("load_spawn_pos")
						pos_restored = true
					elif old_state == State.START_MENU or old_state == State.GAME_OVER:
						var world_gen = scene_root.find_child("WorldGenerator", true, false)
						if world_gen and world_gen.has_method("get_spawn_position"):
							spawn_pos = world_gen.get_spawn_position()
							pos_restored = true
						else:
							# 终极兜底坐标
							spawn_pos = Vector2(0, 300 * 16) 
							pos_restored = true 
					
					if pos_restored:
						# 使用新的安全生成逻辑，替代旧的直接赋值
						_spawn_player_safely(player, spawn_pos)
					
					# 如果是转生，触发玩家节点刷新数据
					if old_state == State.REINCARNATING and player.has_method("refresh_data"):
						player.refresh_data()
				
				# 3. 恢复建筑 (仅在非转生状态)
				if old_state != State.REINCARNATING and GameState.has_meta("load_buildings"):
						var buildings_data = GameState.get_meta("load_buildings")
						GameState.remove_meta("load_buildings")
						print("GameManager: 恢复 %d 个建筑..." % buildings_data.size())
						
						var b_container = get_tree().get_first_node_in_group("buildings_container")
						# 清空可能由生成器产生的预置建筑（如果有）
						if b_container:
							for child in b_container.get_children():
								child.queue_free()
								
							for b_info in buildings_data:
								var scene_path = b_info.scene_path
								# 路径修正逻辑 (从 save_manager 移植并增强)
								if "workshop.tscn" in scene_path and not "buildings/" in scene_path:
									scene_path = "res://scenes/world/buildings/workshop.tscn"
								if "ruins_stone.tscn" in scene_path and not "buildings/" in scene_path:
									scene_path = "res://scenes/world/buildings/ruins_stone.tscn"
									
								if not FileAccess.file_exists(scene_path): 
									push_warning("GameManager: 找不到建筑场景 %s" % scene_path)
									continue
								
								var scene = load(scene_path)
								if scene:
									var instance = scene.instantiate()
									b_container.add_child(instance)
									instance.global_position = b_info.position
									instance.rotation = b_info.rotation
									
									# 恢复关联的 BuildingResource 和数据
									if b_info.has("custom_data") and b_info.custom_data.has("resource_id"):
										var res_id = b_info.custom_data.resource_id
										if GameState.building_db.has(res_id):
											var res = GameState.building_db[res_id]
											if instance.has_method("setup"):
												instance.setup(res)
											
											# 注册到城邦系统
											if get_node_or_null("/root/SettlementManager"):
												get_node("/root/SettlementManager").register_building(instance, res)
									
									if instance.has_method("load_custom_data"):
										instance.load_custom_data(b_info.get("custom_data", {}))
		State.PAUSED:
			get_tree().paused = true
			UIManager.open_window("PauseMenu", "res://scenes/ui/PauseMenu.tscn")
		State.REINCARNATING:
			get_tree().paused = true
			UIManager.open_window("Reincarnation", "res://scenes/ui/ReincarnationWindow.tscn")
		State.GAME_OVER:
			get_tree().paused = true
			UIManager.open_window("GameOver", "res://scenes/ui/GameOverWindow.tscn")

var _is_starting_new_game: bool = false

func reset_game_state() -> void:
	# 核心状态重置，用于返回主菜单或清理会话
	print("GameManager: Resetting game state...")
	is_new_game = false
	_is_starting_new_game = false
	GameState.player_data = null
	
	# 重置持久化层
	if SaveManager and SaveManager._cached_player_data:
		SaveManager._cached_player_data.clear()
		
	# 重置子系统
	if InfiniteChunkManager and InfiniteChunkManager.has_method("restart"): InfiniteChunkManager.restart()
	if NPCSpawner and NPCSpawner.has_method("reset"): NPCSpawner.reset()
	if Chronometer and Chronometer.has_method("reset"): Chronometer.reset()
	if LayerManager and LayerManager.has_method("reset"): LayerManager.reset() 

func start_new_game() -> void:
	if _is_starting_new_game:
		return
	_is_starting_new_game = true
	
	# 先重置所有旧状态
	reset_game_state()
	
	# 显式标记为新游戏
	is_new_game = true 
	
	# 1. 缓冲机制：先进入黑屏，确保场景切换期间玩家看不到原始 UI 的闪烁
	if UIManager:
		await UIManager.play_fade(true, 0.3)
	
	# 2. 彻底停掉当前的逻辑，执行数据重置
	get_tree().paused = true
	
	randomize()
	var new_seed = randi()
	if GameState:
		# 清空 meta 但保留种子
		for meta_key in GameState.get_meta_list():
			GameState.remove_meta(meta_key)
		GameState.set_meta("pending_new_seed", new_seed)
		
		# 避免空指针 crash：初始化一个临时的空玩家数据，防止场景加载期间脚本访问报错
		GameState.player_data = CharacterData.new()
	
	print("GameManager: 新游戏启动，种子: ", new_seed)
	
	if InfiniteChunkManager: InfiniteChunkManager.restart()
	if NPCSpawner and NPCSpawner.has_method("reset"): NPCSpawner.reset()
	if Chronometer and Chronometer.has_method("reset"): Chronometer.reset()
	if LayerManager and LayerManager.has_method("reset"): LayerManager.reset()
	if UIManager and UIManager.has_method("clear_all_references"):
		UIManager.clear_all_references()
	
	# 2. 执行场景切换
	current_state = State.GAME_OVER 
	
	# 场景切换需要时间，延时 0.2 秒通常足以避开引擎切换时的不稳定期
	var tree = get_tree()

	var main_scene_path = ProjectSettings.get_setting("application/run/main_scene")
	if not main_scene_path: main_scene_path = "res://scenes/main.tscn"

	var error = get_tree().change_scene_to_file(main_scene_path)
	if error == OK:
		# 使用计时器进行一次性延迟初始化，避免在场景过渡帧内运行逻辑
		tree.create_timer(0.2).timeout.connect(_on_reload_finished)
	else:
		get_tree().paused = false
		
		# 如果存档包含特定场景路径，切换到该场景
		if GameState.has_meta("pending_scene_path"):
			var scene_path = GameState.get_meta("pending_scene_path")
			GameState.remove_meta("pending_scene_path")
			if scene_path != get_tree().current_scene.scene_file_path:
				get_tree().change_scene_to_file(scene_path)
			else:
				get_tree().reload_current_scene()
		else:
			get_tree().reload_current_scene()
			
		# 场景加载是异步的，我们需要通过定时器来等待加载完成
		# 如果使用 change_scene_to_file，通常 SceneTree 会在下一帧完成切换
		var timer = get_tree().create_timer(0.2)
		# 尝试解绑旧连接以免重复
		if timer.timeout.is_connected(_on_reload_finished):
			timer.timeout.disconnect(_on_reload_finished)
		
		timer.timeout.connect(_on_reload_finished)

func load_game(slot_id: int) -> void:
	if _is_starting_new_game: return
	_is_starting_new_game = true
	
	reset_game_state()
	
	# Load data into Cache
	if not SaveManager.load_game(slot_id):
		_is_starting_new_game = false
		print("GameManager: Load failed!")
		return
	
	# Transition
	if UIManager:
		await UIManager.play_fade(true, 0.3)
	
	get_tree().paused = true
	current_state = State.GAME_OVER
	
	var scene_path = "res://scenes/main.tscn"
	if GameState.has_meta("pending_scene_path"):
		scene_path = GameState.get_meta("pending_scene_path")
		GameState.remove_meta("pending_scene_path")
	
	var error = get_tree().change_scene_to_file(scene_path)
	if error == OK:
		get_tree().create_timer(0.2).timeout.connect(_on_reload_finished)
	else:
		_is_starting_new_game = false
		get_tree().paused = false
		print("GameManager: Failed to change scene during load.")

func _on_reload_finished() -> void:
	_is_starting_new_game = false
	print("GameManager: 场景重载完毕，正在初始化...")
	get_tree().paused = false
	
	# 重置小地图数据
	if MinimapManager:
		print("Resetting Minimap...")
		MinimapManager.reset_map()
	
	# 初始化玩家数据
	print("Initializing Player Data...")
	# 避免覆盖在 start_new_game 或 load_game 中已经初始化的数据引用
	if not GameState.player_data:
		GameState.player_data = CharacterData.new()
	
	# 如果是从存档重载，恢复缓存的数据
	if SaveManager and not SaveManager._cached_player_data.is_empty():
		var p_data = GameState.player_data
		var saved = SaveManager._cached_player_data
		
		# 映射数据到新对象
		p_data.display_name = saved.get("display_name", "冒险者")
		p_data.health = saved.get("health", 100)
		p_data.max_health = saved.get("max_health", 100)
		p_data.strength = saved.get("strength", 10)
		p_data.agility = saved.get("agility", 10)
		p_data.intelligence = saved.get("intelligence", 10)
		p_data.constitution = saved.get("constitution", 10)
		p_data.stat_points = int(saved.get("stat_points", 0))
		p_data.level = int(saved.get("level", 1))
		p_data.experience = float(saved.get("experience", 0.0))
		
		# 血脉系统属性
		if saved.has("stat_levels"): p_data.stat_levels = saved.stat_levels
		if saved.has("mutations"): p_data.mutations = saved.mutations
		p_data.generation = int(saved.get("generation", 1))
		p_data.current_age = float(saved.get("age", saved.get("current_age", 20.0)))
		p_data.max_life_span = float(saved.get("max_life_span", 120.0))
		p_data.growth_stage = int(saved.get("growth_stage", 2)) # 默认成年
		
		# 恢复教程进度
		p_data.tutorial_completed = saved.get("tutorial_completed", false)
		p_data.tutorial_step = int(saved.get("tutorial_step", 0))

		# 强制重置新游戏标志，防止教程污染
		if p_data.tutorial_completed or not is_new_game:
			is_new_game = false
		
		print("GameManager: 已从 SaveManager 缓存恢复玩家属性 (HP: %d, LV: %d)" % [p_data.health, p_data.level])
		# 清理缓存，防止下次非存档重载干扰
		SaveManager._cached_player_data = {}
	else:
		GameState.player_data.display_name = "冒险者"
		# 新游戏状态下，确认教程初始状态
		if is_new_game:
			GameState.player_data.tutorial_completed = false
			GameState.player_data.tutorial_step = 0
	
	if EventBus:
		print("Emitting player_data_refreshed...")
		EventBus.player_data_refreshed.emit()
	
	# 强制切换到 PLAYING 状态
	print("Switching state to PLAYING...")
	current_state = State.GAME_OVER # 确保 change_state 能生效
	change_state(State.PLAYING)
	
	# 初始化完成后，平滑淡出黑屏，显示游戏世界，
	# 仅当不在新手教程流程中才自动淡入（因为教程有自己的控制）
	if UIManager:
		if is_new_game:
			# 如果是新游戏，确保 UI 能够接收输入以允许按 K 键
			UIManager.set_process_input(true)
		else:
			UIManager.play_fade(false, 0.5)

func pause_game() -> void:
	if current_state == State.PLAYING:
		change_state(State.PAUSED)
	elif current_state == State.PAUSED:
		change_state(State.PLAYING)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# 1. 如果已经在暂停状态，按 Esc 恢复游戏
		if current_state == State.PAUSED:
			change_state(State.PLAYING)
			return
			
		# 2. 如果在游戏中，按 Esc 暂停并关闭所有打开的 UI（如建造菜单）
		if current_state == State.PLAYING:
			# 关闭所有非持久窗口（如建造菜单、结算界面等）
			UIManager.close_all_windows(false)
			
			# 同时取消当前的建造模式
			var building_mgr = get_tree().get_first_node_in_group("building_manager")
			if building_mgr and building_mgr.has_method("cancel_building"):
				building_mgr.cancel_building()
				
			pause_game()
			return
	
	# 增加 false 参数以忽略按键重复 (echo)
	if event.is_action_pressed("inventory", false) and current_state == State.PLAYING:
		# 检查是否正在建造模式，如果是则先取消建造
		var building_mgr = get_tree().get_first_node_in_group("building_manager")
		if building_mgr and building_mgr.has_method("is_building") and building_mgr.is_building():
			building_mgr.cancel_building()
			
		UIManager.toggle_window("InventoryWindow", "res://scenes/ui/InventoryWindow.tscn")

	# 制作快捷键：按 I 键（同时也是背包键）启动，或单独逻辑
	# 注意：如果 inventory 动作已经是 'I'，这里可以保持逻辑统一
	# 如果用户明确要求快捷键 I 用于制作且修复工作台逻辑
	if event.is_action_pressed("inventory", false) and current_state == State.PLAYING:
		# 我们在打开 CharacterPanel 的同时也具备了查看配方的能力，
		# 但如果用户在工作台旁边，我们应该确保制作逻辑可用。
		pass

func _spawn_player_safely(player: Node2D, target_pos: Vector2) -> void:
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.global_position = target_pos
	if player is CharacterBody2D:
		player.velocity = Vector2.ZERO
	if not InfiniteChunkManager:
		player.process_mode = Node.PROCESS_MODE_INHERIT
		return
	InfiniteChunkManager.update_player_vicinity(target_pos)
	var chunk_coord = InfiniteChunkManager.get_chunk_coord(target_pos)
	if not InfiniteChunkManager.loaded_chunks.has(chunk_coord):
		var max_wait = 500
		while not InfiniteChunkManager.loaded_chunks.has(chunk_coord) and max_wait > 0:
			await get_tree().process_frame
			max_wait -= 1
	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.global_position = target_pos + Vector2(0, -2)
