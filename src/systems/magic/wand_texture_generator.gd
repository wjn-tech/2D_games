extends Node
class_name WandTextureGenerator

# Generates a 16x48 pixel art texture from WandData
static func generate_texture(wand_data) -> ImageTexture:
	var width = 16
	var height = 48
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	if wand_data and wand_data.visual_grid:
		for coords in wand_data.visual_grid:
			var actual_coords = coords
			if coords is String:
				# Emergency fallback if normalize_grid failed
				var s = coords.replace("(", "").replace(")", "").replace("Vector2i", "").strip_edges()
				var parts = s.split(",")
				if parts.size() == 2:
					actual_coords = Vector2i(int(parts[0]), int(parts[1]))
			
			if actual_coords is Vector2i:
				if actual_coords.x >= 0 and actual_coords.x < width and actual_coords.y >= 0 and actual_coords.y < height:
					var item = wand_data.visual_grid.get(coords)
					if item and item.get("wand_visual_color"):
						img.set_pixel(actual_coords.x, actual_coords.y, item.wand_visual_color)
	
	return ImageTexture.create_from_image(img)
