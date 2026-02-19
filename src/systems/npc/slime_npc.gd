extends BaseNPC
class_name SlimeNPC

# --- Configuration ---
@export_group("Slime Settings")
@export var size_category: String = "small" # tiny, small, medium, large, king
@export var jump_windup_time: float = 0.6 # Increased for anticipation
@export var jump_cooldown: float = 1.5
@export var jump_gravity: float = 2000.0 # Heavy gravity
@export var jump_apex_height: float = 150.0 # Fixed height above target
@export var detection_radius: float = 600.0 

# --- State Machine ---
enum SlimeState { IDLE, CHASE, JUMP_PREPARE, JUMP_AIRBORNE, LAND_RECOVER }
var current_state: SlimeState = SlimeState.IDLE
var state_timer: float = 0.0

# --- Runtime Variables ---
var target: Node2D = null
var last_damage_time: float = 0.0
var damage_cooldown: float = 0.5
var original_scale: Vector2 = Vector2.ONE
var last_jump_time: float = 0.0
var squash_scale: Vector2 = Vector2.ONE # Visual scaling factor

# --- Visuals ---
var _visual_tween: Tween

# --- Signals ---
signal slime_jumped
signal slime_landed

func _ready() -> void:
	super._ready() 
	add_to_group("enemies") 
	if min_visual:
		original_scale = min_visual.scale
		squash_scale = original_scale  # Initialize

	
	# --- Collision Setup for Instant Contact Damage ---
	var contact_area = Area2D.new()
	contact_area.name = "ContactDamageArea"
	add_child(contact_area)
	
	var collision_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 20.0 
	collision_shape.shape = circle
	contact_area.add_child(collision_shape)
	
	contact_area.collision_layer = 0
	contact_area.collision_mask = LayerManager.LAYER_PLAYER
	contact_area.body_entered.connect(_on_contact_area_body_entered)
	
	ai_type = AIType.FIGHTER
	
	if npc_data:
		speed = npc_data.speed
	
	state_timer = randf_range(0.0, 1.0)

func _physics_process(delta: float) -> void:
	state_timer += delta
	
	_update_perception()
	
	if stun_timer <= 0:
		match current_state:
			SlimeState.IDLE:     _update_idle(delta)
			SlimeState.CHASE:    _update_chase(delta)
			SlimeState.JUMP_PREPARE: _update_jump_prepare(delta)
			SlimeState.JUMP_AIRBORNE: _update_jump_airborne(delta)
			SlimeState.LAND_RECOVER: _update_land_recover(delta)
	
	# Gravity - Only apply if airborne or falling
	if not is_on_floor():
		velocity.y += jump_gravity * delta
		# Air drag
		velocity.x = move_toward(velocity.x, 0, 50 * delta)
	else:
		# Rapid friction on ground
		velocity.x = move_toward(velocity.x, 0, 1500 * delta)

	move_and_slide()
	
	_update_visuals(delta)
	_check_contact_damage()
	
	if hp_bar: _update_hp_bar()

# --- State Logic ---

func _change_state(new_state: SlimeState) -> void:
	current_state = new_state
	state_timer = 0.0
	
	# Kill previous tween
	if _visual_tween:
		_visual_tween.kill()
	_visual_tween = null

	if not min_visual:
		return

	# Create a new tween only once we know visuals exist
	_visual_tween = create_tween().set_parallel(true)
	
	match new_state:
		SlimeState.IDLE:
			# Breathe
			_visual_tween.set_loops(0) # 0 means infinite loops in most versions but check Godot 4
			_visual_tween.tween_property(self, "squash_scale", Vector2(1.05, 0.95) * abs(original_scale.x), 1.0)
			_visual_tween.tween_property(self, "squash_scale", Vector2(0.95, 1.05) * abs(original_scale.x), 1.0)
			
		SlimeState.JUMP_PREPARE:
			# Windup: Flatten
			_visual_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			_visual_tween.tween_property(self, "squash_scale", Vector2(1.4, 0.6) * abs(original_scale.x), jump_windup_time)
			_visual_tween.tween_property(min_visual, "position:y", 5.0, jump_windup_time) # Center shift
			
			# Flash Warning - Just do a simple back and forth without set_loops on tweener
			_visual_tween.tween_property(min_visual, "modulate", Color(1.5, 0.8, 0.8), jump_windup_time / 2.0)
			_visual_tween.tween_property(min_visual, "modulate", Color.WHITE, jump_windup_time / 2.0).set_delay(jump_windup_time / 2.0)
			
		SlimeState.JUMP_AIRBORNE:
			slime_jumped.emit()
			# Launch: Stretch
			_visual_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
			_visual_tween.tween_property(self, "squash_scale", Vector2(0.7, 1.3) * abs(original_scale.x), 0.3)
			_visual_tween.tween_property(min_visual, "position:y", 0.0, 0.1)
			_visual_tween.tween_property(min_visual, "modulate", Color.WHITE, 0.1)
			
		SlimeState.LAND_RECOVER:
			var impact = min(400.0, abs(velocity.y)) / 400.0
			slime_landed.emit()
			# Impact: SQUASH hard
			_visual_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
			_visual_tween.tween_property(self, "squash_scale", Vector2(1.5, 0.5) * abs(original_scale.x), 0.1)
			_visual_tween.tween_property(self, "squash_scale", original_scale, 0.4).set_delay(0.1)
			
			# Screen Shake on Land
			if CombatManager and is_instance_valid(target) and global_position.distance_to(target.global_position) < 300:
				CombatManager._trigger_screen_shake(0.2, 5.0 * impact) # Explicitly call internal or public shake

func _update_idle(_delta: float) -> void:
	if target:
		_change_state(SlimeState.CHASE)
		return
	if state_timer > randf_range(2.0, 4.0):
		_decide_jump(null)

func _update_chase(_delta: float) -> void:
	if not is_instance_valid(target):
		_change_state(SlimeState.IDLE)
		return
		
	# Decisions
	var dist = global_position.distance_to(target.global_position)
	var time_since_jump = Time.get_ticks_msec() / 1000.0 - last_jump_time
	
	if is_on_floor() and time_since_jump > jump_cooldown:
		if dist < 400: # Aggro range
			_decide_jump(target)
		elif dist > 800: # Give up
			_change_state(SlimeState.IDLE)

func _update_jump_prepare(_delta: float) -> void:
	if state_timer >= jump_windup_time:
		_execute_jump()

func _update_jump_airborne(_delta: float) -> void:
	if is_on_floor() and velocity.y >= 0:
		_change_state(SlimeState.LAND_RECOVER)
		
	# Rotate based on velocity for juice
	if min_visual:
		var rotation_target = velocity.x * 0.001
		min_visual.rotation = lerp_angle(min_visual.rotation, rotation_target, 0.1)

func _update_land_recover(_delta: float) -> void:
	if min_visual: min_visual.rotation = lerp_angle(min_visual.rotation, 0.0, 0.2)
	if state_timer >= 0.4:
		_change_state(SlimeState.IDLE) # Go to Idle first to allow cooldown

# --- Physics Calculation ---

var pending_velocity: Vector2

func _decide_jump(jump_target: Node2D) -> void:
	if jump_target:
		# 1. 预测目标位置 (针对玩家移动进行预判)
		var target_pos = jump_target.global_position
		if jump_target is CharacterBody2D:
			# 根据预估跳跃时间(约0.6s)预判玩家位置
			target_pos += jump_target.velocity * 0.6 
		
		# 2. 物理求解：斜向跳跃抛物线 (Fixed Height Arc)
		var start_pos = global_position
		
		# 确保斜跳弧度：计算相对于水平面最高点 (Apex)
		# 这里的 jump_apex_height 是相对于起跳点和落点中较高的那个再往上加的高度
		var max_h = min(start_pos.y, target_pos.y) - jump_apex_height
		var h_disp = start_pos.y - max_h # 向上位移
		
		# 起跳纵向速度 v_y: v^2 = u^2 + 2as -> uy = sqrt(2gh)
		var vy = -sqrt(2 * jump_gravity * h_disp)
		
		# 计算到达最高点的时间
		var t_up = -vy / jump_gravity
		
		# 计算从最高点落到目标点的时间
		var down_disp = target_pos.y - max_h 
		var t_down = sqrt(max(0, 2 * down_disp / jump_gravity))
		
		var total_time = t_up + t_down
		
		# 关键：计算斜度 (水平速度 vx = 距离 / 总飞行时间)
		var dx = target_pos.x - start_pos.x
		var vx = dx / total_time
		
		# 限制最大斜度/初速度，防止由于计算偏差导致的“瞬移”
		vx = clamp(vx, -1000, 1000)
		
		# 赋予斜向扑杀力量
		pending_velocity = Vector2(vx, vy)
		
	else:
		# 随机斜跳 (游荡模式)
		var dir = 1 if randf() > 0.5 else -1
		pending_velocity = Vector2(dir * randf_range(150, 300), -650)
	
	last_jump_time = Time.get_ticks_msec() / 1000.0
	_change_state(SlimeState.JUMP_PREPARE)

func _execute_jump() -> void:
	velocity = pending_velocity
	# Snap up slightly to avoid "stuck on floor" for one frame
	global_position.y -= 2.0 
	_change_state(SlimeState.JUMP_AIRBORNE)


# --- Perception ---

func _update_perception() -> void:
	if target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist > detection_radius * 1.5:
			target = null # Lost detection
	else:
		# Find new target
		var players = get_tree().get_nodes_in_group("player")
		for p in players:
			if global_position.distance_to(p.global_position) < detection_radius:
				target = p
				break

# --- Combat ---

func _on_contact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		if Time.get_ticks_msec() / 1000.0 - last_damage_time < damage_cooldown:
			return
			
		_apply_damage(body)
		last_damage_time = Time.get_ticks_msec() / 1000.0
		
		# Recoil the slime
		var recoil_dir = sign(global_position.x - body.global_position.x)
		if recoil_dir == 0: recoil_dir = 1.0
		velocity.x = recoil_dir * 300
		velocity.y = -200
		_change_state(SlimeState.JUMP_AIRBORNE)

func _check_contact_damage() -> void:
	# Already handled by _on_contact_area_body_entered
	pass

func _apply_damage(player: Node) -> void:
	var damage_amount = 10.0
	
	# Determine knockback direction (centralized in CombatManager, but we pass custom data if needed)
	if CombatManager:
		CombatManager.deal_damage(self, player, damage_amount, "physical")
	else:
		player.take_damage(damage_amount, "physical")
		if player.has_method("apply_knockback"):
			var kb_dir = (player.global_position - global_position).normalized()
			player.apply_knockback(kb_dir * 400.0)

# --- Visuals ---

func _update_visuals(_delta: float) -> void:
	if not min_visual: return
	
	# Apply squash scale with facing direction
	var sign_x = 1.0
	if velocity.x != 0:
		sign_x = sign(velocity.x)
	elif min_visual.scale.x != 0:
		sign_x = sign(min_visual.scale.x)
		
	min_visual.scale.x = abs(squash_scale.x) * sign_x
	min_visual.scale.y = abs(squash_scale.y)
