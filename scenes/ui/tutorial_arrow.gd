extends Control

@onready var visual = $Visual

func _ready() -> void:
	# Bouncing animation
	var tween = create_tween().set_loops()
	tween.tween_property(visual, "position:y", -10.0, 0.5).as_relative()
	tween.tween_property(visual, "position:y", 10.0, 0.5).as_relative()
