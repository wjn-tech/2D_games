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
			
			# 只有从菜单进入或重新开始时才生成世界，暂停恢复时不重新生成
			if old_state == State.START_MENU or old_state == State.GAME_OVER:
				var world_gen = get_tree().current_scene.find_child("WorldGenerator", true, false)
				if world_gen:
					if world_gen.has_method("start_generation"):
						world_gen.start_generation()
					elif world_gen.has_method("generate_world"):
						world_gen.generate_world()
					
					# 设置玩家初始位置
					var player = get_tree().current_scene.find_child("Player", true, false)
					if player:
						var spawn_pos = Vector2.ZERO
						if world_gen.has_method("get_spawn_position"):
							spawn_pos = world_gen.get_spawn_position()
						else:
							# 针对无限地图的起始坐标 (Fallback)
							spawn_pos = Vector2(0, 300 * 16) 
						
						# 预加载玩家所在位置的区块，防止开局掉落
						if InfiniteChunkManager:
							InfiniteChunkManager.update_player_vicinity(spawn_pos)
							
						player.global_position = spawn_pos
						print("GameManager: 玩家已生成在: ", player.global_position)
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
