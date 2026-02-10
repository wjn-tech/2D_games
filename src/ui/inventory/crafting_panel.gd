extends PanelContainer
class_name CraftingPanel

signal recipe_selected(recipe)
signal craft_requested(recipe)

var recipe_list_container: VBoxContainer
var details_panel: VBoxContainer
var craft_button: Button
var selected_recipe: CraftingRecipe

func _ready() -> void:
	_setup_ui()
	_populate_recipes()

func _setup_ui() -> void:
	# Basic vertical layout
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Title
	var title = Label.new()
	title.text = "合成制作"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)
	
	# Split View: Recipe List (Top) vs Details (Bottom) or List (Left) Details (Right)?
	# The spec says "Recipe List" and "Details Panel"
	# Let's use a VBox: List then Details
	
	# Recipe List Area
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)
	
	recipe_list_container = VBoxContainer.new()
	scroll.add_child(recipe_list_container)
	
	# Details Area
	var separator = HSeparator.new()
	main_vbox.add_child(separator)
	
	details_panel = VBoxContainer.new()
	details_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_panel.size_flags_stretch_ratio = 0.5 # Smaller than list
	main_vbox.add_child(details_panel)
	
	# Craft Button
	craft_button = Button.new()
	craft_button.text = "制作"
	craft_button.disabled = true
	craft_button.pressed.connect(_on_craft_pressed)
	main_vbox.add_child(craft_button)

func _populate_recipes() -> void:
	# Clear existing
	for child in recipe_list_container.get_children():
		child.queue_free()
		
	# Fetch recipes from Global Manager
	var cm = GameState.get("crafting_manager")
	if not cm:
		# 尝试通过组查找
		cm = get_tree().get_first_node_in_group("crafting_manager")
		
	if cm and cm.has_method("get_handcrafting_recipes"):
		print("CraftingPanel: Found CraftingManager, loading recipes...")
		var recipes = cm.get_handcrafting_recipes()
		for recipe in recipes:
			add_recipe_to_list(recipe)
	else:
		print("CraftingPanel: CraftingManager NOT found or no recipes.")
		# Test/Fallback: if no recipes found, create a placeholder
		var label = Label.new()
		label.text = "暂无解锁配方"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		recipe_list_container.add_child(label)

func add_recipe_to_list(recipe: CraftingRecipe) -> void:
	var btn = Button.new()
	# btn.text = recipe.result_item.display_name
	# Since result_item might be null during dev, check safe
	var name_str = "未知配方"
	if recipe.result_item:
		name_str = recipe.result_item.display_name
	
	btn.text = name_str
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(func(): _select_recipe(recipe))
	recipe_list_container.add_child(btn)

func _select_recipe(recipe: CraftingRecipe) -> void:
	selected_recipe = recipe
	_update_details()
	emit_signal("recipe_selected", recipe)

func _update_details() -> void:
	# Clear details
	for child in details_panel.get_children():
		child.queue_free()
		
	if not selected_recipe:
		craft_button.disabled = true
		return
		
	# Show Info
	var info = Label.new()
	info.text = "制作材料:"
	info.add_theme_font_size_override("font_size", 14)
	details_panel.add_child(info)
	
	var can_craft = true
	
	# Try to get player's inventory manager for checking counts
	# In this project, it's often GameState.inventory or via player group
	var inv_manager = GameState.inventory
	if not inv_manager:
		var player = get_tree().get_first_node_in_group("player")
		if player: inv_manager = player.get("inventory")

	for item_id in selected_recipe.ingredients:
		var amount = selected_recipe.ingredients[item_id]
		var has_count = 0
		if inv_manager and inv_manager.has_method("get_item_count"):
			has_count = inv_manager.get_item_count(item_id)
		
		# 尝试获取友好的名称
		var display_name = item_id
		var name_map = {
			"wood": "木材",
			"iron_ore": "铁矿石",
			"copper_ore": "铜矿石",
			"gold_ore": "金矿石",
			"diamond": "钻石",
			"stone": "石头",
			"dirt": "泥土"
		}
		if name_map.has(item_id):
			display_name = name_map[item_id]
		
		var line = Label.new()
		line.text = "• %s: %d / %d" % [display_name, has_count, amount]
		line.add_theme_font_size_override("font_size", 12)
		
		if has_count < amount:
			line.modulate = Color.TOMATO
			can_craft = false
		else:
			line.modulate = Color.LIGHT_GREEN
			
		details_panel.add_child(line)
		
	craft_button.disabled = not can_craft

func _on_craft_pressed() -> void:
	if selected_recipe:
		# Use Global Crafting Manager
		var cm = GameState.get("crafting_manager")
		if not cm:
			# Try to find it in the tree if not a singleton
			cm = get_tree().get_first_node_in_group("crafting_manager")
		
		if cm and cm.has_method("craft"):
			var success = cm.craft(selected_recipe)
			if success:
				_update_details() # Refresh counts
				print("CraftingPanel: 制作成功!")
		else:
			# Fallback for testing if CraftingManager isn't fully wired as a singleton
			print("CraftingPanel: CraftingManager not found!")
