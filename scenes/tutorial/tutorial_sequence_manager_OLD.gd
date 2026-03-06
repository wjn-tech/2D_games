extends Node2D

@onready var fade_rect = $FadeOverlay/FadeRect
@onready var shake_timer = $ShakeTimer
@onready var court_mage = $CourtMage
@onready var env_controller = $EnvironmentController

# Node references
var player: CharacterBody2D
var camera: Camera2D

# State
var _shake_amplitude: float = 0.0
var _original_cam_offset: Vector2 = Vector2.ZERO
var _wait_condition: String = ""
var _movement_locked: bool = false
var _has_crash_started: bool = false
var _movement_start_pos: Vector2 = Vector2.ZERO

# Dialogue Content
var dialogue_lines = [
	"State: CRITICAL. Hull Integrity: 12%. Life Support: FAILING.",
	"Wake up! We are going down!",
	"<emit:rumble_mild> The Mana Drive is unstable. Come here, quickly!",
	"<emit:wait_move> Good, you're not concussed.",
	"Take this. It's a standard issue Caster, but it's wiped clean.",
	"<emit:give_items> I also saved these Logic Shards from the debris.",
	"You need to reprogram the wand before we crash. Open your inventory. <emit:wait_inventory>",
	"It's in your backpack. Drag it to your hotbar and equip it! <emit:highlight:inventory_slot> <emit:wait_equip>",
	"Now, open the Logic Interface (Press K). <emit:wait_editor>",
	"We need to access the Core Logic. Switch to the Logic Tab. <emit:highlight:logic_tab> <emit:wait_logic_tab>",
	"The grid is empty. Magic is dead without logic.",
	"Drag the ENERGY SOURCE component (Green) into the grid. <emit:highlight:generator> <emit:wait_generator>",
	"And the PROJECTILE component (Red). <emit:highlight:action_projectile> <emit:wait_projectile>",
	"Connect them: ENERGY -> PROJECTILE. Use the ports. <emit:highlight:connect> <emit:wait_program>",
	"That's it! The circuit is complete. Close the editor (ESC or K) and test it!",
	"Blast that loose panel! We need to get to the escape pods!",
	"<emit:spawn_target> <emit:wait_shoot>",
	"<emit:crash_start> TOO LATE! BRACE FOR IMPACT!"
]

# Assets
const OverlayManagerScene = preload("res://scenes/ui/tutorial/OverlayManager.tscn")
const ArrowScene = preload("res://scenes/ui/tutorial_arrow.tscn")
const WallScene = preload("res://scenes/tutorial/breakable_wall.tscn")

enum Phase {
	NONE,
	MOVEMENT,
	INVENTORY,
	EQUIP,
	EDITOR,
	LOGIC_TAB,
	GENERATOR,
	PROJECTILE,
	PROGRAM,
	COMBAT,
	COMPLETE
}

var current_phase: Phase = Phase.NONE
var overlay_manager: OverlayManager
var arrow_instance: Control
var wall_instance: Node2D

func _ready() -> void:
	add_to_group("tutorial_manager") # 重要：让其他组件能找到教程管理器并隐藏提示
	
	# 1. Check if we should run tutorial
	if not GameManager.is_new_game:
		# print("Tutorial: Not a new game, skipping.")
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		queue_free()
		return		
	# Ensure tutorial logic runs even when WandEditor pauses the game
	process_mode = Node.PROCESS_MODE_ALWAYS	
	print("Tutorial: Starting new game sequence.")
	visible = true
	
	# 2. Wait for Main scene to initialize entities
	await get_tree().process_frame
	
	# Clear inventory for tutorial start
	_clear_all_items()
	
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("Tutorial: Player not found via group 'player'. Aborting.")
		queue_free()
		return

	# Force fade-in since GameManager leaves it black for us
	if UIManager:
		UIManager.play_fade(false, 2.0)

	# 3. Setup Camera
	camera = get_viewport().get_camera_2d()
	if not camera:
		if "camera" in player and player.camera:
			camera = player.camera
		else:
			# If no camera exists yet, wait another frame or look deeper
			await get_tree().process_frame
			camera = get_viewport().get_camera_2d()
	
	if camera:
		_original_cam_offset = camera.offset
	
	# 4. Teleport Player to Ship
	self.global_position = Vector2(0, -50000)
	player.global_position = self.global_position + Vector2(-100, 0)
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	player.set_process(true)
	
	# 5. Lock Player Input (Partial)
	# Allow UI interaction and movement, but script handles logic flow
	if EventBus:
		EventBus.player_movement_locked.emit(false) 
		EventBus.player_input_enabled.emit(true)
	
	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.set_physics_process(true)
	
	# 6. Start Sequence
	# Cinematic Intro
	_shake_amplitude = 3.0
	if env_controller:
		env_controller.set_alert_level(ShipEnvironmentController.AlertLevel.RED)

	if shake_timer:
		if not shake_timer.timeout.is_connected(_on_shake_timer):
			shake_timer.timeout.connect(_on_shake_timer)
		shake_timer.start(0.05)
		
	# Connect Signals
	_connect_signals()
	
	# Spawn UI Elements
	_setup_ui_overlays()
	
	# Start Dialogue
	call_deferred("_start_opening_dialogue")

func _setup_ui_overlays() -> void:
	# Clean up previous instance if any
	if overlay_manager:
		overlay_manager.queue_free()
		
	overlay_manager = OverlayManagerScene.instantiate()
	overlay_manager.name = "OverlayManager"
	add_child(overlay_manager)
		
	arrow_instance = ArrowScene.instantiate()
	arrow_instance.visible = false
	# Add arrow to the overlay manager (which handles the canvas layer)
	overlay_manager.add_child(arrow_instance)

func _connect_signals() -> void:
	if DialogueManager:
		if not DialogueManager.dialogue_event.is_connected(_on_dialogue_event):
			DialogueManager.dialogue_event.connect(_on_dialogue_event)

	# EventBus Hooks
	EventBus.inventory_opened.connect(func(): _check_step("inventory"))
	EventBus.item_equipped.connect(func(_item): _check_step("equip"))
	EventBus.wand_editor_opened.connect(func(): 
		_check_step("editor")
		if env_controller: env_controller.set_focus_mode(true)
		# Defer clearing to ensure WandEditor has fully loaded the wand data (which happens after signal emission)
		if current_phase == Phase.EDITOR or current_phase == Phase.LOGIC_TAB or current_phase == Phase.PROGRAM:
			get_tree().create_timer(0.1).timeout.connect(_force_clear_wand_logic)
	)
	EventBus.wand_editor_closed.connect(func():
		if env_controller: env_controller.set_focus_mode(false)
	)
	
	if not EventBus.item_crafted.is_connected(_on_item_crafted):
		EventBus.item_crafted.connect(_on_item_crafted)

func _on_item_crafted(_item):
	_check_step("craft")

func _force_clear_wand_logic() -> void:
	if UIManager.active_windows.has("WandEditor"):
		var we = UIManager.active_windows["WandEditor"]
		
		# Force click the logic button if we are in logic tab phase
		var logic_btn = we.find_child("LogicModeButton", true, false)
		if logic_btn and not logic_btn.button_pressed:
			logic_btn.set_pressed(true)

		if we.current_wand:
			# Only clear if we haven't already successfully programmed it
			if current_phase == Phase.PROGRAM and _wait_condition != "program":
				return 
				
			we.current_wand.logic_nodes.clear()
			we.current_wand.logic_connections.clear()
			if we.logic_board:
				we.logic_board.set_data(we.current_wand)
			# Find and select logic mode button if not selected
			var btn = we.find_child("LogicModeButton", true, false)
			if btn and not btn.button_pressed:
				btn.set_pressed(true) # Force switch to logic mode

			print("Tutorial: Wand logic cleared.")
	
	if not EventBus.spell_logic_updated.is_connected(_on_spell_logic_updated):
		EventBus.spell_logic_updated.connect(_on_spell_logic_updated)

func _on_spell_logic_updated(wand_data: Resource) -> void:
	if _wait_condition != "program" and _wait_condition != "generator" and _wait_condition != "projectile":
		return
		
	# Check for valid connection (Generator -> Projectile)
	var has_connection = false
	var has_generator = false
	var has_projectile = false
	
	var nodes = wand_data.logic_nodes
	var connections = wand_data.logic_connections
	
	# 1. Identify Node IDs
	var generator_ids = []
	var projectile_ids = []
	
	for node in nodes:
		var type = node.get("type", "")
		if type == "generator": 
			generator_ids.append(node["id"])
			has_generator = true
		elif type == "action_projectile":
			projectile_ids.append(node["id"])
			has_projectile = true
			
	if _wait_condition == "generator" and has_generator:
		_check_step("generator", false)
		return
		
	if _wait_condition == "projectile" and has_projectile:
		_check_step("projectile", false)
		return
			
	# 2. Check Connections
	for conn in connections:
		# WandData connections use from_id/to_id strings
		if conn["from_id"] in generator_ids and conn["to_id"] in projectile_ids:
			has_connection = true
			break
			
	if _wait_condition == "program" and has_connection:
		_check_step("program", false)
		if UIManager:
			UIManager.show_notification("Tutorial: Program Success!")
		if overlay_manager:
			overlay_manager.clear_ghost()
			overlay_manager.clear_highlight()

func _start_opening_dialogue() -> void:
	await get_tree().create_timer(1.0).timeout
	DialogueManager.dialogue_event.emit("rumble_mild") # Ensure start state
	DialogueManager.start_dialogue("Court Mage", dialogue_lines)

func _process(delta: float) -> void:
	if _wait_condition == "move":
		# 强制每一帧确保玩家有控制权，防止被其他系统（如过场动画残留）覆盖
		if player:
			player.set("movement_locked", false)
			player.set("input_enabled", true)
			
		if player and player.global_position.distance_to(_movement_start_pos) > 50.0:
			_check_step("move")

	if _wait_condition == "logic_tab":
		if UIManager.active_windows.has("WandEditor"):
			var we = UIManager.active_windows["WandEditor"]
			
			# Aggressively clear wand logic during logic_tab wait to ensure clean slate for next step
			if we.current_wand:
				if we.current_wand.logic_nodes.size() > 0 or we.current_wand.logic_connections.size() > 0:
					we.current_wand.logic_nodes.clear()
					we.current_wand.logic_connections.clear()
					if we.logic_board:
						we.logic_board.set_data(we.current_wand)
					print("Tutorial: Aggressively cleared wand logic.")

			if we.get("logic_board") and we.logic_board.visible:
				_check_step("logic_tab")

func _on_shake_timer() -> void:
	if not camera or _shake_amplitude <= 0:
		return
		
	var offset = Vector2(
		randf_range(-_shake_amplitude, _shake_amplitude),
		randf_range(-_shake_amplitude, _shake_amplitude)
	)
	camera.offset = _original_cam_offset + offset

func _handle_highlight_event(target_raw: String) -> void:
	if not overlay_manager: return
	
	# Clear previous ghosts/highlights when a new one starts
	overlay_manager.clear_ghost()
	overlay_manager.clear_highlight()
	
	var control: Control = null
	var msg = ""
	var ghost_start = Vector2.ZERO
	var ghost_end = Vector2.ZERO
	var should_drag = false
	
	match target_raw:
		"inventory_slot_1", "inventory_slot", "inventory_slot_0":
			msg = "Drag Wand to Hotbar"
			if UIManager.active_windows.has("InventoryWindow"):
				var inv = UIManager.active_windows["InventoryWindow"]
				# Assumes InventoryUI has grid_container with children
				if inv.grid_container and inv.grid_container.get_child_count() > 0:
					control = inv.grid_container.get_child(0)
					
					if control:
						ghost_start = control.global_position + control.size / 2
						
						# Find Hotbar Slot 1 (in HUD)
						var hud = get_tree().get_first_node_in_group("hud")
						if hud:
							var hb = hud.find_child("HotbarWidget", true, false)
							if hb and hb.has_method("get_slot_global_position"):
								ghost_end = hb.get_slot_global_position(0)
								should_drag = true
							# Legacy fallback
							elif hud.find_child("Hotbar", true, false):
								var legacy_hb = hud.find_child("Hotbar", true, false)
								if legacy_hb and legacy_hb.get_child_count() > 0:
									var slot = legacy_hb.get_child(0)
									ghost_end = slot.global_position + slot.size / 2
									should_drag = true
		
		"logic_tab":
			msg = "Click Logic Mode"
			if UIManager.active_windows.has("WandEditor"):
				var we = UIManager.active_windows["WandEditor"]
				var btn = we.find_child("LogicModeButton", true, false)
				if btn:
					control = btn

		"trigger", "generator":
			msg = "Drag Energy Source"
			if UIManager.active_windows.has("WandEditor"):
				var we = UIManager.active_windows["WandEditor"]
				# Try to find by item_id
				if we.has_method("get_palette_button_by_item_id"):
					control = we.get_palette_button_by_item_id("generator")
					if not control: control = we.get_palette_button_by_item_id("trigger")
				elif we.find_child("PaletteGrid", true, false):
					var palette = we.find_child("PaletteGrid", true, false)
					for btn in palette.get_children():
						var id = btn.get_meta("item_id") if btn.has_meta("item_id") else ""
						if id == "generator" or id == "trigger":
							control = btn
							break
				
				if control:
					ghost_start = control.global_position + control.size / 2
					if we.has_method("get_grid_cell_global_position"):
						ghost_end = we.get_grid_cell_global_position(1, 1) # Grid(1,1)
						should_drag = true
						
		"action_projectile":
			msg = "Drag Projectile"
			if UIManager.active_windows.has("WandEditor"):
				var we = UIManager.active_windows["WandEditor"]
				if we.has_method("get_palette_button_by_item_id"):
					control = we.get_palette_button_by_item_id("action_projectile")
				elif we.find_child("PaletteGrid", true, false):
					var palette = we.find_child("PaletteGrid", true, false)
					for btn in palette.get_children():
						if btn.has_meta("item_id") and btn.get_meta("item_id") == "action_projectile":
							control = btn
							break
							
				if control:
					ghost_start = control.global_position + control.size / 2
					if we.has_method("get_grid_cell_global_position"):
						ghost_end = we.get_grid_cell_global_position(3, 1) # Grid(3,1)
						should_drag = true
		"connect":
			msg = "Connect Nodes"
			if UIManager.active_windows.has("WandEditor"):
				var we = UIManager.active_windows["WandEditor"]
				var generator = we.get_logic_node_by_type("generator")
				# Fallback if old name
				if not generator: generator = we.get_logic_node_by_type("trigger")
				
				var projectile = we.get_logic_node_by_type("action_projectile")
				
				if generator and projectile:
					# Assuming port 0 for both
					# Warning: If get_output_port_position is not available or differs, this might be offset.
					# But typically nodes have these methods.
					ghost_start = generator.global_position + generator.get_output_port_position(0)
					ghost_end = projectile.global_position + projectile.get_input_port_position(0)
					
					if overlay_manager:
						overlay_manager.show_ghost_connect(ghost_start, ghost_end)

	if control:
		overlay_manager.highlight_element(control, msg)
		if should_drag:
			overlay_manager.show_ghost_drag(ghost_start, ghost_end)

func start_phase(new_phase: Phase):
	current_phase = new_phase
	
	if overlay_manager:
		overlay_manager.clear_prompts()
		overlay_manager.clear_ghost()
		overlay_manager.clear_highlight()
	
	match new_phase:
		Phase.MOVEMENT:
			if overlay_manager:
				overlay_manager.show_input_prompt(["up", "left", "down", "right"])
			EventBus.player_movement_locked.emit(false)
			if player: _movement_start_pos = player.global_position
			_start_wait("move")
			
		Phase.INVENTORY:
			if overlay_manager:
				overlay_manager.show_input_prompt(["inventory"])
			EventBus.player_movement_locked.emit(true)
			_start_wait("inventory")
			
		Phase.EQUIP:
			# Highlight and Ghost handled by highlight events
			_check_step("inventory")
			_start_wait("equip")
			
		Phase.EDITOR:
			_check_step("equip")
			if overlay_manager:
				# Use custom key K since wand_editor action is not in InputMap
				if overlay_manager.has_method("show_custom_key_prompt"):
					overlay_manager.show_custom_key_prompt("K", "Knowledge")
				else:
					overlay_manager.show_input_prompt(["wand_editor"]) 
			_start_wait("editor")

		Phase.LOGIC_TAB:
			_check_step("editor")
			_start_wait("logic_tab")

		Phase.GENERATOR:
			_check_step("logic_tab")
			_start_wait("generator")
			
		Phase.PROJECTILE:
			_check_step("generator")
			_start_wait("projectile")

		Phase.PROGRAM:
			_check_step("projectile")
			_start_wait("program")
			# Use strict validation instead of loose connection count
			_force_check_program_logic()

		Phase.COMBAT:
			EventBus.player_movement_locked.emit(false)
			if overlay_manager:
				overlay_manager.show_input_prompt(["attack"])
			_start_wait("shoot")
			_spawn_wall_target() # Ensure legacy spawn works or move here

func _on_dialogue_event(event_name: String) -> void:
	if event_name.begins_with("highlight:"):
		_handle_highlight_event(event_name.trim_prefix("highlight:"))
		return

	match event_name:
		"rumble_mild":
			_shake_amplitude = 2.0
			if env_controller: env_controller.set_alert_level(ShipEnvironmentController.AlertLevel.YELLOW)
		"give_items":
			_give_starter_items()
			if env_controller: env_controller.set_alert_level(ShipEnvironmentController.AlertLevel.RED)
		
		"wait_move":
			start_phase(Phase.MOVEMENT)
			
		"wait_inventory":
			start_phase(Phase.INVENTORY)
			
		"wait_equip":
			start_phase(Phase.EQUIP)
			
		"wait_editor":
			start_phase(Phase.EDITOR)
			
		"wait_logic_tab":
			start_phase(Phase.LOGIC_TAB)
		
		"wait_trigger":
			start_phase(Phase.GENERATOR)
			
		"wait_generator":
			start_phase(Phase.GENERATOR)
			
		"wait_projectile":
			start_phase(Phase.PROJECTILE)	
			
		"wait_program":
			start_phase(Phase.PROGRAM)
			
		"wait_craft":
			_start_wait("craft")
			
		"spawn_target":
			# Handled in Phase.COMBAT primarily, but keep if dialogue calls it separately
			pass 
			
		"wait_shoot":
			start_phase(Phase.COMBAT)
			
		"crash_start":
			_start_crash_sequence()
			if env_controller: env_controller.set_alert_level(ShipEnvironmentController.AlertLevel.BREACH)

func _start_wait(condition: String) -> void:
	_wait_condition = condition
	# Pause Dialogue System
	DialogueManager.pause_dialogue()
	print("Tutorial: Waiting for %s..." % condition)

func _check_step(condition: String, advance_line: bool = true) -> void:
	if _wait_condition == condition:
		print("Tutorial: Step completed (%s)" % condition)
		_wait_condition = ""
		
		if UIManager.has_method("clear_highlight"):
			UIManager.clear_highlight()
		
		if arrow_instance: arrow_instance.visible = false
		
		# Auto-advance Dialogue to prevent stall
		DialogueManager.resume_dialogue()
		if advance_line:
			DialogueManager.next_line()

func _show_arrow(screen_pos: Vector2) -> void:
	if arrow_instance:
		arrow_instance.position = screen_pos # Global screen pos for CanvasLayer
		arrow_instance.visible = true

func _show_arrow_at_control(target: Control, msg: String = "") -> void:
	if not arrow_instance or not target: return
	
	# Wait for a frame to ensure UI layout is updated and global_rect is correct
	await get_tree().process_frame
	
	# IMPROVED: Check if target is a vertical or horizontal container
	# If it's a hotbar, we want to point to the FIRST slot, not the container center
	var pointer_target = target
	if target.get_child_count() > 0:
		pointer_target = target.get_child(0)

	var rect = pointer_target.get_global_rect()
	# The Hotbar is at the bottom. Point to it from above.
	# arrow_instance is in a CanvasLayer (100), its position is local to that layer (screen coords)
	arrow_instance.global_position = Vector2(rect.position.x + rect.size.x / 2, rect.position.y - 20)
	arrow_instance.visible = true
	if "text" in arrow_instance:
		arrow_instance.set("text", msg)
	elif arrow_instance.has_node("Label"):
		arrow_instance.get_node("Label").text = msg

func _clear_all_items() -> void:
	if not GameState.inventory: return
	
	# We access the internal inventories directly if possible, or use clear_slot
	var backpack = GameState.inventory.backpack
	var hotbar = GameState.inventory.hotbar
	
	if backpack:
		for i in range(backpack.capacity):
			backpack.clear_slot(i)
	
	if hotbar:
		for i in range(hotbar.capacity):
			hotbar.clear_slot(i)

func _give_starter_items() -> void:
	if not GameState.inventory: return
	
	# Add items
	var wand_data = load("res://scenes/test_wand.tres")
	
	if wand_data:
		# Create WandItem wrapper for inventory
		var wand_item = WandItem.new()
		wand_item.wand_data = wand_data
		wand_item.id = wand_data.id
		wand_item.display_name = wand_data.display_name
		
		# FIX: Ensure wand has an icon so it is visible in UI
		if wand_data.icon:
			wand_item.icon = wand_data.icon
		elif ResourceLoader.exists("res://assets/ui/icons/icon_node.svg"):
			wand_item.icon = load("res://assets/ui/icons/icon_node.svg")
		else:
			wand_item.icon = load("res://icon.svg")
			
		# Force add to Backpack Slot 0 (for tutorial drag interaction)
		if GameState.inventory and GameState.inventory.backpack:
			GameState.inventory.backpack.set_item(0, wand_item, 1)
			
	# Unlock Logic Shards for the tutorial
	if GameState.has_method("unlock_spell"):
		print("Tutorial: Unlocking logic shards...")
		# Ensure base components are unlocked
		GameState.unlock_spell("generator")
		GameState.unlock_spell("trigger_cast") # In case needed
		GameState.unlock_spell("action_projectile")

func _start_crash_sequence() -> void:
	if _has_crash_started: return
	_has_crash_started = true
	
	DialogueManager.end_dialogue()
	
	# 1. Ramp up shake
	_shake_amplitude = 20.0
	
	# 2. Fade to black (or white)
	var tween = create_tween()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.visible = true
	tween.tween_property(fade_rect, "color:a", 1.0, 2.0)
	
	await tween.finished
	
	# 3. Teleport and Clean up
	_finish_tutorial()

func _finish_tutorial() -> void:
	print("Tutorial: Finishing and transitioning to World.")
	
	# Reset Player
	player.global_position = Vector2(0, -50) # World Spawn
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	
	# Disable Tutorial Locks
	EventBus.player_movement_locked.emit(false)
	EventBus.player_input_enabled.emit(true)
	
	# Reset Camera
	if camera:
		camera.offset = _original_cam_offset
		# 确保相机回到跟随玩家
		if player.has_node("Camera2D"):
			var player_cam = player.get_node("Camera2D")
			if player_cam:
				player_cam.make_current()
	
	# Mark as not new game (session persistence)
	GameManager.is_new_game = false
	
	# Fade In (Tutorial UI)
	var tween = create_tween()
	# 确保淡入完成前全黑
	fade_rect.color = Color(0, 0, 0, 1) 
	tween.tween_property(fade_rect, "color:a", 0.0, 1.0)
	
	# 同时通知 UIManager 清除可能存在的遮罩
	if UIManager:
		UIManager.play_fade(false, 1.0)
	
	await tween.finished
	
	# Cleanup Tutorial
	print("Tutorial: Cleanup complete. Welcome to the world.")
	queue_free()

func _force_check_program_logic() -> void:
	if not UIManager.active_windows.has("WandEditor"): return
	var we = UIManager.active_windows["WandEditor"]
	if we.current_wand:
		_on_spell_logic_updated(we.current_wand)

func _spawn_wall_target() -> void:
	if wall_instance: return
	
	wall_instance = WallScene.instantiate()
	add_child(wall_instance)
	wall_instance.global_position = self.global_position + Vector2(250, 0)
	
	if wall_instance.has_signal("wall_broken"):
		wall_instance.wall_broken.connect(func(): _check_step("shoot"))
