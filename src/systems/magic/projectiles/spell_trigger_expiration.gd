extends SpellTriggerBase
class_name SpellTriggerExpiration

# Trigger on Hit (Collision)
func _custom_trigger_hit(col: KinematicCollision2D):
	execute_children()
	queue_free()

# Trigger on Lifetime (Timer/Fade)
func _on_lifetime_expired():
	execute_children()
	queue_free()


# Basically, any termination spawns it. 
# Re-implementing base methods to call execute instead of just queue_free
