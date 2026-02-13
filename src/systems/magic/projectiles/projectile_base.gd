extends CharacterBody2D
class_name ProjectileBase

# Visuals
@onready var visual = $VisualRect
@onready var collision = $CollisionShape2D

# Stats
var velocity_vector: Vector2 = Vector2.ZERO
var speed: float = 800.0
var lifetime: float = 5.0
var damage: float = 10.0
var element: String = "none"
var max_bounces: int = 3 # Magic bouncing
var _current_bounces: int = 0
var special_behavior: String = ""
var caster: Node2D

# Logic
var modifiers: Array = []
var _fly_time: float = 0.0

# Components
var trail: Line2D

func setup(params: Dictionary, mods: Array):
	if "speed" in params: speed = float(params.speed)
	if "lifetime" in params: lifetime = float(params.lifetime)
	if "damage" in params: damage = float(params.damage)
	if "element" in params: element = params.element
	if "projectile_id" in params: special_behavior = params.projectile_id
	
	modifiers = mods
	_apply_modifiers_stat_change()
	
	velocity_vector = Vector2.RIGHT.rotated(rotation) * speed

func _apply_modifiers_stat_change():
	for mod in modifiers:
		var type = mod.get("wand_logic_type", "")
		if type == "": type = mod.get("type", "") 
		
		var val = mod.get("value", {})
		if val.is_empty(): val = mod.get("wand_logic_value", {})
		
		if type == "modifier_speed":
			speed *= 1.5 
		elif type == "modifier_damage":
			var amt = val.get("amount", 5)
			damage += float(amt)
		elif type == "modifier_element":
			element = val.get("element", "none")
			
	_update_visuals()

func _update_visuals():
	if not visual: return
	
	# Clear old particles to avoid stacking on re-updates
	for child in get_children():
		if child is CPUParticles2D:
			child.queue_free()
	
	visual.color = Color.WHITE # Base reset
	
	# Apply Base Element from params
	if element != "none":
		_add_elemental_effect(element)
	
	for mod in modifiers:
		var type = mod.get("wand_logic_type", "")
		if type == "": type = mod.get("type", "") 
		var val = mod.get("value", {})
		if val.is_empty(): val = mod.get("wand_logic_value", {})
		
		# Overlay stacking visual effects
		if type == "modifier_element":
			var el = val.get("element", "none")
			_add_elemental_effect(el)

	if special_behavior != "":
		_add_special_effect(special_behavior)

	# Final pass for default fallback if nothing was applied
	if element == "none" and not _has_elemental_mod() and special_behavior == "":
		if self is TriggerBase:
			visual.color = Color(1.0, 0.8, 0.0) 
			visual.size = Vector2(10, 10)
		else:
			# Default projectile: Long and white
			visual.color = Color(1.0, 1.0, 1.0)
			visual.size = Vector2(16, 4)
	
	# Ensure visual is centered
	if visual:
		visual.position = -visual.size / 2

func _has_elemental_mod() -> bool:
	for mod in modifiers:
		var type = mod.get("wand_logic_type", "")
		if type == "": type = mod.get("type", "") 
		if type == "modifier_element": return true
	return false

func _add_elemental_effect(type: String):
	if type == "none": return
	
	# Procedurally create particles if resources missing
	if type == "fire":
		var particles = CPUParticles2D.new()
		particles.amount = 15
		particles.lifetime = 0.5
		particles.direction = Vector2(-0.5, 0)
		particles.spread = 30.0
		particles.gravity = Vector2(0, -20)
		particles.initial_velocity_min = 30
		particles.initial_velocity_max = 60
		particles.scale_amount_min = 2.0
		particles.scale_amount_max = 5.0
		particles.color = Color(1.0, 0.4, 0.0)
		particles.color_ramp = Gradient.new()
		particles.color_ramp.add_point(0.0, Color(1, 1, 0))
		particles.color_ramp.add_point(1.0, Color(1, 0, 0, 0))
		add_child(particles)
		visual.color = visual.color.lerp(Color(1, 0.5, 0.2), 0.7)
		
	elif type == "ice":
		var particles = CPUParticles2D.new()
		particles.amount = 12
		particles.lifetime = 0.7
		particles.gravity = Vector2(0, 30)
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = 6.0
		particles.color = Color(0.5, 0.9, 1.0)
		particles.scale_amount_min = 1.0
		particles.scale_amount_max = 4.0
		add_child(particles)
		visual.color = visual.color.lerp(Color(0.4, 0.7, 1.0), 0.7)

	elif type == "slime":
		var particles = CPUParticles2D.new()
		particles.name = "SlimeParticles"
		particles.amount = 20 # More particles
		particles.lifetime = 0.8
		particles.direction = Vector2(0, 1) # Dripping down
		particles.spread = 45.0
		particles.gravity = Vector2(0, 120) # Heavy dripping
		particles.initial_velocity_min = 10
		particles.initial_velocity_max = 30
		particles.scale_amount_min = 3.0
		particles.scale_amount_max = 6.0
		particles.color = Color(0.0, 1.0, 0.0, 0.9) # Bright Lime
		add_child(particles)
		
		visual.color = Color(0.1, 0.9, 0.1) # Vibrant Green
		visual.size = Vector2(14, 14) # Even chunkier (Slime ball)

	# Safety: Ensure following logic always centers the visual
	if visual:
		visual.position = -visual.size / 2

func _add_special_effect(type: String):
	if type == "tnt":
		visual.color = Color(0.8, 0.3, 0.2)
		visual.size = Vector2(14, 14)
		var p = CPUParticles2D.new()
		p.amount = 10
		p.lifetime = 0.3
		p.gravity = Vector2(0, -98)
		p.color = Color(1, 1, 0)
		p.scale_amount_min = 2.0
		add_child(p)
		
	elif type == "blackhole":
		visual.color = Color(0.05, 0.0, 0.1)
		visual.size = Vector2(16, 16)
		var p = CPUParticles2D.new()
		p.amount = 30
		p.lifetime = 0.8
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 40.0
		p.gravity = Vector2.ZERO
		p.radial_accel_min = -60.0
		p.radial_accel_max = -100.0
		p.scale_amount_min = 2.0
		p.color = Color(0.5, 0.0, 1.0)
		add_child(p)
		
	elif type == "teleport":
		visual.color = Color(0.6, 0.2, 0.8)
		visual.size = Vector2(10, 10)
		var p = CPUParticles2D.new()
		p.local_coords = false
		p.amount = 15
		p.lifetime = 0.5
		p.gravity = Vector2.ZERO
		p.color_ramp = Gradient.new()
		p.color_ramp.add_point(0.0, Color(0.6, 0.2, 0.8, 1))
		p.color_ramp.add_point(1.0, Color(1, 1, 1, 0))
		add_child(p)

func _ready():
	_update_visuals()
	_create_trail()

func _create_trail():
	trail = Line2D.new()
	trail.width = 4.0
	trail.top_level = true
	
	# Trail Color matching the projectile
	var col = visual.color if visual else Color.WHITE
	trail.default_color = col
	
	# Fade out gradient
	var grad = Gradient.new()
	grad.set_color(0, Color(col.r, col.g, col.b, 0.0)) # Tail
	grad.set_color(1, col) # Head
	trail.gradient = grad
	
	add_child(trail)

func _process_behavior(delta: float):
	if special_behavior == "blackhole":
		var dm = get_tree().get_first_node_in_group("digging_manager")
		if dm:
			# Blackhole dissolves continuously
			dm.dissolve_at(global_position, 32.0)

func _physics_process(delta):
	_fly_time += delta
	
	_process_behavior(delta)
	
	if _fly_time >= lifetime:
		_on_lifetime_expired()
		return
		
	# Update Trail
	if trail:
		trail.add_point(global_position)
		if trail.get_point_count() > 15:
			trail.remove_point(0)

	# Movement: Use move_and_collide for precise bouncing
	var collision = move_and_collide(velocity_vector * delta)
	if collision:
		_on_hit(collision)

func _on_hit(col: KinematicCollision2D):
	if special_behavior == "tnt":
		_explode()
		return
	
	if special_behavior == "blackhole":
		# Blackholes do not bounce or stop; they eat matter.
		return

	# Subclasses can override _trigger_collision_logic to intercept this.
	# But ProjectileBase itself should NOT have that method to avoid intercepting itself.
	# We use a trick: check if "self" (the instance) has the method, but define it ONLY in subclasses?
	# No, GDScript can't dynamically remove methods.
	# Instead, verify if the subclass implements a specific hook.
	
	# Attempt 2: Explicit Check
	if self is TriggerBase or has_method("start_collision_logic"): 
		# If subclass has the old hook name (renaming required in subclass?)
		# Or rely on specific check
		pass
		
	# Better: Just check if the method exists AND it's not the dummy one?
	# Or, let's just make TriggerBase implement the hook.
	
	if has_method("_custom_trigger_hit"):
		call("_custom_trigger_hit", col)
		return

	# Standard Bounce behavior
	var collider = col.get_collider()
	var hit_enemy = false
	
	if collider.has_method("take_damage"):
		# Use CombatManager to handle juice (knockback, shake, etc)
		if CombatManager:
			CombatManager.deal_damage(self, collider, damage, element)
		else:
			collider.take_damage(damage, element)
		hit_enemy = true
		
	if hit_enemy:
		if special_behavior == "teleport":
			_teleport_caster()
		queue_free()
	else:
		# Wall hit -> Bounce
		if _current_bounces < max_bounces:
			var n = col.get_normal()
			velocity_vector = velocity_vector.bounce(n)
			rotation = velocity_vector.angle()
			_current_bounces += 1
		else:
			if special_behavior == "teleport":
				_teleport_caster()
			queue_free()

# Removed _trigger_collision_logic to prevent self-interception in Base
# func _trigger_collision_logic(col: KinematicCollision2D): ...


# Legacy method - kept for subclasses, but Base implementation is emptied to avoid confusion
# The logic moved to _on_hit
func _on_collision():
	pass

func _on_lifetime_expired():
	if special_behavior == "tnt":
		_explode()
		return
		
	if special_behavior == "teleport":
		_teleport_caster()
	
	if trail: trail.queue_free() # Ensure trail manages itself if detached? Actually queue_free destroys children too.
	queue_free()

func _explode():
	var dm = get_tree().get_first_node_in_group("digging_manager")
	if dm:
		dm.explode_at(global_position, 48.0)
	
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 48.0
	query.shape = shape
	query.transform = global_transform
	# LayerManager usage
	query.collision_mask = LayerManager.LAYER_NPC | LayerManager.LAYER_PLAYER
	
	var results = space.intersect_shape(query)
	for res in results:
		var c = res.collider
		if c.has_method("take_damage") and c != self:
			c.take_damage(30.0, "explosion")

	queue_free()

func _teleport_caster():
	if is_instance_valid(caster):
		var target_pos = global_position
		
		# 1. 强制“同步”加载目标位置的区块，防止掉入虚空
		if InfiniteChunkManager:
			# 扩展加载范围：不仅是目标点，周围一圈也同步加载
			var chunk_coord = InfiniteChunkManager.get_chunk_coord(target_pos)
			for x in range(-1, 2):
				for y in range(-1, 2):
					InfiniteChunkManager.force_load_at_world_pos(target_pos + Vector2(x * 1024, y * 1024))
		
		# --- 关键修复：同步物理状态 ---
		# 在 Godot 中，即使 TileMap 设置了 cell，碰撞体也是下一帧才生效。
		# 强制物理引擎在本帧刷新变换。
		PhysicsServer2D.set_active(true)
		
		# 2. 传送前处理物理状态
		if caster is CharacterBody2D:
			caster.velocity = Vector2.ZERO
		
		# 3. 寻找安全落脚点 (数据层检测)
		if InfiniteChunkManager:
			var safe_pos = InfiniteChunkManager.find_safe_ground(target_pos)
			if safe_pos != null:
				target_pos = safe_pos
		
		# 4. 物理挤出检查
		var space = caster.get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = target_pos
		query.collision_mask = 1 # LAYER_WORLD_0
		if not space.intersect_point(query).is_empty():
			target_pos.y -= 24 # 稍微多挪一点，确保不会卡在地板里
		
		# 5. 执行传送
		caster.global_position = target_pos
		
		# 6. 后置处理：延迟更新区块视野，防止旧区域卸载导致相机黑屏
		if InfiniteChunkManager:
			InfiniteChunkManager.update_player_vicinity.call_deferred(target_pos)
		
		# 传送后自动销毁弹道
		queue_free()
