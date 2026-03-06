extends StaticBody2D

signal wall_broken

@onready var collision_shape = $CollisionPolygon2D
@onready var visual = $Polygon2D

var _broken = false

func _ready() -> void:
	add_to_group("destructible")

func take_damage(_amount: float, _extra = null) -> void:
	if _broken: return
	break_wall()

func break_wall() -> void:
	_broken = true
	wall_broken.emit()
	
	# Disappear logic
	collision_shape.set_deferred("disabled", true)
	
	var tween = create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
	
	# Optional: Spawn debris or particles here if we had them
	print("Tutorial: Wall Broken!")
