extends Node
class_name MagicVisualManager
## Responsibilities: Caching and providing shader materials and particle configurations

static var materials = {}

static func get_energy_material(color: Color = Color(0.2, 0.5, 1.0)) -> ShaderMaterial:
	var key = "energy_" + str(color.to_html())
	if key in materials:
		return materials[key]
	
	var mat = ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/magic/magic_energy.gdshader")
	mat.set_shader_parameter("base_color", color)
	mat.set_shader_parameter("glow_color", color * 5.0) # Boost for bloom
	
	# High-frequency noise for plasma movement
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.08
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	var tex = NoiseTexture2D.new()
	tex.seamless = true
	tex.noise = noise
	mat.set_shader_parameter("noise_tex", tex)
	
	materials[key] = mat
	return mat

static func get_element_particles(element: String) -> ParticleProcessMaterial:
	var key = "particles_" + element
	if key in materials:
		return materials[key]
	
	var mat = ParticleProcessMaterial.new()
	mat.turbulence_enabled = true
	
	match element:
		"fire":
			# "Magma Surge" - Thick, intense, blood-orange heat
			mat.gravity = Vector3(0, -150, 0)
			mat.initial_velocity_min = 120.0
			mat.initial_velocity_max = 240.0
			mat.spread = 30.0
			mat.damping_min = 50.0
			mat.damping_max = 80.0
			mat.scale_min = 1.5
			mat.scale_max = 4.5
			mat.turbulence_noise_strength = 15.0 # Violent magma churning
			
			var grad = Gradient.new()
			grad.set_offsets([0.0, 0.15, 0.4, 0.7, 1.0])
			grad.set_colors([
				Color(40.0, 15.0, 2.0), # Blinding Magma Core
				Color(20.0, 2.0, 0.1),  # Blood Orange
				Color(5.0, 0.1, 0.0),   # Dark Crimson
				Color(0.1, 0.05, 0.05, 0.4), # Thick Soot
				Color(0,0,0,0)
			])
			var g_tex = GradientTexture1D.new()
			g_tex.gradient = grad
			mat.color_ramp = g_tex
			
		"ice":
			# "Glacial Spear" - Sharp, piercing, absolute cold
			mat.gravity = Vector3(0, 30, 0)
			mat.initial_velocity_min = 60.0
			mat.initial_velocity_max = 150.0
			mat.damping_min = 15.0
			mat.damping_max = 30.0
			mat.scale_min = 2.0
			mat.scale_max = 4.0
			mat.particle_flag_align_y = true # Make them look like shards
			
			var grad = Gradient.new()
			grad.set_colors([
				Color(10.0, 40.0, 100.0), # Intense Frost Cyan
				Color(1.0, 5.0, 20.0),    # Deep Ocean Ice
				Color(0.0, 0.2, 0.5, 0.0)
			])
			var g_tex = GradientTexture1D.new()
			g_tex.gradient = grad
			mat.color_ramp = g_tex
			
		"slime":
			# "Deep Jungle Slime" - Thick, rich, concentrated green
			mat.gravity = Vector3(0, 600, 0) 
			mat.initial_velocity_min = 80.0
			mat.initial_velocity_max = 200.0
			mat.scale_min = 6.0
			mat.scale_max = 12.0
			mat.damping_min = 80.0
			mat.damping_max = 120.0
			mat.turbulence_noise_strength = 5.0
			
			var grad = Gradient.new()
			grad.set_offsets([0.0, 0.2, 0.8, 1.0])
			grad.set_colors([
				Color(0.2, 12.0, 0.2), # Deep Glowing Emerald
				Color(0.05, 4.0, 0.05), # Dark Moss Green
				Color(0.01, 1.5, 0.01), # Shadow Green
				Color(0,0,0,0)
			])
			var g_tex = GradientTexture1D.new()
			g_tex.gradient = grad
			mat.color_ramp = g_tex
			
			# Bubbling scale curve: Pop and vanish
			var curve_res = CurveTexture.new()
			var curve = Curve.new()
			curve.add_point(Vector2(0, 0.8))
			curve.add_point(Vector2(0.5, 1.2))
			curve.add_point(Vector2(1.0, 0.0))
			curve_res.curve = curve
			mat.scale_curve = curve_res
			
		_: # Arcane/Default
			mat.gravity = Vector3.ZERO
			mat.initial_velocity_min = 50.0
			mat.initial_velocity_max = 100.0
			mat.damping_min = 10.0
			mat.damping_max = 20.0
			mat.scale_min = 1.0
			mat.scale_max = 2.0
			mat.orbit_velocity_min = 0.5
			mat.orbit_velocity_max = 2.0
			
			var grad = Gradient.new()
			grad.set_colors([Color(5.0, 2.0, 30.0), Color(1, 0, 2, 0)])
			var g_tex = GradientTexture1D.new()
			g_tex.gradient = grad
			mat.color_ramp = g_tex
			
	materials[key] = mat
	return mat
