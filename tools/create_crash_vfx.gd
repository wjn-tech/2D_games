@tool
extends EditorScript

func _run():
	create_ship_debris()
	create_wind_lines()
	create_mage_shield()

func create_ship_debris():
	var particles = CPUParticles2D.new()
	particles.name = "ShipDebris"
	particles.amount = 30
	particles.lifetime = 2.0
	particles.explosiveness = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 50.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 500)
	particles.initial_velocity_min = 200.0
	particles.initial_velocity_max = 400.0
	particles.angular_velocity_min = -360.0
	particles.angular_velocity_max = 360.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 3.0
	# Use color ramp to fade out
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	particles.color_ramp = gradient
	
	# Load texture if available
	if FileAccess.file_exists("res://assets/visuals/spaceship/particle_debris.png"):
		particles.texture = load("res://assets/visuals/spaceship/particle_debris.png")
	
	save_scene(particles, "res://scenes/vfx/ship_debris.tscn")

func create_wind_lines():
	var wind = CPUParticles2D.new()
	wind.name = "WindLines"
	wind.amount = 50
	wind.lifetime = 0.5
	wind.preprocess = 0.5
	# Emission box at top of screen moving down
	wind.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	wind.emission_rect_extents = Vector2(600, 10)
	wind.direction = Vector2(0, -1) # Particles move Up relative to player to simulate falling Down
	wind.spread = 0.0
	wind.gravity = Vector2(0, 0)
	wind.initial_velocity_min = 800.0
	wind.initial_velocity_max = 1200.0
	wind.scale_amount_min = 1.0
	wind.scale_amount_max = 2.0
	wind.color = Color(1, 1, 1, 0.3)
	
	# Create a simple line texture via code or reuse spark stretched
	if FileAccess.file_exists("res://assets/visuals/spaceship/particle_spark.png"):
		wind.texture = load("res://assets/visuals/spaceship/particle_spark.png")
		# We need to stretch it. CPUParticles doesn't support non-uniform scaling easily directly on texture without shader
		# But we can assume the spark is somewhat elongated or just rely on speed blur perception
	
	save_scene(wind, "res://scenes/vfx/falling_wind_lines.tscn")

func create_mage_shield():
	var shield_root = Node2D.new()
	shield_root.name = "MageShield"
	
	var aura = CPUParticles2D.new()
	aura.name = "Aura"
	aura.amount = 30
	aura.lifetime = 1.0
	aura.texture = load("res://assets/visuals/spaceship/particle_spark.png")
	aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	aura.emission_sphere_radius = 40.0
	aura.gravity = Vector2(0, 0)
	aura.radial_accel_min = -20.0
	aura.radial_accel_max = -50.0 # Suck in effect
	aura.tangential_accel_min = 20.0
	aura.tangential_accel_max = 50.0 # Swirl
	aura.scale_amount_min = 0.5
	aura.scale_amount_max = 1.5
	aura.color = Color(0.2, 0.5, 1.0, 0.6) # Blue magic
	shield_root.add_child(aura)
	aura.owner = shield_root
	
	# Add a subtle circle line
	var circle = Line2D.new()
	circle.name = "ShieldRing"
	var points = PackedVector2Array()
	for i in range(33):
		var angle = i * TAU / 32.0
		points.append(Vector2(cos(angle), sin(angle)) * 40.0)
	circle.points = points
	circle.width = 2.0
	circle.default_color = Color(0.4, 0.8, 1.0, 0.4)
	shield_root.add_child(circle)
	circle.owner = shield_root

	save_scene(shield_root, "res://scenes/vfx/mage_shield_aura.tscn")

func save_scene(node, path):
	var packed_scene = PackedScene.new()
	packed_scene.pack(node)
	ResourceSaver.save(packed_scene, path)
	print("Saved " + path)
