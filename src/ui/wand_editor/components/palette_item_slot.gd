extends PanelContainer
class_name PaletteItemSlot

var item_data: BaseItem

func setup(item: BaseItem):
	item_data = item
	
	# Visual Setup match Figure 2 (Slot style)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 1.0) # Dark gray background
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.4, 0.4) # Grey border
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", style)
	
	custom_minimum_size = Vector2(50, 50)
	
	# Inner Content
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	add_child(margin)
	
	var inner_rect = ColorRect.new()
	inner_rect.color = item.wand_visual_color # The "Type" color
	inner_rect.mouse_filter = Control.MOUSE_FILTER_PASS
	# Ensure inner rect fills slot and has rounded corners
	inner_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# inner_rect fills the margin container; MarginContainer's theme constants provide padding
	inner_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	margin.add_child(inner_rect)
	
	if item.icon:
		var icon_rect = TextureRect.new()
		icon_rect.texture = item.icon
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# If icon is pure white/black mask, we might modulate. 
		# If it's full color, we leave it. 
		# For "Blocky", maybe just center it small
		icon_rect.modulate = Color(1,1,1,0.8)
		margin.add_child(icon_rect)
		icon_rect.anchor_left = 0.1
		icon_rect.anchor_top = 0.1
		icon_rect.anchor_right = 0.9
		icon_rect.anchor_bottom = 0.9
		# anchors already set; rely on anchors to inset icon rather than margins
	
	# Tooltip
	tooltip_text = item.display_name

	# Hover highlight
	mouse_entered.connect(func():
		var tw = create_tween()
		tw.tween_property(self, "modulate", Color(1.06,1.06,1.06), 0.12)
	)
	mouse_exited.connect(func():
		var tw = create_tween()
		tw.tween_property(self, "modulate", Color(1,1,1,1), 0.14)
	)

func _get_drag_data(at_position):
	var preview = Control.new()
	var rect = ColorRect.new()
	rect.size = Vector2(40, 40)
	rect.color = item_data.wand_visual_color
	# Center preview
	rect.position = -rect.size / 2
	preview.add_child(rect)
	set_drag_preview(preview)
	return item_data
