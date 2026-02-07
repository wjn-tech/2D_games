extends PanelContainer
class_name WandLogicSlot

signal slot_changed
signal item_dropped(item_data, index)

@onready var icon = $MarginContainer/HBoxContainer/Icon
@onready var label = $MarginContainer/HBoxContainer/Label
@onready var connection_line = $ConnectionLine

var slot_index: int = -1
var current_item: BaseItem = null

func _ready():
	custom_minimum_size.y = 60
	_update_visual()

func set_item(item: BaseItem):
	current_item = item
	_update_visual()
	slot_changed.emit()

func _update_visual():
	if current_item:
		label.text = current_item.display_name
		icon.texture = current_item.icon
		icon.visible = true
		self_modulate = Color.WHITE
		
		# set color based on type
		match current_item.wand_logic_type:
			"trigger": self_modulate = Color(1.0, 0.9, 0.7) # Yellowish
			"modifier_damage", "modifier_element": self_modulate = Color(0.7, 1.0, 0.7) # Greenish
			"splitter": self_modulate = Color(0.7, 0.9, 1.0) # Blueish
			"action_projectile": self_modulate = Color(1.0, 0.7, 0.7) # Reddish
	else:
		label.text = "Empty Slot"
		icon.texture = null
		icon.visible = false
		self_modulate = Color(0.2, 0.2, 0.2)

func _can_drop_data(_at_position, data):
	return data is BaseItem

func _drop_data(_at_position, data):
	item_dropped.emit(data, slot_index)

func set_connection_type(type: String):
	# type: "none", "enhance", "branch"
	match type:
		"none": connection_line.visible = false
		"enhance": 
			connection_line.visible = true
			connection_line.color = Color.GREEN
		"branch":
			connection_line.visible = true
			connection_line.color = Color.AQUA
