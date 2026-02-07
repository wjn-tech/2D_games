extends RefCounted
class_name SpellPayload

var damage: float = 0.0
var element: String = "physical"
var speed: float = 100.0
var size: float = 1.0
var lifetime: float = 1.0
var direction: Vector2 = Vector2.RIGHT
var source_entity: Node2D
var extra_tags: Array[String] = []

func duplicate() -> SpellPayload:
	var new_payload = SpellPayload.new()
	new_payload.damage = damage
	new_payload.element = element
	new_payload.speed = speed
	new_payload.size = size
	new_payload.lifetime = lifetime
	new_payload.direction = direction
	new_payload.source_entity = source_entity
	new_payload.extra_tags = extra_tags.duplicate()
	return new_payload
