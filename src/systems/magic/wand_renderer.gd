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
		var item = wand_data.visual_grid.get(coord)
		if item and item is BaseItem:
			# Safety check: Ensure coord is valid for positioning
			var pos = Vector2.ZERO
			if coord is Vector2i:
				pos = Vector2(coord)
			elif coord is Vector2:
				pos = coord
			else:
				# Skip invalid coordinates like stringified '(-3, 6)' 
				# unless we can parse them. normalize_grid handles parsing.
				continue
				
			var sprite = Sprite2D.new()
			# ...
			
			var rect = ColorRect.new()
			rect.size = Vector2(1, 1)
			rect.position = pos
			
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
