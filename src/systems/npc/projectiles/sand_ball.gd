extends Area2D

@export var speed: float = 450.0
@export var damage: float = 12.0
@export var lifetime: float = 4.0

var direction: Vector2 = Vector2.ZERO

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func launch(dir: Vector2):
	direction = dir
	rotation = dir.angle()
	
func _physics_process(delta: float):
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node2D):
	_handle_hit(body)

func _on_area_entered(area: Area2D):
	# Optional: hit player shields/hitboxes
	_handle_hit(area)

func _handle_hit(node: Node):
	if node.is_in_group("player"):
		if CombatManager:
			CombatManager.deal_damage(self, node, damage, "sand")
		elif node.has_method("take_damage"):
			node.take_damage(damage)
		queue_free()
	elif node is TileMap or node is TileMapLayer:
		queue_free()
	elif node.get_collision_layer() & 1: # World layer bit
		queue_free()
