extends Area2D
class_name Pickup

@export var item_data: ItemData
@export var amount: int = 1

@onready var sprite = $Sprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	if item_data:
		setup(item_data, amount)

func setup(data: ItemData, qty: int):
	item_data = data
	amount = qty
	if sprite and item_data.icon:
		sprite.texture = item_data.icon

func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		# Find InventoryManager on player
		var inv = body.get_node_or_null("InventoryManager")
		if inv:
			var success = inv.add_item(item_data, amount)
			if success:
				queue_free()
