extends Control

signal clicked

@onready var icon: TextureRect = $Icon
@onready var label: Label = $Label
@onready var status_rect: ColorRect = $Status

var house_info: Dictionary

func setup(info: Dictionary) -> void:
	house_info = info
	
	if info.is_valid:
		status_rect.color = Color.GREEN
		var occupant = info.get("occupied_by", "")
		if occupant != "":
			label.text = occupant
			icon.modulate = Color.WHITE
		else:
			label.text = "空闲"
			icon.modulate = Color(1, 1, 1, 0.5)
	else:
		status_rect.color = Color.RED
		label.text = info.error

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		clicked.emit()
