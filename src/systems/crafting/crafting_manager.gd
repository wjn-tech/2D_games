extends Node

var all_recipes: Array[CraftingRecipe] = []

func _ready() -> void:
	# 设置单例/组标识，方便 UI 查找
	add_to_group("crafting_manager")
	# 确保 GameState 能引用到自己 (如果不是通过 Autoload 直接引用的)
	if GameState.get("crafting_manager") == null:
		GameState.set("crafting_manager", self)
		
	_load_all_recipes()

func unlock_all_recipes() -> void:
	# MVP 逻辑：目前 all_recipes 就是所有可用食谱
	# 如果以后有 "unlocked_recipes" 集合，可以在这里全部添加
	print("CraftingManager: All recipes unlocked!")

func _load_all_recipes() -> void:
	# 清空旧数据防止重复加载
	all_recipes.clear()
	
	# Load a default icon for testing
	var default_icon =  preload("res://icon.svg")
	
	# 如果没有找到 icon.svg，则尝试使用内部图标
	if not default_icon:
		default_icon = PlaceholderTexture2D.new()

	# 1. 工作台 (Workbench)
	var recipe_workbench = CraftingRecipe.new()
	var item_workbench = BaseItem.new()
	item_workbench.id = "workbench"
	item_workbench.display_name = "工作台"
	item_workbench.description = "放置在地面上以制作进阶物品。"
	item_workbench.item_type = "Placeable" 
	
	# Create a simple brown visual for the workbench icon
	var icon_tex = GradientTexture2D.new()
	icon_tex.width = 32
	icon_tex.height = 32
	var fill_gradient = Gradient.new()
	fill_gradient.set_color(0, Color(0.45, 0.24, 0.14)) # Brown
	fill_gradient.set_color(1, Color(0.45, 0.24, 0.14))
	icon_tex.gradient = fill_gradient
	item_workbench.icon = icon_tex
	
	recipe_workbench.result_item = item_workbench
	recipe_workbench.ingredients = { "wood": 4 }
	recipe_workbench.required_station = "" # 徒手即可制作工作台
	all_recipes.append(recipe_workbench)

	# 2. 法杖杖芯 (铜)
	_add_billet_recipe("wand_billet_copper", "铜制法杖胚", "copper_ore", default_icon, "workbench", Color.BROWN, 0.5)
	
	# 3. 法杖杖芯 (铁)
	_add_billet_recipe("wand_billet_iron", "铁制法杖胚", "iron_ore", default_icon, "workbench", Color.GRAY, 0.4)
	
	# 4. 法杖杖芯 (金)
	_add_billet_recipe("wand_billet_gold", "金制法杖胚", "gold_ore", default_icon, "workbench", Color.GOLD, 0.3)
	
	# 5. 法杖杖芯 (钻石)
	_add_billet_recipe("wand_billet_diamond", "钻石法杖胚", "diamond", default_icon, "workbench", Color.CYAN, 0.2)
	
	print("CraftingManager: Loaded %d recipes." % all_recipes.size())

func _add_billet_recipe(id: String, name: String, ore_id: String, icon: Texture2D, station: String = "", color: Color = Color.WHITE, recharge: float = 0.5) -> void:
	var recipe = CraftingRecipe.new()
	
	# 这里改为创建 WandItem 而不是 BaseItem，以便能够进入法杖编辑器
	var item = WandItem.new()
	item.id = id
	item.display_name = name
	
	# 初始化法杖数据
	var w_data = WandData.new()
	w_data.embryo = WandEmbryo.new()
	w_data.embryo.grid_resolution = 16
	w_data.embryo.recharge_rate = recharge # 设置真实的射速（冷却时间）
	
	# 可以在胚料中添加一个基础色块作为提示
	var mat = BaseItem.new()
	mat.id = "base_material"
	mat.display_name = "基础材质"
	mat.wand_visual_color = color
	# 默认在中间放一个小方块
	w_data.visual_grid[Vector2i(8, 24)] = mat
	
	item.wand_data = w_data
	
	# 生成一个预览图标
	var icon_tex = WandTextureGenerator.generate_texture(w_data)
	item.icon = icon_tex if icon_tex else icon
	
	recipe.result_item = item
	recipe.ingredients = { ore_id: 2 }
	recipe.required_station = station
	all_recipes.append(recipe)

func get_handcrafting_recipes() -> Array[CraftingRecipe]:
	var result: Array[CraftingRecipe] = []
	var available_stations = _get_nearby_stations()
	
	for recipe in all_recipes:
		if recipe.required_station == "" or recipe.required_station in available_stations:
			result.append(recipe)
	return result

func _get_nearby_stations() -> Array[String]:
	var stations: Array[String] = []
	var player = get_tree().get_first_node_in_group("player")
	if not player: return stations
	
	# 检查玩家附近的交互区域
	var interaction_area = player.get_node_or_null("InteractionArea")
	if not interaction_area: return stations
	
	var bodies = interaction_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("workbench") or body.name.to_lower().contains("workbench"):
			if "workbench" not in stations: stations.append("workbench")
			
	var areas = interaction_area.get_overlapping_areas()
	for area in areas:
		# 有些工作台可能是 Area2D 或者子节点是 Area2D
		var p = area.get_parent()
		if area.is_in_group("workbench") or (p and (p.is_in_group("workbench") or p.name.to_lower().contains("workbench"))):
			if "workbench" not in stations: stations.append("workbench")
			
	return stations

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
		
	# 1. 扣除材料
	for item_id in recipe.ingredients:
		# 注意：这里假设 inventory.remove_item 能够通过 ID 移除
		# 实际上 inventory_manager.gd 的 remove_item 需要 from_inv + slot_index
		# 这里需要 InventoryManager 提供更高级的按 ID 移除接口
		# 暂时假设 GameState.inventory 有 remove_item_by_id 或类似扩展，或者我们需要在这里处理查找
		# 原代码: GameState.inventory.remove_item(item_id, recipe.ingredients[item_id])
		# 这似乎暗示 GameState.inventory 是一个比 InventoryManager 更高层的封装或者 InventoryManager 有 helper
		GameState.inventory.remove_item_by_id(item_id, recipe.ingredients[item_id])
		
	# 2. 计算品质
	var quality_info = _calculate_quality_results()
	
	# 3. 生成物品实例
	var result_item = recipe.result_item.duplicate(true)
	result_item.quality_score = quality_info.score
	result_item.quality_grade = quality_info.grade
	result_item.crafted_by = "Player" # 占位
	
	# 4. 添加产物
	GameState.inventory.add_item(result_item, recipe.result_amount)
	
	print("制作成功: %s (%s)" % [result_item.display_name, result_item.quality_grade])
	return true

func _calculate_quality_results() -> Dictionary:
	# 简单的 MVP 品质计算
	var score = randf_range(0.0, 100.0)
	var grade = "Common"
	
	if score >= 90.0:
		grade = "Masterwork"
	elif score >= 75.0:
		grade = "Epic"
	elif score >= 50.0:
		grade = "Rare"
	else:
		grade = "Common"
		
	return { "score": score, "grade": grade }


# 移除旧的私有辅助方法，因为 InventoryManager 已经处理了
