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

@export var animator: AnimatedSprite2D
@export var interaction_area: Area2D

var attributes: AttributeComponent
var camera: Camera2D
var input_enabled: bool = true

# 缓存的基础数值
var BASE_SPEED = 200.0
var BASE_JUMP = -600.0

func _ready() -> void:
	add_to_group("player")
	
	# 初始化属性组件
	attributes = AttributeComponent.new()
	attributes.name = "AttributeComponent"
	attributes.data = GameState.player_data
	add_child(attributes)
	attributes.attribute_changed.connect(_on_stats_updated)
	_on_stats_updated("", 0) # 首次强制同步
	
	EventBus.player_input_enabled.connect(func(enabled): input_enabled = enabled)
	
	if animator:
		animator.animation_finished.connect(_on_animation_finished)
		# 确保攻击动画不循环，否则无法触发 finished 信号
		if animator.sprite_frames.has_animation("combat"):
			animator.sprite_frames.set_animation_loop("combat", false)
	
	# 初始化相机
	# 优先复用场景中已存在的 Camera2D (例如 test.tscn 中添加带有 Shake 脚本的相机)
	var existing_cam = get_node_or_null("Camera2D")
	if existing_cam and existing_cam is Camera2D:
		camera = existing_cam
	else:
		camera = Camera2D.new()
		add_child(camera)
		
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10.0 # 提高平滑速度减少拖影
	# 使用 Camera2D.CAMERA2D_PROCESS_PHYSICS (0)
	if "process_callback" in camera:
		camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	# _setup_camera_limits() # 禁用硬编码边界以支持无限世界
	
	# 确保初始物理状态与 LayerManager 同步
	if LayerManager:
		LayerManager.move_entity_to_layer(self, 0)
	else:
		collision_layer = 1 << 4 # Player Bit
		collision_mask = 1 << 0  # Layer 0
	
	if interaction_area:
		interaction_area.collision_layer = 0
		interaction_area.collision_mask = LayerManager.LAYER_INTERACTION

# 挖掘状态
var current_mining_tile: Vector2i = Vector2i(-1, -1)
var is_attacking: bool = false

# 动作冷却
var action_cooldown: float = 0.0
const ACTION_INTERVAL: float = 0.25 # 0.25秒触发一次动作

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
	if not input_enabled: return
	
	# 鼠标滚轮缩放
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom = (camera.zoom + Vector2(0.1, 0.1)).clamp(Vector2(1.5, 1.5), Vector2(4.0, 4.0))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom = (camera.zoom - Vector2(0.1, 0.1)).clamp(Vector2(1.5, 1.5), Vector2(4.0, 4.0))

func _physics_process(delta: float) -> void:
	# --- 无限地图更新 ---
	if InfiniteChunkManager and Engine.get_frames_drawn() % 10 == 0:
		InfiniteChunkManager.update_player_vicinity(global_position)

	if action_cooldown > 0:
		action_cooldown -= delta

	if not input_enabled:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		return

	_handle_input_actions()
	
	if Input.is_action_just_pressed("interact"):
		_interact()
		
	if is_attacking:
		# 攻击动画播放中，由 _on_animation_finished 处理状态重置
		pass
	elif velocity==Vector2.ZERO:
		animator.play("idle1")
	elif velocity.x!=0 and is_on_floor():
		animator.play("run1")
	else :
		animator.play("jump")
	# 水平移动输入（保持原数量级）
	var direction := Input.get_axis("left", "right")
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 翻转精灵以匹配移动方向（向左时翻转）
	if animator:
		if velocity.x < 0:
			animator.flip_h = true
		elif velocity.x > 0:
			animator.flip_h = false

	# 更新 coyote 与 jump buffer 计时器
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	if Input.is_action_just_pressed("space"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

	# 尝试触发跳跃：当存在 buffer 且在 coyote 时间内
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		# 启动跳跃渐变（代替立即把 velocity.y 直接设为 JUMP_VELOCITY）
		jump_ramp_timer = JUMP_RAMP_TIME
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# 在跳跃渐变时间内逐帧施加上升冲力（总量等于 JUMP_VELOCITY）
	if jump_ramp_timer > 0.0:
		# 每帧施加的增量，使得在 JUMP_RAMP_TIME 内累计到 JUMP_VELOCITY
		# 使用线性分配（更长的 JUMP_RAMP_TIME 会使施力更慢）
		var ramp_amount = JUMP_VELOCITY * (delta / JUMP_RAMP_TIME)
		velocity.y += ramp_amount
		jump_ramp_timer = max(0.0, jump_ramp_timer - delta)

	# 渐变重力：根据当前垂直速度方向与跳跃键是否按住调整重力强度
	if not is_on_floor():
		if velocity.y < 0:
			# 上升阶段
			# 当按住跳跃键时减小重力，释放时增大重力（短跳）
			if Input.is_action_pressed("space"):
				velocity.y += GRAVITY * GRAVITY_HOLD_MULTIPLIER * delta
			else:
				velocity.y += GRAVITY * GRAVITY_RELEASE_MULTIPLIER * delta
		else:
			# 下落阶段：动态增加下落重力，使得下落先缓后快更真实
			fall_time += delta
			var dynamic_fall_multiplier = clamp(GRAVITY_FALL_MULTIPLIER + fall_time * FALL_GRAVITY_GROWTH, GRAVITY_FALL_MULTIPLIER, 4.5)
			velocity.y += GRAVITY * dynamic_fall_multiplier * delta
	else:
		# 着地时重置下落计时
		fall_time = 0.0

	# 空气阻力（对整个速度向量作用，二次阻力）
	if velocity.length() > 0.0:
		var drag_dir = -velocity.normalized()
		var drag_mag = AIR_DRAG_COEFF * velocity.length_squared()
		var drag = drag_dir * drag_mag
		# 把阻力作为加速度积分到速度上
		velocity += drag * delta

	var was_on_floor = is_on_floor()
	move_and_slide()
	
	# 自动上台阶逻辑
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

func _handle_input_actions() -> void:
	if Input.is_action_just_pressed("interact"):
		_interact()
	
	if Input.is_action_just_pressed("build"):
		UIManager.toggle_window("BuildingMenu", "res://scenes/ui/BuildingMenu.tscn", false)
	
	if Input.is_action_just_pressed("craft"):
		UIManager.toggle_window("CraftingWindow", "res://scenes/ui/CraftingWindow.tscn", false)
	
	if Input.is_action_just_pressed("settlement"):
		UIManager.toggle_window("SettlementUI", "res://scenes/ui/SettlementUI.tscn", false)
	
	if Input.is_action_just_pressed("save"):
		SaveManager.save_game()
		
	if Input.is_action_just_pressed("load"):
		SaveManager.load_game()
		
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
					if tree_layer.has_method("get_layers_count"):
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
					if tile_map.has_method("get_layers_count"):
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

func _handle_mouse_action() -> void:
	# 如果正在建造，不执行挖掘逻辑
	var building_mgr = get_tree().get_first_node_in_group("building_manager")
	if building_mgr and building_mgr.has_method("is_building") and building_mgr.is_building():
		return

	var mouse_pos = get_global_mouse_position()
	if global_position.distance_to(mouse_pos) > 150:
		if current_mining_tile != Vector2i(-1, -1):
			if GameState.digging: GameState.digging.reset_mining_progress(current_mining_tile)
			current_mining_tile = Vector2i(-1, -1)
		return

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
				_start_attack()
			return # 成功击中实体后停止处理

	# 2. 挖掘 TileMap 逻辑
	if GameState.digging:
		var tile_map = GameState.digging._get_current_tile_map()
		if tile_map:
			var local_pos = tile_map.to_local(mouse_pos)
			var map_pos = tile_map.local_to_map(local_pos)
			
			# 检查距离，防止全屏挖掘
			if global_position.distance_to(mouse_pos) < 150:
				# 如果切换了瓦片，重置旧瓦片的进度
				if current_mining_tile != map_pos:
					if current_mining_tile != Vector2i(-1, -1):
						GameState.digging.reset_mining_progress(current_mining_tile)
					current_mining_tile = map_pos
				
				# 暂时使用 0 作为徒手挖掘力，后续可从装备系统获取
				var power = 0 
				# 使用持续挖掘逻辑
				if GameState.digging.mine_tile_step(map_pos, get_physics_process_delta_time(), power):
					# 挖掘成功后，current_mining_tile 会在下一帧重置或更新
					pass
			else:
				# 超出距离，重置进度
				if current_mining_tile != Vector2i(-1, -1):
					GameState.digging.reset_mining_progress(current_mining_tile)
					current_mining_tile = Vector2i(-1, -1)

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
		if target.has_method("take_damage"):
			target.take_damage(10) # 基础伤害
			print("Player: 攻击实体: ", target.name)
			action_cooldown = ACTION_INTERVAL

func _start_attack() -> void:
	if is_attacking: return
	is_attacking = true
	if animator:
		animator.play("combat")

func _on_animation_finished() -> void:
	if animator.animation == "combat":
		is_attacking = false
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
