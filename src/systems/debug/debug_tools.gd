extends Node

## DebugTools (Autoload)
## 开发者调试工具，用于快速验证繁育于继承系统。

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 自动为开发者生成测试用公主，延迟1秒等待场景加载
	get_tree().create_timer(1.0).timeout.connect(spawn_princess)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed: return
	
	if event.keycode == KEY_F1:
		_debug_force_marry(get_hovered_npc())
	elif event.keycode == KEY_F2:
		_debug_spawn_baby(get_hovered_npc())
	elif event.keycode == KEY_F3: # 催熟 (原F8)
		_debug_grow_child(get_hovered_npc())
	elif event.keycode == KEY_F4: # 自杀 (原F7)
		_debug_kill_player()
	elif event.keycode == KEY_F12: # 公主 (原F9)
		spawn_princess()

func get_hovered_npc() -> Node:
	# Raycast from mouse
	var _mouse_pos = get_viewport().get_mouse_position()
	# Only works if camera logic converts properly. Assuming 2D.
	# We need world position.
	var _canvas_item = get_viewport().canvas_transform
	# Simple overlap check at mouse position in world
	var world_pos = GameState.get_tree().root.get_mouse_position() # This might be screen pos
	# Better: use the current camera to project?
	# In 2D, get_global_mouse_position() on a stored node is easier.
	if not GameState.player_data: return null
	var player = get_tree().get_first_node_in_group("player")
	if not player: return null
	
	world_pos = player.get_global_mouse_position()
	
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space_state.intersect_point(query)
	for res in result:
		var collider = res.collider
		if collider.is_in_group("npc") or collider is CharacterBody2D: # Assuming NPC class
			# Check if it has npc_data
			if "npc_data" in collider:
				return collider
				
	return null

func _debug_force_marry(target: Node) -> void:
	if not target: 
		print("Debug: No target under mouse for Marriage.")
		return
	
	var n_data = target.npc_data
	var p_data = GameState.player_data
	
	# Skip checks
	p_data.spouse_id = n_data.uuid
	n_data.spouse_id = p_data.uuid
	SocialManager.marriage_occurred.emit(p_data, n_data)
	print("Debug: Forced Marriage with ", n_data.display_name)

func _debug_spawn_baby(target: Node) -> void:
	if not target or not "npc_data" in target:
		print("Debug: No NPC target for Baby.")
		return
		
	var n_data = target.npc_data
	var p_data = GameState.player_data
	
	print("Debug: Forcing Baby Spawn from ", n_data.display_name)
	
	# 手动触发生成，绕过繁育冷却
	var child_data = LineageManager._generate_offspring_data(n_data, p_data)
	LineageManager._spawn_baby(child_data, target.global_position + Vector2(20, 20))
	print("Debug: Forced Baby Spawned.")

func _debug_grow_child(target: Node) -> void:
	if not target or not "npc_data" in target:
		print("Debug: No valid NPC target for growth.")
		return
	
	var data = target.npc_data
	# 直接催熟到成年，节省玩家调试时间
	data.growth_stage = 2
	print("Debug: NPC ", data.display_name, " forced to Adult (Stage 2)")
	
	if UIManager:
		UIManager.show_floating_text("Mature!", target.global_position, Color.GOLD)
		
	# 关键：同步视觉缩放
	if target.has_method("update_growth_visual"):
		target.update_growth_visual()

func _debug_kill_player() -> void:
	if GameState.player_data:
		LifespanManager.consume_lifespan(GameState.player_data, 9999.0)
		print("Debug: Player Killed.")

func spawn_princess() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		# If player not ready, try again in 1s
		await get_tree().create_timer(1.0).timeout
		player = get_tree().get_first_node_in_group("player")
		if not player: return
		
	var princess_scene = load("res://scenes/npc/princess.tscn")
	if not princess_scene:
		print("Debug Error: Princess scene not found at res://scenes/npc/princess.tscn")
		return
		
	var princess = princess_scene.instantiate()
	# Position near player
	princess.global_position = player.global_position + Vector2(64, 0)
	
	# 加入场景树
	player.get_parent().add_child(princess)
	
	# 显式初始化 NPC 数据状态，确保她是成年状态
	if princess.npc_data:
		princess.npc_data.growth_stage = 2
		if princess.has_method("update_growth_visual"):
			princess.update_growth_visual()
			
	print("Debug: Princess spawned near player at ", princess.global_position)
