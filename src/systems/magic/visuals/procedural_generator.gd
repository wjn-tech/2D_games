extends Node
class_name ProceduralGenerator

# Generates a white circle texture with anti-aliasing (but pixel-aligned as much as possible)
static func make_white_circle(size: int) -> ImageTexture:
	var width = size
	var height = size
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	var cx = float(width - 1) * 0.5
	var cy = float(height - 1) * 0.5
	var radius = float(width) * 0.45
	
	for y in range(height):
		for x in range(width):
			var dx = float(x) - cx
			var dy = float(y) - cy
			var dist = sqrt(dx*dx + dy*dy)
			
			if dist <= radius:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
			elif dist <= radius + 1.0: # 1 pixel anti-aliasing
				var alpha = 1.0 - (dist - radius)
				img.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				
	return ImageTexture.create_from_image(img)

static func make_pixel_spark(size: int) -> ImageTexture:
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = size / 2
	for i in range(size):
		img.set_pixel(center, i, Color(1, 1, 1, 1))
		img.set_pixel(i, center, Color(1, 1, 1, 1))
	
	# Add a small core
	if size >= 4:
		img.set_pixel(center-1, center-1, Color(1,1,1,1))
		img.set_pixel(center+1, center+1, Color(1,1,1,1))
		img.set_pixel(center-1, center+1, Color(1,1,1,1))
		img.set_pixel(center+1, center-1, Color(1,1,1,1))

	return ImageTexture.create_from_image(img)
	
static func make_triangle(width: int, height: int) -> ImageTexture:
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var x_mid = width / 2.0
	for y in range(height):
		var y_rel = float(y) / float(height)
		var x_range = y_rel * (width / 2.0)
		for x in range(width):
			if abs(x - x_mid) <= x_range:
				img.set_pixel(x, y, Color(1,1,1,1))
	return ImageTexture.create_from_image(img)
	
static func make_shockwave_ring(size: int, thickness: int = 2) -> ImageTexture:
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx = float(size - 1) * 0.5
	var cy = float(size - 1) * 0.5
	var r_outer = float(size) * 0.48
	var r_inner = r_outer - float(thickness)
	
	for y in range(size):
		for x in range(size):
			var dx = float(x) - cx
			var dy = float(y) - cy
			var d = sqrt(dx*dx + dy*dy)
			
			if d <= r_outer and d >= r_inner:
				img.set_pixel(x, y, Color(1,1,1,1))
			
	return ImageTexture.create_from_image(img)
