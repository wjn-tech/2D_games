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

# Spell Expansion V1
var is_vampiric: bool = false
var is_orbiting_caster: bool = false
var orbit_radius: float = 80.0
var initial_orbit_phase: float = 0.0

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
	modifiers = mods
	
	if "speed" in params: speed = float(params.speed)
	if "lifetime" in params: lifetime = float(params.lifetime)
	if "damage" in params: damage = float(params.damage)
	if "element" in params: element = params.element
	if "projectile_id" in params: special_behavior = params.projectile_id

	if special_behavior == "vampire_bolt":
		is_vampiric = true
	
	# Default Element for Tutorial/Unmodified Spells
	if element == "none" or element == "":
		element = "magic_bolt"
	
	_apply_modifiers_stat_change()
	
	velocity_vector = Vector2.RIGHT.rotated(rotation) * speed
	
	# Initial orbit phase based on cast direction so projectiles don't all stack at 0
	if is_orbiting_caster:
		print("DEBUG: Orbit Enabled! Radius: ", orbit_radius, " Caster: ", caster)
		initial_orbit_phase = rotation
		# Force initial phase setup for renderer immediately
		var phase = initial_orbit_phase
		var offset = Vector2(orbit_radius, 0).rotated(phase)
		if is_instance_valid(caster):
			global_position = caster.global_position + offset
			rotation = phase + PI/2

	_update_visuals()

func _apply_modifiers_stat_change():
	# print("DEBUG: Modifiers applied to projectile: ", modifiers)
	for mod in modifiers:
		var m_type = ""
		var m_params = {}
		
		# Robust param extraction
		if mod is SpellInstruction:
			m_type = mod.type
			m_params = mod.params
		elif mod is Dictionary:
			m_type = mod.get("wand_logic_type", mod.get("type", ""))
			m_params = mod.get("params", mod)
			if m_params.is_empty() and not mod.is_empty(): m_params = mod
			
		# CRITICAL FIX: If generic MODIFIER, check params for true type
		if (m_type == "MODIFIER" or m_type == "modifier") and m_params.has("type"):
			m_type = m_params["type"]
            
		# print("DEBUG: Applying Modifier: ", m_type, " Params:", m_params)

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
		elif m_type == "modifier_homing" or m_type.contains("homing"):
			homing_strength = float(m_params.get("homing_strength", 0.5))
			if special_behavior == "": special_behavior = "homing"
		elif m_type == "modifier_orbit" or m_type.contains("orbit") or m_type == "SPELL_MODIFIER_ORBIT":
			is_orbiting_caster = true
			orbit_radius = 120 # Increase radius for better visibility
			if m_params.has("radius"): orbit_radius = float(m_params.get("radius"))
			# print("DEBUG: Orbit Modifier Active! Caster: ", caster)
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
            
	if is_orbiting_caster:
		var trail = Line2D.new()
		trail.width = 3.0
		trail.default_color = Color(0.5, 0.0, 1.0, 0.5)
		trail.top_level = true
		trail.name = "Trail"
		add_child(trail)
		var script = GDScript.new()
		script.source_code = "extends Line2D\nfunc _physics_process(_delta):\n\tadd_point(get_parent().global_position)\n\tif points.size() > 20: remove_point(0)"
		trail.script = script
	
	if is_vampiric:
		# For vampire, we rely on MagicProjectileVisualizer "vampire_bolt" behavior
		# But we can add a subtle tint just in case visualizer is disabled
		if not use_magic_visualizer:
			modulate = Color(1.0, 0.2, 0.2)


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

	# Orbit Behavior (New V1)
	if is_orbiting_caster:
		_process_orbit(delta)
		return

	# Homing behavior
	if homing_strength > 0.0:
		_process_homing(delta)
	
	# Alignment
	if velocity_vector.length_squared() > 1:
		rotation = velocity_vector.angle()
		if _visualizer: _visualizer.rotation = rotation # Ensure visualizer follows

	# Movement & Collision
	# Orbit projectiles handle their own collision in _process_orbit
	if not is_orbiting_caster:
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

var damage_cooldowns = {} # { collider_id: timestamp }

func _process_orbit(delta: float):
	if not is_instance_valid(caster):
		# Fallback: try to find player
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			caster = players[0]
		else:
			# Lost control, just float
			velocity_vector = Vector2.DOWN * 50.0
			is_orbiting_caster = false
			return
		
	# Angular Motion
	# speed = linear speed. omega = v / r
	var omega = speed / orbit_radius
	
	# Current Phase based on time + initial
	var phase = initial_orbit_phase + (_fly_time * omega)
	
	var offset = Vector2(orbit_radius, 0).rotated(phase)
	var target_pos = caster.global_position + offset
	
	# Update visual rotation to face tangent
	var tangent_angle = phase + PI/2
	rotation = tangent_angle
	if _visualizer: _visualizer.rotation = rotation
	
	# Check for enemies along the path or at target position
	# Using shape query for "collision" without stopping
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12.0 # Approximate projectile size
	query.shape = shape
	query.transform = Transform2D(rotation, global_position)
	query.collision_mask = collision_mask # Use projectile's mask
	
	var results = space.intersect_shape(query, 8)
	for res in results:
		var col = res.collider
		if col == self or col == caster: continue
		if col.has_method("take_damage"):
             # Orbit damage logic
			_try_apply_orbit_damage(col)

	# If motion is huge (first frame snap), just teleport
	var dist = global_position.distance_to(target_pos)
	if dist > 50.0:
		global_position = target_pos
		return
		
	# Move freely, ignoring walls
	global_position = target_pos
	rotation = phase + PI/2 # Face tangent

func _try_apply_orbit_damage(target: Node):
	var now = Time.get_ticks_msec()
	var id = target.get_instance_id()
	
	# 0.5s cooldown per target
	if id in damage_cooldowns:
		if now - damage_cooldowns[id] < 500:
			return
			
	damage_cooldowns[id] = now
	
	if target.is_in_group("destructible") or target is StaticBody2D:
		target.take_damage(damage, global_position)
	else:
		if target is BaseNPC:
			target.take_damage(damage, element, self)
		else:
			target.take_damage(damage, element)
	
	_spawn_hit_vfx(target.global_position)

func _spawn_hit_vfx(pos: Vector2):
	# Small impact effect
	if special_behavior in VFX_SCENES:
		# Use existing visualizer impact handling
		pass

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
		# Check method signature of receiver
		# Some expect (amount, source_pos), others (amount, type/element)
		# We should unify this, but for now, let's duck-type
		# StaticBody walls expect (amount: float, source_pos: Vector2)
		# Entities expect (amount: float, type: String) relative to previous code
		# Let's try to detect based on group or class name
		
		if collider.is_in_group("destructible") or collider is StaticBody2D:
			# Wall logic
			collider.take_damage(damage, global_position)
		else:
			# Enemy/Player logic
			if collider is BaseNPC:
				collider.take_damage(damage, element, self)
			else:
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
