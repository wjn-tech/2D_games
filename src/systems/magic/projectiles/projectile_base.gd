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

# Logic
var modifiers: Array = []
var _fly_time: float = 0.0

# Components
var trail: Line2D

func setup(params: Dictionary, mods: Array):
	if "speed" in params: speed = float(params.speed)
	if "lifetime" in params: lifetime = float(params.lifetime)
	if "damage" in params: damage = float(params.damage)
	
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
	# Instead of changing color based on 'element' variable (which overwrites),
	# we iterate modifiers again or use cached set of elements.
	# Actually, visual.color can be a blend, but particles are better.
	
	if not visual: return
	visual.color = Color.WHITE # Base color
	
	for mod in modifiers:
		var type = mod.get("wand_logic_type", "")
		if type == "": type = mod.get("type", "") 
		var val = mod.get("value", {})
		if val.is_empty(): val = mod.get("wand_logic_value", {})
		
		# Overlay stacking visual effects
		if type == "modifier_element":
			var el = val.get("element", "none")
			_add_elemental_effect(el)

func _add_elemental_effect(type: String):
	# Procedurally create particles if resources missing
	if type == "fire":
		var particles = CPUParticles2D.new()
		particles.amount = 12
		particles.lifetime = 0.5
		particles.direction = Vector2(-1, 0)
		particles.spread = 20.0
		particles.gravity = Vector2(0, -10)
		particles.initial_velocity_min = 20
		particles.initial_velocity_max = 50
		particles.scale_amount_min = 2.0
		particles.scale_amount_max = 4.0
		particles.color = Color(1, 0.5, 0.0) # Orange
		particles.color_ramp = Gradient.new()
		particles.color_ramp.add_point(0.0, Color(1, 1, 0))
		particles.color_ramp.add_point(1.0, Color(1, 0, 0, 0))
		add_child(particles)
		
		# Tint base visual slightly
		visual.color = visual.color.lerp(Color(1, 0.5, 0.5), 0.5)
		
	elif type == "ice":
		var particles = CPUParticles2D.new()
		particles.amount = 12
		particles.lifetime = 0.6
		particles.gravity = Vector2(0, 20) # Falling flakes
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = 5.0
		particles.color = Color(0.6, 0.8, 1.0)
		particles.scale_amount_min = 1.0
		particles.scale_amount_max = 3.0
		add_child(particles)
		
		visual.color = visual.color.lerp(Color(0.5, 0.8, 1.0), 0.5)

	# Clean up logic that relied on match match block
	if element == "none":
		if self is TriggerBase:
			visual.color = Color(1.0, 0.8, 0.0) 
			visual.size = Vector2(10, 10)
		else:
			# Default projectile
			visual.size = Vector2(16, 4)
	
	visual.position = -visual.size / 2

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

func _physics_process(delta):
	_fly_time += delta
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
		queue_free()
	else:
		# Wall hit -> Bounce
		if _current_bounces < max_bounces:
			var n = col.get_normal()
			velocity_vector = velocity_vector.bounce(n)
			rotation = velocity_vector.angle()
			_current_bounces += 1
		else:
			queue_free()

# Removed _trigger_collision_logic to prevent self-interception in Base
# func _trigger_collision_logic(col: KinematicCollision2D): ...


# Legacy method - kept for subclasses, but Base implementation is emptied to avoid confusion
# The logic moved to _on_hit
func _on_collision():
	pass

func _on_lifetime_expired():
	if trail: trail.queue_free() # Ensure trail manages itself if detached? Actually queue_free destroys children too.
	queue_free()
