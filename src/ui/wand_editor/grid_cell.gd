extends TextureButton

signal dropped_data(item)
signal clicked(coords, mouse_idx)

var grid_coords: Vector2i

func _can_drop_data(_at_position, data):
	# Allow drag from palette items (which return a dict with "item")
	return data is Dictionary and data.has("item")

func _drop_data(_at_position, data):
	dropped_data.emit(data["item"])
	
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		clicked.emit(grid_coords, event.button_index)
	# Pass mouse motion for hover effects that might be missed
	if event is InputEventMouseMotion:
		pass
