extends Node
class_name MagicParticleFactory

# Factor method creates generic templates.
# Tuning (color, gravity override) happens in Visualizer.

static func get_material_plasma() -> ParticleProcessMaterial:
	var mat = ParticleProcessMaterial.new()
	mat.gravity = Vector3(0, 20, 0) # Slight gravity for "Heavy" feel
	mat.direction = Vector3(-1, 0, 0)
	mat.spread = 10.0 # Tight stream by default
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 80.0
	mat.damping_min = 10.0 # Air resistance
	mat.damping_max = 20.0
	mat.scale_min = 1.0
	mat.scale_max = 1.0
	# Turbulence adds that "messy" look from Noita
	mat.turbulence_enabled = true
	mat.turbulence_noise_strength = 2.0
	mat.turbulence_noise_scale = 4.0
	return mat

static func get_material_sparks() -> ParticleProcessMaterial:
	var mat = ParticleProcessMaterial.new()
	mat.gravity = Vector3(0, 200, 0) # Heavy sparks fall fast
	mat.direction = Vector3(-1, 0, 0) # Generally backwards
	mat.spread = 60.0 # Wide chaotic spread
	mat.initial_velocity_min = 100.0
	mat.initial_velocity_max = 300.0 # Very fast burst
	mat.damping_min = 50.0 # Slow down quickly
	mat.damping_max = 100.0
	mat.scale_min = 1.0
	mat.scale_max = 1.0
	
	# Physics
	mat.collision_mode = ParticleProcessMaterial.COLLISION_RIGID
	mat.collision_friction = 0.2
	mat.collision_bounce = 0.6 # Bouncy sparks
	return mat

static func get_material_gas() -> ParticleProcessMaterial:
	var mat = ParticleProcessMaterial.new()
	mat.gravity = Vector3(0, -50, 0) # Rises fast
	mat.direction = Vector3(-1, 0, 0)
	mat.spread = 180.0 # Explodes everywhere
	mat.initial_velocity_min = 10.0
	mat.initial_velocity_max = 50.0
	mat.damping_min = 5.0
	mat.damping_max = 15.0
	mat.scale_min = 1.0
	mat.scale_max = 3.0 # Grows into smoke
	
	# Gas turbulence
	mat.turbulence_enabled = true
	mat.turbulence_noise_strength = 5.0
	mat.turbulence_noise_speed = Vector3(0, 1, 0)
	return mat

static func get_material_void() -> ParticleProcessMaterial:
	var mat = ParticleProcessMaterial.new()
	mat.gravity = Vector3(0, 0, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mat.emission_ring_radius = 30.0
	mat.radial_accel_min = -150.0 # Strong suck
	mat.radial_accel_max = -300.0
	mat.scale_min = 1.0
	mat.scale_max = 0.1 # Shrink to nothing
	mat.turbulence_enabled = true
	return mat

static func get_material_slime() -> ParticleProcessMaterial:
	var mat = ParticleProcessMaterial.new()
	mat.gravity = Vector3(0, 98, 0)
	mat.direction = Vector3(0, 1, 0) # Drip down
	mat.spread = 10.0
	mat.initial_velocity_min = 0.0
	mat.initial_velocity_max = 20.0
	# Sticky collision? Not easily doable in particles without custom shader, but we can make them heavy.
	return mat
