extends Button

var item_data: BaseItem

func _get_drag_data(at_position):
	var preview = TextureRect.new()
	# try use icon if available on item_data, fallback to a color rect
	if item_data and item_data.icon:
		preview.texture = item_data.icon
	else:
		var rect = ColorRect.new()
		rect.custom_minimum_size = Vector2(40,40)
		rect.color = item_data.wand_visual_color if item_data else Color(0.8,0.8,0.8)
		preview.add_child(rect)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(40, 40)
	set_drag_preview(preview)
	return item_data

func _ready():
    custom_minimum_size = Vector2(48,48)
    mouse_entered.connect(func(): create_tween().tween_property(self, "scale", Vector2(1.06,1.06), 0.12))
    mouse_exited.connect(func(): create_tween().tween_property(self, "scale", Vector2(1,1), 0.12))
