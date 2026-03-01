extends CharacterBody2D
class_name ProjectileBase

# Visuals
@export var use_magic_visualizer: bool = true
var _visualizer: MagicProjectileVisualizer

# Legacy Visual Stubs (To avoid breaking external references if any)
var visual_node: Node2D
var body_line: Line2D 
var gpu_particles: GPUParticles2D 
# Note: These are now managed internally by _visualizer if present, or unused.

# Stats
var velocity_vector: Vector2 = Vector2.ZERO
var speed: float = 800.0
var lifetime: float = 5.0
var damage: float = 10.0
var element: String = "none"
var max_bounces: int = 3
var _current_bounces: int = 0
var special_behavior: String = ""
var caster: Node2D
var pierce_count: int = 0
var homing_strength: float = 0.0
var explode_on_bounce: bool = false
var homing_target: Node2D = null
var homing_search_radius: float = 400.0

# Logic
var modifiers: Array = []
var _fly_time: float = 0.0

# Components
var impact_vfx: PackedScene

# Visual/Effect Scenes Map (Only used for Impact now)
const VFX_SCENES = {
	"fireball": { "impact": null },
	"magic_bolt": { "impact": null },
	"blackhole": { "impact": null },
	"slime": { "impact": null },
	"tnt": { "impact": null },
	"chainsaw": { "impact": null },
	"tri_bolt": { "impact": null },
	"teleport": { "impact": null }
}

func setup(params: Dictionary, mods: Array):
	if "speed" in params: speed = float(params.speed)
	if "lifetime" in params: lifetime = float(params.lifetime)
	if "damage" in params: damage = float(params.damage)
	if "element" in params: element = params.element
	if "projectile_id" in params: special_behavior = params.projectile_id
	
	modifiers = mods
	_apply_modifiers_stat_change()
	
	velocity_vector = Vector2.RIGHT.rotated(rotation) * speed
	_update_visuals()

func _apply_modifiers_stat_change():
	for mod in modifiers:
		var m_type = ""
		var m_params = {}
		
		if mod is SpellInstruction:
			m_type = mod.type
			m_params = mod.params
		elif mod is Dictionary:
			m_type = mod.get("wand_logic_type", mod.get("type", ""))
			m_params = mod.get("params", mod)
			if m_params.is_empty() and not mod.is_empty(): m_params = mod
			
		if m_type == "modifier_speed":
			speed *= 1.5 
		elif m_type == "modifier_damage":
			var amt = m_params.get("amount", 5)
			damage += float(amt)
		elif m_type == "modifier_element":
			element = m_params.get("element", "none")
		elif m_type == "modifier_lifetime":
			lifetime += float(m_params.get("lifetime_add", 0.0))
		elif m_type == "modifier_pierce":
			pierce_count = int(m_params.get("pierce", 1))
		elif m_type == "modifier_homing":
			homing_strength = float(m_params.get("homing_strength", 0.5))
			if special_behavior == "": special_behavior = "homing"
		elif m_type == "modifier_bounce_explosive":
			explode_on_bounce = true
			if special_behavior == "": special_behavior = "explosive_bounce"
		elif m_type == "modifier_lifetime_add":
			lifetime += float(m_params.get("lifetime_add", 0.0))
		elif m_type == "modifier_mana_to_damage":
			damage *= float(m_params.get("damage_multiplier", 1.0))

func _update_visuals():
	# 1. Initialize Visualizer
	if use_magic_visualizer:
		# If using the new visualizer, REMOVE any legacy placeholder sprites/rects
		# This prevents the "White Rectangle" artifact from appearing underneath the new effects.
		if has_node("VisualRect"): get_node("VisualRect").queue_free()
		if has_node("Sprite"): get_node("Sprite").queue_free()
		if has_node("Sprite2D"): get_node("Sprite2D").queue_free()

		if not _visualizer:
			_visualizer = MagicProjectileVisualizer.new()
			add_child(_visualizer)
		_visualizer.setup(self, special_behavior, element)
		
		# Ensure we are in the tree before playing flash, or delay it by a frame
		if is_inside_tree():
			_visualizer.play_muzzle_flash()
		else:
			call_deferred("_play_muzzle_flash_deferred")

func _play_muzzle_flash_deferred():
	if is_instance_valid(_visualizer) and _visualizer.is_inside_tree():
		_visualizer.play_muzzle_flash()

	# 2. Logic-Specific Adjustments (Non-Visual, purely stats)
	match special_behavior:
		"bouncing_burst":
			max_bounces = 12
		"chainsaw":
			lifetime = 0.05
			damage *= 2.0
		"teleport":
			# Handled in logic
			pass
		"blackhole":
			# Handled in _process_behavior
			pass

	# 3. Setup Impact VFX from Map
	if special_behavior in VFX_SCENES:
		var data = VFX_SCENES[special_behavior]
		if data.has("impact") and data["impact"]:
			impact_vfx = data["impact"]

func _physics_process(delta: float):
	_fly_time += delta
	
	_process_behavior(delta)
	
	if _fly_time >= lifetime:
		_on_lifetime_expired()
		return

	# Homing behavior
	if homing_strength > 0.0:
		_process_homing(delta)
	
	# Alignment
	if velocity_vector.length_squared() > 1:
		rotation = velocity_vector.angle()
		if _visualizer: _visualizer.rotation = rotation # Ensure visualizer follows

	# Movement & Collision
	var collision = move_and_collide(velocity_vector * delta)
	if collision:
		_on_hit(collision)

func _process_homing(delta: float):
	if not is_instance_valid(homing_target):
		homing_target = _find_homing_target(homing_search_radius)
	elif is_instance_valid(homing_target) and (homing_target.global_position - global_position).length() > homing_search_radius:
		homing_target = null
	
	if is_instance_valid(homing_target):
		var to_target = (homing_target.global_position - global_position).normalized()
		var desired_angle = to_target.angle()
		var current_angle = velocity_vector.angle()
		var turn_alpha = clamp(homing_strength * delta * 5.0, 0.0, 1.0) # Multiply for stronger turn
		var new_angle = lerp_angle(current_angle, desired_angle, turn_alpha)
		velocity_vector = Vector2.RIGHT.rotated(new_angle) * speed

func _process_behavior(delta: float):
	if special_behavior == "blackhole":
		_process_blackhole(delta)
	elif special_behavior == "tnt" or special_behavior == "cluster_bomb":
		# Heavy ordnance affected by gravity
		velocity_vector.y += 900.0 * delta # Gravity pull 
		velocity_vector.x = move_toward(velocity_vector.x, 0.0, 200.0 * delta)
	elif special_behavior == "bouncing_burst":
		# Lightweight bouncy logic
		velocity_vector.y += 400.0 * delta # Light gravity pull

func _process_blackhole(delta: float):
	var dm = get_tree().get_first_node_in_group("digging_manager")
	if dm:
		dm.dissolve_at(global_position, 32.0)
		
	var suck_radius = 180.0
	var kill_radius = 20.0
	
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = suck_radius
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 2 | 4 | 1 
	
	var results = space.intersect_shape(query, 32)
	for res in results:
		var target = res.collider
		if target == self: continue
		
		var to_bh = global_position - target.global_position
		var dist = to_bh.length()
		var dir = to_bh.normalized()
		
		if dist < kill_radius:
			if target.has_method("take_damage"):
				target.take_damage(damage * 5.0, "arcane")
			elif target is not TileMap:
				target.queue_free()
		else:
			var strength = pow((suck_radius - dist) / suck_radius, 2) * 2500.0
			if target is RigidBody2D:
				target.apply_central_impulse(dir * strength * delta)
			elif target is CharacterBody2D:
				target.velocity += dir * strength * delta * 0.5

func _find_homing_target(radius: float) -> Node:
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 0xFFFF # Broad search
	var results = space.intersect_shape(query, 64)
	var best: Node = null
	var best_dist = 1e9
	for res in results:
		var col = res.collider
		if col == self: continue
		if col == caster: continue
		if not is_instance_valid(col): continue
		if col.has_method("take_damage"):
			var d = (col.global_position - global_position).length()
			if d < best_dist:
				best_dist = d
				best = col
	return best

func _on_hit(col: KinematicCollision2D):
	if special_behavior == "tnt":
		_explode()
		return
	
	if special_behavior == "blackhole":
		return

	var collider = col.get_collider()
	var hit_enemy = false
	
	if collider.has_method("take_damage"):
		collider.take_damage(damage, element)
		hit_enemy = true
		
	if hit_enemy:
		if pierce_count > 0:
			pierce_count -= 1
			# Continue through logic (maybe reduce damage?)
			return
		else:
			if special_behavior == "teleport": _teleport_caster()
			_spawn_death_vfx()
			queue_free()
	else:
		if _current_bounces < max_bounces:
			var n = col.get_normal()
			
			if special_behavior == "bouncing_burst":
				velocity_vector = velocity_vector.bounce(n) * 1.1 # Speed up slightly on bounce for chaotic feel
			else:
				velocity_vector = velocity_vector.bounce(n)
			
			rotation = velocity_vector.angle()
			_current_bounces += 1
		else:
			if special_behavior == "teleport": _teleport_caster()
			_spawn_death_vfx()
			queue_free()

func _on_lifetime_expired():
	if special_behavior == "tnt":
		_explode()
		return
		
	if special_behavior == "teleport":
		_teleport_caster()
	
	_spawn_death_vfx()
	queue_free()

func _explode():
	var dm = get_tree().get_first_node_in_group("digging_manager")
	if dm: dm.explode_at(global_position, 48.0)
	
	_spawn_death_vfx() # Boom VFX
	
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 48.0
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 1 | 2 # Map and Objects
	
	var results = space.intersect_shape(query)
	for res in results:
		var c = res.collider
		if c.has_method("take_damage") and c != self:
			c.take_damage(30.0, "explosion")

	queue_free()

func _teleport_caster():
	if is_instance_valid(caster):
		var target_pos = global_position
		
		# Assuming InfiniteChunkManager utility is global/singleton if exists
		# if has_node("/root/InfiniteChunkManager"): ...
		
		# Reset Caster Velocity
		if caster is CharacterBody2D:
			caster.velocity = Vector2.ZERO
		
		# Safe Teleport Logic (Simplified)
		var space = caster.get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = target_pos
		query.collision_mask = 1 
		if not space.intersect_point(query).is_empty():
			target_pos.y -= 24 
		
		caster.global_position = target_pos
		_spawn_death_vfx()
		queue_free()

func _spawn_death_vfx():
	# Use new visualizer if available
	if _visualizer:
		_visualizer.play_impact_effect()
	
	# Also play configured VFX scene if available (Legacy/Extra)
	if impact_vfx:
		var vfx = impact_vfx.instantiate()
		get_parent().add_child(vfx)
		vfx.global_position = global_position
		vfx.rotation = rotation
		if vfx is GPUParticles2D:
			vfx.emitting = true
