@tool
extends SceneTree

func _init():
	var texture_path = "res://assets/visuals/spaceship/tileset_industrial.png"
	var texture = load(texture_path)
	if not texture:
		print("Error: Texture not found at ", texture_path)
		quit()
		return

	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(64, 64)
	
	var source = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(64, 64)
	
	# Create tiles for the 3x3 grid
	for x in range(3):
		for y in range(3):
			source.create_tile(Vector2i(x, y))
			
	# Add physics? The brief didn't strictly require physics on the tileset, 
	# but we have CollisionPolygon2D in the scene for the structure.
	# Let's rely on the existing CollisionPolygon2D for physics for now to avoid complexity in this script,
	# or add a simple square collision to the Wall tiles (Row 1).
	
	var physics_layer_index = 0
	tileset.add_physics_layer(physics_layer_index)
	tileset.set_physics_layer_collision_layer(physics_layer_index, 1)
	tileset.set_physics_layer_collision_mask(physics_layer_index, 1)

	# Add collision to walls (Row 1, y=1) and ceiling (Row 2, y=2 maybe?)
	# Actually, usually walls are solid.
	# Let's make Row 1 (Index 1) solid.
	for x in range(3):
		var tile_data = source.get_tile_data(Vector2i(x, 1), 0)
		if tile_data:
			var poly = [Vector2(-32, -32), Vector2(32, -32), Vector2(32, 32), Vector2(-32, 32)]
			tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, poly)
			
	tileset.add_source(source)
	
	var save_path = "res://assets/visuals/spaceship/industrial_tileset.tres"
	var err = ResourceSaver.save(tileset, save_path)
	if err == OK:
		print("Successfully created tileset at ", save_path)
	else:
		print("Failed to save tileset: ", err)
	
	quit()
