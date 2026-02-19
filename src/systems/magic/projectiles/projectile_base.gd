extends CharacterBody2D
class_name ProjectileBase

# Visuals
@onready var collision = $CollisionShape2D
var visual_node # Generic container (deprecated, but keeping for compatibility)
var body_line: Line2D
var gpu_particles: GPUParticles2D
var secondary_particles: GPUParticles2D
var current_core_color: Color # Cached for visual effects

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
var pierce_count: int = 0
var homing_strength: float = 0.0
var explode_on_bounce: bool = false
var homing_target: Node = null
var homing_search_radius: float = 400.0

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
		var m_type = ""
		var m_params = {}
		
		if mod is SpellInstruction:
			m_type = mod.type
			m_params = mod.params
		elif mod is Dictionary:
			m_type = mod.get("wand_logic_type", mod.get("type", ""))
			m_params = mod.get("params", mod)
			# Fallback if dictionary IS the params
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
			# mark special behavior for visuals
			if special_behavior == "":
				special_behavior = "homing"
		elif m_type == "modifier_bounce_explosive":
			explode_on_bounce = true
			if special_behavior == "":
				special_behavior = "explosive_bounce"
		elif m_type == "modifier_lifetime_add":
			lifetime += float(m_params.get("lifetime_add", 0.0))
		elif m_type == "modifier_mana_to_damage":
			# simple multiplier example
			damage *= float(m_params.get("damage_multiplier", 1.0))
			
	_update_visuals()

func _update_visuals():
	# Clean up logic
	for child in get_children():
		if child is GPUParticles2D or child is Line2D and child != trail:
			if child != body_line:
				child.queue_free()
	
	# Personality Logic
	var core_color = Color(1.0, 5.0, 30.0) # Radiant Arcane Blue
	var core_width = 3.0
	var core_length = Vector2(-20, 2) # Elegant needle shape
	var glow_power = 2.0
	
	match element:
		"fire": 
			core_color = Color(10.0, 2.0, 0.1) # Fire Deep Orange
			core_width = 4.0
		"ice": 
			core_color = Color(0.1, 5.0, 10.0)  # Ice Cyan
			core_width = 3.0
		"slime": 
			core_color = Color(0.2, 8.0, 0.2) # Slime Green
			core_width = 5.0
	
	# Apply Special Behavior Personality TO THE CORE
	match special_behavior:
		"spark_bolt":
			core_color = Color(1.0, 5.0, 50.0) # Blinding Light Blue
			core_width = 1.5
			core_length = Vector2(-12, 1)
			_add_spark_trail(Color(0.5, 2.0, 10.0))
		"magic_bolt":
			core_color = Color(20.0, 1.0, 50.0) # Intense Purple/Magenta
			core_width = 6.0
			core_length = Vector2(-25, 4)
			_add_heavy_trail(Color(10.0, 0.5, 30.0))
		"bouncing_burst":
			core_color = Color(40.0, 40.0, 2.0) # High-energy Neon Yellow
			core_width = 10.0
			core_length = Vector2(-5, 5)
			max_bounces = 12
			_add_ring_pulsate(Color(10, 10, 0.1))
		"chainsaw":
			core_color = Color(100.0, 100.0, 100.0) # Pure Blinding White
			core_width = 25.0
			core_length = Vector2(-2, 2)
			lifetime = 0.05 # Near instant
			damage *= 2.0
			_add_explosion_on_spawn(Color.WHITE, 0.2)
		"tri_bolt":
			core_color = Color(0.1, 50.0, 10.0) # Intense Teal
			core_width = 3.0
			core_length = Vector2(-15, 2)
		"fireball":
			core_color = Color(12.0, 3.0, 0.2)
			core_width = 8.0
			core_length = Vector2(-18, 6)
			_add_spark_trail(Color(2.0, 0.6, 0.1))
		"magic_arrow":
			core_color = Color(8.0, 1.0, 12.0)
			core_width = 4.0
			core_length = Vector2(-28, 4)
			_add_heavy_trail(Color(6.0, 0.4, 10.0))
		"energy_sphere":
			core_color = Color(2.0, 6.0, 6.0)
			core_width = 10.0
			core_length = Vector2(-12, 12)
			_add_ring_pulsate(Color(2.0, 1.0, 1.0))
		"cluster_bomb":
			core_color = Color(10.0, 5.0, 0.2)
			core_width = 6.0
			core_length = Vector2(-8, 6)
			_add_flicker_effect(Color(10.0, 6.0, 0.2), 0.08)
		"homing":
			core_color = Color(1.5, 1.0, 0.3)
			core_width = 4.0
			core_length = Vector2(-14, 3)
			_add_spark_trail(Color(1.0, 1.0, 0.4))
		"explosive_bounce":
			core_color = Color(3.0, 1.0, 0.1)
			core_width = 9.0
			core_length = Vector2(-6, 6)
			_add_ring_pulsate(Color(4.0, 2.0, 0.2))
		"tnt":
			core_color = Color(100.0, 10.0, 0.1) # Volcanic Red
			core_width = 15.0
			core_length = Vector2(-4, 4)
			_add_flicker_effect(Color(100, 100, 100), 0.05)
		"blackhole":
			core_color = Color(0.0, 0.0, 0.0, 1.0) # Void
			core_width = 12.0
			core_length = Vector2(-1, 1)
			_add_swirl_effect(Color(0.5, 0.0, 1.0))
		"teleport":
			core_color = Color(0.2, 100.0, 100.0) # Electric Cyan Jitter
			core_width = 2.0
			core_length = Vector2(-40, 40)
	
	# 1. THE CORE
	if not body_line:
		body_line = Line2D.new()
		add_child(body_line)
	
	body_line.width = core_width
	body_line.points = [Vector2(core_length.x, 0), Vector2(core_length.y, 0)]
	body_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	body_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	body_line.default_color = core_color
	body_line.material = MagicVisualManager.get_energy_material(core_color)
	current_core_color = core_color # Store for flicker reference
	
	# Glow effect (Z-Index and Light)
	if not has_node("GlowPoint"):
		var light = PointLight2D.new()
		light.name = "GlowPoint"
		light.texture = _create_sparkle_texture()
		light.texture_scale = 8.0 
		light.color = core_color
		light.energy = 5.0
		add_child(light)

	# 2. MAIN ELEMENTAL TRAIL (Diverse per element)
	gpu_particles = GPUParticles2D.new()
	gpu_particles.local_coords = false 
	gpu_particles.texture = _create_sparkle_texture()
	gpu_particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gpu_particles.process_material = MagicVisualManager.get_element_particles(element)
	
	var part_mat = CanvasItemMaterial.new()
	part_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	gpu_particles.material = part_mat
	add_child(gpu_particles)
	
	# 3. MODIFIER OVERLAY
	for mod in modifiers:
		_apply_modifier_visual(mod, core_color)

	if special_behavior != "":
		_add_special_effect(special_behavior)

func _add_spark_trail(col: Color):
	var p = GPUParticles2D.new()
	p.amount = 30
	p.lifetime = 0.5
	p.local_coords = false
	p.texture = _create_sparkle_texture()
	var pm = ParticleProcessMaterial.new()
	pm.gravity = Vector3(0, 0, 0)
	pm.initial_velocity_min = 50.0
	pm.initial_velocity_max = 100.0
	pm.scale_min = 3.0
	pm.scale_max = 8.0
	pm.color = col
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 2.0
	p.process_material = pm
	add_child(p)

func _add_heavy_trail(col: Color):
	var p = GPUParticles2D.new()
	p.amount = 80
	p.lifetime = 1.0
	p.local_coords = false
	p.texture = _create_sparkle_texture()
	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3(-1, 0, 0)
	pm.spread = 15.0
	pm.gravity = Vector3(0, 400, 0) # Falling embers
	pm.initial_velocity_min = 100.0
	pm.initial_velocity_max = 300.0
	pm.scale_min = 4.0
	pm.scale_max = 12.0
	pm.color = col
	p.process_material = pm
	add_child(p)

func _add_ring_pulsate(col: Color):
	var ring = Line2D.new()
	ring.width = 1.5
	ring.default_color = col
	ring.closed = true
	var pts = []
	for i in range(16):
		var ang = i * TAU / 16.0
		pts.append(Vector2.RIGHT.rotated(ang) * 8.0)
	ring.points = pts
	add_child(ring)
	
	var tw = create_tween().set_loops()
	tw.tween_property(ring, "scale", Vector2(1.5, 1.5), 0.2)
	tw.tween_property(ring, "scale", Vector2(0.8, 0.8), 0.2)
	tw.tween_property(ring, "modulate:a", 0.0, 0.4).set_delay(0.1)

func _add_explosion_on_spawn(col: Color, size: float):
	var p = GPUParticles2D.new()
	p.amount = 40
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.3
	p.texture = _create_sparkle_texture()
	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0, 0)
	pm.spread = 180.0
	pm.gravity = Vector3(0, 0, 0)
	pm.initial_velocity_min = 300.0
	pm.initial_velocity_max = 600.0 * size
	pm.scale_min = 2.0
	pm.scale_max = 6.0
	pm.color = col
	p.process_material = pm
	add_child(p)
	p.emitting = true

func _add_swirl_effect(col: Color):
	var p = GPUParticles2D.new()
	p.amount = 100
	p.lifetime = 1.2
	p.texture = _create_sparkle_texture()
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_radius = 12.0
	pm.emission_ring_inner_radius = 8.0
	pm.gravity = Vector3(0, 0, 0)
	pm.radial_accel_min = -100.0 
	pm.radial_accel_max = -50.0
	pm.scale_min = 2.0
	pm.scale_max = 5.0
	pm.color = col
	p.process_material = pm
	add_child(p)

func _add_flicker_effect(alt_color: Color, speed: float):
	var tween = create_tween().set_loops()
	tween.tween_property(body_line, "default_color", alt_color, speed)
	tween.tween_property(body_line, "default_color", current_core_color, speed)

func _apply_modifier_visual(mod, base_col: Color):
	var m_type = ""
	var m_params = {}
	
	if mod is SpellInstruction:
		m_type = mod.type
		m_params = mod.params
	elif mod is Dictionary:
		m_type = mod.get("wand_logic_type", mod.get("type", ""))
		m_params = mod.get("params", mod)
		if m_params.is_empty() and not mod.is_empty(): m_params = mod

	if m_type == "modifier_damage":
		# Power spikes
		var p = GPUParticles2D.new()
		p.amount = 15
		p.lifetime = 0.2
		p.local_coords = true
		p.texture = _create_sparkle_texture()
		var pm = ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		pm.emission_ring_radius = 6.0
		pm.gravity = Vector3.ZERO
		pm.orbit_velocity_min = 2.0
		pm.orbit_velocity_max = 5.0
		pm.color = Color(3.0, 0.5, 0.5) # Intense red aura
		p.process_material = pm
		add_child(p)
		
	elif m_type == "modifier_speed":
		# Ghostly velocity lines
		var p = GPUParticles2D.new()
		p.amount = 40
		p.lifetime = 0.4
		p.local_coords = false
		p.texture = _create_sparkle_texture()
		var pm = ParticleProcessMaterial.new()
		pm.gravity = Vector3.ZERO
		pm.direction = Vector3(-1, 0, 0)
		pm.initial_velocity_min = 200.0
		pm.initial_velocity_max = 400.0
		pm.scale_min = 0.1
		pm.scale_max = 0.5
		pm.particle_flag_align_y = true
		pm.color = base_col.lightened(0.5)
		p.process_material = pm
		add_child(p)
		
	elif m_type == "modifier_element":
		var element_type = m_params.get("element", "")
		var e_col = Color(1, 1, 1)
		var e_grav = Vector3.ZERO
		var e_turb = 0.0
		
		match element_type:
			"fire":
				e_col = Color(80.0, 10.0, 0.5) # Blazing Solar Flare (Hard Red/Orange)
				e_grav = Vector3(0, -400, 0) 
				e_turb = 25.0
			"ice":
				e_col = Color(1.0, 20.0, 150.0) # Absolute Zero (Hard Cyan/White)
				e_grav = Vector3(0, 50, 0)
				e_turb = 2.0
			"slime":
				e_col = Color(0.2, 30.0, 0.2) # Concentrated Bio-Emerald (Deep Green)
				e_grav = Vector3(0, 1200, 0)
				e_turb = 15.0
		
		var p = GPUParticles2D.new()
		p.amount = 150 # Increased density
		p.lifetime = 1.0
		p.local_coords = false
		p.texture = _create_sparkle_texture()
		
		var pm = ParticleProcessMaterial.new()
		pm.gravity = e_grav
		pm.turbulence_enabled = true
		pm.turbulence_influence_min = 0.2
		pm.turbulence_influence_max = 0.5
		pm.scale_min = 3.0
		pm.scale_max = 8.0
		pm.color = e_col
		
		var grad = Gradient.new()
		grad.set_colors([e_col, Color(0,0,0,0)])
		var gte = GradientTexture1D.new()
		gte.gradient = grad
		pm.color_ramp = gte
		p.process_material = pm
		add_child(p)
	elif m_type == "modifier_lifetime":
		var p2 = GPUParticles2D.new()
		p2.amount = 50
		p2.lifetime = 1.4
		p2.local_coords = false
		p2.texture = _create_sparkle_texture()
		var pm2 = ParticleProcessMaterial.new()
		pm2.gravity = Vector3(0, 0, 0)
		pm2.initial_velocity_min = 20.0
		pm2.initial_velocity_max = 60.0
		pm2.scale_min = 1.0
		pm2.scale_max = 3.0
		pm2.color = base_col.lightened(0.3)
		p2.process_material = pm2
		add_child(p2)

	elif m_type == "modifier_pierce":
		# Visual cue for piercing
		var ln = Line2D.new()
		ln.width = 2.0
		ln.default_color = Color(1.0, 0.8, 0.2)
		ln.points = [Vector2(-6, -2), Vector2(6, 2)]
		add_child(ln)

	elif m_type == "modifier_homing":
		var p3 = GPUParticles2D.new()
		p3.amount = 40
		p3.lifetime = 0.6
		p3.texture = _create_sparkle_texture()
		var pm3 = ParticleProcessMaterial.new()
		pm3.initial_velocity_min = 30
		pm3.initial_velocity_max = 90
		pm3.direction = Vector3(-1, 0, 0)
		pm3.color = Color(1.0, 0.9, 0.5)
		p3.process_material = pm3
		add_child(p3)

	elif m_type == "modifier_bounce_explosive":
		# Small explosive overlay
		var p4 = GPUParticles2D.new()
		p4.amount = 30
		p4.one_shot = true
		p4.lifetime = 0.4
		p4.texture = _create_sparkle_texture()
		var pm4 = ParticleProcessMaterial.new()
		pm4.initial_velocity_min = 120
		pm4.initial_velocity_max = 320
		pm4.scale_min = 2.0
		pm4.scale_max = 5.0
		pm4.color = Color(3.0, 1.5, 0.2)
		p4.process_material = pm4
		add_child(p4)

	elif m_type == "modifier_mana_to_damage":
		var p5 = GPUParticles2D.new()
		p5.amount = 12
		p5.lifetime = 0.3
		p5.texture = _create_sparkle_texture()
		var pm5 = ParticleProcessMaterial.new()
		pm5.initial_velocity_min = 60
		pm5.initial_velocity_max = 180
		pm5.scale_min = 1.5
		pm5.scale_max = 4.0
		pm5.color = Color(0.8, 0.4, 1.0)
		p5.process_material = pm5
		add_child(p5)

func _create_sparkle_texture() -> CanvasTexture:
	# A soft 4x4 pixel to make trails look fluid but still pixelated
	var tex = GradientTexture2D.new()
	tex.width = 4
	tex.height = 4
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	
	var grad = Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	grad.set_offsets([0.2, 0.9])
	
	tex.gradient = grad
	
	var ct = CanvasTexture.new()
	ct.diffuse_texture = tex
	return ct

func _has_elemental_mod() -> bool:
	for mod in modifiers:
		var m_type = ""
		if mod is SpellInstruction:
			m_type = mod.type
		elif mod is Dictionary:
			m_type = mod.get("wand_logic_type", mod.get("type", ""))
		
		if m_type == "modifier_element": return true
	return false

# Deprecated: Logic moved to _update_visuals
func _add_elemental_effect(type: String):
	pass

func _add_special_effect(type: String):
	if not gpu_particles:
		_update_visuals()

	if type == "tnt":
		# THE TNT: Violent, Pulsing, Heavy
		body_line.width = 16.0 
		body_line.points = [Vector2(-2, 0), Vector2(2, 0)]
		body_line.material = MagicVisualManager.get_energy_material(Color(40.0, 1.0, 0.2))
		
		# Explosive fuse trail - bright sparks
		var fuse = GPUParticles2D.new()
		fuse.amount = 60
		fuse.lifetime = 0.4
		fuse.local_coords = false
		fuse.texture = _create_sparkle_texture()
		var f_p_mat = ParticleProcessMaterial.new()
		f_p_mat.gravity = Vector3(0, -100, 0)
		f_p_mat.initial_velocity_min = 100.0
		f_p_mat.initial_velocity_max = 200.0
		f_p_mat.spread = 180.0
		f_p_mat.damping_min = 50.0
		f_p_mat.damping_max = 80.0
		f_p_mat.scale_min = 0.5
		f_p_mat.scale_max = 3.0
		f_p_mat.color = Color(30, 25, 5) # Blinding magnesium sparks
		fuse.process_material = f_p_mat
		add_child(fuse)
		
	elif type == "blackhole":
		# THE BLACKHOLE: Swirling Vacuum of Doom
		var bh_color = Color(30.0, 5.0, 80.0) # Vivid Pulsing Royal Purple
		body_line.width = 16.0
		body_line.points = [Vector2(-1, 0), Vector2(1, 0)]
		body_line.material = MagicVisualManager.get_energy_material(bh_color)
		
		# Sucking Outer Ring (Accretion Disk)
		var portal = GPUParticles2D.new()
		portal.amount = 400
		portal.lifetime = 1.2
		portal.local_coords = true 
		portal.texture = _create_sparkle_texture()
		var p_p_mat = ParticleProcessMaterial.new()
		p_p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		p_p_mat.emission_ring_radius = 42.0
		p_p_mat.emission_ring_inner_radius = 38.0
		p_p_mat.gravity = Vector3.ZERO
		p_p_mat.radial_accel_min = -300.0 # Extreme inward pull
		p_p_mat.radial_accel_max = -500.0
		p_p_mat.orbit_velocity_min = 3.0 # High speed spin
		p_p_mat.orbit_velocity_max = 5.0
		
		var grad = Gradient.new()
		grad.set_colors([Color(50.0, 0.0, 100.0), Color(5.0, 0.5, 20.0), Color(0,0,0,0)])
		var gte = GradientTexture1D.new()
		gte.gradient = grad
		p_p_mat.color_ramp = gte
		p_p_mat.scale_min = 2.0
		p_p_mat.scale_max = 6.0
		portal.process_material = p_p_mat
		add_child(portal)
		
		# Inner Event Horizon (The "Consuming" Core)
		var core_p = GPUParticles2D.new()
		core_p.amount = 400
		core_p.lifetime = 1.0
		core_p.local_coords = true
		core_p.texture = _create_sparkle_texture()
		var cp_mat = ParticleProcessMaterial.new()
		cp_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		cp_mat.emission_sphere_radius = 18.0
		cp_mat.gravity = Vector3.ZERO
		cp_mat.radial_accel_min = -400.0 # Violent inward snap
		cp_mat.radial_accel_max = -800.0
		cp_mat.scale_min = 4.0
		cp_mat.scale_max = 10.0
		
		# Distortion/Glitch spikes
		cp_mat.turbulence_enabled = true
		cp_mat.turbulence_noise_strength = 15.0
		cp_mat.turbulence_influence_min = 0.5
		cp_mat.turbulence_influence_max = 0.8
		
		var c_grad = Gradient.new()
		c_grad.set_colors([Color(50.0, 5.0, 100.0), Color(2.0, 0.0, 10.0), Color(0,0,0,0)])
		var c_gte = GradientTexture1D.new()
		c_gte.gradient = c_grad
		cp_mat.color_ramp = c_gte
		
		core_p.process_material = cp_mat
		add_child(core_p)
		
		# Spacetime distortion ripples (Subtle but rapid scale oscillation)
		var tween = create_tween().set_loops()
		tween.tween_property(core_p, "scale", Vector2(1.3, 0.7), 0.05)
		tween.tween_property(core_p, "scale", Vector2(0.7, 1.3), 0.05)
		
		# White-hot singularity center
		var sing = GPUParticles2D.new()
		sing.amount = 20
		sing.lifetime = 0.1
		sing.process_material = ParticleProcessMaterial.new()
		sing.process_material.gravity = Vector3.ZERO
		sing.process_material.color = Color(50, 50, 50)
		add_child(sing)
		
	elif type == "teleport":
		# Teleport Jitter: Electronic ghost
		body_line.width = 4.0
		body_line.points = [Vector2(-30, 0), Vector2(30, 0)]
		body_line.default_color = Color(0.2, 50.0, 50.0) # Uranium Cyan
		
		# Glitch trail: Square particles that stay in place (low speed)
		var glitch = GPUParticles2D.new()
		glitch.amount = 50
		glitch.lifetime = 0.4
		glitch.local_coords = false
		glitch.texture = _create_sparkle_texture()
		var g_p_mat = ParticleProcessMaterial.new()
		g_p_mat.gravity = Vector3.ZERO
		g_p_mat.spread = 0.0
		g_p_mat.scale_min = 2.0
		g_p_mat.scale_max = 10.0
		g_p_mat.color = Color(0.1, 10.0, 10.0, 0.8)
		# Add jitter to the particles themselves
		g_p_mat.turbulence_enabled = true
		g_p_mat.turbulence_noise_strength = 20.0
		glitch.process_material = g_p_mat
		add_child(glitch)

func _ready():
	visual_node = get_node_or_null("VisualRect")
	if visual_node: visual_node.visible = false # Hide old gourd
	
	_update_visuals()
	_create_trail()
	
	# Initial scale bounce for "impact" feel
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func _create_trail():
	trail = Line2D.new()
	trail.width = 1.0 # Very thin trail, mostly particles do the work
	trail.top_level = true
	
	# Trail Color matching the projectile
	var col = body_line.default_color if body_line else Color.WHITE
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
			
		# Attraction logic: Suck in items
		var suck_radius = 180.0 # Expanded range
		var kill_radius = 20.0
		
		# VISUAL: Screenshake/Distortion around Blackhole (Simulated via scale)
		var pulse = 1.0 + sin(_fly_time * 15.0) * 0.15
		body_line.scale = Vector2(pulse, pulse)
		
		# Space state query for efficiency
		var space = get_world_2d().direct_space_state
		var query = PhysicsShapeQueryParameters2D.new()
		var shape = CircleShape2D.new()
		shape.radius = suck_radius
		query.shape = shape
		query.transform = global_transform
		query.collision_mask = 2 | 4 | 1 # Sucks items(2), projectiles(4), and bits of terrain(1)
		
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
				# Violent Gravity: Exponential pull
				var strength = pow((suck_radius - dist) / suck_radius, 2) * 2500.0
				if target is RigidBody2D:
					target.apply_central_impulse(dir * strength * delta)
				elif target is CharacterBody2D:
					target.velocity += dir * strength * delta * 0.5

func _physics_process(delta):
	_fly_time += delta
	
	_process_behavior(delta)
	
	if _fly_time >= lifetime:
		_on_lifetime_expired()
		return

	# Homing behavior: steer toward nearest valid target
	if homing_strength > 0.0:
		# validate existing target
		if not is_instance_valid(homing_target):
			homing_target = _find_homing_target(homing_search_radius)
		elif is_instance_valid(homing_target) and (homing_target.global_position - global_position).length() > homing_search_radius:
			homing_target = null
		
		if is_instance_valid(homing_target):
			var to_target = (homing_target.global_position - global_position).normalized()
			var desired_angle = to_target.angle()
			var current_angle = velocity_vector.angle()
			var turn_alpha = clamp(homing_strength * delta, 0.0, 1.0)
			var new_angle = lerp_angle(current_angle, desired_angle, turn_alpha)
			velocity_vector = Vector2.RIGHT.rotated(new_angle) * speed
			rotation = new_angle
		
	# Update Trail
	if trail:
		trail.add_point(global_position)
		if trail.get_point_count() > 15:
			trail.remove_point(0)

	# Movement: Use move_and_collide for precise bouncing
	var collision = move_and_collide(velocity_vector * delta)
	if collision:
		_on_hit(collision)


func _find_homing_target(radius: float) -> Node:
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	# Search common layers (players/enemies/world) - broad by default
	query.collision_mask = 0xFFFF
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
		# Pierce handling: if we have pierce charges, consume one and continue
		if pierce_count > 0:
			pierce_count -= 1
			return
		else:
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
		# DISABLED: 传送不应该强制落地，允许空中传送
		# if InfiniteChunkManager:
		# 	var safe_pos = InfiniteChunkManager.find_safe_ground(target_pos)
		# 	if safe_pos != null:
		# 		target_pos = safe_pos
		
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
