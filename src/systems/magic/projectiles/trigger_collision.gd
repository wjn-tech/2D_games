extends TriggerBase
class_name CollisionTrigger

# Override the new hook from ProjectileBase to intercept the hit logic
func _custom_trigger_hit(col: KinematicCollision2D):
	# Collision Trigger Behavior: Explode on contact
	_on_collision()

func _on_collision():
	execute_children()
	queue_free()

func _on_lifetime_expired():
	# Fizzle if max range reached without hit
	queue_free()
