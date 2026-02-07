extends TriggerBase
class_name TimerTrigger

var timer_duration: float = 2.0

func setup(params: Dictionary, mods: Array):
	super.setup(params, mods)
	if "duration" in params: timer_duration = float(params.duration)
	if "value" in params and params.value is Dictionary and "duration" in params.value:
		timer_duration = float(params.value.duration)
	# Assuming 'speed' is inherited from ProjectileBase default or params

func _physics_process(delta):
	# ProjectileBase handles movement and lifetime
	super._physics_process(delta)
	
	# Timer logic piggybacks on _fly_time from Base? 
	# Base uses _fly_time for lifetime.
	if _fly_time >= timer_duration:
		_on_timer_complete()

func _on_timer_complete():
	execute_children()
	queue_free()

# Timer Trigger should just use standard projectile behavior (Bounce)
# So we remove/comment out the old collision handler that killed it.
# func _on_collision(): ...
