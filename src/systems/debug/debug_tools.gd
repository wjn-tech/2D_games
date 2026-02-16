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
	elif event.keycode == KEY_F5: # 全解锁 (新增)
		_debug_unlock_everything()
	elif event.keycode == KEY_F10: # 测试法杖 (新增)
		_debug_give_god_wand()
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

func _debug_give_god_wand():
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	# Give the wand
	var item = WandItem.new()
	item.id = "god_wand"
	item.display_name = "至高测试法杖"
	item.icon = preload("res://icon.svg")
	
	var data = WandData.new()
	var embryo = WandEmbryo.new()
	embryo.level = 99
	embryo.logic_capacity = 999
	embryo.mana_capacity = 99999
	embryo.recharge_time = 0.05
	data.embryo = embryo
	
	item.wand_data = data
	if player.has_method("get_inventory"):
		player.get_inventory().add_item(item)
	elif "inventory" in player:
		player.inventory.add_item(item)
	
	# Unlock all components in GameState
	if GameState:
		var ids = [
			"generator", "trigger_cast", "trigger_collision", "trigger_timer",
			"element_fire", "element_ice", "modifier_damage", 
			"modifier_pierce", "modifier_speed", "modifier_delay",
			"logic_splitter", "logic_sequence", "action_projectile",
			"projectile_slime", "projectile_tnt", "projectile_blackhole", "projectile_teleport",
			"projectile_spark_bolt", "projectile_magic_bolt", "projectile_bouncing_burst",
			"projectile_tri_bolt", "projectile_chainsaw", "modifier_damage_plus",
			"modifier_add_mana", "modifier_element_slime", "modifier_speed_plus"
		]
		for id in ids:
			if id not in GameState.unlocked_spells:
				GameState.unlocked_spells.append(id)
	
	print("Debug: Gave God Wand and unlocked all spells.")

func _debug_kill_player() -> void:
	if GameState.player_data:
		LifespanManager.consume_lifespan(GameState.player_data, 9999.0)
		print("Debug: Player Killed.")

func _debug_unlock_everything() -> void:
	print("Debug: Unlocking EVERYTHING...")
	
	# 1. 获得所有物品
	var player = get_tree().get_first_node_in_group("player")
	if player and player.inventory:
		for item_id in GameState.item_db:
			var item = GameState.item_db[item_id]
			if item:
				player.inventory.add_item(item, 100)
		print("Debug: Added 100 of all items to inventory.")
	
	# 2. 解锁所有法术
	var all_spells = [
		"generator", 
		"trigger_cast", "trigger_collision", "trigger_timer",
		"action_projectile", 
		"projectile_slime", "projectile_tnt", "projectile_blackhole", "projectile_teleport",
		"projectile_spark_bolt", "projectile_magic_bolt", "projectile_bouncing_burst",
		"projectile_tri_bolt", "projectile_chainsaw",
		"modifier_damage", "modifier_damage_plus", "modifier_pierce", 
		"modifier_speed", "modifier_speed_plus", "modifier_delay", "modifier_add_mana",
		"modifier_element_fire", "modifier_element_ice", "modifier_element_slime",
		"element_fire", "element_ice", 
		"logic_splitter", "logic_sequence"
	]
	
	for s in all_spells:
		GameState.unlock_spell(s)
	
	UIManager.show_floating_text("DEV MODE: UNLOCKED ALL", player.global_position, Color.MAGENTA)

func build_instant_house(pos: Vector2):
	var tile_map = get_tree().get_first_node_in_group("world_tiles")
	if not tile_map: return
	
	var ts = 16
	var origin = tile_map.local_to_map(tile_map.to_local(pos))
	origin.y -= 1 # Move up slightly
	
	var sid = 0 # Default Source ID
	
	# Layout: 10 wide, 6 high
	for x in range(10):
		for y in range(6):
			var p = origin + Vector2i(x, -y)
			
			# Background
			var bg_map = tile_map
			if has_node("/root/LayerManager"):
				bg_map = get_node("/root/LayerManager").layer_nodes.get(1, tile_map)
			if bg_map:
				# Use dirt wall or wood wall? atlas(0,1)
				bg_map.set_cell(p, sid, Vector2i(0, 1))

			# Foreground Frame
			if x == 0 or x == 9 or y == 0 or y == 5:
				tile_map.set_cell(p, sid, Vector2i(2, 0)) # Stone block (Collision!)
			else:
				# Ensure interior is empty
				tile_map.set_cell(p, -1)
	
	# Housing Update Notification
	var sm = get_node_or_null("/root/SettlementManager")
	if sm:
		sm.mark_housing_dirty(pos)
		print("Debug: House built and SettlementManager notified.")

	# Furniture
	var items = [
		# path, tile_grid_offset (x from left, y from bottom)
		["res://scenes/world/buildings/door.tscn", Vector2(1, 0)],
		["res://scenes/world/buildings/chair.tscn", Vector2(3, 0)],
		["res://scenes/world/buildings/table.tscn", Vector2(5, 0)],
		["res://scenes/world/buildings/torch.tscn", Vector2(5, 3)] 
	]
	
	var parent = get_tree().get_first_node_in_group("buildings_container")
	if not parent: parent = tile_map
	
	for it in items:
		var scn = load(it[0])
		if scn:
			var node = scn.instantiate()
			parent.add_child(node)
			# Map pos of that slot
			var slot_p = origin + Vector2i(it[1].x, -it[1].y)
			var snapped_local = tile_map.map_to_local(slot_p)
			var snapped_global = tile_map.to_global(snapped_local)
			
			# UNIFIED TILE ALIGNMENT (Matching BuildingManager)
			var tile_top_left = snapped_global - Vector2(ts/2.0, ts/2.0)
			
			var gs = Vector2i(1, 1)
			if "grid_size" in node: gs = node.grid_size
			elif "door" in it[0]: gs = Vector2i(1, 2)
			
			var bottom_y = tile_top_left.y + ts
			var top_y = bottom_y - (gs.y * ts)
			
			node.global_position = Vector2(tile_top_left.x, top_y)
			
			# Embedding fix is handled by BuildingManager but here we spawn raw.

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
