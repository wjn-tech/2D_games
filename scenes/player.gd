extends CharacterBody2D

signal water_state_changed(previous_state: String, next_state: String, immersion: float)
signal water_interaction_event(event_name: String, immersion: float)

# Safe transform helpers
const TransformHelper = preload("res://src/utils/transform_helper.gd")

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
const FALL_PRELOAD_SPEED_THRESHOLD = 900.0
const TERMINAL_FALL_SPEED = 1280.0
const FALL_PRELOAD_DISTANCE_MIN = 128.0
const FALL_PRELOAD_DISTANCE_MAX = 896.0
const FALL_PRELOAD_FRAME_INTERVAL = 6
const EXTREME_STREAM_REFRESH_INTERVAL = 1
const FAST_FALL_STREAM_REFRESH_INTERVAL = 2
const HIGH_SPEED_STREAM_REFRESH_INTERVAL = 2
const NORMAL_STREAM_REFRESH_INTERVAL = 4
const STREAM_PRESSURE_SPEED_THRESHOLD = 520.0
const STREAM_PRESSURE_SPEED_THRESHOLD_EXTREME = 900.0
const WALK_AHEAD_PRELOAD_DISTANCE = 192.0
const WALK_AHEAD_PRELOAD_FRAME_INTERVAL = 8
const WALK_AHEAD_PRELOAD_DISTANCE_MAX = 768.0
const WALK_AHEAD_PRELOAD_DISTANCE_FACTOR = 0.45
const EMERGENCY_SYNC_LOAD_COOLDOWN_MS = 90
const WALK_SYNC_GUARD_MIN_SPEED = 24.0
const WALK_SYNC_GUARD_COOLDOWN_MS = 120
const FOOTSTEP_INTERVAL_BASE = 0.24
const FOOTSTEP_INTERVAL_FAST = 0.16
const PLAYER_FEET_OFFSET = 8.0
const TERRAIN_RECOVERY_COOLDOWN = 0.15
const FREEFALL_RESCUE_TIME = 3.0
const FREEFALL_RESCUE_MIN_SPEED = 900.0
const FREEFALL_RESCUE_CHUNK_MISS_TIME = 1.2

const WATER_STATE_DRY := "dry"
const WATER_STATE_WADING := "wading"
const WATER_STATE_SWIMMING := "swimming"
const WATER_STATE_SUBMERGED := "submerged"

const WATER_ENTER_WADING := 0.08
const WATER_EXIT_WADING := 0.03
const WATER_ENTER_SWIMMING_TORSO := 0.24
const WATER_EXIT_SWIMMING_TORSO := 0.14
const WATER_ENTER_SUBMERGED_HEAD := 0.28
const WATER_EXIT_SUBMERGED_HEAD := 0.16

const WATER_SWIM_UP_ACCEL := 920.0
const WATER_SWIM_UP_MAX_SPEED := 220.0
const WATER_EVENT_COOLDOWN_MS := 220
const WATER_LOOP_EVENT_INTERVAL_MS := 380
const MINA_CONTROL_DURATION := 10.0
const MINA_ATTACK_MULTIPLIER_FLOOR := 0.2

@export var interaction_area: Area2D

const WandRendererScene = preload("res://src/systems/magic/wand_renderer.tscn")

var current_wand: WandData
var _last_equipped_wand_snapshot: WandData = null
var weapon_pivot: Marker2D
var wand_sprite: Sprite2D
var projectile_spawn_point: Marker2D
var knockback_velocity: Vector2 = Vector2.ZERO

var attributes: AttributeComponent
var camera: Camera2D
var input_enabled: bool = true
var movement_locked: bool = false
var invincible: bool = false
var _gravity_enabled: bool = true
var _debug_lock_warned: bool = false # 防止刷屏的调试变量
var _terrain_recovery_timer: float = 0.0
var _last_safe_ground_position: Vector2 = Vector2.ZERO
var _has_safe_ground_position: bool = false
var _last_streaming_chunk_coord: Variant = null
var _last_fall_preload_chunk_coord: Variant = null
var _fast_fall_streaming_active: bool = false
var _last_walk_preload_chunk_coord: Variant = null
var _last_emergency_sync_chunk_coord: Variant = null
var _last_emergency_sync_load_msec: int = 0
var _last_walk_sync_guard_chunk_coord: Variant = null
var _last_walk_sync_guard_msec: int = 0
var _freefall_chunk_miss_time: float = 0.0
var _footstep_timer: float = 0.0
var _water_state: String = WATER_STATE_DRY
var _water_immersion: float = 0.0
var _water_probe_foot: float = 0.0
var _water_probe_torso: float = 0.0
var _water_probe_head: float = 0.0
var _water_head_submerged: bool = false
var _water_event_next_ms: Dictionary = {}
var _water_motion_profile: Dictionary = {
	"speed_scale": 1.0,
	"accel_scale": 1.0,
	"gravity_scale": 1.0,
	"buoyancy": 0.0,
	"jump_scale": 1.0,
	"max_fall_speed": 99999.0,
}
var _water_jump_ramp_scale: float = 1.0
var _poison_remaining_time: float = 0.0
var _poison_tick_interval: float = 1.0
var _poison_tick_timer: float = 0.0
var _poison_tick_max_hp_percent: float = 0.0
var _mina_projectile_lock_time: float = 0.0
var _mina_input_inversion_time: float = 0.0
var _mina_gravity_flip_time: float = 0.0
var _mina_angina_time: float = 0.0
var _mina_angina_original_max_health: float = -1.0
var _mina_attack_multiplier: float = 1.0
var _mina_projectile_lock_feedback_cooldown: float = 0.0

func set_gravity_enabled(enabled: bool) -> void:
	_gravity_enabled = enabled
	if not enabled:
		velocity.y = 0

func apply_mina_angina(duration: float = MINA_CONTROL_DURATION) -> void:
	if attributes == null or attributes.data == null:
		return
	if _mina_angina_time <= 0.0:
		_mina_angina_original_max_health = maxf(1.0, float(attributes.data.max_health))
	_mina_angina_time = maxf(_mina_angina_time, duration)
	var reduced_max := maxf(1.0, _mina_angina_original_max_health * 0.5)
	attributes.data.max_health = reduced_max
	if attributes.data.health > reduced_max:
		attributes.data.health = reduced_max

func apply_mina_projectile_lock(duration: float = MINA_CONTROL_DURATION) -> void:
	_mina_projectile_lock_time = maxf(_mina_projectile_lock_time, duration)

func apply_mina_input_inversion(duration: float = MINA_CONTROL_DURATION) -> void:
	_mina_input_inversion_time = maxf(_mina_input_inversion_time, duration)

func apply_mina_gravity_flip(duration: float = MINA_CONTROL_DURATION) -> void:
	_mina_gravity_flip_time = maxf(_mina_gravity_flip_time, duration)

func apply_mina_attack_reduction_step() -> void:
	_mina_attack_multiplier = maxf(MINA_ATTACK_MULTIPLIER_FLOOR, _mina_attack_multiplier * 0.8)

func get_combat_damage_multiplier() -> float:
	return maxf(MINA_ATTACK_MULTIPLIER_FLOOR, _mina_attack_multiplier)

func clear_mina_combat_debuffs() -> void:
	_mina_projectile_lock_time = 0.0
	_mina_input_inversion_time = 0.0
	_mina_gravity_flip_time = 0.0
	_mina_angina_time = 0.0
	_mina_projectile_lock_feedback_cooldown = 0.0
	_mina_attack_multiplier = 1.0
	if attributes and attributes.data and _mina_angina_original_max_health > 0.0:
		attributes.data.max_health = _mina_angina_original_max_health
		attributes.data.health = minf(attributes.data.health, attributes.data.max_health)
	_mina_angina_original_max_health = -1.0

func _is_mina_projectile_locked() -> bool:
	return _mina_projectile_lock_time > 0.0

func _is_mina_input_inverted() -> bool:
	return _mina_input_inversion_time > 0.0

func _get_current_gravity_direction() -> float:
	return -1.0 if _mina_gravity_flip_time > 0.0 else 1.0

func _clamp_terminal_velocity_signed(limit: float) -> void:
	var gravity_dir := _get_current_gravity_direction()
	if gravity_dir > 0.0:
		if velocity.y > limit:
			velocity.y = limit
	else:
		if velocity.y < -limit:
			velocity.y = -limit

func _process_mina_combat_debuffs(delta: float) -> void:
	if _mina_projectile_lock_time > 0.0:
		_mina_projectile_lock_time = maxf(0.0, _mina_projectile_lock_time - delta)
	if _mina_input_inversion_time > 0.0:
		_mina_input_inversion_time = maxf(0.0, _mina_input_inversion_time - delta)
	if _mina_gravity_flip_time > 0.0:
		_mina_gravity_flip_time = maxf(0.0, _mina_gravity_flip_time - delta)
	if _mina_projectile_lock_feedback_cooldown > 0.0:
		_mina_projectile_lock_feedback_cooldown = maxf(0.0, _mina_projectile_lock_feedback_cooldown - delta)

	if _mina_angina_time > 0.0:
		_mina_angina_time = maxf(0.0, _mina_angina_time - delta)
		if attributes and attributes.data and _mina_angina_original_max_health > 0.0:
			var reduced_max := maxf(1.0, _mina_angina_original_max_health * 0.5)
			attributes.data.max_health = reduced_max
			attributes.data.health = minf(attributes.data.health, reduced_max)
	elif _mina_angina_original_max_health > 0.0:
		if attributes and attributes.data:
			attributes.data.max_health = _mina_angina_original_max_health
			attributes.data.health = minf(attributes.data.health, attributes.data.max_health)
		_mina_angina_original_max_health = -1.0

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
	
	# Setup Inventory - USE GLOBAL SINGLETON
	inventory = GameState.inventory
	
	# Delay selection to let UI init first? Or select now.
	# inventory.select_hotbar_slot(0) # Don't auto-select slot 0 on start to avoid visual "always on" if user prefers
	
	inventory.equipped_item_changed.connect(_on_equipped_item_changed)
	
	current_wand = null # Default clean state
	
	# setup inventory ui
	_setup_inventory_ui()
	
	# _setup_test_wand() # REMOVED: Do not override equipped item with debug wand on start
	
	# Weapon Attachment Setup (Wand Decoration System)
	weapon_pivot = Marker2D.new()
	weapon_pivot.name = "WeaponPivot"
	weapon_pivot.position = Vector2(0, -12) # 移至角色躯干中心
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
	
	# _update_wand_visual() # Removed initial wand setup which uses test_wand always
	if wand_sprite: wand_sprite.visible = false # Default to hidden until equipped
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
	# var ice_wand = _create_debug_wand("Ice Wand")
	# inventory.add_item(ice_wand)
	# var fire_wand = _create_debug_wand("Fire Wand")
	# inventory.add_item(fire_wand)
	# inventory.select_hotbar_slot(0) # Removed auto-selection to fix "always lit" first slot


	# --- 系统连接与初始化 ---
	EventBus.player_input_enabled.connect(func(enabled): input_enabled = enabled)
	EventBus.player_movement_locked.connect(func(locked): movement_locked = locked)
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
	_last_safe_ground_position = global_position
	_has_safe_ground_position = true

func _process(delta: float) -> void:
	if current_wand:
		current_wand.update_mana(delta)
		# Update transient data for HUD
		if attributes and attributes.data:
			attributes.data.current_tool_mana = current_wand.current_mana
			if current_wand.embryo:
				attributes.data.current_tool_max_mana = current_wand.embryo.mana_capacity
	else:
		if attributes and attributes.data:
			attributes.data.current_tool_max_mana = -1.0
		
	if weapon_pivot and input_enabled:
		var mouse_pos = get_global_mouse_position()
		var dir = (mouse_pos - global_position).normalized()
		weapon_pivot.rotation = dir.angle()

func get_spell_spawn_transform() -> Dictionary:
	var spawn_pos = global_position
	if projectile_spawn_point:
		spawn_pos = projectile_spawn_point.global_position

	var direction = Vector2.RIGHT
	if weapon_pivot:
		direction = Vector2.RIGHT.rotated(weapon_pivot.global_rotation)
	elif input_enabled:
		direction = get_global_mouse_position() - global_position

	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()

	return {
		"position": spawn_pos,
		"direction": direction,
	}

# Combat Juice Interfaces
func take_damage(amount: float, _type: String = "physical") -> void:
	if invincible: return # 无敌状态下不响应伤害
	
	if attributes and attributes.data:
		attributes.data.health -= amount
		print("Player takes damage: ", amount, " | New HP: ", attributes.data.health)
		# Basic death check
		if attributes.data.health <= 0:
			var boss_encounter_manager = _find_boss_encounter_manager()
			if boss_encounter_manager and boss_encounter_manager.has_method("handle_player_death"):
				if boss_encounter_manager.handle_player_death(self):
					return
			print("Player Health depleted! Triggering Reincarnation...")
			LifespanManager.trigger_instant_death(attributes.data, "战斗死亡")
			
	_trigger_damage_vignette()
	
	if UIManager:
		UIManager.show_floating_text(str(int(amount)), global_position + Vector2(0, -30), Color.CRIMSON)

	if camera and camera.has_method("shake"):
		camera.shake(0.4, 15.0) # Increased shake on player hit for awareness

func apply_poison_effect(duration: float, tick_interval: float, max_hp_percent_per_tick: float) -> void:
	if duration <= 0.0 or max_hp_percent_per_tick <= 0.0:
		return
	_poison_remaining_time = maxf(_poison_remaining_time, duration)
	_poison_tick_interval = clampf(tick_interval, 0.1, 5.0)
	if _poison_tick_timer <= 0.0:
		_poison_tick_timer = _poison_tick_interval
	else:
		_poison_tick_timer = minf(_poison_tick_timer, _poison_tick_interval)
	_poison_tick_max_hp_percent = maxf(_poison_tick_max_hp_percent, max_hp_percent_per_tick)

func _process_poison_status(delta: float) -> void:
	if _poison_remaining_time <= 0.0:
		return
	_poison_remaining_time = maxf(0.0, _poison_remaining_time - delta)
	_poison_tick_timer -= delta

	while _poison_tick_timer <= 0.0 and _poison_remaining_time > 0.0:
		_poison_tick_timer += _poison_tick_interval
		var max_health_value := _get_player_max_health()
		if max_health_value <= 0.0:
			continue
		var poison_damage := maxf(1.0, max_health_value * _poison_tick_max_hp_percent)
		take_damage(poison_damage, "poison")
		if UIManager:
			UIManager.show_floating_text("Poison", global_position + Vector2(0, -44), Color(0.5, 1.0, 0.45))

	if _poison_remaining_time <= 0.0:
		_poison_tick_max_hp_percent = 0.0
		_poison_tick_timer = 0.0

func _get_player_max_health() -> float:
	if attributes and attributes.data:
		return float(attributes.data.max_health)
	return 0.0

func apply_knockback(impulse: Vector2) -> void:
	# Y axis handles impulse directly (gravity logic compatible)
	velocity.y += impulse.y
	# X axis uses residual velocity to persist against input overwrite
	knockback_velocity.x += impulse.x
	
	if is_on_floor() and impulse.y >= 0:
		velocity.y = -150 # Small hop if grounded and hit horizontally

func _trigger_damage_vignette() -> void:
	var tree := get_tree()
	if tree == null:
		return

	var hud = tree.get_first_node_in_group("hud") # Ensure HUD is grouped
	if hud and hud.has_method("show_damage_vignette"):
		hud.show_damage_vignette()
	else:
		if not is_inside_tree():
			return
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
	# Legacy hotbar creation removed to prevent duplicates with main HUD
	# The main HUD now handles the hotbar display.
	hotbar_ui = null 
	pass

	# var ui_layer = CanvasLayer.new()
	# add_child(ui_layer)
	
	# var hb = preload("res://src/systems/inventory/ui/hotbar_panel.tscn").instantiate()
	# ui_layer.add_child(hb)
	# hb.position = Vector2(20, 20) 
	# hb.setup(inventory.hotbar)
	# hb.item_clicked.connect(func(idx): inventory.select_hotbar_slot(idx))
	# hotbar_ui = hb
	
	# Backpack is now integrated into CharacterPanel (via GameManager + UIManager)
	# No separate backpack_ui instance here.



func _on_equipped_item_changed(item: Resource):
	# Signal EventBus for Tutorials
	EventBus.item_equipped.emit(item)
	
	# 允许重复触发，以便在右键取消后，再次点击同一格能重新唤出预览
	var bm = get_tree().get_first_node_in_group("building_manager")
	
	# Check if item is a Wand (either by class or duck-typing)
	var is_wand = false
	if item and (item is WandItem or item.get("wand_data") != null):
		is_wand = true
		
	if is_wand:
		if bm: bm.cancel_building()
		current_wand = item.wand_data
		_cache_current_wand_snapshot()
		if wand_sprite: wand_sprite.visible = true
		_update_wand_visual()
	elif item is TileItemData or (item and item.has_meta("building_resource")) or (item and (item.id == "workbench" or item.id == "workbench_item")):
		if bm: 
			if bm.is_building(): bm.cancel_building()
			_try_place_held_item() # 内部已经处理了建筑启动逻辑
		
		# Clear wand status since we hold a building item
		_cache_current_wand_snapshot()
		current_wand = null
		if wand_sprite and item: 
			wand_sprite.visible = true
			if item.icon:
				wand_sprite.texture = item.icon
			else:
				# 容错：如果物品没图标，不清除旧贴图以免变黑，或者给个默认的
				pass
			wand_sprite.offset = Vector2(16, 0)
			wand_sprite.centered = true
			wand_sprite.rotation = 0
			wand_sprite.scale = Vector2(0.5, 0.5) 
			wand_sprite.modulate = Color(1, 1, 1, 1)
			wand_sprite.z_index = 5
	elif item == null:
		# Unequipped
		_cache_current_wand_snapshot()
		current_wand = null
		if bm and bm.is_building(): bm.cancel_building()
		if wand_sprite: wand_sprite.visible = false
	elif item and (item.has_meta("building_resource") or item.id == "workbench" or item.id == "workbench_item"):
		# 建筑类物品：立即进入建造预览模式
		_cache_current_wand_snapshot()
		current_wand = null
		if wand_sprite: 
			wand_sprite.visible = true
			wand_sprite.texture = item.icon
			wand_sprite.offset = Vector2(16, 0)
			wand_sprite.scale = Vector2(0.8, 0.8)
			wand_sprite.modulate = Color(1, 1, 1, 0.8)
			
		if bm:
			if bm.is_building(): bm.cancel_building()
			if item.id == "workbench" or item.id == "workbench_item":
				var res = BuildingResource.new()
				res.scene = load("res://scenes/world/workbench.tscn")
				res.cost = { item.id: 1 }
				res.id = item.id
				res.display_name = item.display_name
				res.requires_flat_ground = true
				res.influence_radius = 160.0 # 明确设置工作台的影响范围/可见圈
				bm.start_building(res)
			elif item.has_meta("building_resource"):
				bm.start_building(item.get_meta("building_resource"))
	else:
		_cache_current_wand_snapshot()
		current_wand = null
		if wand_sprite: 
			wand_sprite.texture = null
			wand_sprite.visible = false
		if bm: bm.cancel_building()
	
	if interaction_area:
		interaction_area.collision_layer = 0
		interaction_area.collision_mask = LayerManager.LAYER_INTERACTION

# 挖掘状态
var current_mining_tile: Vector2i = Vector2i(-1, -1)
var is_attacking: bool = false
var action_cooldown: float = 0.0
const ACTION_INTERVAL: float = 0.25 # 0.25秒触发一次动作

# Wand System Helpers
# func _setup_test_wand(): # REMOVED: Do not override equipped item with debug wand on start
# 	var test_path = "res://scenes/test_wand.tres"
# 	if ResourceLoader.exists(test_path):
# 		var loaded = ResourceLoader.load(test_path, "", ResourceLoader.CACHE_MODE_IGNORE)
# 		if loaded is WandData:
# 			current_wand = loaded

func get_equipped_wand():
	if inventory:
		var item = inventory.get_equipped_item()
		if item and (item is WandItem or item.get("wand_data") != null):
			return item
	return null

func get_last_known_wand_snapshot() -> WandData:
	if current_wand:
		return current_wand.duplicate(true)
	if _last_equipped_wand_snapshot:
		return _last_equipped_wand_snapshot.duplicate(true)
	return null

func _cache_current_wand_snapshot() -> void:
	if current_wand:
		_last_equipped_wand_snapshot = current_wand.duplicate(true)

func _toggle_wand_editor():
	if UIManager:
		UIManager.toggle_window("WandEditor", "res://src/ui/wand_editor/wand_editor.tscn")

func _update_wand_visual():
	if not current_wand:
		if wand_sprite: wand_sprite.visible = false
		return
		
	# Use new generator logic or fallback
	var tex = null
	# Try usage as static class or singleton
	if WandTextureGenerator:
		tex = WandTextureGenerator.generate_texture(current_wand)
		
	if wand_sprite:
		if tex:
			wand_sprite.texture = tex
		else:
			# Fallback or clear if generation failed
			pass
		
		# Ensure visual settings correct for wands
		wand_sprite.visible = true
		wand_sprite.centered = false
		wand_sprite.offset = Vector2(-8, -48)
		wand_sprite.rotation = PI / 2
		wand_sprite.scale = Vector2.ONE 
	
	# Update Inventory Icon if applicable
	if current_wand and tex:
		_update_inventory_icon(tex)
		# 恢复魔杖的特殊中心和旋转位移
		wand_sprite.centered = false
		wand_sprite.offset = Vector2(-8, -48)
		wand_sprite.rotation = PI / 2
		# Remove old scale hack if present, keep 1:1 pixel art
		wand_sprite.scale = Vector2.ONE 
	
	# Update Inventory Icon if applicable
	if current_wand and tex:
		# Find the item in inventory that holds this data?
		# Currently Player holds `current_wand` but we need the `WandItem` wrapper to update icon.
		_update_inventory_icon(tex)

func _update_inventory_icon(tex: Texture2D):
	# If we have a reference to current item wrapper
	if inventory:
		var item_wrapper = inventory.get_equipped_item()
		# Robust check
		if item_wrapper and (item_wrapper is WandItem or item_wrapper.get("wand_data") == current_wand):
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
		# Changed from KEY_C (Conflict with Character Sheet) to KEY_K (Knowledge/Magic)
		if event.keycode == KEY_K:
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
	
	# 鼠标点击逻辑优化：
	# 1. 如果手里拿着可放置物品，且当前不在建造模式，点击左键先启动预览
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var bm = get_tree().get_first_node_in_group("building_manager")
		if bm and not bm.is_building():
			_try_place_held_item()
	
	# 右键取消建造
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var bm = get_tree().get_first_node_in_group("building_manager")
		if bm and bm.is_building():
			bm.cancel_building()
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	_process_poison_status(delta)
	_process_mina_combat_debuffs(delta)
	up_direction = Vector2.UP if _get_current_gravity_direction() > 0.0 else Vector2.DOWN

	var in_independent_encounter := false
	var boss_encounter_manager = _find_boss_encounter_manager()
	if boss_encounter_manager and boss_encounter_manager.has_method("is_player_in_active_encounter"):
		in_independent_encounter = bool(boss_encounter_manager.is_player_in_active_encounter(self))
	var is_fast_fall_streaming := (not is_on_floor() and velocity.y > FALL_PRELOAD_SPEED_THRESHOLD)
	var horizontal_stream_bias: int = 0
	if abs(velocity.x) > 25.0:
		horizontal_stream_bias = 1 if velocity.x > 0.0 else -1
	var allow_stream_unload: bool = abs(velocity.x) < 35.0
	var stream_vertical_radius: int = 2
	if velocity.y > 280.0:
		stream_vertical_radius = 3
	if not in_independent_encounter and _fast_fall_streaming_active and not is_fast_fall_streaming and InfiniteChunkManager:
		# 离开高速坠落状态后立即恢复完整邻域，统一回收临时保留区块。
		InfiniteChunkManager.update_player_vicinity(global_position, -1, allow_stream_unload, horizontal_stream_bias, stream_vertical_radius)
		_last_streaming_chunk_coord = InfiniteChunkManager.get_chunk_coord(global_position)
	_fast_fall_streaming_active = is_fast_fall_streaming if not in_independent_encounter else false

	# --- 无限地图更新 ---
	var max_component_speed: float = maxf(absf(velocity.x), absf(velocity.y))
	var is_extreme_streaming_speed: bool = max_component_speed >= STREAM_PRESSURE_SPEED_THRESHOLD_EXTREME
	var is_high_speed_streaming: bool = is_fast_fall_streaming or max_component_speed >= STREAM_PRESSURE_SPEED_THRESHOLD
	var stream_refresh_interval: int = NORMAL_STREAM_REFRESH_INTERVAL
	if is_extreme_streaming_speed:
		stream_refresh_interval = EXTREME_STREAM_REFRESH_INTERVAL
	elif is_high_speed_streaming:
		stream_refresh_interval = HIGH_SPEED_STREAM_REFRESH_INTERVAL
	elif is_fast_fall_streaming:
		stream_refresh_interval = FAST_FALL_STREAM_REFRESH_INTERVAL
	if not in_independent_encounter and InfiniteChunkManager and Engine.get_frames_drawn() % stream_refresh_interval == 0:
		var current_chunk := InfiniteChunkManager.get_chunk_coord(global_position)
		var should_refresh_vicinity: bool = (_last_streaming_chunk_coord == null or current_chunk != _last_streaming_chunk_coord)
		# 在低速/停下时定期触发一次邻域维护，回收移动期暂缓卸载的区块。
		if not should_refresh_vicinity and allow_stream_unload and Engine.get_frames_drawn() % 60 == 0:
			should_refresh_vicinity = true

		if should_refresh_vicinity:
			# 高速运动阶段扩大前向加载并暂停卸载，保证加载速度不落后于玩家位移速度。
			if is_high_speed_streaming:
				var fast_fall_vertical_radius: int = maxi(4, stream_vertical_radius + 1)
				var fast_radius_x: int = 1
				if absf(velocity.x) > 420.0:
					fast_radius_x = 2
				if is_extreme_streaming_speed:
					fast_radius_x = 3
				InfiniteChunkManager.update_player_vicinity(global_position, fast_radius_x, false, horizontal_stream_bias, fast_fall_vertical_radius)
			else:
				InfiniteChunkManager.update_player_vicinity(global_position, -1, allow_stream_unload, horizontal_stream_bias, stream_vertical_radius)
			_last_streaming_chunk_coord = current_chunk
		if MinimapManager:
			MinimapManager.reveal_area(global_position, 30) # 约 1.5 个屏幕半径的探索范围

	if _terrain_recovery_timer > 0.0:
		_terrain_recovery_timer = max(0.0, _terrain_recovery_timer - delta)
	if _footstep_timer > 0.0:
		_footstep_timer = max(0.0, _footstep_timer - delta)

	if action_cooldown > 0:
		action_cooldown -= delta
	
	# --- 击退衰减 ---
	if knockback_velocity.length_squared() > 100:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 1000 * delta)
	else:
		knockback_velocity = Vector2.ZERO

	_update_water_interaction_state(delta)

	if not input_enabled:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if not is_on_floor():
			if _gravity_enabled:
				if _water_state == WATER_STATE_DRY:
					velocity.y += GRAVITY * delta * _get_current_gravity_direction()
					_clamp_terminal_velocity_signed(TERMINAL_FALL_SPEED)
				else:
					_apply_water_vertical_forces(delta, false)
		if not in_independent_encounter:
			_mitigate_fast_fall_chunk_gaps()
		move_and_slide()
		if not in_independent_encounter:
			_recover_from_terrain_embed()
		return
		
	# --- 动作处理 ---
	if movement_locked:
		# DEBUG: 确保日志打印以帮助定位问题，以防万一还卡住
		if not _debug_lock_warned:
			print("Player WARNING: Movement locked while expecting to move!")
			_debug_lock_warned = true
	
	if not movement_locked:
		_handle_input_actions()
		
		# 鼠标动作逻辑（挖矿/攻击）
		var is_mining = false
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			# If wand is equipped, skip mining logic entirely to ensure wand fires
			if current_wand:
				is_mining = false
			else:
				is_mining = _handle_mouse_action()
		
		if not is_mining:
			_handle_continuous_actions()
	
	# --- 水平移动 ---
	var direction := 0.0
	if not movement_locked:
		direction = Input.get_axis("left", "right")
		if _is_mina_input_inverted():
			direction = -direction
		
	var accel_scale := float(_water_motion_profile.get("accel_scale", 1.0))
	var target_speed_x = direction * SPEED * float(_water_motion_profile.get("speed_scale", 1.0))
	
	# 平滑移动处理并叠加击退速度
	var current_move_x = velocity.x - knockback_velocity.x
	var movement_x = target_speed_x
	if direction == 0:
		movement_x = move_toward(current_move_x, 0, SPEED * 10.0 * accel_scale * delta)
	
	velocity.x = movement_x + knockback_velocity.x
	
	# --- 垂直运动 (跳跃与重力) ---
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		fall_time = 0.0
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	if not movement_locked and Input.is_action_just_pressed("space"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		_water_jump_ramp_scale = float(_water_motion_profile.get("jump_scale", 1.0))
		if _water_state == WATER_STATE_SWIMMING or _water_state == WATER_STATE_SUBMERGED:
			jump_ramp_timer = 0.0
			velocity.y = minf(velocity.y, -WATER_SWIM_UP_MAX_SPEED * 0.9)
		else:
			jump_ramp_timer = JUMP_RAMP_TIME
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		# 跳跃音效 - 根据需求已注释
		# if has_node("/root/AudioManager"):
		# 	get_node("/root/AudioManager").play_sfx("jump", -8.0, 0.2)

	if jump_ramp_timer > 0.0:
		velocity.y += JUMP_VELOCITY * _water_jump_ramp_scale * (delta / JUMP_RAMP_TIME) * _get_current_gravity_direction()
		jump_ramp_timer = max(0.0, jump_ramp_timer - delta)

	if not is_on_floor():
		if _gravity_enabled:
			if _water_state == WATER_STATE_DRY:
				var gravity_dir := _get_current_gravity_direction()
				if velocity.y * gravity_dir < 0.0:
					var is_holding_jump = (not movement_locked and Input.is_action_pressed("space"))
					var g_mult = GRAVITY_HOLD_MULTIPLIER if is_holding_jump else GRAVITY_RELEASE_MULTIPLIER
					velocity.y += GRAVITY * g_mult * delta * gravity_dir
				else:
					fall_time += delta
					var dynamic_fall_multiplier = clamp(GRAVITY_FALL_MULTIPLIER + fall_time * FALL_GRAVITY_GROWTH, GRAVITY_FALL_MULTIPLIER, 4.5)
					velocity.y += GRAVITY * dynamic_fall_multiplier * delta * gravity_dir
			else:
				_apply_water_vertical_forces(delta, not movement_locked)

		if _water_state == WATER_STATE_DRY:
			_clamp_terminal_velocity_signed(TERMINAL_FALL_SPEED)

	# --- 空气阻力 ---
	if velocity.length() > 0.0:
		velocity += (-velocity.normalized() * AIR_DRAG_COEFF * velocity.length_squared()) * delta

	if not in_independent_encounter:
		_mitigate_fast_fall_chunk_gaps()
		_mitigate_walk_chunk_gaps()

	# --- 物理执行与翻转 ---
	var was_on_floor = is_on_floor()
	move_and_slide()

	# World Wrapping Logic (Planetary Mode)
	if not in_independent_encounter and has_node("/root/WorldTopology"):
		var topology = get_node("/root/WorldTopology")
		if topology.has_method("is_planetary") and topology.is_planetary():
			# Single Source of Truth for Wrapping
			global_position.x = topology.wrap_x(global_position.x)

	if not in_independent_encounter:
		_recover_from_terrain_embed()
	
	# 落地音效
	if not was_on_floor and is_on_floor():
		_last_safe_ground_position = global_position
		_has_safe_ground_position = true
		# 检查垂直速度，只有达到一定速度（下落一定距离）才播放声音
		if abs(velocity.y) > 400 or (fall_time > 0.4): # fall_time 是 player.gd 中已有的变量
			if has_node("/root/AudioManager"):
				get_node("/root/AudioManager").play_sfx("land", -10.0, 0.2)
	elif is_on_floor():
		_last_safe_ground_position = global_position
		_has_safe_ground_position = true
	
	# Audio Footsteps
	if is_on_floor() and abs(velocity.x) > 10:
		var step_interval_sec: float = FOOTSTEP_INTERVAL_BASE
		if abs(velocity.x) > SPEED * 1.5:
			step_interval_sec = FOOTSTEP_INTERVAL_FAST

		if _footstep_timer <= 0.0 and has_node("/root/AudioManager"):
			var am = get_node("/root/AudioManager")
			var sound_to_play = "footstep"

			# 简单的地面检测（按步触发，不再每帧取模检测）
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 10))
			query.collision_mask = 1
			query.exclude = [get_rid()]
			var result = space_state.intersect_ray(query)

			if result and result.collider is TileMapLayer:
				var tm = result.collider
				var map_pos = tm.local_to_map(tm.to_local(result.position + Vector2(0, 2)))
				var atlas_coords = tm.get_cell_atlas_coords(map_pos)
				if atlas_coords == Vector2i(1, 0):
					sound_to_play = "footstep_grass"
				elif atlas_coords == Vector2i(0, 0):
					sound_to_play = "footstep_dirt"

			# 进一步降低 pitch 抖动，避免脚步音头部爆裂感。
			am.play_sfx(sound_to_play, -18.0, 0.02)
			_footstep_timer = step_interval_sec
	
	if min_visual and velocity.x != 0:
		min_visual.scale.x = abs(min_visual.scale.x) * sign(velocity.x)
	
	if is_on_wall() and was_on_floor:
		_handle_step_up()

	if not in_independent_encounter:
		_update_freefall_chunk_miss_timer(delta)
		_recover_from_long_freefall()

func _resolve_liquid_contact_amount(global_probe_pos: Vector2) -> float:
	if not LiquidManager or not LiquidManager.has_method("get_liquid_contact_at_global_position"):
		return 0.0
	var contact_variant = LiquidManager.get_liquid_contact_at_global_position(global_probe_pos)
	if not (contact_variant is Dictionary):
		return 0.0
	var contact: Dictionary = contact_variant
	if not bool(contact.get("in_liquid", false)):
		return 0.0
	if String(contact.get("type", "")) != "water":
		return 0.0
	return clampf(float(contact.get("amount", 0.0)), 0.0, 1.0)

func _sample_water_probe_amounts() -> Dictionary:
	var foot_probe := global_position + Vector2(0, 12)
	var torso_probe := global_position + Vector2(0, -2)
	var head_probe := global_position + Vector2(0, -18)
	var foot_amount := _resolve_liquid_contact_amount(foot_probe)
	var torso_amount := _resolve_liquid_contact_amount(torso_probe)
	var head_amount := _resolve_liquid_contact_amount(head_probe)
	return {
		"foot": foot_amount,
		"torso": torso_amount,
		"head": head_amount,
	}

func _resolve_water_state_from_probes(previous_state: String, foot_amount: float, torso_amount: float, head_amount: float, immersion: float) -> String:
	var target_state := WATER_STATE_DRY
	if head_amount >= WATER_ENTER_SUBMERGED_HEAD or immersion >= 0.82:
		target_state = WATER_STATE_SUBMERGED
	elif torso_amount >= WATER_ENTER_SWIMMING_TORSO or immersion >= 0.46:
		target_state = WATER_STATE_SWIMMING
	elif foot_amount >= WATER_ENTER_WADING or immersion >= WATER_ENTER_WADING:
		target_state = WATER_STATE_WADING

	if previous_state == WATER_STATE_SUBMERGED and head_amount >= WATER_EXIT_SUBMERGED_HEAD:
		return WATER_STATE_SUBMERGED
	if (previous_state == WATER_STATE_SWIMMING or previous_state == WATER_STATE_SUBMERGED) and torso_amount >= WATER_EXIT_SWIMMING_TORSO:
		if target_state == WATER_STATE_WADING or target_state == WATER_STATE_DRY:
			return WATER_STATE_SWIMMING
	if previous_state != WATER_STATE_DRY and foot_amount >= WATER_EXIT_WADING and target_state == WATER_STATE_DRY:
		return WATER_STATE_WADING

	return target_state

func _water_motion_profile_for_state(state: String, immersion: float) -> Dictionary:
	var clamped_immersion := clampf(immersion, 0.0, 1.0)
	var profile := {
		"speed_scale": 1.0,
		"accel_scale": 1.0,
		"gravity_scale": 1.0,
		"buoyancy": 0.0,
		"jump_scale": 1.0,
		"max_fall_speed": 99999.0,
	}

	match state:
		WATER_STATE_WADING:
			profile["speed_scale"] = lerpf(0.92, 0.82, clamped_immersion)
			profile["accel_scale"] = 0.86
			profile["gravity_scale"] = 0.64
			profile["buoyancy"] = 90.0
			profile["jump_scale"] = 0.72
			profile["max_fall_speed"] = 520.0
		WATER_STATE_SWIMMING:
			profile["speed_scale"] = lerpf(0.70, 0.58, clamped_immersion)
			profile["accel_scale"] = 0.64
			profile["gravity_scale"] = 0.36
			profile["buoyancy"] = lerpf(420.0, 560.0, clamped_immersion)
			profile["jump_scale"] = 0.52
			profile["max_fall_speed"] = 360.0
		WATER_STATE_SUBMERGED:
			profile["speed_scale"] = lerpf(0.58, 0.46, clamped_immersion)
			profile["accel_scale"] = 0.54
			profile["gravity_scale"] = 0.28
			profile["buoyancy"] = lerpf(600.0, 760.0, clamped_immersion)
			profile["jump_scale"] = 0.42
			profile["max_fall_speed"] = 260.0

	return profile

func _emit_water_event(event_name: String) -> void:
	var now_ms := Time.get_ticks_msec()
	var cooldown_ms := WATER_EVENT_COOLDOWN_MS
	if event_name == "underwater_loop":
		cooldown_ms = WATER_LOOP_EVENT_INTERVAL_MS
	var next_ms := int(_water_event_next_ms.get(event_name, 0))
	if now_ms < next_ms:
		return
	_water_event_next_ms[event_name] = now_ms + cooldown_ms

	water_interaction_event.emit(event_name, _water_immersion)
	if EventBus and EventBus.has_signal("player_water_interaction_event"):
		EventBus.player_water_interaction_event.emit(event_name, _water_immersion)

	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am and am.has_method("play_sfx"):
			match event_name:
				"enter_water":
					am.play_sfx("water_enter", -14.0, 0.04)
				"exit_water":
					am.play_sfx("water_exit", -16.0, 0.04)
				"surface_break":
					am.play_sfx("water_surface_break", -15.0, 0.05)
				"underwater_loop":
					am.play_sfx("water_swim_loop", -22.0, 0.03)

func _on_water_state_changed(previous_state: String, next_state: String) -> void:
	water_state_changed.emit(previous_state, next_state, _water_immersion)
	if EventBus and EventBus.has_signal("player_water_state_changed"):
		EventBus.player_water_state_changed.emit(next_state, _water_immersion)

	if previous_state == WATER_STATE_DRY and next_state != WATER_STATE_DRY:
		_emit_water_event("enter_water")
	elif previous_state != WATER_STATE_DRY and next_state == WATER_STATE_DRY:
		_emit_water_event("exit_water")

func _update_water_interaction_state(_delta: float) -> void:
	var previous_state := _water_state
	var previous_head_submerged := _water_head_submerged

	var probes := _sample_water_probe_amounts()
	_water_probe_foot = float(probes.get("foot", 0.0))
	_water_probe_torso = float(probes.get("torso", 0.0))
	_water_probe_head = float(probes.get("head", 0.0))
	_water_immersion = clampf(_water_probe_foot * 0.25 + _water_probe_torso * 0.45 + _water_probe_head * 0.30, 0.0, 1.0)
	_water_state = _resolve_water_state_from_probes(_water_state, _water_probe_foot, _water_probe_torso, _water_probe_head, _water_immersion)
	_water_motion_profile = _water_motion_profile_for_state(_water_state, _water_immersion)
	_water_head_submerged = _water_probe_head >= WATER_ENTER_SUBMERGED_HEAD

	if previous_state != _water_state:
		_on_water_state_changed(previous_state, _water_state)

	if previous_head_submerged != _water_head_submerged:
		_emit_water_event("surface_break")

	if (_water_state == WATER_STATE_SWIMMING or _water_state == WATER_STATE_SUBMERGED) and velocity.length() >= 45.0:
		_emit_water_event("underwater_loop")

func _apply_water_vertical_forces(delta: float, allow_swim_input: bool) -> void:
	var gravity_scale := float(_water_motion_profile.get("gravity_scale", 1.0))
	var buoyancy := float(_water_motion_profile.get("buoyancy", 0.0))
	var max_fall_speed := float(_water_motion_profile.get("max_fall_speed", 99999.0))
	var gravity_dir := _get_current_gravity_direction()

	velocity.y += GRAVITY * gravity_scale * delta * gravity_dir
	velocity.y -= buoyancy * maxf(_water_immersion, 0.2) * delta * gravity_dir

	if allow_swim_input and (_water_state == WATER_STATE_SWIMMING or _water_state == WATER_STATE_SUBMERGED) and Input.is_action_pressed("space"):
		velocity.y = move_toward(velocity.y, -WATER_SWIM_UP_MAX_SPEED * gravity_dir, WATER_SWIM_UP_ACCEL * delta)

	if velocity.y * gravity_dir > max_fall_speed:
		velocity.y = max_fall_speed * gravity_dir

func _attempt_execution() -> void:
	var enemies = get_tree().get_nodes_in_group("npcs")
	var closest: Node2D = null
	var min_dist = 200.0 # Increased range for execution (User Request: "延长斩杀判定距离")
	
	for enemy in enemies:
		# Check if property exists first
		if enemy.get("is_executable"):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = enemy
	
	if closest and closest.has_method("execute_by_player"):
		closest.execute_by_player(self)

func _handle_step_up() -> void:
	var direction = Input.get_axis("left", "right")
	if _is_mina_input_inverted():
		direction = -direction
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

func _mitigate_fast_fall_chunk_gaps() -> void:
	if not InfiniteChunkManager:
		return

	if is_on_floor() or velocity.y <= FALL_PRELOAD_SPEED_THRESHOLD:
		_last_fall_preload_chunk_coord = null
		return

	if Engine.get_frames_drawn() % FALL_PRELOAD_FRAME_INTERVAL != 0:
		return

	var feet_pos = global_position + Vector2(0, PLAYER_FEET_OFFSET)
	var lookahead = clamp(velocity.y * 0.25, FALL_PRELOAD_DISTANCE_MIN, FALL_PRELOAD_DISTANCE_MAX)
	var current_coord: Vector2i = InfiniteChunkManager.get_chunk_coord(feet_pos)
	var preload_coord: Vector2i = InfiniteChunkManager.get_chunk_coord(feet_pos + Vector2(0, lookahead))
	if _last_fall_preload_chunk_coord != null and preload_coord == _last_fall_preload_chunk_coord and preload_coord.y <= current_coord.y:
		return

	_last_fall_preload_chunk_coord = preload_coord
	var preload_targets: Array = []
	var y_start: int = current_coord.y + 1
	var y_end: int = preload_coord.y
	if y_end < y_start:
		y_start = y_end
		y_end = current_coord.y + 1
	var max_depth_span: int = 6
	var y_cursor: int = y_start
	while y_cursor <= y_end and preload_targets.size() < max_depth_span:
		preload_targets.append(Vector2i(preload_coord.x, y_cursor))
		y_cursor += 1

	# 高速下落且有横向速度时，预热一列侧向区块，减少对角坠落时的空白带。
	if abs(velocity.x) > 120.0:
		var side_x: int = preload_coord.x + (1 if velocity.x > 0.0 else -1)
		var side_targets: Array = []
		for target in preload_targets:
			if target is Vector2i:
				side_targets.append(Vector2i(side_x, target.y))
		preload_targets.append_array(side_targets)

	if preload_targets.is_empty():
		preload_targets.append(preload_coord)
	InfiniteChunkManager.prime_required_chunks(preload_targets)
	_try_emergency_sync_stream_guard(feet_pos + Vector2(0, lookahead), preload_coord)

func _mitigate_walk_chunk_gaps() -> void:
	if not InfiniteChunkManager:
		return
	var horizontal_speed: float = absf(velocity.x)
	if not is_on_floor() or horizontal_speed < 40.0:
		_last_walk_preload_chunk_coord = null
		return

	var preload_interval := WALK_AHEAD_PRELOAD_FRAME_INTERVAL
	if horizontal_speed > STREAM_PRESSURE_SPEED_THRESHOLD_EXTREME:
		preload_interval = 2
	elif horizontal_speed > STREAM_PRESSURE_SPEED_THRESHOLD:
		preload_interval = 4
	if Engine.get_frames_drawn() % preload_interval != 0:
		return

	var ahead_dir := 1.0 if velocity.x > 0.0 else -1.0
	var lookahead_distance := clampf(horizontal_speed * WALK_AHEAD_PRELOAD_DISTANCE_FACTOR, WALK_AHEAD_PRELOAD_DISTANCE, WALK_AHEAD_PRELOAD_DISTANCE_MAX)
	var feet_pos := global_position + Vector2(0, PLAYER_FEET_OFFSET)
	var current_coord: Vector2i = InfiniteChunkManager.get_chunk_coord(feet_pos)
	var ahead_pos := global_position + Vector2(ahead_dir * lookahead_distance, PLAYER_FEET_OFFSET)
	var preload_coord: Vector2i = InfiniteChunkManager.get_chunk_coord(ahead_pos)
	if _last_walk_preload_chunk_coord != null and preload_coord == _last_walk_preload_chunk_coord:
		return

	_last_walk_preload_chunk_coord = preload_coord
	var preload_targets: Array = []
	var direction_sign: int = 1 if preload_coord.x >= current_coord.x else -1
	var x_cursor: int = current_coord.x + direction_sign
	var max_forward_span: int = 5
	while direction_sign > 0 and x_cursor <= preload_coord.x and preload_targets.size() < max_forward_span:
		preload_targets.append(Vector2i(x_cursor, current_coord.y))
		x_cursor += 1
	while direction_sign < 0 and x_cursor >= preload_coord.x and preload_targets.size() < max_forward_span:
		preload_targets.append(Vector2i(x_cursor, current_coord.y))
		x_cursor -= 1

	if preload_targets.is_empty():
		preload_targets.append(preload_coord)
	InfiniteChunkManager.prime_required_chunks(preload_targets)
	_try_emergency_sync_stream_guard(ahead_pos, preload_coord)
	_try_walk_sync_stream_guard(ahead_pos, preload_coord, horizontal_speed)

func _try_emergency_sync_stream_guard(target_world_pos: Vector2, target_chunk: Vector2i) -> void:
	if not InfiniteChunkManager:
		return
	if not InfiniteChunkManager.has_method("force_load_at_world_pos"):
		return
	if not InfiniteChunkManager.has_method("is_chunk_loaded"):
		return

	var max_component_speed := maxf(absf(velocity.x), absf(velocity.y))
	if max_component_speed < STREAM_PRESSURE_SPEED_THRESHOLD_EXTREME:
		return

	if bool(InfiniteChunkManager.is_chunk_loaded(target_chunk)):
		return

	var now_msec := Time.get_ticks_msec()
	if _last_emergency_sync_chunk_coord != null and target_chunk == _last_emergency_sync_chunk_coord and now_msec - _last_emergency_sync_load_msec < EMERGENCY_SYNC_LOAD_COOLDOWN_MS:
		return

	InfiniteChunkManager.force_load_at_world_pos(target_world_pos)
	_last_emergency_sync_chunk_coord = target_chunk
	_last_emergency_sync_load_msec = now_msec

func _try_walk_sync_stream_guard(target_world_pos: Vector2, target_chunk: Vector2i, horizontal_speed: float) -> void:
	if not InfiniteChunkManager:
		return
	if not InfiniteChunkManager.has_method("force_load_at_world_pos"):
		return
	if not InfiniteChunkManager.has_method("is_chunk_loaded"):
		return
	if not is_on_floor() or horizontal_speed < WALK_SYNC_GUARD_MIN_SPEED:
		return
	if bool(InfiniteChunkManager.is_chunk_loaded(target_chunk)):
		return

	var now_msec := Time.get_ticks_msec()
	if _last_walk_sync_guard_chunk_coord != null and target_chunk == _last_walk_sync_guard_chunk_coord and now_msec - _last_walk_sync_guard_msec < WALK_SYNC_GUARD_COOLDOWN_MS:
		return

	InfiniteChunkManager.force_load_at_world_pos(target_world_pos)
	_last_walk_sync_guard_chunk_coord = target_chunk
	_last_walk_sync_guard_msec = now_msec

func _update_freefall_chunk_miss_timer(delta: float) -> void:
	if not InfiniteChunkManager or not InfiniteChunkManager.has_method("is_world_pos_chunk_loaded"):
		_freefall_chunk_miss_time = 0.0
		return
	if is_on_floor() or velocity.y < FREEFALL_RESCUE_MIN_SPEED:
		_freefall_chunk_miss_time = 0.0
		return

	var probe_pos := global_position + Vector2(0, PLAYER_FEET_OFFSET)
	if bool(InfiniteChunkManager.is_world_pos_chunk_loaded(probe_pos)):
		_freefall_chunk_miss_time = 0.0
	else:
		_freefall_chunk_miss_time += delta

func _recover_from_terrain_embed() -> void:
	if not InfiniteChunkManager or _terrain_recovery_timer > 0.0:
		return
	if not _is_embedded_in_terrain():
		return

	var safe_pos = InfiniteChunkManager.find_safe_ground(global_position, 256.0)
	if safe_pos == null:
		return

	global_position = safe_pos
	velocity.y = min(velocity.y, 0.0)
	_terrain_recovery_timer = TERRAIN_RECOVERY_COOLDOWN

func _recover_from_long_freefall() -> void:
	if not InfiniteChunkManager:
		return
	if is_on_floor() or fall_time < FREEFALL_RESCUE_TIME or velocity.y < FREEFALL_RESCUE_MIN_SPEED:
		return
	if _freefall_chunk_miss_time < FREEFALL_RESCUE_CHUNK_MISS_TIME:
		return
	if not _has_safe_ground_position:
		return

	var rescue_pos = InfiniteChunkManager.find_safe_ground(_last_safe_ground_position, 256.0)
	if rescue_pos == null:
		rescue_pos = _last_safe_ground_position

	global_position = rescue_pos
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	fall_time = 0.0
	jump_ramp_timer = 0.0
	coyote_timer = COYOTE_TIME
	jump_buffer_timer = 0.0
	_terrain_recovery_timer = TERRAIN_RECOVERY_COOLDOWN
	print("Player: freefall rescue triggered at ", global_position)

func _is_embedded_in_terrain() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	var gen = tree.get_first_node_in_group("world_generator")
	if not gen or not gen.layer_0:
		return false

	var sample_points = [
		global_position,
		global_position + Vector2(0, -10),
		global_position + Vector2(0, 4)
	]

	for sample in sample_points:
		var map_pos = gen.layer_0.local_to_map(TransformHelper.safe_to_local(gen.layer_0, sample))
		if _is_solid_map_cell(gen, map_pos):
			return true

	return false

func _is_solid_map_cell(gen, map_pos: Vector2i) -> bool:
	if _is_physical_map_cell(gen.layer_0, map_pos):
		return true
	if _is_physical_map_cell(gen.layer_1, map_pos):
		return true
	if _is_physical_map_cell(gen.layer_2, map_pos):
		return true
	return false

func _is_physical_map_cell(layer: TileMapLayer, map_pos: Vector2i) -> bool:
	if not layer or not layer.collision_enabled:
		return false
	return layer.get_cell_source_id(map_pos) != -1

func _handle_continuous_actions() -> void:
	if not input_enabled:
		return
	
	# 魔杖自动连发逻辑
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# 如果装备了魔杖，优先使用魔杖，且阻止挖掘/近战？
		if current_wand:
			if _is_mina_projectile_locked():
				if _mina_projectile_lock_feedback_cooldown <= 0.0 and UIManager:
					UIManager.show_floating_text("投射封锁", global_position + Vector2(0, -34), Color(1.0, 0.4, 0.4))
					_mina_projectile_lock_feedback_cooldown = 0.8
				return
			if action_cooldown <= 0.0:
				var cast_transform = get_spell_spawn_transform()
				var dir = cast_transform.get("direction", Vector2.RIGHT)
				var spawn_pos = cast_transform.get("position", global_position)
				
				# Call Cast Spell - returns internal duration + recharge + delay
				var total_cooldown = SpellProcessor.cast_spell(current_wand, self, dir, spawn_pos)
				
				# 发射音效 (根据魔杖类型可以做区分，此处使用通用音效)
				if total_cooldown > 0: # 确认施法成功（非冷却中）
					if has_node("/root/AudioManager"):
						get_node("/root/AudioManager").play_sfx("spell_fire", -6.0, 0.3)
				
				# Action cooldown prevents firing until sequence is done
				action_cooldown = max(total_cooldown, 0.05) # Minimum speed cap
				# print("Player: Cast Spell. Cooldown set: ", action_cooldown)
		else:
			pass # Normal mining/melee handled in _handle_mouse_action or elsewhere

func _handle_input_actions() -> void:
	# --- Cheats (Request 6 & 7) ---
	if Input.is_physical_key_pressed(KEY_I) and Input.is_physical_key_pressed(KEY_ALT):
		invincible = !invincible
		print("Cheat: Invincibility = ", invincible)
		
	if Input.is_physical_key_pressed(KEY_H) and Input.is_physical_key_pressed(KEY_ALT):
		_cheat_build_house()
		
	if Input.is_key_pressed(KEY_F):
		_attempt_execution()

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
				var local_pos = tile_map.to_local(mouse_pos)
				var map_pos = tile_map.local_to_map(local_pos)
				is_mining_target = GameState.digging.has_mineable_tile_at(map_pos)
		
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
	
	# 如果刚刚结束建造（防止一次点击同时完成放置和挖掘）
	if action_cooldown > 0:
		return false

	# 检查当前装备是否为工具

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
			var has_tile = GameState.digging.has_mineable_tile_at(map_pos)

			# 检查距离，防止全屏挖掘
			if global_position.distance_to(mouse_pos) < 150:
				if has_tile:
					# 如果切换了瓦片，重置旧瓦片的进度
					if current_mining_tile != map_pos:
						if current_mining_tile != Vector2i(-1, -1):
							GameState.digging.reset_mining_progress(current_mining_tile)
						current_mining_tile = map_pos
					
					var power = 0 
					GameState.digging.mine_tile_step(map_pos, get_physics_process_delta_time(), power)
					return true
				else:
					# 检查是否有可挖掘建筑
					# 统一检查所有可破坏物组
					var buildings = []
					buildings.append_array(get_tree().get_nodes_in_group("doors"))
					buildings.append_array(get_tree().get_nodes_in_group("tables"))
					buildings.append_array(get_tree().get_nodes_in_group("chairs"))
					buildings.append_array(get_tree().get_nodes_in_group("torches"))
					buildings.append_array(get_tree().get_nodes_in_group("housing_furniture"))
					
					for b in buildings:
						if not is_instance_valid(b): continue
						
						# 使用简单的碰撞矩形或距离检查
						# 必须转换到局部坐标检查点击位置
						var local_m_pos = TransformHelper.safe_to_local(b, get_global_mouse_position()) # Use global mouse pos (safe)
						
						# 假设建筑大小约为 1-2 格 (16-32px)
						#稍微放宽检测范围
						if abs(local_m_pos.x) < 24 and abs(local_m_pos.y) < 24:
							GameState.digging.mine_building_step(b, get_physics_process_delta_time(), 0)
							return true

			# 超出距离或无瓦片/建筑，重置进度
			if current_mining_tile != Vector2i(-1, -1):
				GameState.digging.reset_mining_progress(current_mining_tile)
				current_mining_tile = Vector2i(-1, -1)
	
	return false

func _try_place_held_item() -> void:
	if not inventory: return
	
	var item = inventory.get_equipped_item() 
	if not item: return
	
	# 检查是否是可放置物品
	# 改为统一的左键点击启动建造模式逻辑
	var bm = get_tree().get_first_node_in_group("building_manager")
	if not bm: return
	
	# 如果已经在建造中，则忽略，防止冲突
	# 但如果我们要“切换”建筑，可能需要逻辑
	
	# 1. 优先处理瓦片物品 (泥土、石头等)，确保不会被建筑数据库拦截
	if item is TileItemData:
		bm.start_building(item)
		return

	# 2. 检查元数据中是否有预载的建筑资源 (针对门、桌子、火把等)
	if item.has_meta("building_resource"):
		# 传递 override cost，确保消耗物品本身而不是原材料
		bm.start_building(item.get_meta("building_resource"), { item.id: 1 })
		return

	# 3. 检查全局建筑数据库 (解决掉落物捡回后丢失元数据的问题)
	if GameState.building_db.has(item.id):
		bm.start_building(GameState.building_db[item.id], { item.id: 1 })
		return

func _interact() -> void:
	var boss_encounter_manager = _find_boss_encounter_manager()
	if boss_encounter_manager and boss_encounter_manager.has_method("try_start_encounter_from_player"):
		if boss_encounter_manager.try_start_encounter_from_player(self):
			return

	if not interaction_area:
		return
		
	# 检查 Area 检测到的可交互对象
	var areas = interaction_area.get_overlapping_areas()
	for area in areas:
		if area.has_method("interact"):
			area.interact(self)
			return
		elif area.get_parent() and area.get_parent().has_method("interact"):
			area.get_parent().interact(self)
			return

	# 检查 Body 检测到的可交互对象 (例如静态物块、宝箱)
	var bodies = interaction_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("interact"):
			body.interact(self)
			return
		elif body.get_parent() and body.get_parent().has_method("interact"):
			body.get_parent().interact(self)
			return

func _find_boss_encounter_manager() -> Node:
	return get_node_or_null("/root/BossEncounterManager")

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
		var attack_damage := 10.0 * get_combat_damage_multiplier()
		
		# Improved Combat Feedback: Use CombatManager
		if CombatManager:
			# Consider windup time? For now, instant hit is fine for 2D feeling unless we have complex animation
			CombatManager.deal_damage(self, target, attack_damage, "physical") 
			print("Player: 攻击实体: ", target.name)
		elif target.has_method("take_damage"):
			target.take_damage(attack_damage) # Fallback
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

func _cheat_build_house():
	# Request 7: Instant House Cheat
	var mpos = get_global_mouse_position()
	DebugTools.build_instant_house(mpos)

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
