extends PanelContainer

signal item_selected(item)

var item_data: BaseItem
var _drag_start_pos: Vector2 = Vector2.ZERO
var _is_pressed: bool = false

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drag_start_pos = event.position
				_is_pressed = true
				accept_event()
			else:
				if _is_pressed: # Release
					if _drag_start_pos != Vector2.ZERO:
						# Click (Release without drag)
						item_selected.emit(item_data)
						_highlight_selection()
					_is_pressed = false
					_drag_start_pos = Vector2.ZERO
	
	if event is InputEventMouseMotion and _is_pressed:
		if _drag_start_pos != Vector2.ZERO and event.position.distance_to(_drag_start_pos) > 5:
			_drag_start_pos = Vector2.ZERO
			_trigger_drag()

func _highlight_selection():
	var parent = get_parent()
	for child in parent.get_children():
		child.modulate = Color.WHITE
	modulate = Color.GREEN # Simple highlight

func _trigger_drag():
	var preview = Control.new()
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.color = item_data.wand_visual_color
	preview.add_child(icon)
	# Center preview
	icon.position = -icon.custom_minimum_size / 2
	set_drag_preview(preview)
	
	return {"item": item_data} # Return dictionary for grid_cell compatibility

func _get_drag_data(at_position):
	return _trigger_drag()

func setup(item):
	item_data = item
	mouse_filter = Control.MOUSE_FILTER_STOP 
	custom_minimum_size = Vector2(50, 50)
	tooltip_text = item.display_name
	
	for c in get_children(): c.queue_free()
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	add_child(vbox)
	
	# Icon / Color Block
	var icon = ColorRect.new()
	icon.color = item.wand_visual_color
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon)
