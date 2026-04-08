extends Button

## Opens the gameplay guide window when pressed

signal guide_requested

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	guide_requested.emit()
