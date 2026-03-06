extends TileMapLayer

func _ready() -> void:
	# Define bounds matching the CollisionPolygons
	
	clear()
	
	# Floor
	# 600 width each side. ~10 tiles each side.
	for x in range(-12, 13):
		# Floor at y=0 (relative to layer position, usually floor is at collision y)
		# NOTE: Collision floor is y=50.
		# If this Layer is at (0,0), then tile (0,0) is at (0,0) to (64,64).
		# We probably want floor tiles to be at y=0 which corresponds to world y=0..64.
		# Since collision is y=50, the tile (x,0) covers y=0 to 64, which matches well.
		set_cell(Vector2i(x, 0), 1, Vector2i(0, 0)) # Source 1, Atlas(0,0) [Floor]
		
		# Ceiling at y=-300.
		# -300 / 64 = -4.68. So tile y=-5 (covers -320 to -256) or -6?
		# Let's put ceiling tiles at y=-6 to be above the play area.
		set_cell(Vector2i(x, -6), 1, Vector2i(0, 2)) # Source 1, Atlas(0,2) [Ceiling]
		
	# Walls
	for y in range(-6, 1):
		# Left Wall at x=-600.
		# -600 / 64 = -9.375. So tile x=-10 (covers -640 to -576).
		set_cell(Vector2i(-10, y), 1, Vector2i(0, 1)) # Source 1, Atlas(0,1) [Wall]
		
		# Right Wall at x=600 approx.
		set_cell(Vector2i(9, y), 1, Vector2i(0, 1)) # Source 1, Atlas(0,1) [Wall]
	
	# Background Wall Fill
	for x in range(-9, 9):
		for y in range(-5, 0):
			# Back wall tiles
			set_cell(Vector2i(x, y), 1, Vector2i(1, 1)) # Source 1, Atlas(1,1) [Wall variant / BG]
