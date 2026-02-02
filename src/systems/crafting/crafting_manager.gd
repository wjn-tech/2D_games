extends Node

func can_craft(recipe: CraftingRecipe) -> bool:
	for item_id in recipe.ingredients:
		var required_amount = recipe.ingredients[item_id]
		if GameState.inventory.get_item_count(item_id) < required_amount:
			return false
	return true

func craft(recipe: CraftingRecipe) -> bool:
	if not can_craft(recipe):
		print("材料不足，无法制作")
		return false
		
	# 扣除材料
	for item_id in recipe.ingredients:
		GameState.inventory.remove_item(item_id, recipe.ingredients[item_id])
		
	# 添加产物
	GameState.inventory.add_item(recipe.result_item, recipe.result_amount)
	print("制作成功: ", recipe.result_item.display_name)
	return true

# 移除旧的私有辅助方法，因为 InventoryManager 已经处理了
