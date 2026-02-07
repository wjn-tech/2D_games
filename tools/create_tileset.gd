@tool
extends SceneTree

# Script to generate minimalist_tileset.tres with configured collisions

func _init():
	print("Building Minimalist TileSet...")
	
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(16, 16)
	
	# Add Physics Layer 0
	tileset.add_physics_layer(0)
	tileset.set_physics_layer_collision_layer(0, 1) # Layer 1 (World)
	tileset.set_physics_layer_collision_mask(0, 0)
	
	# Load image
	var image_path = "res://assets/minimalist_palette.png"
	var texture = load(image_path)
	if not texture:
		print("Error: Could not load " + image_path)
		quit(1)
		return

	# Create Source (ID 0)
	var source = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(16, 16)
	
	# Define Tiles to create
	# Grid is 4x4 (64x64 image) or larger. Python script makes 64x image (4 columns). 
	# Rows 0-4.
	
	# Helper to create tile with Full Square Collision
	var full_poly = PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	])
	
	for y in range(8): # Scan up to 8 rows
		for x in range(4): # 4 columns
			if y > 4: continue # Assuming script max output
			
			var coords = Vector2i(x, y)
			source.create_tile(coords)
			var tile_data = source.get_tile_data(coords, 0)
			
			# Define Collision Logic
			var has_collision = true
			
			# Row 1: Liquids vs Solids
			if y == 1:
				if x == 0 or x == 1: # Water, Lava
					has_collision = false
				else: # Grass (2,1), Snow (3,1)
					has_collision = true
				
			# Row 4+: Non-solids or unused
			if y >= 4:
				has_collision = false
			
			# Apply
			if has_collision:
				tile_data.add_collision_polygon(0)
				tile_data.set_collision_polygon_points(0, 0, full_poly)
				
	tileset.add_source(source, 0) # source_id = 0
	
	var save_path = "res://assets/minimalist_tileset.tres"
	var err = ResourceSaver.save(tileset, save_path)
	if err == OK:
		print("Success: Saved to " + save_path)
	else:
		print("Error: Failed to save resource. Code: ", err)
	
	quit()
