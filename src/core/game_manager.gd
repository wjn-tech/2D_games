extends Node

## GameManager (Autoload)
## 负责管理游戏的高层状态切换与核心流程。

enum State {
	START_MENU,
	LOADING_WORLD,
	PLAYING,
	PAUSED,
	REINCARNATING,
	GAME_OVER
}

var current_state: State = State.GAME_OVER # 初始设为非 START_MENU 状态，确保第一次切换生效
var is_new_game: bool = false # 标记是否为新游戏开始，用于触发新手教程

signal state_changed(new_state: State)

const STARTUP_STAGE_ORDER := [
	"scene_stable",
	"topology_restore",
	"save_restore",
	"world_bootstrap",
	"spawn_area_ready",
	"gameplay_handoff",
]

const STARTUP_STAGE_WEIGHTS := {
	"scene_stable": 0.10,
	"topology_restore": 0.10,
	"save_restore": 0.20,
	"world_bootstrap": 0.20,
	"spawn_area_ready": 0.30,
	"gameplay_handoff": 0.10,
}

const STARTUP_STAGE_LABELS := {
	"scene_stable": "稳定场景",
	"topology_restore": "恢复世界拓扑",
	"save_restore": "恢复会话数据",
	"world_bootstrap": "启动世界生成",
	"spawn_area_ready": "预热出生区域",
	"gameplay_handoff": "进入世界",
}

const STARTUP_VERTICAL_PREWARM_CHUNKS_PLANETARY := 12
const STARTUP_VERTICAL_PREWARM_CHUNKS_LEGACY := 6
const STARTUP_PREGEN_FORCE_FULL_WORLD := true
const STARTUP_PREGEN_CHUNK_BUDGET := 320
const STARTUP_PREGEN_TIME_BUDGET_SEC := 8.0

var _startup_stage_progress: Dictionary = {}
var _startup_current_stage: String = ""
var _startup_stage_status: String = ""

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
			if UIManager and UIManager.has_method("dismiss_loading_overlay"):
				UIManager.dismiss_loading_overlay()
			
			get_tree().paused = true
			# 修复：先彻底清理所有 UI 字典引用，防止 close_all_windows 与旧场景节点混淆
			if UIManager.has_method("clear_all_references"):
				UIManager.clear_all_references()
			
			# 关闭除了主菜单以外的所有窗口
			UIManager.close_all_windows(false, ["MainMenu"]) 
			UIManager.open_window("MainMenu", "res://scenes/ui/MainMenu.tscn")
		State.LOADING_WORLD:
			get_tree().paused = false
			var loading_root = get_tree().current_scene
			if loading_root:
				var menu_window = loading_root.find_child("MainMenu", true, false)
				if menu_window:
					menu_window.visible = false
				var hud_window = loading_root.find_child("HUD", true, false)
				if hud_window:
					hud_window.visible = false
				var loading_entities = loading_root.find_child("Entities", true, false)
				if loading_entities:
					loading_entities.visible = false
				var loading_background = loading_root.find_child("Background", true, false)
				if loading_background:
					loading_background.visible = false
			if EventBus:
				EventBus.player_input_enabled.emit(false)
			var loading_player = get_tree().get_first_node_in_group("player")
			if loading_player:
				loading_player.process_mode = Node.PROCESS_MODE_DISABLED
			if UIManager and UIManager.has_method("show_loading_overlay"):
				UIManager.show_loading_overlay("世界加载中", String(STARTUP_STAGE_LABELS.get("scene_stable", "稳定场景")), _calculate_startup_progress(), _startup_stage_status)
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
			if old_state != State.LOADING_WORLD and (old_state == State.START_MENU or old_state == State.GAME_OVER or old_state == State.REINCARNATING):
				# 尝试处理世界生成
				if old_state == State.START_MENU or old_state == State.GAME_OVER:
					# 广度优先搜索世界生成器，防止嵌套过深
					var world_gen = scene_root.find_child("WorldGenerator", true, false)
					if not world_gen:
						# 最后的努力：通过组寻找
						var gens = get_tree().get_nodes_in_group("world_generator")
						if gens.is_empty():
							gens = get_tree().get_nodes_in_group("world_generators")
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
				
				# 4. 恢复建筑 (仅在非转生状态)
				if old_state != State.REINCARNATING and GameState.has_meta("load_buildings"):
					_restore_pending_buildings()
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

func _generate_fresh_world_seed() -> int:
	# 组合多源时间抖动，避免短时间内重复点击“新游戏”得到相同种子。
	var unix_sec := int(Time.get_unix_time_from_system())
	var unix_usec := int(Time.get_unix_time_from_system() * 1000000.0)
	var tick_usec := Time.get_ticks_usec()
	randomize()
	var rnd := randi()
	var mixed := int(unix_sec * 73856093) ^ int(unix_usec) ^ int(tick_usec * 19349663) ^ int(rnd)
	if mixed == 0:
		mixed = 1
	return abs(mixed)

func reset_game_state() -> void:
	# 核心状态重置，用于返回主菜单或清理会话
	print("GameManager: Resetting game state...")
	is_new_game = false
	_is_starting_new_game = false
	GameState.player_data = null
	GameState.unlocked_spells.clear()
	
	# 重置持久化层
	if SaveManager and SaveManager._cached_player_data:
		SaveManager._cached_player_data.clear()
		
	# 重置子系统
	if InfiniteChunkManager and InfiniteChunkManager.has_method("restart"): InfiniteChunkManager.restart(false)
	if NPCSpawner and NPCSpawner.has_method("reset"): NPCSpawner.reset()
	if Chronometer and Chronometer.has_method("reset"): Chronometer.reset()
	if LayerManager and LayerManager.has_method("reset"): LayerManager.reset() 

func start_new_game() -> void:
	if _is_starting_new_game:
		return
	
	# 先重置所有旧状态
	reset_game_state()
	_is_starting_new_game = true
	
	# 显式标记为新游戏
	is_new_game = true 
	
	# 1. 缓冲机制：先进入黑屏，确保场景切换期间玩家看不到原始 UI 的闪烁
	if UIManager:
		await UIManager.play_fade(true, 0.3)
		if UIManager.has_method("show_loading_overlay"):
			UIManager.show_loading_overlay("世界加载中", "切换游戏场景", 0.0, "正在创建新的世界会话...")
	if EventBus:
		EventBus.player_input_enabled.emit(false)
	
	# 2. 彻底停掉当前的逻辑，执行数据重置
	get_tree().paused = true
	
	var new_seed = _generate_fresh_world_seed()
	# 每次新游戏使用独立 runtime 世界路径，避免历史临时区块改动串档。
	var runtime_world_path := "user://saves/runtime_new_game/session_%d/world_deltas/" % new_seed
	var legacy_runtime_world_path := "user://saves/runtime_new_game/world_deltas/"
	if GameState:
		# 清空 meta 但保留种子
		for meta_key in GameState.get_meta_list():
			GameState.remove_meta(meta_key)
		GameState.set_meta("pending_new_seed", new_seed)
		if WorldTopology and WorldTopology.has_method("create_new_world"):
			var world_metadata: Dictionary = WorldTopology.create_new_world(new_seed)
			GameState.set_meta("pending_world_metadata", world_metadata)
		
		# 避免空指针 crash：初始化一个临时的空玩家数据，防止场景加载期间脚本访问报错
		GameState.player_data = CharacterData.new()
	
	print("GameManager: 新游戏启动，种子: ", new_seed)
	
	if InfiniteChunkManager: InfiniteChunkManager.restart(false)
	if SaveManager:
		SaveManager.current_slot_id = -1
		if SaveManager.has_method("stop_autosave"):
			SaveManager.stop_autosave()
	if InfiniteChunkManager and InfiniteChunkManager.has_method("clear_save_root_data"):
		# 兼容清理旧共享目录，防止历史版本留下的脏块继续污染新局。
		InfiniteChunkManager.clear_save_root_data(legacy_runtime_world_path)
		InfiniteChunkManager.clear_save_root_data(runtime_world_path)
		InfiniteChunkManager.set_save_root(runtime_world_path)
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
	
	reset_game_state()
	_is_starting_new_game = true
	
	# Load data into Cache
	if not SaveManager.load_game(slot_id):
		_is_starting_new_game = false
		print("GameManager: Load failed!")
		return
	
	# Transition
	if UIManager:
		await UIManager.play_fade(true, 0.3)
		if UIManager.has_method("show_loading_overlay"):
			UIManager.show_loading_overlay("世界加载中", "切换游戏场景", 0.0, "正在读取存档并切换到目标场景...")
	if EventBus:
		EventBus.player_input_enabled.emit(false)
	
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
	change_state(State.LOADING_WORLD)
	_reset_startup_progress()
	_report_startup_progress("scene_stable", 1.0, "场景已稳定，正在恢复世界入口状态...")
	
	# 重置小地图数据
	if MinimapManager:
		print("Resetting Minimap...")
		MinimapManager.reset_map()
	var topology_status := _restore_world_topology_after_reload()
	_report_startup_progress("topology_restore", 1.0, topology_status)
	var restored_from_save := _restore_player_data_after_reload()
	var save_status := "存档数据已恢复" if restored_from_save else "新游戏会话数据已初始化"
	_report_startup_progress("save_restore", 1.0, save_status)
	await _complete_world_startup()

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

func _reset_startup_progress() -> void:
	_startup_stage_progress.clear()
	for stage_id in STARTUP_STAGE_ORDER:
		_startup_stage_progress[stage_id] = 0.0
	_startup_current_stage = ""
	_startup_stage_status = ""

func _calculate_startup_progress() -> float:
	var total_weight := 0.0
	var accumulated := 0.0
	for stage_id in STARTUP_STAGE_ORDER:
		var stage_weight := float(STARTUP_STAGE_WEIGHTS.get(stage_id, 0.0))
		total_weight += stage_weight
		accumulated += stage_weight * clampf(float(_startup_stage_progress.get(stage_id, 0.0)), 0.0, 1.0)
	if total_weight <= 0.0:
		return 0.0
	return accumulated / total_weight

func _report_startup_progress(stage_id: String, progress: float, status: String = "") -> void:
	if not _startup_stage_progress.has(stage_id):
		return
	var previous := float(_startup_stage_progress.get(stage_id, 0.0))
	var clamped := maxf(previous, clampf(progress, 0.0, 1.0))
	_startup_stage_progress[stage_id] = clamped
	_startup_current_stage = stage_id
	if status != "":
		_startup_stage_status = status
	if UIManager and UIManager.has_method("show_loading_overlay") and UIManager.has_method("update_loading_overlay"):
		UIManager.show_loading_overlay("世界加载中", String(STARTUP_STAGE_LABELS.get(stage_id, stage_id)), _calculate_startup_progress(), _startup_stage_status)
		UIManager.update_loading_overlay(_calculate_startup_progress(), String(STARTUP_STAGE_LABELS.get(stage_id, stage_id)), _startup_stage_status)

func _restore_world_topology_after_reload() -> String:
	if not WorldTopology:
		return "未启用世界拓扑服务"
	var pending_seed := 0
	if GameState.has_meta("pending_new_seed"):
		pending_seed = int(GameState.get_meta("pending_new_seed"))
	elif is_new_game:
		pending_seed = _generate_fresh_world_seed()
		GameState.set_meta("pending_new_seed", pending_seed)
	if GameState.has_meta("pending_world_metadata"):
		var metadata = GameState.get_meta("pending_world_metadata")
		GameState.remove_meta("pending_world_metadata")
		WorldTopology.load_world_metadata(metadata)
	elif is_new_game and WorldTopology.has_method("create_new_world"):
		var created_metadata: Dictionary = WorldTopology.create_new_world(pending_seed)
		WorldTopology.load_world_metadata(created_metadata)
	else:
		WorldTopology.reset_to_legacy(pending_seed)
	var current_metadata := WorldTopology.get_current_metadata() if WorldTopology.has_method("get_current_metadata") else {}
	return "世界拓扑: %s / %s" % [
		String(current_metadata.get("topology_mode", "legacy_infinite")),
		String(current_metadata.get("world_size_preset", "legacy")),
	]

func _restore_player_data_after_reload() -> bool:
	print("Initializing Player Data...")
	if not GameState.player_data:
		GameState.player_data = CharacterData.new()

	var restored_from_save := SaveManager and not SaveManager._cached_player_data.is_empty()
	if restored_from_save:
		var p_data = GameState.player_data
		var saved = SaveManager._cached_player_data
		p_data.display_name = saved.get("display_name", "冒险者")
		if saved.has("stat_levels"):
			p_data.stat_levels = saved.stat_levels
		if saved.has("attributes"):
			p_data.attributes = saved.attributes
		if not saved.has("stat_levels"):
			p_data.strength = saved.get("strength", 10)
			p_data.agility = saved.get("agility", 10)
			p_data.intelligence = saved.get("intelligence", 10)
			p_data.constitution = saved.get("constitution", 10)
			p_data.max_health = saved.get("max_health", 100)
		p_data.stat_points = int(saved.get("stat_points", 0))
		p_data.level = int(saved.get("level", 1))
		p_data.experience = float(saved.get("experience", 0.0))
		p_data.health = saved.get("health", 100)
		if saved.has("mutations"):
			p_data.mutations = saved.mutations
		p_data.generation = int(saved.get("generation", 1))
		p_data.current_age = float(saved.get("age", saved.get("current_age", 20.0)))
		p_data.max_life_span = float(saved.get("max_life_span", 120.0))
		p_data.growth_stage = int(saved.get("growth_stage", 2))
		p_data.tutorial_completed = saved.get("tutorial_completed", false)
		p_data.tutorial_step = int(saved.get("tutorial_step", 0))
		if p_data.tutorial_completed or not is_new_game:
			is_new_game = false
		print("GameManager: 已从 SaveManager 缓存恢复玩家属性 (HP: %d, LV: %d)" % [p_data.health, p_data.level])
		SaveManager._cached_player_data = {}
	else:
		GameState.player_data.display_name = "冒险者"
		if is_new_game:
			GameState.player_data.tutorial_completed = false
			GameState.player_data.tutorial_step = 0

	if EventBus:
		print("Emitting player_data_refreshed...")
		EventBus.player_data_refreshed.emit()
	return restored_from_save

func _complete_world_startup() -> void:
	var scene_root = get_tree().current_scene
	if not scene_root:
		await _abort_startup_to_menu("当前场景尚未就绪，无法完成世界启动。")
		return

	var world_gen = _find_world_generator(scene_root)
	if not world_gen:
		await _abort_startup_to_menu("未找到 WorldGenerator，无法初始化世界。")
		return

	_apply_pending_world_seed(world_gen)
	_report_startup_progress("world_bootstrap", 0.15, "正在初始化世界生成器...")
	if world_gen.has_method("start_generation"):
		world_gen.start_generation()
	elif world_gen.has_method("generate_world"):
		world_gen.generate_world()
	_report_startup_progress("world_bootstrap", 0.65, "世界生成器已完成关键启动。")

	var pregen_status := await _pregenerate_finite_world_if_supported()
	_report_startup_progress("world_bootstrap", 0.95, pregen_status)

	_restore_pending_buildings()
	_report_startup_progress("world_bootstrap", 1.0, "关键世界对象已恢复。")

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		await _abort_startup_to_menu("未找到玩家节点，无法完成启动。")
		return

	var startup_spawn := _resolve_startup_spawn_context(scene_root, world_gen)
	var spawn_ready := await _prepare_spawn_area(player, startup_spawn)
	if not spawn_ready:
		await _abort_startup_to_menu("出生区域预热超时，已取消进入世界。")
		return

	_report_startup_progress("gameplay_handoff", 0.5, "正在释放 HUD、实体层与玩家输入...")
	change_state(State.PLAYING)
	player.process_mode = Node.PROCESS_MODE_INHERIT
	if EventBus:
		EventBus.player_input_enabled.emit(true)
	_report_startup_progress("gameplay_handoff", 1.0, "世界已准备完成。")

	if UIManager:
		if is_new_game:
			await UIManager.hide_loading_overlay(0.2)
		else:
			await UIManager.play_fade(false, 0.35)
			await UIManager.hide_loading_overlay(0.2)

func _on_finite_world_pregen_progress(done: int, total: int) -> void:
	if total <= 0:
		return
	var ratio := clampf(float(done) / float(total), 0.0, 1.0)
	var mapped_progress := 0.66 + ratio * 0.28
	_report_startup_progress(
		"world_bootstrap",
		mapped_progress,
		"正在预生成有限世界区块 %d/%d..." % [done, total]
	)

func _pregenerate_finite_world_if_supported() -> String:
	if not InfiniteChunkManager or not InfiniteChunkManager.has_method("pregenerate_finite_world"):
		return "未启用有限世界全量预生成。"

	if not WorldTopology or not WorldTopology.has_method("is_planetary") or not WorldTopology.is_planetary():
		return "当前世界模式跳过全量预生成。"

	# 读档路径默认跳过全量预生成，避免每次加载存档都重复等待完整世界构建。
	if SaveManager and SaveManager.current_slot_id >= 0 and not is_new_game:
		return "读档路径跳过全量预生成（按需流式加载）。"

	_report_startup_progress("world_bootstrap", 0.66, "正在准备有限世界全量预生成...")
	var chunk_budget := -1 if STARTUP_PREGEN_FORCE_FULL_WORLD else STARTUP_PREGEN_CHUNK_BUDGET
	var time_budget_sec := 0.0 if STARTUP_PREGEN_FORCE_FULL_WORLD else STARTUP_PREGEN_TIME_BUDGET_SEC
	var result: Dictionary = await InfiniteChunkManager.pregenerate_finite_world(
		Callable(self, "_on_finite_world_pregen_progress"),
		chunk_budget,
		time_budget_sec
	)
	var full_total := int(result.get("full_total", 0))
	var total := int(result.get("total", 0))
	var done := int(result.get("done", 0))
	var max_chunk_y := int(result.get("max_chunk_y", 0))
	var reason := String(result.get("reason", "unknown"))

	match reason:
		"completed":
			return "有限世界预生成完成：%d 个区块（Y <= %d）" % [total, max_chunk_y]
		"chunk_budget_capped":
			return "启动期预生成已达区块预算：%d/%d（剩余将按需加载）" % [done, maxi(full_total, total)]
		"time_budget_exhausted":
			return "启动期预生成已达时间预算：%d/%d（剩余将按需加载）" % [done, maxi(full_total, total)]
		"already_cached":
			return "复用已有预生成缓存：%d 个区块" % total
		"legacy_mode":
			return "当前为旧拓扑模式，跳过全量预生成。"
		"invalid_circumference":
			return "世界边界异常，跳过全量预生成。"
		"missing_world_generator":
			return "未找到生成器，跳过全量预生成。"
		_:
			return "有限世界预生成已跳过（%s）。" % reason

func _find_world_generator(scene_root: Node) -> Node:
	var world_gen = scene_root.find_child("WorldGenerator", true, false)
	if world_gen:
		return world_gen
	var gens = get_tree().get_nodes_in_group("world_generator")
	if gens.is_empty():
		gens = get_tree().get_nodes_in_group("world_generators")
	if not gens.is_empty():
		return gens[0]
	return null

func _apply_pending_world_seed(world_gen: Node) -> void:
	if GameState.has_meta("pending_new_seed"):
		world_gen.seed_value = GameState.get_meta("pending_new_seed")
		GameState.remove_meta("pending_new_seed")
		print("GameManager: 使用预设种子: ", world_gen.seed_value)
		return
	if world_gen.get("seed_value") == null:
		return
	if is_new_game:
		world_gen.seed_value = _generate_fresh_world_seed()
		print("GameManager: 新游戏回退生成种子: ", world_gen.seed_value)
		return
	if int(world_gen.seed_value) == 0:
		world_gen.seed_value = _generate_fresh_world_seed()
		print("GameManager: 回退随机生成新种子: ", world_gen.seed_value)

func _resolve_startup_spawn_context(scene_root: Node, world_gen: Node) -> Dictionary:
	var tutorial_ship = scene_root.find_child("TutorialSpaceship", true, false)
	if tutorial_ship and tutorial_ship.has_method("should_override_startup_spawn") and tutorial_ship.call("should_override_startup_spawn"):
		return {
			"position": tutorial_ship.call("get_startup_spawn_position"),
			"requires_chunk_warmup": false,
			"snap_to_safe_ground": false,
		}
	if GameState.has_meta("load_spawn_pos"):
		var saved_spawn: Vector2 = GameState.get_meta("load_spawn_pos")
		GameState.remove_meta("load_spawn_pos")
		return {
			"position": saved_spawn,
			"requires_chunk_warmup": true,
			"snap_to_safe_ground": true,
		}
	if world_gen and world_gen.has_method("get_spawn_position"):
		return {
			"position": world_gen.get_spawn_position(),
			"requires_chunk_warmup": true,
			"snap_to_safe_ground": true,
		}
	var player = get_tree().get_first_node_in_group("player")
	if player:
		return {
			"position": player.global_position,
			"requires_chunk_warmup": true,
			"snap_to_safe_ground": true,
		}
	return {
		"position": Vector2(0, 300 * 16),
		"requires_chunk_warmup": true,
		"snap_to_safe_ground": true,
	}

func _prepare_spawn_area(player: Node2D, spawn_context: Dictionary) -> bool:
	player.process_mode = Node.PROCESS_MODE_DISABLED
	_report_startup_progress("spawn_area_ready", 0.05, "正在预热出生区域...")
	var target_pos: Vector2 = spawn_context.get("position", Vector2.ZERO)
	var requires_chunk_warmup := bool(spawn_context.get("requires_chunk_warmup", true))
	var snap_to_safe_ground := bool(spawn_context.get("snap_to_safe_ground", true))
	if not InfiniteChunkManager:
		await _spawn_player_safely(player, target_pos, false)
		_report_startup_progress("spawn_area_ready", 1.0, "出生区域已准备完成。")
		return true
	if not requires_chunk_warmup:
		await _spawn_player_safely(player, target_pos, false)
		_report_startup_progress("spawn_area_ready", 1.0, "教程出生区域已准备完成。")
		return true

	var required_chunks := _collect_required_startup_chunks(target_pos)
	InfiniteChunkManager.update_player_vicinity(target_pos)
	for entry in required_chunks:
		var canonical_coord: Vector2i = entry.get("canonical", Vector2i.ZERO)
		var display_coord: Vector2i = entry.get("display", canonical_coord)
		InfiniteChunkManager.request_chunk_load(canonical_coord, display_coord)
	var remaining_frames := mini(maxi(600, required_chunks.size() * 20), 2400)
	while remaining_frames > 0:
		var loaded_count := 0
		for entry in required_chunks:
			var canonical_coord: Vector2i = entry.get("canonical", Vector2i.ZERO)
			if InfiniteChunkManager.loaded_chunks.has(canonical_coord):
				loaded_count += 1
		var chunk_progress := float(loaded_count) / float(maxi(required_chunks.size(), 1))
		_report_startup_progress("spawn_area_ready", chunk_progress * 0.9, "正在预热出生区域 %d/%d..." % [loaded_count, required_chunks.size()])
		if loaded_count >= required_chunks.size():
			break
		await get_tree().process_frame
		remaining_frames -= 1

	if remaining_frames <= 0:
		push_warning("GameManager: 出生区域预热超时，启用紧急进入回退。")
		if InfiniteChunkManager and InfiniteChunkManager.has_method("force_load_at_world_pos"):
			InfiniteChunkManager.force_load_at_world_pos(target_pos)
		await _spawn_player_safely(player, target_pos, false)
		var emergency_safe = InfiniteChunkManager.find_safe_ground(player.global_position)
		if snap_to_safe_ground and emergency_safe != null:
			player.global_position = emergency_safe
		_report_startup_progress("spawn_area_ready", 1.0, "出生区域预热超时，已切换紧急进入。")
		return true

	_report_startup_progress("spawn_area_ready", 0.95, "正在放置玩家...")
	await _spawn_player_safely(player, target_pos, false)
	var safe_ground = InfiniteChunkManager.find_safe_ground(player.global_position)
	if snap_to_safe_ground and safe_ground != null:
		player.global_position = safe_ground
	_report_startup_progress("spawn_area_ready", 1.0, "出生区域已准备完成。")
	return true

func _collect_required_startup_chunks(target_pos: Vector2) -> Array:
	if not InfiniteChunkManager:
		return []
	var center_display_chunk: Vector2i = InfiniteChunkManager.get_chunk_coord(target_pos)
	if InfiniteChunkManager.has_method("get_display_chunk_coord"):
		center_display_chunk = InfiniteChunkManager.get_display_chunk_coord(target_pos)
	var radius := 1
	var vertical_depth := STARTUP_VERTICAL_PREWARM_CHUNKS_LEGACY
	if WorldTopology and WorldTopology.has_method("is_planetary") and WorldTopology.is_planetary():
		radius = 2
		vertical_depth = STARTUP_VERTICAL_PREWARM_CHUNKS_PLANETARY
	var needed_chunks: Array = []
	var needed_display_by_canonical: Dictionary = {}
	var min_y := center_display_chunk.y - 1
	var max_y := center_display_chunk.y + vertical_depth
	for x in range(center_display_chunk.x - radius, center_display_chunk.x + radius + 1):
		for y in range(min_y, max_y + 1):
			var display_coord := Vector2i(x, y)
			var coord := display_coord
			if InfiniteChunkManager and InfiniteChunkManager.has_method("canonicalize_chunk_coord"):
				coord = InfiniteChunkManager.canonicalize_chunk_coord(coord)
			if InfiniteChunkManager and InfiniteChunkManager.has_method("resolve_nearest_display_coord"):
				display_coord = InfiniteChunkManager.resolve_nearest_display_coord(coord, center_display_chunk)
			if needed_display_by_canonical.has(coord):
				var current_display: Vector2i = needed_display_by_canonical[coord]
				if absi(display_coord.x - center_display_chunk.x) < absi(current_display.x - center_display_chunk.x):
					needed_display_by_canonical[coord] = display_coord
				continue
			needed_display_by_canonical[coord] = display_coord
			needed_chunks.append({
				"canonical": coord,
				"display": display_coord,
			})
	return needed_chunks

func _restore_pending_buildings() -> void:
	if not GameState.has_meta("load_buildings"):
		return
	var buildings_data = GameState.get_meta("load_buildings")
	GameState.remove_meta("load_buildings")
	print("GameManager: 恢复 %d 个建筑..." % buildings_data.size())
	var b_container = get_tree().get_first_node_in_group("buildings_container")
	if not b_container:
		return
	for child in b_container.get_children():
		child.queue_free()
	for b_info in buildings_data:
		var scene_path = b_info.scene_path
		if "workshop.tscn" in scene_path and not "buildings/" in scene_path:
			scene_path = "res://scenes/world/buildings/workshop.tscn"
		if "ruins_stone.tscn" in scene_path and not "buildings/" in scene_path:
			scene_path = "res://scenes/world/buildings/ruins_stone.tscn"
		if not ResourceLoader.exists(scene_path):
			push_warning("GameManager: 找不到建筑场景 %s" % scene_path)
			continue
		var scene = ResourceLoader.load(scene_path)
		if not scene:
			continue
		var instance = scene.instantiate()
		b_container.add_child(instance)
		instance.global_position = b_info.position
		instance.rotation = b_info.rotation
		if b_info.has("custom_data") and b_info.custom_data.has("resource_id"):
			var res_id = b_info.custom_data.resource_id
			if GameState.building_db.has(res_id):
				var res = GameState.building_db[res_id]
				if instance.has_method("setup"):
					instance.setup(res)
				if get_node_or_null("/root/SettlementManager"):
					get_node("/root/SettlementManager").register_building(instance, res)
		if instance.has_method("load_custom_data"):
			instance.load_custom_data(b_info.get("custom_data", {}))

func _abort_startup_to_menu(message: String) -> void:
	push_error("GameManager: 启动失败 - %s" % message)
	if UIManager and UIManager.has_method("show_loading_failure"):
		UIManager.show_loading_failure(message)
	await get_tree().create_timer(1.1).timeout
	current_state = State.GAME_OVER
	change_state(State.START_MENU)
	if UIManager:
		await UIManager.play_fade(false, 0.2)
		if UIManager.has_method("hide_loading_overlay"):
			await UIManager.hide_loading_overlay(0.15)

func _spawn_player_safely(player: Node2D, target_pos: Vector2, restore_process: bool = true) -> void:
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.global_position = target_pos
	if player is CharacterBody2D:
		player.velocity = Vector2.ZERO
	if not InfiniteChunkManager:
		if restore_process:
			player.process_mode = Node.PROCESS_MODE_INHERIT
		return
	InfiniteChunkManager.update_player_vicinity(target_pos)
	var chunk_coord = InfiniteChunkManager.get_chunk_coord(target_pos)
	if not InfiniteChunkManager.loaded_chunks.has(chunk_coord):
		var max_wait = 500
		while not InfiniteChunkManager.loaded_chunks.has(chunk_coord) and max_wait > 0:
			await get_tree().process_frame
			max_wait -= 1
	if restore_process:
		player.process_mode = Node.PROCESS_MODE_INHERIT
	player.global_position = target_pos + Vector2(0, -2)
