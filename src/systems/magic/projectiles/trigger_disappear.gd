extends TriggerBase
class_name DisappearTrigger

func _exit_tree():
	# Warning: _exit_tree is called on queue_free() too.
	# Logic: "When it disappear it will emit"
	# Does "disappear" mean "Lifetime end" or "Collision" or "Any death"?
	# User prompt: "disappear trigger is a bullet that when it disappear it will emit"
	# This usually implies ANY reason (time out, hit wall, etc)
	# But we must be careful not to spawn if the scene is unloading.
	
	if not is_inside_tree(): return # Check validity
	
	# Only execute if we are actually playing and this is a gameplay death
	# We might need a flag "spawn_on_death" that we set to false if we just want to clear it.
	
	# For safety, let's call execute_children directly in _notification or before queue_free
	pass

func _on_collision():
	execute_children()
	queue_free()

func _on_lifetime_expired():
	execute_children()
	queue_free()

# Basically, any termination spawns it. 
# Re-implementing base methods to call execute instead of just queue_free
