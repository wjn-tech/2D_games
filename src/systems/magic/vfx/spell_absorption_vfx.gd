extends Node2D

var target_node: Node2D
var particles: Array[ColorRect] = [] 
var particle_velocities: Array[Vector2] = []

var particle_count := 40 # Increased particle count
var burst_speed := 400.0 # Initial explosion speed
var absorb_acceleration := 3500.0 # Strong pull force
var drag := 4.0 # Friction for the initial burst

signal all_absorbed

func _ready() -> void:
	z_index = 101 # Above almost everything

func setup(start_pos: Vector2, target: Node2D, color: Color = Color.CYAN):
	global_position = start_pos
	target_node = target
	
	for i in range(particle_count):
		var p = ColorRect.new()
		# Random sizes (some small, some large chunks)
		var size = randf_range(2.0, 5.0)
		p.custom_minimum_size = Vector2(size, size)
		p.size = Vector2(size, size)
		
		# Varied colors
		var c = color
		c.v = clamp(c.v * randf_range(0.8, 1.5), 0.0, 1.0) # Brightness variance
		c.a = randf_range(0.8, 1.0)
		p.color = c
		
		# Center pivot
		p.pivot_offset = Vector2(size/2, size/2)
		p.position = -p.pivot_offset
		
		add_child(p)
		
		# Initial Burst Logic: Explode OUTWARDS
		var angle = randf() * TAU
		var dist = randf_range(0, 10) # Start clustered near center
		p.position += Vector2(cos(angle), sin(angle)) * dist
		
		# Velocity vector for proper physics simulation
		var burst_dir = Vector2(cos(angle), sin(angle))
		var v = burst_dir * randf_range(burst_speed * 0.2, burst_speed * 1.0)
		
		particles.append(p)
		particle_velocities.append(v)
		
		# Random rotation
		p.rotation = randf() * TAU

func _process(delta: float):
	if not is_instance_valid(target_node):
		queue_free()
		return
		
	var target_pos = target_node.global_position
	# Adjust target pos to aim for chest/center (assuming target pivot is feet)
	target_pos.y -= 16.0 
	
	var active_particles = 0
	
	for i in range(particles.size()):
		var p = particles[i]
		if not p.visible: continue
		
		active_particles += 1
		
		var global_p_pos = global_position + p.position
		var to_target = target_pos - global_p_pos
		var dist_sq = to_target.length_squared()
		var dir = to_target.normalized()
		
		# 1. Physics: Apply Forces
		
		# Attraction: Weak at start (let burst happen), strong later
		# We can simulate this by having distinct phases or just distance checks
		# Simple approach: Always attract but drag fights it initially
		
		var attraction = absorb_acceleration
		if dist_sq < 2500: attraction *= 2.0 # Super suck at close range (50px)
		
		# Tangential force (Swirl)
		var tangent = Vector2(-dir.y, dir.x)
		var swirl_force = 1000.0 * (1.0 if i % 2 == 0 else -1.0)
		
		# Apply forces to velocity
		particle_velocities[i] += dir * attraction * delta
		particle_velocities[i] += tangent * swirl_force * delta * 0.1 # Slight swirl
		
		# Drag/Friction (simulates air resistance)
		particle_velocities[i] = particle_velocities[i].move_toward(Vector2.ZERO, drag * particle_velocities[i].length() * delta)
		
		# Update Position
		p.position += particle_velocities[i] * delta
		
		# 2. Visuals: Rotate and Scale based on movement
		
		# Stretch effect based on velocity (Squash & Stretch)
		var speed = particle_velocities[i].length()
		if speed > 10.0:
			var scale_factor = 1.0 + clamp(speed / 1500.0, 0.0, 1.5)
			p.scale = Vector2(scale_factor, 1.0 / scale_factor)
			p.rotation = particle_velocities[i].angle()
		
		# 3. Absorption Check
		if dist_sq < 225.0: # Close enough (15px radius)
			p.visible = false
			
	if active_particles == 0:
		all_absorbed.emit()
		_spawn_final_flash(target_pos)
		set_process(false)

func _spawn_final_flash(pos: Vector2):
	# Simple flash circle
	var flash = ColorRect.new()
	flash.color = particles[0].color # Use base color
	flash.color.a = 1.0
	flash.size = Vector2(50, 50)
	flash.pivot_offset = flash.size / 2
	# Convert global pos to our local space for the child, OR just make it top-level
	# Actually, since we are about to queue_free, let's add it to the PARENT (the world) or just handle it here and delay death.
	
	# Easiest: Add to self, keep self alive for animation
	flash.position = to_local(pos) - flash.pivot_offset
	flash.rotation = randf() * TAU
	flash.z_index = 102
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "scale", Vector2(0.1, 0.1), 0.05).from(Vector2(1.5, 1.5)) # Implode
	tween.tween_property(flash, "scale", Vector2(2.0, 2.0), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) # Explode
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)

