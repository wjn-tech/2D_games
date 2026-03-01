extends Node2D
class_name MagicProjectileVisualizer

# --- CONFIGURATION ---
@export var behavior_name: String = "magic_bolt"
@export var element_type: String = "fire"

# --- INTERNAL NODES ---
var _core_particles: GPUParticles2D # The main "body" of the projectile (High Density Particle Cluster)
var _trail_particles: GPUParticles2D
var _secondary_trail_particles: GPUParticles2D # Secondary, like smoke for fireball
var _light: PointLight2D

# --- DYNAMIC FX NODES ---
var _lightning_lines: Array[Line2D] = []
var _back_buffer: BackBufferCopy
var _distortion_rect: ColorRect

# --- STATE ---
var _base_scale: Vector2 = Vector2.ONE
var _pulse_speed: float = 0.0
var _pulse_amount: float = 0.0
var _jitter_amount: float = 0.0
var _spin_speed: float = 0.0
var _time_alive: float = 0.0
var _is_setup: bool = false
var _velocity_cache: Vector2 = Vector2.ZERO

var _orbit_nodes: Array[Node2D] = []
var _orbit_speed: float = 0.0

func _ready():
	z_index = 10 

func _process(delta: float):
	if not _is_setup: return
	_time_alive += delta

	# Animations
	if _pulse_speed > 0.0:
		scale = _base_scale * (1.0 + sin(_time_alive * _pulse_speed) * _pulse_amount)
		
	if _spin_speed != 0.0:
		rotation += _spin_speed * delta
		
	if _jitter_amount > 0.0:
		position = Vector2(randf_range(-_jitter_amount, _jitter_amount), randf_range(-_jitter_amount, _jitter_amount))
		
	if _orbit_nodes.size() > 0 and _orbit_speed != 0.0:
		for node in _orbit_nodes:
			node.rotation += _orbit_speed * delta
	
	# Light Flicker (Burning)
	if _light and _light.visible:
		_update_lightning(delta)

func _update_lightning(_delta: float):
	for line in _lightning_lines:
		if randf() > 0.6: # Jitter frequently
			line.clear_points()
			var current_pos = Vector2.ZERO
			line.add_point(current_pos)
			
			var segments = randi() % 4 + 3
			var last_angle = 0.0
			# Point backwards against the velocity if available, else roughly random or trailing
			var base_dir = Vector2(-1, 0)
			
			for i in range(segments):
				var length = randf_range(5.0, 15.0)
				var angle = base_dir.angle() + randf_range(-PI/3, PI/3)
				current_pos += Vector2(cos(angle), sin(angle)) * length
				line.add_point(current_pos)
		
func play_muzzle_flash():
	# Instant Burst of Pure Particles (Noita style)
	var flash = GPUParticles2D.new()
	flash.material = CanvasItemMaterial.new()
	flash.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	flash.texture = _create_pixel_dot_texture()
	flash.amount = 40
	flash.lifetime = 0.2
	flash.one_shot = true
	flash.explosiveness = 1.0 # Instant blast
	flash.local_coords = false # Let them sit in world space as the wand moves
	
	# Default Blast physics
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(1, 0, 0) # Forward
	mat.spread = 45.0 # Shotgun spread
	mat.initial_velocity_min = 100.0
	mat.initial_velocity_max = 250.0
	mat.damping_min = 200.0 # Stop them very quickly violently
	mat.damping_max = 400.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 1.0
	mat.scale_max = 2.0
	
	# Base Color fade
	var base_hdr_color = Color.WHITE
	if _light and _light.color:
		base_hdr_color = _light.color * 2.0
		
	# Apply behavior-specific muzzle features
	match behavior_name:
		"spark_bolt":
			mat.tangential_accel_min = -600.0
			mat.tangential_accel_max = 600.0
			mat.spread = 15.0
			mat.initial_velocity_min = 150.0
			mat.initial_velocity_max = 350.0
			mat.color_ramp = _create_complex_fade_gradient(Color(2.0, 2.0, 6.0), Color(0.2, 0.1, 1.0))
			flash.amount = 15 # fewer, but very erratic
		"fireball":
			mat.spread = 60.0 # big puff
			mat.initial_velocity_max = 150.0 # slow expanding
			var curve = CurveTexture.new()
			var c = Curve.new()
			c.add_point(Vector2(0, 0.5))
			c.add_point(Vector2(1, 4.0)) # rapid expansion
			curve.curve = c
			mat.scale_curve = curve
			mat.gravity = Vector3(0, -100, 0) # immediate rise
			mat.color_ramp = _create_complex_fade_gradient(Color(4.0, 3.0, 1.0), Color(0.5, 0.1, 0.0), true) # fades to dark grey
			flash.lifetime = 0.4
			flash.amount = 60
		"chainsaw":
			mat.spread = 90.0
			mat.direction = Vector3(-1, 0, 0) # Backwards blast
			mat.initial_velocity_min = 100.0
			mat.initial_velocity_max = 200.0
			mat.damping_min = 500.0
			mat.damping_max = 800.0
			mat.color_ramp = _create_complex_fade_gradient(Color(2.0, 2.0, 2.0), Color(1.5, 0.1, 0.2))
			flash.amount = 80
		"blackhole":
			mat.spread = 180.0
			mat.radial_accel_min = -300.0
			mat.radial_accel_max = -150.0
			mat.initial_velocity_min = 50.0
			mat.initial_velocity_max = 100.0
			mat.color_ramp = _create_complex_fade_gradient(Color(1.0, 0.0, 2.0), Color(0.1, 0.0, 0.5))
			flash.amount = 30
			flash.lifetime = 0.5
		"bouncing_burst":
			mat.spread = 180.0
			mat.initial_velocity_min = 150.0
			mat.initial_velocity_max = 300.0
			mat.gravity = Vector3(0, 800, 0) # Faster, bouncier drop
			mat.color_ramp = _create_complex_fade_gradient(Color(3.0, 1.5, 0.5), Color(1.0, 0.5, 0.0))
			mat.scale_min = 1.0
			mat.scale_max = 2.5
			# Flash behavior for lightweight bouncing sparks
			flash.amount = 40
			flash.explosiveness = 1.0
			flash.lifetime = 0.4
		_:
			mat.color_ramp = _create_pixel_fade_gradient(base_hdr_color)

	flash.process_material = mat
	add_child(flash)
	
	# Auto clean up (Ensure it is attached to the SceneTree first)
	if is_inside_tree():
		get_tree().create_timer(1.0).timeout.connect(flash.queue_free)
	else:
		# Fallback if called before added to tree completely
		flash.finished.connect(flash.queue_free)

func play_impact_effect():
	# Stop trail emission
	if _trail_particles:
		_trail_particles.emitting = false
	
	# Create Explosion Debris
	# We need to spawn this into the world, not as a child of this dying projectile
	var debris = GPUParticles2D.new()
	debris.material = CanvasItemMaterial.new()
	debris.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	debris.texture = _create_pixel_dot_texture()
	
	if behavior_name == "teleport":
		debris.amount = 100
		debris.lifetime = 1.0
	elif behavior_name == "tnt" or behavior_name == "cluster_bomb":
		debris.amount = 150
		debris.lifetime = 1.5
	else:
		debris.amount = 30
		debris.lifetime = 0.6
		
	debris.one_shot = true
	debris.explosiveness = 1.0
	debris.local_coords = true # Explode locally then stop
	
	# Physics for debris
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	
	if behavior_name == "teleport":
		mat.initial_velocity_min = 300.0
		mat.initial_velocity_max = 600.0
		mat.gravity = Vector3(0, 0, 0)
		mat.radial_accel_min = -200.0
		mat.radial_accel_max = -50.0
		mat.color_ramp = _create_pixel_fade_gradient(Color(3.0, 0.0, 8.0))
		mat.scale_min = 2.0
		mat.scale_max = 5.0
	elif behavior_name == "tnt" or behavior_name == "cluster_bomb":
		mat.initial_velocity_min = 400.0
		mat.initial_velocity_max = 800.0
		mat.gravity = Vector3(0, 500, 0)
		mat.color_ramp = _create_pixel_fade_gradient(Color(8.0, 0.5, 0.1))
		mat.scale_min = 4.0
		mat.scale_max = 8.0
	else:
		mat.initial_velocity_min = 100.0
		mat.initial_velocity_max = 200.0
		mat.gravity = Vector3(0, 400, 0) # Heavy gravity
		mat.scale_min = 2.0
		mat.scale_max = 4.0
		if _light: mat.color_ramp = _create_pixel_fade_gradient(_light.color)
	
	mat.collision_mode = ParticleProcessMaterial.COLLISION_RIGID
	mat.collision_friction = 0.5
	mat.collision_bounce = 0.5
	debris.process_material = mat
	# Set base size for collision
	debris.collision_base_size = 2.0

	# Reparent to world (or just keep running if we manage lifetime externaly)
	# Assuming projectile will queue_free soon, we must move this to root
	# But we can't easily access "World".
	# Hack: Add to GetTree().current_scene
	if is_inside_tree():
		get_tree().current_scene.add_child(debris)
		debris.global_position = global_position
		debris.emitting = true
		
		# Auto cleanup debris
		get_tree().create_timer(1.0).timeout.connect(debris.queue_free)


func setup(projectile: Node2D, behavior: String, element: String):
	# Cleanup previous setup
	for child in get_children():
		child.queue_free()
	
	_core_particles = null
	_trail_particles = null
	_secondary_trail_particles = null
	_light = null
	_lightning_lines.clear()
	_orbit_nodes.clear()
	_back_buffer = null
	_distortion_rect = null
	
	behavior_name = behavior
	if element: element_type = element
	
	# Reset State
	_pulse_speed = 0.0
	_pulse_amount = 0.0
	_jitter_amount = 0.5 # Default tiny jitter for everything (organic feel)
	_spin_speed = 0.0
	_orbit_speed = 0.0
	_base_scale = Vector2.ONE
	scale = Vector2.ONE
	rotation = 0.0
	_time_alive = 0.0
	
	# Setup Additive Material (The "Glow" key)
	var mat_add = CanvasItemMaterial.new()
	mat_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	
	# 1. SETUP CORE PARTICLES (High Density Head)
	_core_particles = GPUParticles2D.new()
	_core_particles.local_coords = true # Core stays with projectile
	_core_particles.material = mat_add
	_core_particles.texture = _create_pixel_dot_texture() # 1x1 only
	_core_particles.texture_filter = TextureFilter.TEXTURE_FILTER_NEAREST
	# Emit frequently to form a solid center
	_core_particles.amount = 100
	_core_particles.lifetime = 0.1
	add_child(_core_particles)
	
	# 2. SETUP TRAIL PARTICLES (The "Thick Trail")
	_trail_particles = GPUParticles2D.new()
	_trail_particles.local_coords = false # Global trails
	_trail_particles.material = mat_add
	_trail_particles.texture = _create_pixel_dot_texture() # 1x1 only
	_trail_particles.texture_filter = TextureFilter.TEXTURE_FILTER_NEAREST
	_trail_particles.fixed_fps = 0 # Updates as fast as possible
	_trail_particles.interpolate = true # Smooth movement between frames
	_trail_particles.collision_base_size = 1.0 # Tiny collision size for pixel sparks
	add_child(_trail_particles)

	# 3. SETUP LIGHT
	_light = PointLight2D.new()
	_light.texture = _create_soft_glow_texture()
	_light.texture_scale = 1.0
	_light.energy = 0.5 # Subdued soft light, let actual particles pop
	add_child(_light)
	
	# 4. APPLY BEHAVIOR IDENTITY
	_apply_behavior_identity()
	
	# Start emission
	if _core_particles:
		_core_particles.emitting = true
	if _trail_particles: 
		_trail_particles.emitting = true
	if _secondary_trail_particles:
		_secondary_trail_particles.emitting = true
	_is_setup = true

func _apply_behavior_identity():
	# --- DEFAULT: HYDRODYNAMIC PIXEL CLUSTER ---
	var core_color = Color(3.0, 3.0, 3.0) # HDR White default
	var rim_color = Color(0, 1, 1) # Cyan default
	
	# Core Particle Defaults (Tight jittering swarm)
	var c_mat = ParticleProcessMaterial.new()
	c_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	c_mat.emission_sphere_radius = 2.0
	c_mat.gravity = Vector3.ZERO
	c_mat.spread = 180.0
	c_mat.initial_velocity_min = 5.0
	c_mat.initial_velocity_max = 15.0
	c_mat.damping_min = 10.0
	c_mat.damping_max = 20.0
	c_mat.scale_min = 1.0
	c_mat.scale_max = 2.0
	_core_particles.process_material = c_mat
	
	# Trail Particle Defaults (Noita-like "Liquid/Gas" feel)
	var p_amount = 150
	var p_lifetime = 0.4
	
	match behavior_name:
		"magic_bolt":
			# ENERGY: Straight cyan light beam. Signature: High trail_length.
			core_color = Color(3.0, 4.0, 5.0)
			rim_color = MagicPalette.MAGIC_CORE
			
			c_mat.scale_min = 1.0
			c_mat.scale_max = 1.0
			c_mat.emission_sphere_radius = 1.0
			
			var p_mat = MagicParticleFactory.get_material_plasma()
			p_mat.scale_min = 2.0
			p_mat.scale_max = 2.0
			p_mat.gravity = Vector3.ZERO
			p_mat.spread = 0.0
			p_mat.turbulence_enabled = false
			p_mat.color_ramp = _create_complex_fade_gradient(core_color, Color(0, 0.4, 0.8))
			
			_trail_particles.process_material = p_mat
			_trail_particles.trail_enabled = true
			_trail_particles.trail_lifetime = 0.3
			p_amount = 50 # Lower amount needed for trails
			p_lifetime = 0.4
			
		"magic_arrow":
			# ENERGY: Purple razor-thin needle
			core_color = Color(5.0, 2.0, 5.0)
			rim_color = Color(0.6, 0.2, 1.0)
			
			c_mat.scale_min = 1.0
			c_mat.scale_max = 1.0
			c_mat.emission_sphere_radius = 0.5
			
			var p_mat = MagicParticleFactory.get_material_plasma()
			p_mat.scale_min = 1.0
			p_mat.scale_max = 1.0
			p_mat.gravity = Vector3.ZERO
			p_mat.spread = 0.0
			p_mat.turbulence_enabled = false
			p_mat.color_ramp = _create_complex_fade_gradient(core_color, rim_color)
			
			_trail_particles.process_material = p_mat
			_trail_particles.trail_enabled = true
			_trail_particles.trail_lifetime = 0.4
			p_amount = 30
			p_lifetime = 0.5
			
		"energy_sphere":
			# ENERGY: Slow pulsing orb
			core_color = Color(4.0, 4.0, 5.0)
			rim_color = Color(0.2, 0.8, 1.0)
			
			c_mat.emission_sphere_radius = 3.0
			
			var curve = CurveTexture.new()
			var c = Curve.new()
			c.add_point(Vector2(0, 0.5))
			c.add_point(Vector2(0.5, 1.5))
			c.add_point(Vector2(1, 0.2))
			curve.curve = c
			c_mat.scale_curve = curve
			
			var p_mat = MagicParticleFactory.get_material_plasma()
			p_mat.gravity = Vector3.ZERO
			p_mat.spread = 180.0
			p_mat.initial_velocity_min = 10.0
			p_mat.initial_velocity_max = 20.0
			p_mat.color_ramp = _create_complex_fade_gradient(core_color, rim_color)
			
			_trail_particles.process_material = p_mat
			p_amount = 100
			p_lifetime = 0.6
			
		"spark_bolt":
			# ELECTRIC: Chaotic blue discharge. Signature: Procedural Line2D arcs.
			core_color = Color(3.0, 3.0, 8.0) # Bright Purple-Blue
			rim_color = MagicPalette.SPARK_CORE
			
			c_mat.emission_sphere_radius = 1.0 # Tiny core
			c_mat.scale_max = 1.0
			
			# Add dynamic electric arcs
			for i in range(3):
				var line = Line2D.new()
				line.width = 1.0
				line.default_color = Color(1.5, 2.0, 5.0, 0.8)
				line.joint_mode = Line2D.LINE_JOINT_SHARP
				_lightning_lines.append(line)
				add_child(line)
			
			# Trail: Erratic spiral discharge
			var p_mat = MagicParticleFactory.get_material_sparks()
			p_mat.color_ramp = _create_complex_fade_gradient(core_color, Color(0.6, 0.2, 1.0))
			p_mat.spread = 25.0
			p_mat.initial_velocity_min = 50.0
			p_mat.initial_velocity_max = 150.0
			# VERY high tangential acceleration causes particles to spiral erratically radially
			p_mat.tangential_accel_min = -600.0
			p_mat.tangential_accel_max = 600.0
			p_mat.gravity = Vector3.ZERO
			
			_trail_particles.process_material = p_mat
			p_amount = 800 # Massive particle count for the storm
			p_lifetime = 0.3 # Brief snapping arcs
			
		"fireball":
			# Soul: Burning Chunk | Yellow-Orange Core | Falling Embers & Rising Smoke
			core_color = Color(4.0, 3.0, 1.0) # White-Yellow Core
			rim_color = MagicPalette.FIRE_CORE
			
			c_mat.emission_sphere_radius = 4.0 # Larger burning head
			c_mat.initial_velocity_min = 20.0
			c_mat.initial_velocity_max = 50.0
			
			# Trail 1: Falling, bouncing red embers
			var ember_mat = MagicParticleFactory.get_material_sparks()
			ember_mat.color_ramp = _create_complex_fade_gradient(core_color, Color(0.8, 0.2, 0.0))
			ember_mat.scale_min = 1.0
			ember_mat.scale_max = 2.0
			ember_mat.gravity = Vector3(0, 300, 0) # Fall quickly
			ember_mat.collision_mode = ParticleProcessMaterial.COLLISION_RIGID
			ember_mat.collision_bounce = 0.4
			ember_mat.collision_friction = 0.3
			_trail_particles.process_material = ember_mat
			p_amount = 60 # Embers are sparse
			p_lifetime = 0.6
			
			# Trail 2: Rising, scaling, thick grey smoke
			_secondary_trail_particles = GPUParticles2D.new()
			_secondary_trail_particles.local_coords = false
			_secondary_trail_particles.material = CanvasItemMaterial.new()
			_secondary_trail_particles.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			_secondary_trail_particles.texture = _create_pixel_dot_texture()
			_secondary_trail_particles.fixed_fps = 0
			_secondary_trail_particles.interpolate = true
			
			var smoke_mat = MagicParticleFactory.get_material_gas()
			# Fade to dark grey
			smoke_mat.color_ramp = _create_complex_fade_gradient(Color(2.0, 1.0, 0.2), Color(0.2, 0.1, 0.1), true)
			# Scale curve makes smoke chunks get huge and fuzzy
			var curve = CurveTexture.new()
			var c = Curve.new()
			c.add_point(Vector2(0, 0.5))
			c.add_point(Vector2(1, 4.0)) # Scales up 4x
			curve.curve = c
			smoke_mat.scale_curve = curve
			smoke_mat.gravity = Vector3(0, -90, 0) # Smoke rises naturally
			smoke_mat.turbulence_enabled = true
			smoke_mat.turbulence_noise_strength = 2.0
			
			_secondary_trail_particles.process_material = smoke_mat
			_secondary_trail_particles.amount = 150
			_secondary_trail_particles.lifetime = 0.8
			add_child(_secondary_trail_particles)
			
		"slime":
			# FLUID: Heavy thick poison
			var base_green = Color(0.2, 0.9, 0.2)
			core_color = base_green # No HDR blowing out, keep it solid
			rim_color = MagicPalette.POISON_RIM
			
			# Overwrite materials to use MIX instead of ADD
			_core_particles.material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
			_trail_particles.material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
			
			c_mat.emission_sphere_radius = 4.0
			c_mat.gravity = Vector3(0, 300, 0)
			
			var p_mat = MagicParticleFactory.get_material_plasma()
			p_mat.color_ramp = _create_complex_fade_gradient(base_green, Color(0.1, 0.5, 0.1))
			p_mat.gravity = Vector3(0, 500, 0) # Real heavy
			p_mat.spread = 30.0
			p_mat.initial_velocity_min = 20.0
			p_mat.initial_velocity_max = 60.0
			p_mat.scale_min = 2.0
			p_mat.scale_max = 4.0
			
			# Splash sub-emitter on collision
			var splash = ParticleProcessMaterial.new()
			splash.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			splash.emission_sphere_radius = 2.0
			splash.direction = Vector3(0, -1, 0)
			splash.initial_velocity_min = 50.0
			splash.initial_velocity_max = 100.0
			splash.gravity = Vector3(0, 600, 0)
			splash.color_ramp = _create_pixel_fade_gradient(base_green)
			p_mat.sub_emitter_mode = ParticleProcessMaterial.SUB_EMITTER_AT_COLLISION
			p_mat.sub_emitter_amount_at_collision = 3
			
			_trail_particles.sub_emitter = NodePath(".") # We need a child sub-emitter node, but to keep it simple we can just map it or wait, in GPUParticles2D, sub-emitter is another GPUParticles2D!
			# Let's add the sub-emitter node proper
			var sub_particles = GPUParticles2D.new()
			sub_particles.material = CanvasItemMaterial.new()
			sub_particles.material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
			sub_particles.texture = _create_pixel_dot_texture()
			sub_particles.amount = 50
			sub_particles.lifetime = 0.5
			sub_particles.explosiveness = 1.0
			sub_particles.process_material = splash
			add_child(sub_particles)
			
			_trail_particles.sub_emitter = sub_particles.get_path()
			p_mat.collision_mode = ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT
			
			_trail_particles.process_material = p_mat
			p_amount = 150
			p_lifetime = 0.6

		"bouncing_burst":
			# PLASMA: Extremely energetic hyper-bouncing neon energy star
			core_color = Color(3.0, 2.0, 0.5) # Blinding Neon Orange/Yellow
			rim_color = Color(3.0, 1.0, 0.0) # Highly vibrant rim

			_pulse_speed = 30.0 # Fast pulsing
			_pulse_amount = 0.3 
			_jitter_amount = 3.0 
			_spin_speed = 25.0 

			_core_particles.texture = _create_dense_core_texture()
			_core_particles.texture_filter = TextureFilter.TEXTURE_FILTER_LINEAR
			_core_particles.amount = 20 # Kept small and light

			c_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			c_mat.emission_sphere_radius = 0.5 # Tiny core radius
			c_mat.scale_min = 0.5
			c_mat.scale_max = 1.0
			c_mat.gravity = Vector3(0, 0, 0)

			# Trail 1: Tiny bright erratic sparks
			var p_mat = MagicParticleFactory.get_material_sparks()
			p_mat.color_ramp = _create_complex_fade_gradient(core_color, rim_color)
			p_mat.gravity = Vector3(0, 400, 0) # Fall moderately
			p_mat.spread = 180.0 
			p_mat.initial_velocity_min = 50.0
			p_mat.initial_velocity_max = 100.0
			p_mat.collision_mode = ParticleProcessMaterial.COLLISION_RIGID
			p_mat.collision_bounce = 1.0 # Absolutely NO energy loss on hit
			p_mat.collision_friction = 0.0
			p_mat.scale_min = 0.5 # Extremely tiny and vibrant sparks
			p_mat.scale_max = 1.0

			_trail_particles.process_material = p_mat
			p_amount = 40 # Sparse clean particles
			p_lifetime = 0.5

			# Trail 2: Thin Energy Ribbon 
			_secondary_trail_particles = GPUParticles2D.new()
			_secondary_trail_particles.local_coords = false
			_secondary_trail_particles.material = CanvasItemMaterial.new()
			_secondary_trail_particles.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			_secondary_trail_particles.texture = _create_pixel_dot_texture()
			
			var ribbon_mat = MagicParticleFactory.get_material_plasma()
			ribbon_mat.color_ramp = _create_complex_fade_gradient(rim_color, Color(1.0, 0.0, 0.0, 0.0))
			ribbon_mat.scale_min = 0.5 # Ribbon is basically a 1-2px line
			ribbon_mat.scale_max = 1.0
			ribbon_mat.gravity = Vector3.ZERO
			ribbon_mat.initial_velocity_min = 0.0
			ribbon_mat.initial_velocity_max = 0.0

			_secondary_trail_particles.process_material = ribbon_mat
			_secondary_trail_particles.amount = 50
			_secondary_trail_particles.lifetime = 0.2

			add_child(_secondary_trail_particles)
		"chainsaw":
			# ELECTRIC: Extreme forward friction sparks
			core_color = Color(3.0, 3.0, 3.0)
			rim_color = Color(1.5, 0.1, 0.2)
			
			c_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
			c_mat.emission_sphere_radius = 0.5
			c_mat.gravity = Vector3.ZERO
			
			var p_mat = MagicParticleFactory.get_material_sparks()
			p_mat.color_ramp = _create_complex_fade_gradient(Color(2.0, 2.0, 2.0), rim_color)
			p_mat.gravity = Vector3(0, 100, 0)
			p_mat.initial_velocity_min = 250.0 
			p_mat.initial_velocity_max = 500.0
			p_mat.direction = Vector3(-1, 0, 0) 
			p_mat.spread = 45.0
			p_mat.damping_min = 500.0
			p_mat.damping_max = 800.0
			
			_trail_particles.process_material = p_mat
			p_amount = 500 
			p_lifetime = 0.15 
			
		"tnt", "cluster_bomb":
			# HEAVY ORDNANCE: High density glowing fireball with shrapnel and thick smoke
			core_color = Color(8.0, 0.5, 0.1) # Extreme bright intense yellow/red
			rim_color = Color(2.0, 0.3, 0.0)

			_pulse_speed = 30.0 # Rapid strobing
			_pulse_amount = 0.3 # Size scales wildly
			_jitter_amount = 3.0 # Shaking violently
			_spin_speed = 10.0 # Tumbling wildly

			# Smooth glowing core instead of blocky pixels
			_core_particles.texture = _create_soft_glow_texture()
			_core_particles.texture_filter = TextureFilter.TEXTURE_FILTER_LINEAR
			_core_particles.amount = 40
			
			c_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			c_mat.emission_sphere_radius = 4.0
			c_mat.scale_min = 0.6
			c_mat.scale_max = 1.2

			# Trail 1: Wild sparks (small sharp shards)
			var p_mat = MagicParticleFactory.get_material_sparks()
			p_mat.color_ramp = _create_complex_fade_gradient(Color(5.0, 2.0, 0.0), Color(1.0, 0.0, 0.0))
			p_mat.scale_min = 1.0 # Smaller, sharper pixels
			p_mat.scale_max = 2.5
			p_mat.gravity = Vector3(0, 500, 0) # Heavy falling sparks
			p_mat.initial_velocity_min = 150.0
			p_mat.initial_velocity_max = 400.0
			p_mat.spread = 180.0
			p_mat.damping_min = 150.0
			p_mat.damping_max = 300.0
			p_mat.collision_mode = ParticleProcessMaterial.COLLISION_RIGID
			p_mat.collision_bounce = 0.4
			_trail_particles.process_material = p_mat
			p_amount = 250
			p_lifetime = 1.2

			# Trail 2: Thick black smoke trailing behind
			_secondary_trail_particles = GPUParticles2D.new()
			_secondary_trail_particles.local_coords = false
			_secondary_trail_particles.material = CanvasItemMaterial.new()
			_secondary_trail_particles.material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
			_secondary_trail_particles.texture = _create_soft_glow_texture()
			
			var smoke_mat = MagicParticleFactory.get_material_plasma()
			smoke_mat.color_ramp = _create_complex_fade_gradient(Color(0.2, 0.1, 0.1, 0.9), Color(0.0, 0.0, 0.0, 0.0))
			smoke_mat.scale_min = 0.6 # Reduced scale due to larger base texture
			smoke_mat.scale_max = 1.2
			smoke_mat.gravity = Vector3(0, -60, 0) # Drifts up
			smoke_mat.initial_velocity_min = 10.0
			smoke_mat.initial_velocity_max = 40.0
			
			_secondary_trail_particles.process_material = smoke_mat
			_secondary_trail_particles.amount = 150
			_secondary_trail_particles.lifetime = 1.5
			add_child(_secondary_trail_particles)
			
		"tri_bolt":
			# ENERGY: 3 distinct spiraling orbs
			core_color = Color(1.0, 5.0, 2.0) # Bright neon orange/pink
			rim_color = Color(0.2, 1.0, 0.4) 
			
			_orbit_speed = 15.0 # Very fast spin
			
			# Main core invisible, we just use the 3 orbs
			c_mat.scale_min = 0.5
			c_mat.scale_max = 1.0
			
			# Turn off default trail, we will instance 3 distinct ones
			_trail_particles.emitting = false
			p_amount = 0
			
			# Create 3 orbiting emitters
			var orbit_radius = 12.0
			for i in range(3):
				var angle = i * (TAU / 3.0)
				var pivot = Node2D.new()
				add_child(pivot)
				_orbit_nodes.append(pivot)
				
				# The actual rotating offset
				var offset_node = Node2D.new()
				offset_node.position = Vector2(cos(angle), sin(angle)) * orbit_radius
				pivot.add_child(offset_node)
				
				var orb_trail = GPUParticles2D.new()
				orb_trail.local_coords = false # Leave trails in world space!
				orb_trail.material = CanvasItemMaterial.new()
				orb_trail.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
				orb_trail.texture = _create_soft_glow_texture()
				
				var mat = MagicParticleFactory.get_material_plasma()
				mat.scale_min = 1.5
				mat.scale_max = 2.0
				mat.color_ramp = _create_complex_fade_gradient(core_color, rim_color)
				mat.gravity = Vector3.ZERO
				orb_trail.process_material = mat
				orb_trail.amount = 50
				orb_trail.lifetime = 0.3
				orb_trail.trail_enabled = true
				orb_trail.trail_lifetime = 0.2
				
				offset_node.add_child(orb_trail)

		"teleport":
			# VOID: Highly magical fast spatial rip, leaves twisting sparkles
			core_color = Color(3.0, 0.0, 8.0) # Bright magic purple core
			rim_color = Color(1.0, 0.0, 3.0) 
			
			_pulse_speed = 15.0 
			_pulse_amount = 0.2
			_spin_speed = 20.0
			
			c_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			c_mat.emission_sphere_radius = 4.0
			c_mat.scale_min = 2.0
			c_mat.scale_max = 3.0
			
			# Huge sweeping vortex trail
			var p_mat = MagicParticleFactory.get_material_plasma()
			p_mat.scale_min = 2.0
			p_mat.scale_max = 4.0
			p_mat.radial_accel_min = -200.0 # Pulls inwards
			p_mat.radial_accel_max = -50.0
			p_mat.tangential_accel_min = 200.0 # Spins fast
			p_mat.tangential_accel_max = 400.0
			p_mat.color_ramp = _create_complex_fade_gradient(Color(2.0, 0.5, 4.0), Color(0.2, 0.0, 1.0))
			_trail_particles.process_material = p_mat
			p_amount = 300
			p_lifetime = 0.6
			
			# Secondary magic sparkles
			_secondary_trail_particles = GPUParticles2D.new()
			_secondary_trail_particles.local_coords = false
			_secondary_trail_particles.material = CanvasItemMaterial.new()
			_secondary_trail_particles.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			_secondary_trail_particles.texture = _create_pixel_dot_texture()
			
			var s_mat = MagicParticleFactory.get_material_sparks()
			s_mat.color_ramp = _create_complex_fade_gradient(Color(5.0, 2.0, 10.0), Color(1.0, 0.0, 2.0))
			s_mat.scale_min = 1.0
			s_mat.scale_max = 2.0
			s_mat.gravity = Vector3(0, -100, 0) # Float up
			s_mat.initial_velocity_min = 10.0
			s_mat.initial_velocity_max = 50.0
			s_mat.spread = 180.0
			s_mat.turbulence_enabled = true
			s_mat.turbulence_noise_strength = 2.0
			
			_secondary_trail_particles.process_material = s_mat
			_secondary_trail_particles.amount = 150
			_secondary_trail_particles.lifetime = 1.0
			add_child(_secondary_trail_particles)
			
		"blackhole":
			# VOID: Light-eating abyss with Screen Distortion
			core_color = Color(0.0, 0.0, 0.0) 
			rim_color = Color(0.5, 0.0, 1.0) 
			
			# Core uses Subtractive Mode to create absolute black
			_core_particles.material.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
			_trail_particles.material.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
			
			# Setup Distortion FX
			_back_buffer = BackBufferCopy.new()
			_back_buffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
			add_child(_back_buffer)
			
			_distortion_rect = ColorRect.new()
			var shader = Shader.new()
			shader.code = """
			shader_type canvas_item;
			uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
			uniform float strength = 0.08;

			void fragment() {
				vec2 dir = UV - vec2(0.5);
				float dist = length(dir);
				// Pull pixels deeply inward
				vec2 offset = normalize(dir) * (strength * smoothstep(0.5, 0.0, dist));
				vec4 c = texture(screen_texture, SCREEN_UV - offset);
				
				// Keep distortion contained in a circle, blending to 0 alpha at edges
				float alpha_mask = smoothstep(0.5, 0.45, dist);
				COLOR = vec4(c.rgb, alpha_mask * c.a);
			}
			"""
			var smaterial = ShaderMaterial.new()
			smaterial.shader = shader
			_distortion_rect.material = smaterial
			_distortion_rect.color = Color(1, 1, 1, 0) # Make the base rect transparent so it doesn't draw a white square
			_distortion_rect.custom_minimum_size = Vector2(80, 80)
			_distortion_rect.position = Vector2(-40, -40)
			add_child(_distortion_rect)
			
			c_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			c_mat.emission_sphere_radius = 6.0
			c_mat.gravity = Vector3.ZERO
			c_mat.color_ramp = _create_pixel_fade_gradient(Color(1.0, 1.0, 1.0, 1.0)) # Subtracts full white -> becomes black
			
			# Purple Ring
			var p_mat = MagicParticleFactory.get_material_plasma()
			p_mat.color_ramp = _create_complex_fade_gradient(Color(1.0, 1.0, 1.0), Color(0.8, 0.8, 0.8)) # Deep subtractive shadow
			p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			p_mat.emission_ring_radius = 20.0
			p_mat.emission_ring_inner_radius = 18.0
			p_mat.radial_accel_min = -150.0 
			p_mat.radial_accel_max = -100.0
			p_mat.gravity = Vector3.ZERO
			p_mat.tangential_accel_min = 50.0 
			p_mat.tangential_accel_max = 100.0
			
			_secondary_trail_particles = GPUParticles2D.new()
			_secondary_trail_particles.local_coords = false
			_secondary_trail_particles.material = CanvasItemMaterial.new()
			_secondary_trail_particles.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			_secondary_trail_particles.texture = _create_pixel_dot_texture()
			_secondary_trail_particles.fixed_fps = 0
			_secondary_trail_particles.interpolate = true
			
			var s_mat = MagicParticleFactory.get_material_sparks()
			s_mat.color_ramp = _create_complex_fade_gradient(Color(2.0, 0.0, 3.0), Color(0.3, 0.0, 1.0))
			s_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			s_mat.emission_sphere_radius = 50.0
			s_mat.radial_accel_min = -300.0
			s_mat.radial_accel_max = -200.0
			s_mat.gravity = Vector3.ZERO
			_secondary_trail_particles.process_material = s_mat
			_secondary_trail_particles.amount = 100
			_secondary_trail_particles.lifetime = 0.5
			add_child(_secondary_trail_particles)
			
			_trail_particles.process_material = p_mat
			p_amount = 200 # Dense ring
			p_lifetime = 0.4 

		_:
			# Falback
			core_color = MagicPalette.MAGIC_CORE * 3.0
			rim_color = MagicPalette.MAGIC_CORE
			_trail_particles.process_material = MagicParticleFactory.get_material_plasma()
			_trail_particles.process_material.color_ramp = _create_pixel_fade_gradient(rim_color)

	# --- APPLY ---
	# Assign the specific colors to the new core particles
	c_mat.color_ramp = _create_pixel_fade_gradient(core_color)
	
	if behavior_name == "blackhole":
		_light.visible = false
	else:
		_light.color = rim_color
		# Give the light a slight scale based on how big the particle emission is
		_light.texture_scale = 0.5 + (c_mat.emission_sphere_radius * 0.1)
	
	if _trail_particles:
		_trail_particles.amount = p_amount
		_trail_particles.lifetime = p_lifetime


func _create_dense_core_texture() -> Texture2D:
	# 4x4 White Block with slight transparency on corners to soften it 
	# effectively a tiny circle in pixel art
	var img = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(1,1,1,1))
	# Knock out corners for "round" pixel look
	img.set_pixel(0,0, Color(1,1,1,0))
	img.set_pixel(3,0, Color(1,1,1,0))
	img.set_pixel(0,3, Color(1,1,1,0))
	img.set_pixel(3,3, Color(1,1,1,0))
	
	return ImageTexture.create_from_image(img)

func _create_pixel_dot_texture() -> Texture2D:
	# 1x1 Solid White
	var grad = Gradient.new()
	grad.set_color(0, Color(1,1,1,1))
	grad.set_color(1, Color(1,1,1,1))
	
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 1
	tex.height = 1
	return tex

func _create_soft_glow_texture() -> Texture2D:
	# 32x32 Radial Falloff
	var grad = Gradient.new()
	grad.set_color(0, Color(1,1,1,1))
	grad.set_color(1, Color(1,1,1,0))
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.9, 0.5) # Prevents square clipping
	tex.width = 64
	tex.height = 64
	return tex

func _create_pixel_fade_gradient(color: Color) -> GradientTexture1D:
	var grad = Gradient.new()
	grad.set_color(0, color)
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var tex = GradientTexture1D.new()
	tex.gradient = grad
	tex.width = 16
	return tex

func _create_complex_fade_gradient(core_hdr_color: Color, tail_color: Color, fade_to_black: bool = false) -> GradientTexture1D:
	var grad = Gradient.new()
	var final_color = Color(0, 0, 0, 0.0) if fade_to_black else Color(tail_color.r, tail_color.g, tail_color.b, 0.0)
	
	# Default Gradient has 2 points at 0.0 and 1.0. Modify them directly and add the in-betweens.
	grad.set_color(0, core_hdr_color)
	grad.set_color(1, final_color)
	
	grad.add_point(0.2, tail_color * 1.5)
	grad.add_point(0.7, tail_color)
	
	var tex = GradientTexture1D.new()
	tex.gradient = grad
	tex.width = 32
	return tex
