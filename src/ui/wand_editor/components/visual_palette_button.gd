extends PanelContainer

signal item_selected(item)

var item_data: BaseItem
var _drag_start_pos: Vector2 = Vector2.ZERO
var _is_pressed: bool = false

const COLOR_BG = Color("#091425")
const COLOR_DIM = Color("#77a5d6")

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
	custom_minimum_size = Vector2(104, 36)
	tooltip_text = item.display_name
	
	for c in get_children(): c.queue_free()

	# Create compact card style
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_BG
	panel_style.border_color = item.wand_visual_color.lightened(0.2)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", panel_style)

	var row = HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	add_child(row)

	# Icon / Color Block
	var icon = ColorRect.new()
	icon.color = item.wand_visual_color
	icon.custom_minimum_size = Vector2(20, 20)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var text_col = VBoxContainer.new()
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 1)
	row.add_child(text_col)

	var name_label = Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = item.display_name
	name_label.clip_text = true
	name_label.add_theme_color_override("font_color", Color("#d9ecff"))
	name_label.add_theme_font_size_override("font_size", 11)
	text_col.add_child(name_label)

	var kind_label = Label.new()
	kind_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kind_label.text = item.wand_logic_type
	kind_label.add_theme_color_override("font_color", COLOR_DIM)
	kind_label.add_theme_font_size_override("font_size", 9)
	text_col.add_child(kind_label)

	# Hover effects
	mouse_entered.connect(func():
		var tw = create_tween()
		tw.tween_property(self, "modulate", Color(1.08, 1.08, 1.08), 0.08)
		if panel_style:
			panel_style.border_color = item.wand_visual_color
			panel_style.shadow_size = 6
			panel_style.shadow_color = item.wand_visual_color
	)
	mouse_exited.connect(func():
		var tw = create_tween()
		tw.tween_property(self, "modulate", Color(1,1,1,1), 0.12)
		if panel_style:
			panel_style.border_color = item.wand_visual_color.lightened(0.2)
			panel_style.shadow_size = 0
	)
