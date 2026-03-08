extends Node2D

# --- Assets ---
const TERMINAL_SCENE = preload("res://scenes/ui/terminal_overlay.tscn")
const CINEMATIC_SCENE = preload("res://scenes/ui/tutorial/cinematic_overlay.tscn")
const OBJECTIVE_SCENE = preload("res://scenes/ui/tutorial/objective_tracker.tscn")
const WAND_ITEM_RES = preload("res://scenes/test_wand.tres")
const WALL_SCENE = preload("res://scenes/tutorial/breakable_wall.tscn")

const DEBRIS_SCENE = preload("res://scenes/vfx/ship_debris.tscn")
const WIND_LINES_SCENE = preload("res://scenes/vfx/falling_wind_lines.tscn")
const SHIELD_SCENE = preload("res://scenes/vfx/mage_shield.tscn")

var _fall_duration: float = 10.0
var _fall_timer: float = 0.0

# --- Nodes ---
# Use @onready to ensure these are ready when the script starts
@onready var court_mage = $CourtMage
@onready var objective_spawn_marker = $TargetMarker if has_node("TargetMarker") else null
@onready var env_controller = $EnvironmentController
@onready var shake_timer = $ShakeTimer
# Removed @onready for player since it might not be a direct child
var player: CharacterBody2D

# --- State ---
enum Step {
	INIT,
	INTRO_CINEMATIC,
	WAIT_MOVE,
	DIALOGUE_GIVE_WAND,
	WAIT_INVENTORY,
	WAIT_EQUIP,
	WAIT_EDITOR,
	WAIT_LOGIC_TAB,
	WAIT_FIX_SPELL,
	WAIT_TEST_FIRE,
	CRASH_SEQUENCE,
	COMPLETED
}

var current_step: Step = Step.INIT:
	set(v):
		current_step = v
		# 实时同步进度到玩家数据，确保随时存档都能保留状态
		if GameState.player_data:
			GameState.player_data.tutorial_step = int(v)
			if v == Step.COMPLETED:
				GameState.player_data.tutorial_completed = true

var camera: Camera2D
var cinematic: Node # Changed from CinematicOverlay to Node to support TerminalOverlay
var tracker: ObjectiveTracker

var _shake_amplitude: float = 0.0
var _original_cam_offset: Vector2 = Vector2.ZERO
var _movement_start_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 显式隐藏，等待数据初始化
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	
	# 等待 GameManager 完成数据加载
	if EventBus:
		EventBus.player_data_refreshed.connect(_on_data_ready)

func _on_data_ready() -> void:
	# 1. 验证是否运行教程
	
	# 首先获取玩家数据状态
	var tutorial_active = false
	var saved_step = 0
	if GameState.player_data:
		if not GameState.player_data.tutorial_completed:
			tutorial_active = true
			saved_step = GameState.player_data.tutorial_step
			
	# 如果是新游戏，强制激活
	if GameManager.is_new_game:
		tutorial_active = true
		saved_step = 0
		
	# 如果是一个纯粹的教程场景文件（例如独立测试场景），也强制激活
	var is_tutorial_scene_file = get_tree().current_scene.scene_file_path.contains("tutorial")
	
	if not tutorial_active and not is_tutorial_scene_file:
		queue_free()
		return
		
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	
	# 使用 cast 或直接赋值 (GDScript 2.0 能够处理 int -> enum)
	current_step = saved_step as Step
	
	# 2. 初始化逻辑 (原 _ready 的剩余部分)
	_init_tutorial_elements()

func _init_tutorial_elements() -> void:
	# 找到合适的主角 (优先使用场景中已有的 Player，避免 TutorialSpaceship 自带的 Player 造成双主角冲突)
	var global_player = get_tree().get_first_node_in_group("player")
	if has_node("Player"):
		var local_player = get_node("Player")
		if global_player and local_player != global_player:
			# 如果世界中已经有一个玩家实例（比如 Main.tscn 的），删除我们自带的
			local_player.queue_free()
			player = global_player
		elif local_player:
			player = local_player
	elif global_player:
		player = global_player
		
	# Teleport Player to Ship
	if player:
		# If we are in Main scene, the spaceship is at (0, -50000) by default, 
		# but let's force the manager position just in case or use local offsets.
		# The Manager is the root of the spaceship scene, so its children (Wall, Mage) are local.
		# But in Main.tscn, the instance is at (0, -50000).
		# We should move the player relative to the manager.
		player.global_position = self.global_position + Vector2(-200, -50)
		player.velocity = Vector2.ZERO
		
	# 清除 UIManager 的黑屏淡入
	if UIManager:
		# INSTANTLY remove UIManager fade so it doesn't obscure our TerminalOverlay
		# TerminalOverlay provides its own black background
		UIManager.play_fade(false, 0.0)
	
	# 清空玩家背包（确保教程环境干净）
	_clear_all_items()
	
	# 3. Setup Camera (PROACTIVE)
	# Find player again just in case
	if not player:
		player = get_tree().get_first_node_in_group("player")
		
	# Try to find existing functional camera
	camera = get_viewport().get_camera_2d()
	var has_valid_camera = false
	
	if player:
		# Check if player has a camera child (GameCamera or Camera2D)
		for child in player.get_children():
			if child is Camera2D:
				camera = child
				has_valid_camera = true
				break
	
	# If no camera on player, or the global camera is just a default Dummy, creating a GameCamera is safer.
	if not has_valid_camera and player:
		print("Tutorial: No camera found on Player. Creating GameCamera attachment.")
		var new_cam = Camera2D.new()
		new_cam.name = "GameCamera"
		# Load the script dynamically to ensure it has the API
		new_cam.set_script(load("res://src/core/game_camera.gd"))
		player.add_child(new_cam)
		new_cam.owner = player if player.owner else player # Ownership handling
		new_cam.make_current()
		new_cam.enabled = true
		camera = new_cam
		
	if camera:
		_original_cam_offset = camera.offset
	else:
		push_error("Tutorial: Failed to initialize any camera!")
		
	# Force camera update instantly to prevent 'glitch' frame at (0,0)
	if camera and player:
		camera.global_position = player.global_position
		if camera.has_method("reset_smoothing"):
			camera.reset_smoothing()
	
	# 初始化 UI 组件
	tracker = OBJECTIVE_SCENE.instantiate()
	# ObjectiveTracker 已经是一个 CanvasLayer，设置它的 layer 确保在编辑器之上
	tracker.layer = 150 
	add_child(tracker)
	
	# 信号连接
	EventBus.inventory_opened.connect(_on_inventory_opened)
	EventBus.item_equipped.connect(_on_item_equipped)
	EventBus.wand_editor_opened.connect(_on_editor_opened)
	EventBus.wand_editor_closed.connect(_on_editor_closed)
	EventBus.spell_logic_updated.connect(_on_spell_logic_updated)
	
	if shake_timer:
		if not shake_timer.timeout.is_connected(_on_shake_timer):
			shake_timer.timeout.connect(_on_shake_timer)
		shake_timer.start(0.05)

	# 3. 开始流程
	start_intro()

func _process(delta: float) -> void:
	if current_step == Step.CRASH_SEQUENCE:
		_process_crash_fall(delta)
	
	# 检查移动任务
	if current_step == Step.WAIT_MOVE:
		if is_instance_valid(player) and player.global_position.distance_to(_movement_start_pos) > 50.0:
			_on_move_done()
	
	# 检查逻辑页签任务
	if current_step == Step.WAIT_LOGIC_TAB:
		if UIManager.active_windows.has("WandEditor"):
			var we = UIManager.active_windows["WandEditor"]
			if we.get("logic_board") and we.logic_board.visible:
				_on_logic_tab_done()


func _process_crash_fall(delta: float) -> void:
	_fall_timer -= delta
	
	if player:
		# Tumble animation
		player.rotation_degrees += 100 * delta
		
		# Simulated camera shake increase
		if camera:
			camera.offset = _original_cam_offset + Vector2(randf_range(-5, 5), randf_range(-5, 5))
			
	if _fall_timer <= 0:
		_on_crash_impact()

func _on_crash_impact() -> void:
	current_step = Step.COMPLETED # Or a new wake up step
	set_process(false)
	
	# Wake Up Sequence
	if UIManager:
		UIManager.play_fade(true, 0.5) # Flash white/black
	
	await get_tree().create_timer(1.0).timeout
	
	if player:
		# Teleport to safe ground
		player.global_position = Vector2(0, 0) # Ground Zero
		player.velocity = Vector2.ZERO
		player.rotation_degrees = -90.0 # Lying down
		
		# Remove attached VFX (Shield, Wind)
		for child in player.get_children():
			if child.name.contains("MageShield") or child.name.contains("Wind"):
				child.queue_free()
		# Remove camera attached VFX
		if camera:
			for child in camera.get_children():
				if child.name.contains("Wind"):
					child.queue_free()
					
	# Restore Environment
	if UIManager:
		UIManager.play_fade(false, 2.0)
		
	# Camera restore
	if camera:
		camera.offset = _original_cam_offset
		
	await get_tree().create_timer(2.0).timeout
	
	# Stand up
	if player:
		var tween = create_tween()
		tween.tween_property(player, "rotation_degrees", 0.0, 1.5).set_trans(Tween.TRANS_SINE)
		await tween.finished
		
		# Enable Controls
		EventBus.player_movement_locked.emit(false)
		EventBus.player_input_enabled.emit(true)
		
		# Tutorial Done!
		GameManager.is_new_game = false
		
		# Final cleanup: Remove Tutorial Spaceship Scene (self)
		# We must defer this to avoid messing up the current frame
		queue_free()

# --- 核心教程步骤 ---

func start_intro() -> void:
	current_step = Step.INTRO_CINEMATIC
	_shake_amplitude = 2.0
	
	# Scene Setup: Prepare Actors
	_setup_actors_for_intro()
	
	# Instantiate Terminal Overlay
	cinematic = TERMINAL_SCENE.instantiate()
	# Ensure TerminalOverlay is very high layer (above 100 which is UIManager defaults)
	cinematic.layer = 128
	add_child(cinematic)
	cinematic.show_terminal()
	cinematic.clear() # Clear default placeholder text
	
	CinematicDirector.sequence_finished.connect(_on_intro_done, CONNECT_ONE_SHOT)
	
	# Define Locations
	var player_pos = player.global_position if player else Vector2.ZERO
	# Mage starts offset to the right (Control Console implied)
	var mage_start_pos = player_pos + Vector2(250, -50)
	if court_mage:
		court_mage.global_position = mage_start_pos
		
	var actions = [
		{"type": "wait", "duration": 0.2},
		{"type": "method", "target": cinematic, "method": "type_text", "args": ["[color=green]" + tr("INTRO_SYSTEM_START") + "[/color]", 0.03], "wait": true, "duration": 0.5},
		{"type": "method", "target": cinematic, "method": "type_text", "args": ["[color=yellow]" + tr("INTRO_HULL_INTEGRITY") + "[/color]", 0.02], "wait": true, "duration": 0.6},
		{"type": "method", "target": cinematic, "method": "type_text", "args": ["[b][color=red][" + tr("INTRO_CRITICAL_FAILURE") + "][/color][/b]", 0.05], "wait": false},
		{"type": "method", "target": cinematic, "method": "flash", "args": [Color(0.8, 0, 0, 1), 0.2]}, # Intense Red Flash
		{"type": "method", "target": self, "method": "trigger_red_alert"}, # Trigger Environment Change
		{"type": "wait", "duration": 0.5},
		{"type": "method", "target": cinematic, "method": "type_text", "args": [tr("INTRO_EMERGENCY_WAKEUP"), 0.02], "wait": true, "duration": 0.5},
		{"type": "method", "target": cinematic, "method": "glitch", "args": [0.3, 1.0]}, 
		{"type": "wait", "duration": 0.3},
		{"type": "method", "target": cinematic, "method": "flash", "args": [Color.WHITE, 0.2]}, # White Flash Transition
		{"type": "method", "target": cinematic, "method": "hide_terminal", "args": [0.1], "wait": false}, # Cut to game
		
		# --- Phase 2: Chaos & Running ---
		{"type": "cam_zoom", "scale": Vector2(1.5, 1.5), "duration": 0.0}, # Instant zoom
		{"type": "cam_pan", "target": mage_start_pos, "duration": 0.0}, # Start camera on Mage
		{"type": "cam_shake", "intensity": 8.0, "duration": 2.0},
		
		# Mage reacts and runs
		{"type": "scale_actor", "target": court_mage, "scale": Vector2(1.2, 0.8), "duration": 0.1}, # Jump/Shock
		{"type": "scale_actor", "target": court_mage, "scale": Vector2(1.0, 1.0), "duration": 0.1, "wait": true},
		{"type": "wait", "duration": 0.2},
		{"type": "cam_pan", "target": player_pos, "duration": 1.5, "wait": false}, # Camera tracks movement
		{"type": "move_actor", "target": court_mage, "destination": player_pos + Vector2(30, 0), "duration": 1.5, "wait": true}, # Run to player
		
		# --- Phase 3: Help Up ---
		{"type": "scale_actor", "target": court_mage, "scale": Vector2(1.0, 0.8), "duration": 0.2}, # Kneel
		{"type": "wait", "duration": 0.5},
		# Player wake up animation (simulated)
		{"type": "rotate_actor", "target": player, "angle": 0.0, "duration": 1.0, "wait": false}, # Stand up
		{"type": "scale_actor", "target": court_mage, "scale": Vector2(1.0, 1.0), "duration": 0.5, "wait": true}, # Mage Stand up
		
		{"type": "wait", "duration": 0.5},
		{"type": "cam_zoom", "scale": Vector2(1.2, 1.2), "duration": 1.0, "wait": true}, # Zoom in for dialogue
	]
	
	CinematicDirector.play_sequence(actions)

func _setup_actors_for_intro() -> void:
	# Strong Control
	if player:
		player.velocity = Vector2.ZERO
		player.process_mode = Node.PROCESS_MODE_DISABLED 
		EventBus.player_movement_locked.emit(true)
		EventBus.player_input_enabled.emit(false)
		
		# Visual: Knocked Down
		player.rotation_degrees = -90.0
		# Optional: Modulate to look unconscious?
		# player.modulate = Color(0.8, 0.8, 0.8, 1.0) 

func trigger_red_alert() -> void:
	if env_controller and env_controller.has_method("set_alert_level"):
		env_controller.set_alert_level(ShipEnvironmentController.AlertLevel.RED)
	
	# Hide Mage barrier effects as he loses control (Critical Failure)
	if court_mage:
		for node_name in ["Beam", "BarrierEffect", "BarrierParticles"]:
			if court_mage.has_node(node_name):
				var node = court_mage.get_node(node_name)
				node.visible = false
				if node is CPUParticles2D:
					node.emitting = false
	
	# Spawn sparks?
	var sparks = preload("res://scenes/vfx/sparks.tscn").instantiate()
	add_child(sparks)
	if player: sparks.global_position = player.global_position + Vector2(50, -50)

func _on_intro_done() -> void:
	if is_instance_valid(cinematic):
		cinematic.queue_free()
	
	# Unlock Player
	if player:
		player.process_mode = Node.PROCESS_MODE_INHERIT
		# Keep input locked for the dialogue that follows immediately
		# EventBus.player_movement_locked.emit(false)
		# EventBus.player_input_enabled.emit(true)
	
	# Skip 'Moved' objective, go straight to panic dialogue
	_start_dialogue_mage()

func _on_move_done() -> void:
	tracker.complete_objective()
	_start_dialogue_mage()

func _start_dialogue_mage() -> void:
	current_step = Step.DIALOGUE_GIVE_WAND
	
	# IMPROVEMENT: Use CinematicDirector for camera framing, then DialogueManager for text
	# instead of blocking the screen with CinematicOverlay.
	
	# 1. Pan Camera to Mage
	if court_mage:
		CinematicDirector.play_sequence([
			{"type": "cam_pan", "target": court_mage.global_position, "duration": 1.0},
			{"type": "wait", "duration": 0.5},
			{"type": "method", "target": self, "method": "_start_dialogue_content"}
		])
	else:
		_start_dialogue_content()

func _start_dialogue_content() -> void:
	# 2. Start In-Game Dialogue
	# Localization
	var dialogue_lines = [
		tr("INTRO_MAGE_1"),
		tr("INTRO_MAGE_2"),
		tr("INTRO_MAGE_3"),
		tr("INTRO_MAGE_4"),
		tr("INTRO_MAGE_5"),
		tr("INTRO_MAGE_6")
	]
	
	# Assume DialogueManager handles UI display without black screen
	# If DialogueManager signal is connected in _ready, we just start it.
	# We need to manually advance steps when dialogue closes?
	# Usually DialogueManager has a 'dialogue_finished' signal.
	
	if DialogueManager:
		# Connect completion signal.
		# Check if already connected (e.g. from previous runs) to avoid duplicates
		if not DialogueManager.dialogue_finished.is_connected(_on_mage_dialogue_done):
			DialogueManager.dialogue_finished.connect(_on_mage_dialogue_done)
			
		DialogueManager.start_dialogue(tr("NPC_COURT_MAGE"), dialogue_lines)

		# Focus camera back to player after dialogue starts? No, keep focus on speaker.
	else:
		# Fallback if no DialogueManager
		print("Tutorial: DialogueManager missing, skipping dialogue.")
		_on_mage_dialogue_done()

func _on_mage_dialogue_done() -> void:
	# Important: Disconnect to prevent triggering this when other dialogues finish later
	if DialogueManager.dialogue_finished.is_connected(_on_mage_dialogue_done):
		DialogueManager.dialogue_finished.disconnect(_on_mage_dialogue_done)

	# Restore Camera to Player
	CinematicDirector.play_sequence([
		{"type": "cam_restore", "duration": 1.0}
	])
	
	# UNLOCK PLAYER INPUT AND MOVEMENT
	if player:
		# Ensure player.gd input_enabled is true so they can open inventory
		EventBus.player_input_enabled.emit(true)
		# But keep movement locked if we want them to stand still?
		# No, let them move. The user complained about movement.
		EventBus.player_movement_locked.emit(false)
	
	_give_starter_items()
	
	current_step = Step.WAIT_INVENTORY
	tracker.show_objective(tr("OBJ_OPEN_INV"))

func _on_inventory_opened() -> void:
	if current_step == Step.WAIT_INVENTORY:
		# 直接更新新目标，不触发 complete 的 3秒淡出逻辑
		current_step = Step.WAIT_EQUIP
		tracker.show_objective(tr("OBJ_EQUIP_WAND"))

func _on_item_equipped(_item) -> void:
	if current_step == Step.WAIT_EQUIP:
		current_step = Step.WAIT_EDITOR
		tracker.show_objective(tr("OBJ_OPEN_EDITOR"))

func _on_editor_opened() -> void:
	if current_step == Step.WAIT_EDITOR:
		current_step = Step.WAIT_LOGIC_TAB
		tracker.show_objective(tr("OBJ_SWITCH_TAB"))

func _on_logic_tab_done() -> void:
	# tracker.complete_objective() # 不需要 complete，直接切换新任务
	current_step = Step.WAIT_FIX_SPELL
	tracker.show_objective(tr("OBJ_CONNECT_NODES"))

func _on_spell_logic_updated(wand_data: Resource) -> void:
	if current_step == Step.WAIT_FIX_SPELL:
		if _is_logic_valid(wand_data):
			# 不要 complete (会变绿然后消失)，而是直接提示下一步：关闭并测试
			tracker.show_objective(tr("OBJ_CLOSE_EDITOR"))

func _on_editor_closed() -> void:
	print("Tutorial: Editor closed. Step: ", current_step)
	
	# Safety check: Ensure input is enabled if we came from editor (which might have locked it)
	if current_step >= Step.WAIT_INVENTORY:
		EventBus.player_input_enabled.emit(true)
		
	if current_step == Step.WAIT_FIX_SPELL or current_step == Step.WAIT_LOGIC_TAB or current_step == Step.WAIT_EDITOR:
		# 修复：教程逻辑检测不仅依赖于刚刚关闭的编辑器，而是检测玩家当前装备的任何合法法杖
		var wand = GameState.inventory.get_equipped_item()
		
		# 如果当前位没有，遍历快捷栏看看有没有合适的法杖
		if not wand or not (wand is WandItem):
			for i in range(GameState.inventory.hotbar_capacity):
				var slot = GameState.inventory.hotbar.get_slot(i)
				if slot.item and slot.item is WandItem:
					wand = slot.item
					# 自动切换到该槽位，方便玩家使用
					GameState.inventory.select_hotbar_slot(i)
					break
		
		var logic_ok = false
		if wand and wand is WandItem:
			logic_ok = _is_logic_valid(wand.wand_data)
			print("Tutorial: Logic check result: ", logic_ok)
			
		if logic_ok:
			current_step = Step.WAIT_TEST_FIRE
			tracker.show_objective(tr("OBJ_TEST_FIRE"))
			print("Tutorial: Logic valid, spawning target...")
			_spawn_target()
		else:
			# 如果用户还没连好就退出了，提醒他重新打开
			tracker.show_objective(tr("OBJ_REOPEN_EDITOR"))
			current_step = Step.WAIT_EDITOR
			print("Tutorial: Logic INVALID, reverting to WAIT_EDITOR")

func _spawn_target() -> void:
	print("Tutorial: _spawn_target() called. WALL_SCENE: ", "Exists" if WALL_SCENE else "NULL")
	if WALL_SCENE:
		# 先移除旧的可能存在的目标，防止重复生成卡死
		for child in get_children():
			if child.is_in_group("tutorial_target"):
				child.queue_free()

		var wall = WALL_SCENE.instantiate()
		wall.add_to_group("tutorial_target")
		
		# 强制设置 z_index 确保可见，并增加显式 add_child
		wall.z_index = 50 
		add_child(wall)
		
		# 关键修正：在 add_child 之后设置 global_position 确保坐标系正确转换
		# 优先使用 TargetMarker 节点，如果没有则在玩家前方生成
		if objective_spawn_marker:
			wall.global_position = objective_spawn_marker.global_position
		else:
			# 确保生成位置在玩家右前方，增加距离防止直接刷在脸上
			var spawn_pos = player.global_position + Vector2(300, -50)
			wall.global_position = spawn_pos
			print("Tutorial: TargetMarker missing, spawning near player at: ", spawn_pos)
			
		print("Tutorial: Target spawned at global: ", wall.global_position)
		
		wall.tree_exited.connect(_on_target_destroyed)
		
		# 震动并指向目标
		CinematicDirector.play_sequence([
			{"type": "cam_shake", "intensity": 5.0, "duration": 0.5},
			{"type": "cam_pan", "target": wall.global_position, "duration": 0.8},
			{"type": "wait", "duration": 1.0},
			{"type": "cam_restore", "duration": 1.0}
		])
	else:
		push_error("Tutorial: WALL_SCENE is missing!")
		# 自动跳过此步骤以防死循环
		_on_target_destroyed()

func _on_target_destroyed() -> void:
	print("Tutorial: Target destroyed! Moving to crash sequence.")
	if current_step == Step.WAIT_TEST_FIRE:
		if is_instance_valid(tracker):
			tracker.complete_objective()
		_start_crash_sequence()

func _start_crash_sequence() -> void:
	current_step = Step.CRASH_SEQUENCE
	_shake_amplitude = 15.0
	
	# 1. Hide the spaceship structure and mage
	if env_controller and env_controller.has_node("ShipTiles"):
		env_controller.get_node("ShipTiles").visible = false
	if env_controller and env_controller.has_node("Structure"):
		env_controller.get_node("Structure").visible = false # Hide colliders too just in case
		env_controller.get_node("Structure").process_mode = Node.PROCESS_MODE_DISABLED
	if env_controller and env_controller.has_node("Props"):
		env_controller.get_node("Props").visible = false
		
	if court_mage:
		court_mage.visible = false # Hide NPC
		
	# 2. Spawn Debris
	if player:
		var debris = DEBRIS_SCENE.instantiate()
		debris.global_position = player.global_position + Vector2(0, -100)
		add_child(debris)
		
		# If debris is a wrapper with particles inside
		if debris.has_node("DebrisEmitter"):
			debris.get_node("DebrisEmitter").emitting = true
		elif debris is CPUParticles2D:
			debris.emitting = true
		
		# 3. Attach Wind Lines to Camera or Player
		var wind = WIND_LINES_SCENE.instantiate()
		if camera:
			camera.add_child(wind)
		else:
			player.add_child(wind)
		
		if wind.has_node("WindEmitter"):
			wind.get_node("WindEmitter").emitting = true
		elif wind is CPUParticles2D:
			wind.emitting = true
			
		# 4. Attach Mage Shield to Player
		var shield = SHIELD_SCENE.instantiate()
		player.add_child(shield)
		
		if shield.has_node("ShieldEmitter"):
			shield.get_node("ShieldEmitter").emitting = true
		elif shield is CPUParticles2D:
			shield.emitting = true
		
		# 5. Enable Physics Fall
		player.process_mode = Node.PROCESS_MODE_INHERIT
		player.velocity = Vector2(0, 100) # Initial push down
		# Ensure movement is locked but physics works
		EventBus.player_movement_locked.emit(true)
		EventBus.player_input_enabled.emit(false)
		
		# Rotate player for fall
		player.rotation_degrees = 180.0 # Head down? Or 90? Let's try constant rotation in process
		
	# Start Fall Timer
	_fall_timer = _fall_duration
	set_process(true)



# --- 辅助方法 ---

func _is_logic_valid(wand_data: Resource) -> bool:
	if not wand_data: return false
	var nodes = wand_data.logic_nodes
	var connections = wand_data.logic_connections
	
	var gen_ids = []
	var proj_ids = []
	
	for n in nodes:
		var n_type = n.get("wand_logic_type")
		if not n_type: n_type = n.get("type")
		
		if n_type == "generator": 
			gen_ids.append(str(n.id))
		elif n_type == "action_projectile" or n_type == "projectile": # loosen check
			proj_ids.append(str(n.id))
			
	if gen_ids.is_empty() or proj_ids.is_empty(): 
		print("Tutorial: Logic check failed - Missing components. Gens: ", gen_ids, " Projs: ", proj_ids)
		return false
	
	for c in connections:
		# Use int/float casting or range checks if necessary, but here we just need to match IDs
		var from_id = str(c.get("from_id", ""))
		var to_id = str(c.get("to_id", ""))
		
		# Allow any generator to connect to any projectile
		if from_id in gen_ids and to_id in proj_ids:
			return true
			
	print("Tutorial: Logic check failed - No valid connection found.")
	return false

func _on_shake_timer() -> void:
	if camera and _shake_amplitude > 0:
		camera.offset = _original_cam_offset + Vector2(
			randf_range(-_shake_amplitude, _shake_amplitude),
			randf_range(-_shake_amplitude, _shake_amplitude)
		)
		# 逐渐衰减震动，除非在 crash_sequence 等步骤中被重置
		if current_step != Step.CRASH_SEQUENCE:
			_shake_amplitude = lerp(_shake_amplitude, 0.0, 0.1)

func _clear_all_items() -> void:
	if GameState.inventory:
		if GameState.inventory.has_method("clear_all"):
			GameState.inventory.clear_all()

func _give_starter_items() -> void:
	if GameState.inventory:
		# 给玩家发基础法杖
		if GameState.inventory.has_method("add_item"):
			# fix: WandSelector requires WandItem (wrapper), not raw WandData
			var wand_item = WandItem.new()
			# Deep copy the resource so modifications in tutorial don't break the asset
			var data = WAND_ITEM_RES.duplicate(true)
			data.id = "starter_wand" # Ensure WandData.id matches the starter_wand
			
			# Ensure it's a "Tutorial" powered wand
			if data.embryo:
				data.embryo = data.embryo.duplicate()
				data.embryo.mana_capacity = 2000.0 # Increase capacity
				data.embryo.mana_recharge_speed = 1000.0 # Extreme regen for tutorial
				data.embryo.recharge_time = 0.1 # Real fast
				data.embryo.cast_delay = 0.05
			data.current_mana = 2000.0
			
			# FORCE logic clear to ensure tutorial starts fresh
			data.logic_nodes = []
			data.logic_connections = []
			
			wand_item.wand_data = data
			wand_item.display_name = "Training Wand"
			wand_item.icon = WAND_ITEM_RES.icon
			wand_item.id = "starter_wand_item" # Wrapper ID
			
			GameState.inventory.add_item(wand_item)
			
			# 自动激活第一个槽位，确保法杖被“装备”
			if GameState.inventory.has_method("select_hotbar_slot"):
				GameState.inventory.select_hotbar_slot(0)
		
		# 解锁必要的逻辑碎片
		if GameState.has_method("unlock_spell"):
			GameState.unlock_spell("generator")
			GameState.unlock_spell("action_projectile")
