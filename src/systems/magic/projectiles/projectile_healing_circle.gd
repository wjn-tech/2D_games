extends ProjectileBase

var healing_area: Area2D
var heal_interval: float = 0.5
var heal_amount_percent: float = 0.05
var active_bodies: Array = []
var active_visual: Line2D
var tween: Tween
var heal_rate_percent_per_second: float = 0.0
var popup_interval: float = 0.25
var heal_popup_accumulator: Dictionary = {}
var heal_popup_elapsed: Dictionary = {}

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

	heal_rate_percent_per_second = heal_amount_percent / max(heal_interval, 0.001)
	
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
	_process_continuous_healing(delta)
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
	_cleanup_body_tracking(body)

func _process_continuous_healing(delta: float) -> void:
	var invalid_bodies: Array = []
	for body in active_bodies:
		if not is_instance_valid(body):
			invalid_bodies.append(body)
			continue

		var healed_amount = _heal_body(body, delta)
		if healed_amount <= 0.0:
			continue

		var body_id = body.get_instance_id()
		heal_popup_accumulator[body_id] = heal_popup_accumulator.get(body_id, 0.0) + healed_amount
		heal_popup_elapsed[body_id] = heal_popup_elapsed.get(body_id, 0.0) + delta

		if heal_popup_elapsed[body_id] >= popup_interval:
			_emit_heal_feedback(body, body_id)

	for body in invalid_bodies:
		active_bodies.erase(body)
		_cleanup_body_tracking(body)

func _heal_body(body, delta: float) -> float:
	var char_data = null
	if "attributes" in body and body.attributes and "data" in body.attributes:
		char_data = body.attributes.data
	elif "npc_data" in body:
		char_data = body.npc_data

	if char_data:
		var max_hp = char_data.max_health
		var missing = max_hp - char_data.health
		if missing <= 0.0:
			return 0.0

		var heal_amount = min(missing, max_hp * heal_rate_percent_per_second * delta)
		char_data.health = char_data.health + heal_amount
		return heal_amount

	if body.has_method("restore_health"):
		var fallback_heal = (20.0 * heal_amount_percent / max(heal_interval, 0.001)) * delta
		if fallback_heal > 0.0:
			body.restore_health(fallback_heal)
			return fallback_heal

	return 0.0

func _emit_heal_feedback(body, body_id: int) -> void:
	var total_heal = heal_popup_accumulator.get(body_id, 0.0)
	if total_heal <= 0.0:
		heal_popup_elapsed[body_id] = 0.0
		return

	if UIManager:
		UIManager.show_floating_text("+%.1f" % total_heal, body.global_position + Vector2(0, -50), Color.GREEN)

	if active_visual:
		var tw = create_tween()
		tw.tween_property(active_visual, "width", 8.0, 0.1)
		tw.tween_property(active_visual, "width", 4.0, 0.2)

	heal_popup_accumulator[body_id] = 0.0
	heal_popup_elapsed[body_id] = 0.0

func _cleanup_body_tracking(body) -> void:
	if not is_instance_valid(body):
		return
	var body_id = body.get_instance_id()
	heal_popup_accumulator.erase(body_id)
	heal_popup_elapsed.erase(body_id)
