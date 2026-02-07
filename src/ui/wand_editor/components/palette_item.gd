extends Button

var item_data: BaseItem

func _get_drag_data(at_position):
	var preview = TextureRect.new()
	preview.texture = icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(40, 40)
	set_drag_preview(preview)
	return item_data
