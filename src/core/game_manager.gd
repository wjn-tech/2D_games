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
	"full_world_preload",
	"spawn_area_ready",
	"gameplay_handoff",
]

const STARTUP_STAGE_WEIGHTS := {
	"scene_stable": 0.10,
	"topology_restore": 0.10,
	"save_restore": 0.15,
	"world_bootstrap": 0.15,
	"full_world_preload": 0.30,
	"spawn_area_ready": 0.10,
	"gameplay_handoff": 0.10,
}

const STARTUP_STAGE_LABELS := {
	"scene_stable": "稳定场景",
	"topology_restore": "恢复世界拓扑",
	"save_restore": "恢复会话数据",
	"world_bootstrap": "启动世界生成",
	"full_world_preload": "全量预加载世界",
	"spawn_area_ready": "预热出生区域",
	"gameplay_handoff": "进入世界",
}

const GAMEPLAY_SCENE_PATH := "res://scenes/main.tscn"
const MIN_LOADING_OVERLAY_VISIBLE_SEC := 0.9
const STARTUP_SCENE_READY_MAX_WAIT_FRAMES := 360
const STARTUP_PLAYER_READY_MAX_WAIT_FRAMES := 180
const STARTUP_SCENE_SWITCH_RETRY_COUNT := 4
const STARTUP_SCENE_SWITCH_RETRY_DELAY_SEC := 0.12
const PLAYER_SCENE_PATH := "res://scenes/player.tscn"

var _startup_stage_progress: Dictionary = {}
var _startup_current_stage: String = ""
var _startup_stage_status: String = ""
var _world_startup_ready: bool = false
var _loading_overlay_shown_at_msec: int = 0
var _pending_startup_scene_path: String = ""
var _last_startup_abort_reason: String = ""
var _last_startup_abort_source: String = ""
var _last_startup_abort_time_msec: int = 0
var _startup_emergency_recovered: bool = false

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
				_mark_loading_overlay_shown()
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
	_world_startup_ready = false
	is_new_game = false
	_is_starting_new_game = false
	GameState.player_data = null
	GameState.unlocked_spells.clear()
	
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
	_last_startup_abort_reason = ""
	_last_startup_abort_source = ""
	_last_startup_abort_time_msec = 0
	_startup_emergency_recovered = false
	
	# 先重置所有旧状态
	reset_game_state()
	_is_starting_new_game = true
	
	# 显式标记为新游戏
	is_new_game = true 
	_world_startup_ready = false
	
	# 1. 缓冲机制：先进入黑屏，确保场景切换期间玩家看不到原始 UI 的闪烁
	if UIManager:
		await UIManager.play_fade(true, 0.3)
		if UIManager.has_method("show_loading_overlay"):
			UIManager.show_loading_overlay("世界加载中", "切换游戏场景", 0.0, "正在创建新的世界会话...")
			_mark_loading_overlay_shown()
	if EventBus:
		EventBus.player_input_enabled.emit(false)
	
	# 2. 彻底停掉当前的逻辑，执行数据重置
	get_tree().paused = true
	
	var new_seed = _generate_fresh_world_seed()
	var runtime_world_path := "user://saves/runtime_new_game/world_deltas/world_%d/" % abs(new_seed)
	if GameState:
		# 清空 meta 但保留种子
		for meta_key in GameState.get_meta_list():
			GameState.remove_meta(meta_key)
		GameState.set_meta("pending_new_seed", new_seed)
		
		# 避免空指针 crash：初始化一个临时的空玩家数据，防止场景加载期间脚本访问报错
		GameState.player_data = CharacterData.new()
	
	print("GameManager: 新游戏启动，种子: ", new_seed)
	
	if InfiniteChunkManager: InfiniteChunkManager.restart()
	if SaveManager:
		SaveManager.current_slot_id = -1
		if SaveManager.has_method("clear_world_binding"):
			SaveManager.clear_world_binding()
		if SaveManager.has_method("stop_autosave"):
			SaveManager.stop_autosave()
	if InfiniteChunkManager and InfiniteChunkManager.has_method("clear_save_root_data"):
		InfiniteChunkManager.clear_save_root_data(runtime_world_path)
		InfiniteChunkManager.set_save_root(runtime_world_path)
	if NPCSpawner and NPCSpawner.has_method("reset"): NPCSpawner.reset()
	if Chronometer and Chronometer.has_method("reset"): Chronometer.reset()
	if LayerManager and LayerManager.has_method("reset"): LayerManager.reset()
	if UIManager and UIManager.has_method("clear_all_references"):
		UIManager.clear_all_references()
	
	# 2. 执行场景切换
	current_state = State.GAME_OVER 
	_pending_startup_scene_path = GAMEPLAY_SCENE_PATH
	get_tree().paused = false

	var scene_switched := await _switch_to_startup_scene(_pending_startup_scene_path, "new_game")
	if scene_switched:
		await _on_reload_finished()
	else:
		_pending_startup_scene_path = ""
		_is_starting_new_game = false
		_world_startup_ready = false
		await _abort_startup_to_menu("切换目标场景失败，无法开始新游戏。", "switch_scene_new_game")

func load_game(slot_id: int) -> void:
	if _is_starting_new_game: return
	_last_startup_abort_reason = ""
	_last_startup_abort_source = ""
	_last_startup_abort_time_msec = 0
	_startup_emergency_recovered = false
	
	reset_game_state()
	_is_starting_new_game = true
	_world_startup_ready = false
	
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
			_mark_loading_overlay_shown()
	if EventBus:
		EventBus.player_input_enabled.emit(false)
	
	get_tree().paused = true
	current_state = State.GAME_OVER
	
	var scene_path = GAMEPLAY_SCENE_PATH
	if GameState.has_meta("pending_scene_path"):
		scene_path = GameState.get_meta("pending_scene_path")
		GameState.remove_meta("pending_scene_path")
	_pending_startup_scene_path = scene_path
	get_tree().paused = false

	var scene_switched := await _switch_to_startup_scene(_pending_startup_scene_path, "load_game")
	if scene_switched:
		await _on_reload_finished()
	else:
		_pending_startup_scene_path = ""
		_is_starting_new_game = false
		_world_startup_ready = false
		await _abort_startup_to_menu("切换目标场景失败，无法读取存档。", "switch_scene_load_game")

func _on_reload_finished() -> void:
	get_tree().paused = false
	var scene_ready := await _wait_for_expected_startup_scene_ready()
	if not scene_ready:
		var retry_scene := _pending_startup_scene_path.strip_edges()
		if retry_scene == "":
			retry_scene = GAMEPLAY_SCENE_PATH
		var retry_switched := await _switch_to_startup_scene(retry_scene, "startup_recover")
		if retry_switched:
			scene_ready = await _wait_for_expected_startup_scene_ready()

	if not scene_ready:
		_is_starting_new_game = false
		_world_startup_ready = false
		await _abort_startup_to_menu("目标场景加载超时，无法完成世界启动。", "reload_scene_ready_timeout")
		return

	_is_starting_new_game = false
	_world_startup_ready = false
	print("GameManager: 场景重载完毕，正在初始化...")
	_pending_startup_scene_path = ""
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
	var forced_planetary := false
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
	elif WorldTopology.has_method("create_new_world"):
		var world_size_preset := "medium"
		if GameState.has_meta("pending_world_size_preset"):
			world_size_preset = String(GameState.get_meta("pending_world_size_preset"))
			GameState.remove_meta("pending_world_size_preset")
		WorldTopology.create_new_world(pending_seed, world_size_preset)
	else:
		WorldTopology.reset_to_legacy(pending_seed)

	if WorldTopology.has_method("is_planetary") and not bool(WorldTopology.is_planetary()) and WorldTopology.has_method("create_new_world"):
		forced_planetary = true
		var fallback_seed := pending_seed
		var fallback_world_size := "medium"
		if WorldTopology.has_method("get_current_metadata"):
			var current: Dictionary = WorldTopology.get_current_metadata()
			if fallback_seed == 0:
				fallback_seed = int(current.get("primary_seed", current.get("world_seed", 0)))
			var loaded_preset := String(current.get("world_size_preset", ""))
			if loaded_preset != "" and loaded_preset != "legacy":
				fallback_world_size = loaded_preset
		if fallback_seed == 0:
			fallback_seed = _generate_fresh_world_seed()
		WorldTopology.create_new_world(fallback_seed, fallback_world_size)
	var current_metadata := WorldTopology.get_current_metadata() if WorldTopology.has_method("get_current_metadata") else {}
	var summary := "世界拓扑: %s / %s" % [
		String(current_metadata.get("topology_mode", "legacy_infinite")),
		String(current_metadata.get("world_size_preset", "legacy")),
	]
	if forced_planetary:
		summary += " (已强制切换为有限环形世界)"
	return summary

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
		for i in range(STARTUP_SCENE_READY_MAX_WAIT_FRAMES):
			await get_tree().process_frame
			scene_root = get_tree().current_scene
			if scene_root:
				break
		if not scene_root:
			await _abort_startup_to_menu("当前场景尚未就绪，无法完成世界启动。", "startup_scene_missing")
			return

	var world_gen = _find_world_generator(scene_root)
	if not world_gen:
		for i in range(90):
			await get_tree().process_frame
			world_gen = _find_world_generator(scene_root)
			if world_gen:
				break
	if not world_gen:
		push_warning("GameManager: 未找到 WorldGenerator，回退到无生成器兼容启动路径。")

	if world_gen:
		_apply_pending_world_seed(world_gen)
		_report_startup_progress("world_bootstrap", 0.15, "正在初始化世界生成器...")
		if world_gen.has_method("start_generation"):
			world_gen.start_generation()
		elif world_gen.has_method("generate_world"):
			world_gen.generate_world()
		_report_startup_progress("world_bootstrap", 0.65, "世界生成器已完成关键启动。")
	else:
		_report_startup_progress("world_bootstrap", 0.65, "未检测到世界生成器，使用兼容启动路径。")

	_restore_pending_buildings()
	_report_startup_progress("world_bootstrap", 1.0, "关键世界对象已恢复。")

	var preload_gate := await _run_startup_full_preload_gate()
	if not bool(preload_gate.get("ok", false)):
		var reason_code := String(preload_gate.get("reason_code", "PRELOAD_FAILED"))
		push_warning("GameManager: 全量预加载失败，回退到兼容出生区预热路径。reason=%s" % reason_code)
		_report_startup_progress("full_world_preload", 1.0, "全量预加载失败，已切换兼容预热路径。")
		preload_gate = {
			"ok": true,
			"required": false,
			"legacy_fallback": true,
		}

	var player := await _resolve_startup_player(scene_root)
	if not player:
		await _abort_startup_to_menu("未找到玩家节点，无法完成启动。", "startup_player_missing")
		return

	var startup_spawn := _resolve_startup_spawn_context(scene_root, world_gen)
	if bool(preload_gate.get("required", false)) and not bool(preload_gate.get("legacy_fallback", false)):
		startup_spawn["requires_chunk_warmup"] = false
	var spawn_ready := await _prepare_spawn_area(player, startup_spawn)
	if not spawn_ready:
		push_warning("GameManager: 出生区域预热超时，回退到直接放置玩家。")
		await _spawn_player_safely(player, Vector2(startup_spawn.get("position", Vector2.ZERO)), false)

	_report_startup_progress("gameplay_handoff", 0.5, "正在释放 HUD、实体层与玩家输入...")
	_world_startup_ready = true
	change_state(State.PLAYING)
	player.process_mode = Node.PROCESS_MODE_INHERIT
	if EventBus:
		EventBus.player_input_enabled.emit(true)
	_report_startup_progress("gameplay_handoff", 1.0, "世界已准备完成。")

	if UIManager:
		await _await_min_loading_overlay_visibility()
		if is_new_game:
			await UIManager.hide_loading_overlay(0.2)
		else:
			await UIManager.play_fade(false, 0.35)
			await UIManager.hide_loading_overlay(0.2)


func _mark_loading_overlay_shown() -> void:
	_loading_overlay_shown_at_msec = Time.get_ticks_msec()


func _await_min_loading_overlay_visibility() -> void:
	if _loading_overlay_shown_at_msec <= 0:
		return
	var elapsed_sec := float(Time.get_ticks_msec() - _loading_overlay_shown_at_msec) / 1000.0
	var remain_sec := MIN_LOADING_OVERLAY_VISIBLE_SEC - elapsed_sec
	if remain_sec > 0.0:
		await get_tree().create_timer(remain_sec).timeout
	_loading_overlay_shown_at_msec = 0

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
			"requires_chunk_warmup": true,
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
		_report_startup_progress("spawn_area_ready", 1.0, "全量预加载已完成，出生点无需增量预热。")
		return true

	var required_chunks := _collect_required_startup_chunks(target_pos)
	if InfiniteChunkManager.has_method("set_startup_streaming_mode"):
		InfiniteChunkManager.set_startup_streaming_mode(true)
	if InfiniteChunkManager.has_method("prime_required_chunks"):
		InfiniteChunkManager.prime_required_chunks(required_chunks)
	else:
		InfiniteChunkManager.update_player_vicinity(target_pos)
	var remaining_frames := 600
	while remaining_frames > 0:
		var loaded_count := 0
		for coord in required_chunks:
			if InfiniteChunkManager.loaded_chunks.has(coord):
				loaded_count += 1
		var chunk_progress := float(loaded_count) / float(maxi(required_chunks.size(), 1))
		_report_startup_progress("spawn_area_ready", chunk_progress * 0.9, "正在预热出生区域 %d/%d..." % [loaded_count, required_chunks.size()])
		if loaded_count >= required_chunks.size():
			break
		await get_tree().process_frame
		remaining_frames -= 1

	if remaining_frames <= 0:
		return false

	_report_startup_progress("spawn_area_ready", 0.95, "正在放置玩家...")
	await _spawn_player_safely(player, target_pos, false)
	var safe_ground = InfiniteChunkManager.find_safe_ground(player.global_position)
	if snap_to_safe_ground and safe_ground != null:
		player.global_position = safe_ground
	if InfiniteChunkManager.has_method("set_startup_streaming_mode"):
		InfiniteChunkManager.set_startup_streaming_mode(false, 45)
	_report_startup_progress("spawn_area_ready", 1.0, "出生区域已准备完成。")
	return true

func _on_startup_full_preload_progress(snapshot: Dictionary) -> void:
	var processed_chunks := int(snapshot.get("processed_chunks", 0))
	var remaining_chunks := int(snapshot.get("remaining_chunks", 0))
	var total_chunks := processed_chunks + remaining_chunks
	var batch_index := int(snapshot.get("batch_index", 0))
	var progress := clampf(float(snapshot.get("progress", 0.0)), 0.0, 1.0)
	_report_startup_progress(
		"full_world_preload",
		progress,
		"全量预加载 %d/%d 区块 (batch %d)" % [processed_chunks, maxi(total_chunks, 1), batch_index]
	)

func _run_startup_full_preload_gate() -> Dictionary:
	_report_startup_progress("full_world_preload", 0.02, "正在检查世界拓扑与预加载范围...")
	if not InfiniteChunkManager or not InfiniteChunkManager.has_method("run_planetary_full_preload"):
		_report_startup_progress("full_world_preload", 1.0, "当前版本未启用全量预加载，使用兼容预热路径。")
		return {
			"ok": true,
			"required": false,
			"legacy_fallback": true,
			"reason_code": "PRELOAD_UNAVAILABLE",
			"progress_snapshot": {},
		}

	if InfiniteChunkManager.preload_progress.is_connected(_on_startup_full_preload_progress):
		InfiniteChunkManager.preload_progress.disconnect(_on_startup_full_preload_progress)
	InfiniteChunkManager.preload_progress.connect(_on_startup_full_preload_progress)

	var preload_options := {
		"batch_size": 128,
		"checkpoint_interval_batches": 8,
		"checkpoint_interval_msec": 2500,
	}
	if WorldTopology and WorldTopology.has_method("get_preload_batch_size"):
		preload_options["batch_size"] = maxi(int(WorldTopology.get_preload_batch_size()), 96)
	var preload_result: Dictionary = await InfiniteChunkManager.run_planetary_full_preload(preload_options)

	if InfiniteChunkManager.preload_progress.is_connected(_on_startup_full_preload_progress):
		InfiniteChunkManager.preload_progress.disconnect(_on_startup_full_preload_progress)

	if not bool(preload_result.get("required", false)):
		_report_startup_progress("full_world_preload", 1.0, "legacy/infinite 模式，保留出生区预热兼容路径。")
		return {
			"ok": true,
			"required": false,
			"legacy_fallback": true,
			"reason_code": "",
			"progress_snapshot": preload_result,
		}

	if not bool(preload_result.get("completed", false)):
		var reason_code := String(preload_result.get("failure_reason", "PRELOAD_FAILED"))
		var failure_status := "全量预加载失败: %s" % reason_code
		_report_startup_progress("full_world_preload", clampf(float(preload_result.get("progress", 0.0)), 0.0, 1.0), failure_status)
		return {
			"ok": false,
			"required": true,
			"legacy_fallback": false,
			"reason_code": reason_code,
			"progress_snapshot": preload_result.get("progress_snapshot", preload_result),
		}

	var source_desc := "已命中缓存" if bool(preload_result.get("reused_completed_cache", false)) else "已新生成"
	_report_startup_progress("full_world_preload", 1.0, "全量预加载完成 (%s)。" % source_desc)
	return {
		"ok": true,
		"required": true,
		"legacy_fallback": false,
		"reason_code": "",
		"progress_snapshot": preload_result,
	}

func _collect_required_startup_chunks(target_pos: Vector2) -> Array:
	if not InfiniteChunkManager:
		return []
	var center_chunk: Vector2i = InfiniteChunkManager.get_chunk_coord(target_pos)
	var radius := 1
	var needed_chunks: Array = []
	for x in range(center_chunk.x - radius, center_chunk.x + radius + 1):
		for y in range(center_chunk.y - radius, center_chunk.y + radius + 1):
			var coord := Vector2i(x, y)
			if InfiniteChunkManager.has_method("get_canonical_chunk_coord"):
				coord = InfiniteChunkManager.get_canonical_chunk_coord(coord)
			if not needed_chunks.has(coord):
				needed_chunks.append(coord)

	for x in range(center_chunk.x - 1, center_chunk.x + 2):
		for y in range(center_chunk.y + 2, center_chunk.y + 4):
			var corridor_coord := Vector2i(x, y)
			if InfiniteChunkManager.has_method("get_canonical_chunk_coord"):
				corridor_coord = InfiniteChunkManager.get_canonical_chunk_coord(corridor_coord)
			if not needed_chunks.has(corridor_coord):
				needed_chunks.append(corridor_coord)
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

func _abort_startup_to_menu(message: String, source: String = "unknown") -> void:
	_world_startup_ready = false
	_pending_startup_scene_path = ""
	_last_startup_abort_reason = message
	_last_startup_abort_source = source
	_last_startup_abort_time_msec = Time.get_ticks_msec()
	push_error("GameManager: 启动失败 - %s (source=%s state=%d)" % [message, source, int(current_state)])

	if await _try_emergency_startup_handoff(message):
		return

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

func is_world_startup_ready() -> bool:
	return _world_startup_ready


func _switch_to_startup_scene(scene_path: String, context: String) -> bool:
	var target := scene_path.strip_edges()
	if target == "":
		push_warning("GameManager: startup scene is empty. context=%s" % context)
		return false

	var last_error := OK
	for attempt in range(STARTUP_SCENE_SWITCH_RETRY_COUNT):
		last_error = get_tree().change_scene_to_file(target)
		if last_error == OK:
			return true
		push_warning("GameManager: change_scene_to_file failed (%d) attempt=%d/%d context=%s target=%s" % [last_error, attempt + 1, STARTUP_SCENE_SWITCH_RETRY_COUNT, context, target])
		await get_tree().process_frame
		await get_tree().create_timer(STARTUP_SCENE_SWITCH_RETRY_DELAY_SEC).timeout

	push_error("GameManager: change_scene_to_file exhausted retries. context=%s target=%s last_error=%d" % [context, target, last_error])
	return false


func _scene_has_startup_markers(scene_root: Node) -> bool:
	if not scene_root:
		return false
	if get_tree().get_first_node_in_group("player"):
		return true
	if scene_root.find_child("Player", true, false):
		return true
	if scene_root.find_child("WorldGenerator", true, false):
		return true
	if scene_root.find_child("Entities", true, false):
		return true
	return false


func _wait_for_expected_startup_scene_ready() -> bool:
	var expected := _pending_startup_scene_path.strip_edges()
	if expected == "":
		var current = get_tree().current_scene
		return current != null and _scene_has_startup_markers(current)

	for i in range(STARTUP_SCENE_READY_MAX_WAIT_FRAMES):
		var scene_root = get_tree().current_scene
		if scene_root and String(scene_root.scene_file_path) == expected:
			return true
		await get_tree().process_frame

	var current_scene = get_tree().current_scene
	if current_scene:
		if _scene_has_startup_markers(current_scene):
			push_warning("GameManager: startup scene path mismatch but markers detected. expected=%s current=%s" % [expected, String(current_scene.scene_file_path)])
			return true
		push_warning("GameManager: startup scene mismatch. expected=%s current=%s" % [expected, String(current_scene.scene_file_path)])
	else:
		push_warning("GameManager: startup scene missing after wait. expected=%s" % expected)
	return false


func _resolve_startup_player(scene_root: Node) -> Node2D:
	var player = get_tree().get_first_node_in_group("player")
	if player and player is Node2D:
		return player

	for i in range(STARTUP_PLAYER_READY_MAX_WAIT_FRAMES):
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group("player")
		if player and player is Node2D:
			return player

	var fallback_player = scene_root.find_child("Player", true, false)
	if fallback_player and fallback_player is Node2D:
		return fallback_player

	if not ResourceLoader.exists(PLAYER_SCENE_PATH):
		return null

	var player_scene = ResourceLoader.load(PLAYER_SCENE_PATH)
	if not player_scene or not (player_scene is PackedScene):
		return null

	var entities = scene_root.find_child("Entities", true, false)
	if not entities:
		var entities_root := Node2D.new()
		entities_root.name = "Entities"
		scene_root.add_child(entities_root)
		entities = entities_root

	var spawned = (player_scene as PackedScene).instantiate()
	entities.add_child(spawned)
	if spawned is Node2D:
		(spawned as Node2D).global_position = Vector2.ZERO
		push_warning("GameManager: startup fallback spawned Player instance.")
		return spawned

	spawned.queue_free()
	return null


func _try_emergency_startup_handoff(message: String) -> bool:
	var startup_window := current_state == State.LOADING_WORLD or current_state == State.GAME_OVER
	if not startup_window:
		return false

	var scene_root := get_tree().current_scene
	if not _scene_has_startup_markers(scene_root):
		for i in range(120):
			await get_tree().process_frame
			scene_root = get_tree().current_scene
			if _scene_has_startup_markers(scene_root):
				break
		if not _scene_has_startup_markers(scene_root):
			return false

	var player := await _resolve_startup_player(scene_root)
	if not player:
		return false

	push_warning("GameManager: startup failure recovered by emergency handoff. reason=%s" % message)
	_startup_emergency_recovered = true
	_report_startup_progress("gameplay_handoff", 0.75, "检测到启动异常，已切换兼容接管路径...")
	_world_startup_ready = true
	change_state(State.PLAYING)
	player.process_mode = Node.PROCESS_MODE_INHERIT
	if EventBus:
		EventBus.player_input_enabled.emit(true)

	if UIManager:
		await _await_min_loading_overlay_visibility()
		if UIManager.has_method("hide_loading_overlay"):
			await UIManager.hide_loading_overlay(0.12)
		elif UIManager.has_method("dismiss_loading_overlay"):
			UIManager.dismiss_loading_overlay()

	return true


func get_startup_debug_snapshot() -> Dictionary:
	return {
		"current_state": int(current_state),
		"is_starting_new_game": _is_starting_new_game,
		"pending_scene": _pending_startup_scene_path,
		"last_abort_reason": _last_startup_abort_reason,
		"last_abort_source": _last_startup_abort_source,
		"last_abort_time_msec": _last_startup_abort_time_msec,
		"emergency_recovered": _startup_emergency_recovered,
	}
