extends CharacterBody2D

# 物理参数将由 AttributeComponent 动态调整
var SPEED: float = 200.0
var JUMP_VELOCITY: float = -600.0
var GRAVITY: float = 2000.0

# 重力乘数，用于实现更自然的“渐变”跳跃
const GRAVITY_HOLD_MULTIPLIER = 0.6
const GRAVITY_RELEASE_MULTIPLIER = 2.2
const GRAVITY_FALL_MULTIPLIER = 1.8

# 跳跃过渡参数
# 将跳跃冲力分摊到更长时间以获得更慢、更可控的起跳感
const JUMP_RAMP_TIME = 0.15	# 缩短渐变时间，适应下调后的跳跃力
const COYOTE_TIME = 0.08	# 容错步距，允许在离地短时间内仍能跳跃
const JUMP_BUFFER_TIME = 0.12	# 按键缓冲短时间

var jump_ramp_timer: float = 0.0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var fall_time: float = 0.0

# 空气阻力（二次阻力系数），可调。该值较小以匹配当前速度数量级。
const AIR_DRAG_COEFF = 0.000001

# 下落重力随时间增长速率（每秒增加的乘数量）
const FALL_GRAVITY_GROWTH = 0.9
const STEP_HEIGHT = 18.0 # 自动上台阶的高度（略大于一个图块高度）

@export var interaction_area: Area2D

const WandRendererScene = preload("res://src/systems/magic/wand_renderer.tscn")

var current_wand: WandData
var weapon_pivot: Marker2D
var wand_sprite: Sprite2D
var projectile_spawn_point: Marker2D
var knockback_velocity: Vector2 = Vector2.ZERO

var attributes: AttributeComponent
var camera: Camera2D
var input_enabled: bool = true

# Inventory
var inventory: InventoryManager
# UI References
var backpack_ui: Control
var hotbar_ui: Control

# 缓存的基础数值
var BASE_SPEED = 200.0
var BASE_JUMP = -600.0

@onready var min_visual = $MinimalistEntity

const GameCameraScript = preload("res://src/core/game_camera.gd")

func _ready() -> void:
	add_to_group("player")
	add_to_group("damageable") # Tag as damageable
	
	# Setup Inventory
	inventory = InventoryManager.new()
	inventory.name = "InventoryManager"
	inventory.add_to_group("inventory_manager")
	add_child(inventory)
	inventory.equipped_item_changed.connect(_on_equipped_item_changed)
	
	# setup inventory ui
	_setup_inventory_ui()
	
	# --- Wand System Init ---
	_setup_test_wand()
	
	# Weapon Attachment Setup (Wand Decoration System)
	weapon_pivot = Marker2D.new()
	weapon_pivot.name = "WeaponPivot"
	add_child(weapon_pivot)
	
	wand_sprite = Sprite2D.new()
	wand_sprite.name = "WandVisual"
	# Offset logic for 16x48 Wand:
	# Texture is 16px wide, 48px tall.
	# We assume the user draws it vertically.
	# We want the "Handle" area (bottom center) to be at the pivot.
	# Pivot (0,0) is player center.
	# Sprite rotation 0 points RIGHT.
	# To make a vertical drawing point RIGHT, we rotate -90 degrees.
	# But wait, Godot Right is X+. If we hold a staff, it usually points parallel to arm.
	# Let's align the bottom-center of the texture to (0,0).
	# Texture size (16, 48). Center (8, 24).
	# Bottom center is (8, 48).
	# If we set offset to (0, -24) (centering y), then rotate...
	# Let's simplify: Standard weapon sprite logic -> Texture points RIGHT.
	# But user interface is Vertical (16x48).
	# So we rotate the sprite internally by -90 degrees so Top of Grid is Right of Player.
	# OR
	# We just rotate the sprite node -90 deg.
	# Let's stick to: Visual drawn vertically (Up is top distally).
	# So in game, "Up" on grid = "Forward" away from player.
	# "Down" on grid (Handle) = At player hand.
	# Center of texture X is 8. Bottom Y is 48.
	# We want (8, 48) to be at (0,0) locally.
	# Sprite.offset moves the texture relative to the Node position.
	# If offset is (-8, -48), then (8, 48) of texture is at (0,0).
	# Then we rotate the Sprite Node by -90 degrees (Top points Right).
	
	wand_sprite.offset = Vector2(0, -24) # Align center-y so rotation is clean?
	# Let's try: Centered=false.
	# Then (0,0) of texture is Node Pos.
	# We want (8, 48) to be Node Pos.
	# So offset = (-8, -48).
	# Then rotate -90 degrees.
	
	wand_sprite.centered = false
	wand_sprite.offset = Vector2(-8, -48) # Bottom-Center anchored (Handle at pivot)
	wand_sprite.rotation = PI / 2 # Rotate +90 deg so "Up"(Top of grid) points "Right"(Aim dir)
	
	wand_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST 
	weapon_pivot.add_child(wand_sprite)
	
	projectile_spawn_point = Marker2D.new()
	projectile_spawn_point.name = "Muzzle"
	projectile_spawn_point.position = Vector2(48, 0) # 3 Units (48px) forward (Length of wand)
	weapon_pivot.add_child(projectile_spawn_point)
	
	_update_wand_visual()
	# ------------------------

	# --- Minimalist Visual Injection ---
	# Configured in Editor
	pass

	# 初始化属性组件
	attributes = AttributeComponent.new()
	attributes.name = "AttributeComponent"
	attributes.data = GameState.player_data
	add_child(attributes)
	attributes.attribute_changed.connect(_on_stats_updated)
	_on_stats_updated("", 0) # 首次强制同步
	
	# Add some debug items
	var ice_wand = _create_debug_wand("Ice Wand")
	inventory.add_item(ice_wand)
	var fire_wand = _create_debug_wand("Fire Wand")
	inventory.add_item(fire_wand)
	inventory.select_hotbar_slot(0)

	# --- 系统连接与初始化 ---
	EventBus.player_input_enabled.connect(func(enabled): input_enabled = enabled)
	EventBus.player_data_refreshed.connect(refresh_data)
	if UIManager:
		UIManager.window_closed.connect(func(win_name): 
			if win_name == "WandEditor": 
				_update_wand_visual()
		)

	# 初始化相机

	var existing_cam = get_node_or_null("Camera2D")
	if existing_cam and existing_cam is Camera2D:
		camera = existing_cam
	else:
		camera = Camera2D.new()
		add_child(camera)
		camera.make_current()
	
	if not camera.get_script():
		camera.set_script(GameCameraScript)
		
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10.0
	if "process_callback" in camera:
		camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	
	# 同步初始物理状态
	if LayerManager:
		LayerManager.move_entity_to_layer(self, 0)

func _process(_delta: float) -> void:
	if weapon_pivot and input_enabled:
		var mouse_pos = get_global_mouse_position()
		var dir = (mouse_pos - global_position).normalized()
		weapon_pivot.rotation = dir.angle()

# Combat Juice Interfaces
func take_damage(amount: float, _type: String = "physical") -> void:
	if attributes and attributes.data:
		attributes.data.health -= amount
		print("Player takes damage: ", amount, " | New HP: ", attributes.data.health)
		# Basic death check
		if attributes.data.health <= 0:
			# Die logic (TODO)
			pass
			
	_trigger_damage_vignette()
	
	if UIManager:
		UIManager.show_floating_text(str(int(amount)), global_position + Vector2(0, -30), Color.CRIMSON)

	if camera and camera.has_method("shake"):
		camera.shake(0.4, 15.0) # Increased shake on player hit for awareness

func apply_knockback(impulse: Vector2) -> void:
	# Y axis handles impulse directly (gravity logic compatible)
	velocity.y += impulse.y
	# X axis uses residual velocity to persist against input overwrite
	knockback_velocity.x += impulse.x
	
	if is_on_floor() and impulse.y >= 0:
		velocity.y = -150 # Small hop if grounded and hit horizontally

func _trigger_damage_vignette() -> void:
	var hud = get_tree().get_first_node_in_group("hud") # Ensure HUD is grouped
	if hud and hud.has_method("show_damage_vignette"):
		hud.show_damage_vignette()
	else:
		# Fallback: Flash player modualte
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 0.4, 0.4), 0.1)
		tween.tween_property(self, "modulate", Color.WHITE, 0.1)
		


func _create_debug_wand(wname: String) -> WandItem:
	var item = WandItem.new()
	item.id = wname.to_lower().replace(" ", "_")
	item.display_name = wname
	item.icon = preload("res://icon.svg")
	item.wand_data = WandData.new()
	return item

func _setup_inventory_ui():
	var ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	var hb = preload("res://src/systems/inventory/ui/hotbar_panel.tscn").instantiate()
	ui_layer.add_child(hb)
	hb.position = Vector2(20, 20) 
	hb.setup(inventory.hotbar)
	hb.item_clicked.connect(func(idx): inventory.select_hotbar_slot(idx))
	hotbar_ui = hb
	
	# Backpack is now integrated into CharacterPanel (via GameManager + UIManager)
	# No separate backpack_ui instance here.



func _on_equipped_item_changed(item: Resource):
	if item is WandItem:
		current_wand = item.wand_data
		# Note: We now generate the texture from data, not use item icon directly for in-hand visual
		# unless we want to support generic icon fallback?
		# For now, let's force regeneration to match decoration system
		_update_wand_visual()
	else:
		current_wand = null
		if wand_sprite: wand_sprite.texture = null
	
	if interaction_area:
		interaction_area.collision_layer = 0
		interaction_area.collision_mask = LayerManager.LAYER_INTERACTION

# 挖掘状态
var current_mining_tile: Vector2i = Vector2i(-1, -1)
var is_attacking: bool = false
var action_cooldown: float = 0.0
const ACTION_INTERVAL: float = 0.25 # 0.25秒触发一次动作

# Wand System Helpers
func _setup_test_wand():
	var test_path = "res://scenes/test_wand.tres"
	if ResourceLoader.exists(test_path):
		current_wand = ResourceLoader.load(test_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		print("Loaded existing wand from ", test_path)
		# Ensure embryo exists
		if not current_wand.embryo:
			current_wand.embryo = WandEmbryo.new()
	else:
		print("Creating new test wand...")
		var embryo = WandEmbryo.new()
		embryo.grid_resolution = 4
		current_wand = WandData.new()
		current_wand.embryo = embryo
		current_wand.resource_path = test_path # Assign path for saving
		current_wand.logic_nodes = [] # CLEAR TEMPLATE
		current_wand.logic_connections = []
		
		var mat = BaseItem.new()
		mat.wand_visual_color = Color.AQUA
		mat.id = "test_block"
		current_wand.visual_grid[Vector2i(1,1)] = mat
		current_wand.visual_grid[Vector2i(2,2)] = mat
		
		# Logic Chain: Trigger -> Dmg -> Projectile
		var trig = { "id": "1", "type": "trigger", "position": Vector2(50, 50), "title": "Click" }
		var mod = { "id": "2", "type": "modifier_damage", "position": Vector2(250, 50), "value": {"amount": 50}, "title": "+Dmg" }
		var act = { "id": "3", "type": "action_projectile", "position": Vector2(450, 50), "title": "Fire" }
		
		current_wand.logic_nodes = [trig, mod, act]
		current_wand.logic_connections = [
			{"from_id": "1", "from_port": 0, "to_id": "2", "to_port": 0},
			{"from_id": "2", "from_port": 0, "to_id": "3", "to_port": 0}
		]
		# Save initial
		ResourceSaver.save(current_wand, test_path)

func _toggle_wand_editor():
	if UIManager:
		UIManager.toggle_window("WandEditor", "res://src/ui/wand_editor/wand_editor.tscn")

func _update_wand_visual():
	# Use new generator logic
	var tex = WandTextureGenerator.generate_texture(current_wand)
	if wand_sprite:
		wand_sprite.texture = tex
		# Remove old scale hack if present, keep 1:1 pixel art
		wand_sprite.scale = Vector2.ONE 
		# Rotation fixed at -90deg in _ready for vertical-to-horizontal mapping
	
	# Update Inventory Icon if applicable
	if current_wand and tex:
		# Find the item in inventory that holds this data?
		# Currently Player holds `current_wand` but we need the `WandItem` wrapper to update icon.
		_update_inventory_icon(tex)

func _update_inventory_icon(tex: Texture2D):
	# If we have a reference to current item wrapper
	if inventory:
		var item_wrapper = inventory.get_equipped_item()
		if item_wrapper and item_wrapper is WandItem and item_wrapper.wand_data == current_wand:
			item_wrapper.icon = tex
			# Signals inventory update?
			inventory.item_visual_updated.emit(item_wrapper) 
			# InventoryManager needs this signal or we trigger full refresh
			if hotbar_ui:
				hotbar_ui.refresh() # Brute force refresh for now

func _setup_camera_limits() -> void:
	var world_gen = get_tree().get_first_node_in_group("world_generator")

	if world_gen and camera:
		# 假设瓦片大小为 16
		var tile_size = 16
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = world_gen.world_width * tile_size
		camera.limit_bottom = world_gen.world_height * tile_size
		camera.zoom = Vector2(2.5, 2.5) # 初始缩放
		print("Camera: 边界已设置为: ", camera.limit_right, "x", camera.limit_bottom)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_C:
			_toggle_wand_editor()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var idx = event.keycode - KEY_1
			if inventory:
				inventory.select_hotbar_slot(idx)
		# KEY_I is handled by GameManager to open CharacterPanelUI
	
	# Removed single-click firing to support continuous fire in _physics_process
	
	if not input_enabled: return
	
	# 鼠标滚轮缩放 (需按住 Ctrl)
	if event is InputEventMouseButton and Input.is_key_pressed(KEY_CTRL):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom = (camera.zoom + Vector2(0.1, 0.1)).clamp(Vector2(0.5, 0.5), Vector2(4.0, 4.0)) # 允许缩得更小以便查看更多
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom = (camera.zoom - Vector2(0.1, 0.1)).clamp(Vector2(0.5, 0.5), Vector2(4.0, 4.0))
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	# --- 无限地图更新 ---
	if InfiniteChunkManager and Engine.get_frames_drawn() % 10 == 0:
		InfiniteChunkManager.update_player_vicinity(global_position)

	if action_cooldown > 0:
		action_cooldown -= delta
	
	# --- 击退衰减 ---
	if knockback_velocity.length_squared() > 100:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 1000 * delta)
	else:
		knockback_velocity = Vector2.ZERO

	if not input_enabled:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		velocity += knockback_velocity 
		move_and_slide()
		return

	# --- 动作处理 ---
	_handle_input_actions()
	
	var is_mining = false
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		is_mining = _handle_mouse_action()
	
	if not is_mining:
		_handle_continuous_actions()
	
	# --- 水平移动 ---
	var direction := Input.get_axis("left", "right")
	var target_speed_x = direction * SPEED
	
	# 平滑移动处理并叠加击退速度
	var movement_x = target_speed_x
	if direction == 0:
		movement_x = move_toward(velocity.x - knockback_velocity.x, 0, SPEED)
	
	velocity.x = movement_x + knockback_velocity.x
	
	# --- 垂直运动 (跳跃与重力) ---
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		fall_time = 0.0
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	if Input.is_action_just_pressed("space"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		jump_ramp_timer = JUMP_RAMP_TIME
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	if jump_ramp_timer > 0.0:
		velocity.y += JUMP_VELOCITY * (delta / JUMP_RAMP_TIME)
		jump_ramp_timer = max(0.0, jump_ramp_timer - delta)

	if not is_on_floor():
		if velocity.y < 0:
			var g_mult = GRAVITY_HOLD_MULTIPLIER if Input.is_action_pressed("space") else GRAVITY_RELEASE_MULTIPLIER
			velocity.y += GRAVITY * g_mult * delta
		else:
			fall_time += delta
			var dynamic_fall_multiplier = clamp(GRAVITY_FALL_MULTIPLIER + fall_time * FALL_GRAVITY_GROWTH, GRAVITY_FALL_MULTIPLIER, 4.5)
			velocity.y += GRAVITY * dynamic_fall_multiplier * delta

	# --- 空气阻力 ---
	if velocity.length() > 0.0:
		velocity += (-velocity.normalized() * AIR_DRAG_COEFF * velocity.length_squared()) * delta

	# --- 物理执行与翻转 ---
	var was_on_floor = is_on_floor()
	move_and_slide()
	
	if min_visual and velocity.x != 0:
		min_visual.scale.x = abs(min_visual.scale.x) * sign(velocity.x)
	
	if is_on_wall() and was_on_floor:
		_handle_step_up()

func _handle_step_up() -> void:
	var direction = Input.get_axis("left", "right")
	if direction == 0: return
	
	# 1. 向上探测：检查头顶是否有空间
	var step_test_up = Vector2(0, -STEP_HEIGHT)
	if test_move(global_transform, step_test_up):
		return
		
	# 2. 向前探测：检查台阶上方是否有空间
	# 在向上移动后的位置，尝试向前移动
	var test_transform = global_transform.translated(step_test_up)
	if test_move(test_transform, Vector2(direction * 2, 0)):
		return
		
	# 3. 确认可以上台阶，执行位移
	# 稍微向上并向前移动，然后让重力将其压回地面
	global_position.y -= STEP_HEIGHT
	global_position.x += direction * 2

func _handle_continuous_actions() -> void:
	if not input_enabled:
		return
	
	# 魔杖自动连发逻辑
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# 如果装备了魔杖，优先使用魔杖，且阻止挖掘/近战？
		if current_wand and action_cooldown <= 0.0:
			var dir = (get_global_mouse_position() - global_position).normalized()
			
			var spawn_pos = global_position
			if projectile_spawn_point:
				spawn_pos = projectile_spawn_point.global_position
				
			SpellProcessor.cast_spell(current_wand, self, dir, spawn_pos)
			
			# 充能时间从 wand 数据获取，如果没有默认 0.2
			var recharge = 0.2
			if current_wand.embryo:
				recharge = current_wand.embryo.recharge_rate
			action_cooldown = recharge

func _handle_input_actions() -> void:
	if Input.is_action_just_pressed("interact"):
		_interact()
	
	if Input.is_action_just_pressed("build"):
		UIManager.toggle_window("BuildingMenu", "res://scenes/ui/BuildingMenu.tscn", false)
	
	if Input.is_action_just_pressed("craft"):
		UIManager.toggle_window("CraftingWindow", "res://scenes/ui/CraftingWindow.tscn", false)
	
	if Input.is_action_just_pressed("settlement"):
		UIManager.toggle_window("SettlementUI", "res://scenes/ui/SettlementUI.tscn", false)
	
	if Input.is_action_just_pressed("save") and OS.is_debug_build():
		# 调试快捷键默认使用 1 号档位，仅在开发模式生效
		SaveManager.save_game(1)
		
	if Input.is_action_just_pressed("load") and OS.is_debug_build():
		SaveManager.load_game(1)
		
	if Input.is_action_just_pressed("mouse_left"):
		# 优先检查是否点击了可挖掘的瓦片，如果是，则不播放攻击动画
		var is_mining_target = false
		if GameState.digging:
			var tile_map = GameState.digging._get_current_tile_map()
			if tile_map:
				var mouse_pos = get_global_mouse_position()
				# 检查树木层
				var tree_layer = GameState.digging._get_tree_layer(tile_map)
				if tree_layer:
					var local_pos = tree_layer.to_local(mouse_pos)
					var map_pos = tree_layer.local_to_map(local_pos)
					var s_id = -1
					if tree_layer is TileMap:
						s_id = tree_layer.get_cell_source_id(GameState.digging.mining_layer, map_pos)
					else:
						s_id = tree_layer.get_cell_source_id(map_pos)
					
					if s_id != -1:
						is_mining_target = true
				
				# 检查地面层
				if not is_mining_target:
					var local_pos = tile_map.to_local(mouse_pos)
					var map_pos = tile_map.local_to_map(local_pos)
					var s_id = -1
					if tile_map is TileMap:
						s_id = tile_map.get_cell_source_id(GameState.digging.mining_layer, map_pos)
					else:
						s_id = tile_map.get_cell_source_id(map_pos)
						
					if s_id != -1:
						is_mining_target = true
		
		if not is_mining_target:
			_perform_combat_action()
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_handle_mouse_action()
	else:
		# 如果没有按住左键，重置挖掘进度
		if current_mining_tile != Vector2i(-1, -1):
			if GameState.digging:
				GameState.digging.reset_mining_progress(current_mining_tile)
			current_mining_tile = Vector2i(-1, -1)

func _handle_mouse_action() -> bool:
	# 如果正在建造，不执行挖掘逻辑
	var building_mgr = get_tree().get_first_node_in_group("building_manager")
	if building_mgr and building_mgr.has_method("is_building") and building_mgr.is_building():
		return false

	var mouse_pos = get_global_mouse_position()
	if global_position.distance_to(mouse_pos) > 150:
		if current_mining_tile != Vector2i(-1, -1):
			if GameState.digging: GameState.digging.reset_mining_progress(current_mining_tile)
			current_mining_tile = Vector2i(-1, -1)
		return false

	# 1. 优先检查点击的是否是 Destructible 实体 (如建筑、矿石节点)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collision_mask = 0xFFFFFFFF # 检查所有层
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query)
	for result in results:
		var target = result.collider
		if target.is_in_group("destructible") and target.has_method("hit"):
			if action_cooldown <= 0:
				target.hit(10, mouse_pos) # 传入伤害
				action_cooldown = ACTION_INTERVAL
				# 挖掘时不触发法杖后坐力
			return true # 成功击中实体后停止处理

	# 2. 挖掘 TileMap 逻辑
	if GameState.digging:
		var tile_map = GameState.digging._get_current_tile_map()
		if tile_map:
			var local_pos = tile_map.to_local(mouse_pos)
			var map_pos = tile_map.local_to_map(local_pos)
			
			# 检查该位置是否有物块 (挖掘的前提是目标点有物块)
			var has_tile = false
			if tile_map is TileMap:
				has_tile = tile_map.get_cell_source_id(GameState.digging.mining_layer, map_pos) != -1
			else:
				has_tile = tile_map.get_cell_source_id(map_pos) != -1
				
			if not has_tile:
				# 检查树木层
				var tree_layer = GameState.digging._get_tree_layer(tile_map)
				if tree_layer:
					if tree_layer is TileMap:
						has_tile = tree_layer.get_cell_source_id(0, map_pos) != -1
					else:
						has_tile = tree_layer.get_cell_source_id(map_pos) != -1

			# 检查距离，防止全屏挖掘
			if global_position.distance_to(mouse_pos) < 150 and has_tile:
				# 如果切换了瓦片，重置旧瓦片的进度
				if current_mining_tile != map_pos:
					if current_mining_tile != Vector2i(-1, -1):
						GameState.digging.reset_mining_progress(current_mining_tile)
					current_mining_tile = map_pos
				
				# 暂时使用 0 作为徒手挖掘力，后续可从装备系统获取
				var power = 0 
				# 使用持续挖掘逻辑
				GameState.digging.mine_tile_step(map_pos, get_physics_process_delta_time(), power)
				return true
			else:
				# 超出距离或无瓦片，重置进度
				if current_mining_tile != Vector2i(-1, -1):
					GameState.digging.reset_mining_progress(current_mining_tile)
					current_mining_tile = Vector2i(-1, -1)
	
	return false

func _interact() -> void:
	if not interaction_area:
		return
		
	# 检查 Area 检测到的可交互对象
	var areas = interaction_area.get_overlapping_areas()
	for area in areas:
		if area.has_method("interact"):
			area.interact()
			return
		elif area.get_parent() and area.get_parent().has_method("interact"):
			area.get_parent().interact()
			return

	# 检查 Body 检测到的可交互对象 (例如静态物块、宝箱)
	var bodies = interaction_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("interact"):
			body.interact()
			return
		elif body.get_parent() and body.get_parent().has_method("interact"):
			body.get_parent().interact()
			return

func _perform_combat_action() -> void:
	if action_cooldown > 0: return
	
	var mouse_pos = get_global_mouse_position()
	# 检查攻击距离
	if global_position.distance_to(mouse_pos) > 150:
		return
		
	_start_attack()
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collision_mask = LayerManager.LAYER_NPC
	query.collide_with_areas = true
	
	var results = space_state.intersect_point(query)
	if results.size() > 0:
		var target = results[0].collider
		
		# Improved Combat Feedback: Use CombatManager
		if CombatManager:
			# Consider windup time? For now, instant hit is fine for 2D feeling unless we have complex animation
			CombatManager.deal_damage(self, target, 10, "physical") 
			print("Player: 攻击实体: ", target.name)
		elif target.has_method("take_damage"):
			target.take_damage(10) # Fallback
			print("Player: 攻击实体: ", target.name)
			
		action_cooldown = ACTION_INTERVAL

func _start_attack() -> void:
	if is_attacking: return
	is_attacking = true
	
	# Minimalist Attack Visual (Lunge) - Improved "Juice"
	if min_visual:
		var original_x = min_visual.position.x
		# Check facing direction from scale
		var lunge_dir = 10.0
		if min_visual.scale.x < 0: lunge_dir = -10.0
		
		var tween = create_tween()
		# Phase 1: Windup (Back slightly)
		tween.tween_property(min_visual, "position:x", original_x - lunge_dir * 0.3, 0.05).set_trans(Tween.TRANS_SINE)
		# Phase 2: Lunge (Fast Forward)
		tween.tween_property(min_visual, "position:x", original_x + lunge_dir * 1.5, 0.08).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		# Phase 3: Recover
		tween.tween_property(min_visual, "position:x", original_x, 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
		tween.tween_callback(func(): is_attacking = false)
	else:
		get_tree().create_timer(0.2).timeout.connect(func(): is_attacking = false)

	# if animator:
	# 	animator.play("combat")

func _on_animation_finished() -> void:
	pass
	# if animator.animation == "combat":
	# 	is_attacking = false
		# print("Player: 攻击动画播放完毕")

func _on_stats_updated(_name: String, _val: float) -> void:
	if attributes:
		SPEED = attributes.get_move_speed(BASE_SPEED)
		JUMP_VELOCITY = attributes.get_jump_force(BASE_JUMP)
		print("Player: 属性已同步 (Speed: %.1f, Jump: %.1f)" % [SPEED, JUMP_VELOCITY])

func refresh_data() -> void:
	if attributes:
		attributes.data = GameState.player_data
		# 强制重新连接信号（防止旧引用残留）
		if attributes.data.stat_changed.is_connected(attributes.update_modifiers_from_signal):
			attributes.data.stat_changed.disconnect(attributes.update_modifiers_from_signal)
		attributes.data.stat_changed.connect(attributes.update_modifiers_from_signal)
		attributes.update_modifiers()
		_on_stats_updated("", 0)
	print("Player: 数据已刷新，当前角色: ", GameState.player_data.display_name)
