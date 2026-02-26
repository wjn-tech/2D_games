extends PanelContainer
class_name TrashSlotUI

signal item_trashed(data: Variant)

@onready var icon: TextureRect = %Icon

func _ready() -> void:
	# Enable drop
	pass

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Accept item dictionary from inventory drag (ItemSlotUI sends {inventory, index, item})
	return typeof(data) == TYPE_DICTIONARY and data.get("inventory") != null and data.get("index") != null

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# Confirm or just emit
	item_trashed.emit(data)
	# Play sound or effect?
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Maybe show trash info or clear all?
		pass
