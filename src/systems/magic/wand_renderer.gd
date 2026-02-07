extends SubViewport
class_name WandRenderer

@onready var canvas = $Canvas

func render(wand_data: WandData):
	if not canvas:
		return
		
	# Clear previous
	for child in canvas.get_children():
		child.queue_free()
		
	if not wand_data:
		return
		
	var resolution = wand_data.get_grid_resolution()
	self.size = Vector2i(resolution, resolution)
	
	for coord in wand_data.visual_grid:
		var item = wand_data.visual_grid[coord]
		if item and item is BaseItem:
			var sprite = Sprite2D.new()
			# Ideally items have a specific "pixel texture" or we just use a color
			# For now, let's assume we tint a 1x1 white pixel or scale down the icon
			# But pixel art scaling down big icons looks bad.
			# Let's assume for this prototype we draw a ColorRect 1x1
			
			var rect = ColorRect.new()
			rect.size = Vector2(1, 1)
			rect.position = coord
			
			if "wand_visual_color" in item:
				rect.color = item.wand_visual_color
			else:
				# Fallback hash color
				rect.color = Color.from_hsv((item.id.hash() % 100) / 100.0, 0.8, 0.8)
				
			canvas.add_child(rect)

func get_texture_copy() -> ImageTexture:
	# Force update
	render_target_update_mode = UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var img = get_texture().get_image()
	return ImageTexture.create_from_image(img)
