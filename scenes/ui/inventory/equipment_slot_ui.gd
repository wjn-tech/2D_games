extends "res://src/ui/inventory/item_slot_ui.gd"
class_name EquipmentSlotUI

@export var equip_slot_type: String = ""
@export var placeholder_texture: Texture2D

func _ready() -> void:
	super()
	_update_placeholder()

func setup(index: int, slot_data: Dictionary, inventory_ref: Resource) -> void:
	super(index, slot_data, inventory_ref)
	_update_placeholder()
	
func _update_placeholder() -> void:
	if not current_item and placeholder_texture:
		if icon_rect:
			icon_rect.texture = placeholder_texture
			icon_rect.visible = true
			icon_rect.modulate = Color(1, 1, 1, 0.2)
	else:
		if icon_rect:
			icon_rect.modulate = Color(1, 1, 1, 1)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Basic check from parent
	if not super._can_drop_data(at_position, data): return false
	
	var item = data.get("item")
	if not item: return false
	
	# Check type
	if equip_slot_type != "":
		# Try get_equip_slot() method or slot_type property
		if item.has_method("get_equip_slot"):
			if item.get_equip_slot() != equip_slot_type:
				return false
		elif "slot_type" in item:
			if item.slot_type != equip_slot_type:
				return false
	
	return true
