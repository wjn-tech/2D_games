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

signal state_changed(new_state: State)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 监听寿命耗尽信号
	if LifespanManager:
		LifespanManager.lifespan_depleted.connect(_on_lifespan_ended)
		
	# 延迟一帧确保所有 Autoload 初始化完成
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
			get_tree().paused = true
			UIManager.close_all_windows(false) # 关闭所有，包括 HUD
			UIManager.open_window("MainMenu", "res://scenes/ui/MainMenu.tscn")
		State.PLAYING:
			get_tree().paused = false
			# 仅关闭拦截输入的窗口，保留 HUD
			UIManager.close_all_windows(true)
			UIManager.open_window("HUD", "res://scenes/ui/HUD.tscn", false) # HUD 不拦截输入
			
			# 显示实体层
			var entities = get_tree().current_scene.find_child("Entities", true, false)
			if entities:
				entities.visible = true
			
			# 只有从菜单进入、从死亡状态恢复或转生成功时才生成/重置玩家位置
			if old_state == State.START_MENU or old_state == State.GAME_OVER or old_state == State.REINCARNATING:
				# 1. 尝试处理世界生成 (主要针对新游戏和死亡重开)
				if old_state == State.START_MENU or old_state == State.GAME_OVER:
					var world_gen = get_tree().current_scene.find_child("WorldGenerator", true, false)
					if world_gen:
						if world_gen.has_method("start_generation"):
							world_gen.start_generation()
						elif world_gen.has_method("generate_world"):
							world_gen.generate_world()
				
				# 2. 核心位置同步逻辑：必须在所有状态下都尝试执行，确保转生不掉落
				var player = get_tree().get_first_node_in_group("player")
				if player:
					var spawn_pos = Vector2.ZERO
					var pos_restored = false
					
					if GameState.has_meta("load_spawn_pos"):
						spawn_pos = GameState.get_meta("load_spawn_pos")
						GameState.remove_meta("load_spawn_pos")
						pos_restored = true
						print("GameManager: 成功应用转生/存档位置: ", spawn_pos)
					# 补充：处理新游戏或无存档坐标时的默认生成逻辑
					elif old_state == State.START_MENU or old_state == State.GAME_OVER:
						var world_gen = get_tree().current_scene.find_child("WorldGenerator", true, false)
						if world_gen and world_gen.has_method("get_spawn_position"):
							spawn_pos = world_gen.get_spawn_position()
							pos_restored = true
							print("GameManager: 此时无存档坐标，使用世界生成器建议坐标: ", spawn_pos)
						else:
							# 终极兜底坐标：地表约在 y=300 块处，即 300*16 = 4800
							spawn_pos = Vector2(0, 300 * 16) 
							pos_restored = true 
					
					if pos_restored:
						# 立即同步位置，并在下一帧再次强制同步以防物理引擎干扰
						player.global_position = spawn_pos
						if player is CharacterBody2D:
							player.velocity = Vector2.ZERO
						
						# 预加载块
						if InfiniteChunkManager:
							InfiniteChunkManager.update_player_vicinity(spawn_pos)
							
						# 延迟一帧微调，防止物理穿插或引擎归位
						(func(): if is_instance_valid(player): player.global_position = spawn_pos).call_deferred()
					
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
								if not FileAccess.file_exists(b_info.scene_path): continue
								
								var scene = load(b_info.scene_path)
								if scene:
									var instance = scene.instantiate()
									b_container.add_child(instance)
									instance.global_position = b_info.position
									instance.rotation = b_info.rotation
									# 可以在此恢复自定义数据
		State.PAUSED:
			get_tree().paused = true
			UIManager.open_window("PauseMenu", "res://scenes/ui/PauseMenu.tscn")
		State.REINCARNATING:
			get_tree().paused = true
			UIManager.open_window("Reincarnation", "res://scenes/ui/ReincarnationWindow.tscn")
		State.GAME_OVER:
			get_tree().paused = true
			UIManager.open_window("GameOver", "res://scenes/ui/GameOverWindow.tscn")

func start_new_game() -> void:
	# 初始化游戏数据
	GameState.player_data = CharacterData.new()
	GameState.player_data.display_name = "新冒险者"
	
	# 发出信号通知所有引用玩家数据的组件更新 (例如 HUD 和 Player 节点)
	if EventBus:
		EventBus.player_data_refreshed.emit()
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("refresh_data"):
		player.refresh_data()
	
	# 重置天气与光照，防止残留黑色滤镜
	if WeatherManager:
		WeatherManager.current_weather = WeatherManager.WeatherType.SUNNY
		WeatherManager._apply_weather_effects()
	
	change_state(State.PLAYING)

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
			
		UIManager.toggle_window("CharacterPanel", "res://scenes/ui/CharacterPanel.tscn")
