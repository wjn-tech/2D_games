extends ProjectileBase

var healing_area: Area2D
var healing_timer: Timer
var heal_interval: float = 0.5
var heal_amount_percent: float = 0.05
var active_bodies: Array = []
var active_visual: Line2D
var tween: Tween

func _ready():
	_setup_visuals()
	
	# Override physics
	speed = 0.0
	velocity_vector = Vector2.ZERO
	# gravity_scale = 0.0 # Removed: Not a property of CharacterBody2D
	
	healing_area = Area2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 80.0 
	var coll = CollisionShape2D.new()
	coll.shape = shape
	healing_area.add_child(coll)
	# Use new LayerManager constants: LAYER_WORLD_0 (1), LAYER_PLAYER (16), LAYER_NPC (32)
	# Also Bit 0 is 1. Bit 4 is 16. Bit 5 is 32.
	# We want to heal Player (16) and maybe Friendly NPCs (32).
	healing_area.collision_mask = 1 | 16 | 32 
	add_child(healing_area)
	
	healing_area.body_entered.connect(_on_body_entered)
	healing_area.body_exited.connect(_on_body_exited)
	
	healing_timer = Timer.new()
	healing_timer.wait_time = heal_interval
	healing_timer.autostart = true
	add_child(healing_timer)
	healing_timer.timeout.connect(_on_heal_tick)
	
	# Animate Appearance
	scale = Vector2.ZERO
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _setup_visuals():
	# Remove old visuals if any
	for c in get_children():
		if c is ColorRect or c is Sprite2D or c is MagicProjectileVisualizer:
			c.queue_free()
			
	active_visual = Line2D.new()
	var points = []
	for i in range(33):
		var angle = i * TAU / 32.0
		points.append(Vector2(cos(angle), sin(angle)) * 80.0)
	active_visual.points = PackedVector2Array(points)
	active_visual.default_color = Color(0.2, 0.9, 0.4, 0.8) # Emerald Green
	active_visual.width = 4.0
	active_visual.closed = true
	add_child(active_visual)
	
	# Inner pulse ring
	var inner = Line2D.new()
	inner.points = active_visual.points
	inner.default_color = Color(0.6, 1.0, 0.8, 0.4)
	inner.width = 1.0
	inner.closed = true
	inner.scale = Vector2(0.5, 0.5)
	add_child(inner)
	
	var t = create_tween().set_loops()
	t.tween_property(inner, "scale", Vector2(0.9, 0.9), 1.0)
	t.tween_property(inner, "modulate:a", 0.0, 1.0)
	t.parallel().tween_property(inner, "scale", Vector2(0.3, 0.3), 0.0)
	t.parallel().tween_property(inner, "modulate:a", 1.0, 0.0)

func _physics_process(delta):
	# Override ProjectileBase movement to stay put
	_fly_time += delta
	if _fly_time >= lifetime:
		# Shrink out
		var t = create_tween()
		t.tween_property(self, "scale", Vector2.ZERO, 0.2)
		t.tween_callback(queue_free)
		set_physics_process(false) # Stop processing
		return

func _on_body_entered(body):
	if body.is_in_group("player") and not active_bodies.has(body):
		active_bodies.append(body)

func _on_body_exited(body):
	if active_bodies.has(body):
		active_bodies.erase(body)

func _on_heal_tick():
	for body in active_bodies:
		if not is_instance_valid(body):
			continue
			
		# Check cooldown meta to prevent stacking from multiple rings
		if body.has_meta("healing_cooldown_frame"):
			var last_frame = body.get_meta("healing_cooldown_frame")
			# Allow heal every 30 frames (0.5s at 60fps) approx, 
			# but we rely on this timer being 0.5s.
			# If multiple rings overlap, they might fire at different times.
			# We want to limit HEAL FREQUENCY on the target.
			if Engine.get_process_frames() - last_frame < 20: 
				continue
		
		body.set_meta("healing_cooldown_frame", Engine.get_process_frames())
		
		# Heal logic
		# Player stores data in attributes.data (CharacterData)
		var char_data = null
		if "attributes" in body and body.attributes and "data" in body.attributes:
			char_data = body.attributes.data
		elif "npc_data" in body:
			char_data = body.npc_data
			
		# Fallback if no data detected but has method
		if not char_data and body.has_method("restore_health"):
			# Assuming restore_health exists on body
			body.restore_health(max(1.0, 20.0 * heal_amount_percent)) # Estimation
		
		# Regular healing via CharacterData
		if char_data:
			var max_hp = char_data.max_health
			var missing = max_hp - char_data.health
			if missing > 0:
				var heal = ceil(max_hp * heal_amount_percent)
				char_data.health = min(char_data.health + heal, max_hp)
				
				# Visual Popup
				if UIManager:
					UIManager.show_floating_text("+%.0f" % heal, body.global_position + Vector2(0, -50), Color.GREEN)
				
				# Pulse effect on ring (only if healed)
				if active_visual:
					var tw = create_tween()
					tw.tween_property(active_visual, "width", 8.0, 0.1)
					tw.tween_property(active_visual, "width", 4.0, 0.2)
