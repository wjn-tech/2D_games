extends Node

## specific_name: CinematicDirector
## description: Manages cutscene sequences, camera movements, and UI overlays.

signal step_started(step_data)
signal step_completed
signal sequence_finished

var _queue: Array = []
var _current_step_index: int = -1
var _is_playing: bool = false
var _wait_timer: Timer

# Core Dependencies (can be set by the scene or found dynamically)
var main_camera: Camera2D
var ui_layer: CanvasLayer

func _ready() -> void:
	_wait_timer = Timer.new()
	_wait_timer.one_shot = true
	_wait_timer.timeout.connect(_on_wait_timeout)
	add_child(_wait_timer)
	
	# Attempt to find common dependencies if they exist
	# (In a real implementation, these might be registered by the game manager)
	pass

## Public API

func play_sequence(actions: Array) -> void:
	if _is_playing:
		push_warning("CinematicDirector: Already playing a sequence. Aborting old one.")
		stop_sequence()
		
	_queue = actions
	_current_step_index = -1
	_is_playing = true
	
	# Optional: Lock player input here
	# InputManager.lock_input()
	
	print("[CinematicDirector] Starting sequence with %d steps." % _queue.size())
	_advance()

func stop_sequence() -> void:
	_is_playing = false
	_queue.clear()
	_wait_timer.stop()
	emit_signal("sequence_finished")
	
	# Optional: Unlock player input here
	# InputManager.unlock_input()

## Internal Logic

func _advance() -> void:
	_current_step_index += 1
	
	if _current_step_index >= _queue.size():
		stop_sequence()
		return
		
	var step_data = _queue[_current_step_index]
	emit_signal("step_started", step_data)
	_execute_step(step_data)

func _execute_step(data: Dictionary) -> void:
	var type = data.get("type", "wait")
	
	match type:
		"wait":
			var time = data.get("duration", 1.0)
			_wait_timer.start(time)
			
		"log":
			print("[Cinematic] %s" % data.get("message", ""))
			call_deferred("_step_done")
			
		"ui_text":
			# Placeholder for UI integration
			# Signal or direct call to TerminalOverlay
			# Global.ui.terminal.type(data["text"])
			print("[Cinematic] UI Text: %s" % data.get("text", ""))
			# Simulate duration if no callback
			var duration = data.get("duration", 2.0) 
			_wait_timer.start(duration)
			
		"cam_pan":
			var cam = _find_camera()
			if cam and cam.has_method("pan_to"):
				cam.pan_to(data.get("target", Vector2.ZERO), data.get("duration", 1.0))
			else:
				push_warning("CinematicDirector: Camera not found or missing pan_to()")
				
			var duration = data.get("duration", 1.0)
			_wait_timer.start(duration)
			
		"cam_zoom":
			var cam = _find_camera()
			if cam and cam.has_method("zoom_to"):
				cam.zoom_to(data.get("scale", Vector2.ONE), data.get("duration", 1.0))
			
			if data.get("wait", false):
				_wait_timer.start(data.get("duration", 1.0))
			else:
				call_deferred("_step_done")

		"cam_shake":
			var cam = _find_camera()
			if cam and cam.has_method("shake_screen"):
				cam.shake_screen(data.get("intensity", 5.0), data.get("duration", 0.5))
			call_deferred("_step_done")

		"cam_restore":
			var cam = _find_camera()
			if cam and cam.has_method("restore_control"):
				cam.restore_control(data.get("duration", 1.0))
			
			if data.get("wait", true):
				_wait_timer.start(data.get("duration", 1.0))
			else:
				call_deferred("_step_done")

		"method":
			# Call a method on a node (if passed) or singleton
			var target = data.get("target")
			var method = data.get("method", "")
			var args = data.get("args", [])
			if target and target.has_method(method):
				target.callv(method, args)
			
			if data.get("wait", false):
				_wait_timer.start(data.get("duration", 0.0))
			else:
				call_deferred("_step_done")
		
		"signal":
			var sig_name = data.get("name", "")
			if self.has_signal(sig_name):
				emit_signal(sig_name)
			call_deferred("_step_done")

		"move_actor":
			var target = data.get("target")
			if is_instance_valid(target) and target is Node2D:
				var dest = data.get("destination", target.position)
				var dur = data.get("duration", 1.0)
				var tween = create_tween()
				tween.tween_property(target, "global_position", dest, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
				if data.get("wait", true):
					_wait_timer.start(dur)
				else:
					call_deferred("_step_done")
			else:
				push_warning("CinematicDirector: Invalid target for move_actor")
				call_deferred("_step_done")

		"rotate_actor":
			var target = data.get("target")
			if is_instance_valid(target) and target is Node2D:
				var angle = data.get("angle", 0.0)
				var dur = data.get("duration", 1.0)
				var tween = create_tween()
				tween.tween_property(target, "rotation_degrees", angle, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				if data.get("wait", true):
					_wait_timer.start(dur)
				else:
					call_deferred("_step_done")
			else:
				push_warning("CinematicDirector: Invalid target for rotate_actor")
				call_deferred("_step_done")

		"scale_actor":
			var target = data.get("target")
			if is_instance_valid(target) and target is Node2D:
				var scale_vec = data.get("scale", Vector2.ONE)
				var dur = data.get("duration", 1.0)
				var tween = create_tween()
				tween.tween_property(target, "scale", scale_vec, dur).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
				if data.get("wait", true):
					_wait_timer.start(dur)
				else:
					call_deferred("_step_done")
			else:
				push_warning("CinematicDirector: Invalid target for scale_actor")
				call_deferred("_step_done")

		"set_property":
			var target = data.get("target")
			var prop = data.get("property", "")
			var val = data.get("value")
			if is_instance_valid(target) and prop != "":
				target.set(prop, val)
			call_deferred("_step_done")

		_:
			push_warning("CinematicDirector: Unknown step type '%s'" % type)
			call_deferred("_step_done")

func _find_camera() -> Camera2D:
	if is_instance_valid(main_camera):
		return main_camera
	main_camera = get_tree().get_first_node_in_group("main_camera")
	return main_camera

func _step_done() -> void:
	emit_signal("step_completed")
	_advance()

func _on_wait_timeout() -> void:
	_step_done()
