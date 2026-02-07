extends Node
class_name WandTextureGenerator

# Generates a 16x48 pixel art texture from WandData
static func generate_texture(wand_data) -> ImageTexture:
	var width = 16
	var height = 48
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	if wand_data and wand_data.visual_grid:
		for coords in wand_data.visual_grid:
			if coords is Vector2i:
				if coords.x >= 0 and coords.x < width and coords.y >= 0 and coords.y < height:
					var item = wand_data.visual_grid[coords]
					if item and item.get("wand_visual_color"):
						img.set_pixel(coords.x, coords.y, item.wand_visual_color)
	
	return ImageTexture.create_from_image(img)
