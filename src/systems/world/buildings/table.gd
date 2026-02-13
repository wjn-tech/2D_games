extends StaticBody2D

func _ready():
	add_to_group("tables")

func handle_mining(_damage: float):
	# 安全获取桌子物品数据
	var item_res = null
	if GameState.crafting_manager:
		for recipe in GameState.crafting_manager.all_recipes:
			if recipe.result_item.id == "table":
				item_res = recipe.result_item
				break
	
	if item_res:
		var loot_item = preload("res://scenes/world/loot_item.tscn").instantiate()
		get_tree().current_scene.add_child(loot_item)
		loot_item.global_position = global_position
		loot_item.setup(item_res, 1)
	queue_free()
