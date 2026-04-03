extends Control

@onready var recipe_list = $Panel/VBoxContainer/ScrollContainer/RecipeList
@onready var info_label = $Panel/VBoxContainer/InfoLabel
@onready var craft_button = $Panel/VBoxContainer/CraftButton

var selected_recipe: CraftingRecipe = null

func _ready() -> void:
	_populate_recipes()
	craft_button.pressed.connect(_on_craft_pressed)
	$Panel/CloseButton.pressed.connect(func(): UIManager.close_window("CraftingWindow"))
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		_populate_recipes()

func _populate_recipes() -> void:
	for child in recipe_list.get_children():
		child.queue_free()

	var recipes: Array = []
	var cm = get_tree().get_first_node_in_group("crafting_manager")
	if cm and cm.has_method("get_handcrafting_recipes"):
		recipes = cm.get_handcrafting_recipes()
	elif GameState and GameState.get("recipe_db") != null:
		for key in GameState.recipe_db.keys():
			recipes.append(GameState.recipe_db[key])

	for recipe in recipes:
		if recipe == null or recipe.result_item == null:
			continue
		var btn = Button.new()
		btn.text = recipe.result_item.display_name
		btn.pressed.connect(func(): _select_recipe(recipe))
		recipe_list.add_child(btn)

func _select_recipe(recipe: CraftingRecipe) -> void:
	selected_recipe = recipe
	var text = "配方: %s\n需要材料:\n" % recipe.result_item.display_name
	
	var can_make = true
	for id in recipe.ingredients:
		var amount = recipe.ingredients[id]
		var owned = GameState.inventory.get_item_count(id)
		var item_name = id # 默认 ID，后期可从数据库查
		if GameState.item_db.has(id):
			item_name = GameState.item_db[id].display_name
			
		text += "- %s: %d/%d\n" % [item_name, owned, amount]
		if owned < amount:
			can_make = false
			
	info_label.text = text
	craft_button.disabled = not can_make

func _on_craft_pressed() -> void:
	if not selected_recipe: return
	
	var success = CraftingManager.craft(selected_recipe)
	if success:
		_select_recipe(selected_recipe) # 刷新界面状态
		# 播放一个音效或动画
		print("制作完成！")
	else:
		info_label.text += "\n[制作失败：材料不足]"
