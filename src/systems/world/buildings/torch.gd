extends StaticBody2D

func _ready():
	add_to_group("torches")
	add_to_group("housing_light") # 用于房屋检测
	
	# Force custom texture
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		var tex = load("res://assets/world/custom_furniture.png")
		if tex:
			var atlas = AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(64, 16, 16, 16)
			sprite.texture = atlas
			sprite.centered = false

	# 火把没有实际物理碰撞
	collision_layer = 1 # 与泥土同层
	collision_mask = 0  # 但不产生撞击

func handle_mining(_damage: float):
	var item_res = GameState.crafting_manager.get_item_by_id("torch")
	if item_res:
		var loot_item = preload("res://scenes/world/loot_item.tscn").instantiate()
		get_tree().current_scene.add_child(loot_item)
		loot_item.global_position = global_position
		loot_item.setup(item_res, 1)
	queue_free()
