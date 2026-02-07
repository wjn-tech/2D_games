extends Control
class_name WandEditor

const SimulationBoxScene = preload("res://src/ui/wand_editor/components/simulation_box.tscn")
const WandSelectorScene = preload("res://src/ui/wand_editor/components/wand_selector.tscn")

@onready var visual_grid: WandVisualGrid = $VBoxContainer/TabContainer/Visual/MainLayout/WorkspaceSplit/GridArea/VisualGrid
@onready var module_palette: GridContainer = $VBoxContainer/TabContainer/Visual/MainLayout/LibraryPanel/ModuleScroll/ModulePalette

@onready var logic_board: WandLogicBoard = $VBoxContainer/TabContainer/Logic/HSplitContainer/LogicBoard
@onready var palette_grid: GridContainer = $VBoxContainer/TabContainer/Logic/HSplitContainer/LibraryContainer/ScrollContainer/PaletteGrid
@onready var tab_container = $VBoxContainer/TabContainer

var current_wand: WandData
var current_wand_item: WandItem
var simulation_box
var wand_selector

var preview_texture_rect_1x: TextureRect
var preview_texture_rect_4x: TextureRect

func _ready():
	_setup_libraries()
	if logic_board:
		logic_board.nodes_changed.connect(_on_logic_changed)
	
	if visual_grid:
		visual_grid.grid_changed.connect(_on_visual_grid_changed)

	visibility_changed.connect(_on_visibility_changed)
	
	# Setup Preview UI
	_setup_preview_ui()
	
	# Setup Simulation Box
	simulation_box = SimulationBoxScene.instantiate()
	simulation_box.visible = false
	simulation_box.set_anchors_preset(Control.PRESET_CENTER)
	simulation_box.custom_minimum_size = Vector2(800, 600)
	add_child(simulation_box)
	
	# Setup Wand Selector
	wand_selector = WandSelectorScene.instantiate()
	wand_selector.visible = false
	wand_selector.set_anchors_preset(Control.PRESET_CENTER)
	add_child(wand_selector)
	wand_selector.wand_selected.connect(_on_wand_selected)

	if visible:
		_on_visibility_changed()
	
	# Add Simulation Button to Logic Library Panel
	var lib_container = $VBoxContainer/TabContainer/Logic/HSplitContainer/LibraryContainer
	var btn_sim = Button.new()
	btn_sim.text = "► TEST SPELL"
	btn_sim.add_theme_color_override("font_color", Color.GREEN)
	btn_sim.custom_minimum_size.y = 40
	btn_sim.pressed.connect(_on_test_spell_pressed)
	lib_container.add_child(btn_sim)
	lib_container.move_child(btn_sim, 0)
	
	# Add "Change Wand" Button
	var btn_change = Button.new()
	btn_change.text = "Change Wand"
	btn_change.pressed.connect(_open_wand_selector)
	lib_container.add_child(btn_change)
	lib_container.move_child(btn_change, 0)

func _setup_preview_ui():
	# Add Preview to Visual Library Panel
	var visual_lib_panel = $VBoxContainer/TabContainer/Visual/MainLayout/LibraryPanel
	
	var preview_container = VBoxContainer.new()
	preview_container.name = "PreviewContainer"
	
	var label = Label.new()
	label.text = "Preview"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_container.add_child(label)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	
	# 4x Preview
	var v_4x = VBoxContainer.new()
	var label_4x = Label.new()
	label_4x.text = "4x"
	label_4x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_texture_rect_4x = TextureRect.new()
	preview_texture_rect_4x.custom_minimum_size = Vector2(32, 96) # Aspect ratio 1:3
	preview_texture_rect_4x.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_texture_rect_4x.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
	# Force initial preview update
	_update_wand_preview()
	
	# Background for 4x
	var bg_4x = ColorRect.new()
	bg_4x.custom_minimum_size = Vector2(40, 100)
	bg_4x.color = Color(0.1, 0.1, 0.1)
	bg_4x.add_child(preview_texture_rect_4x)
	preview_texture_rect_4x.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	v_4x.add_child(bg_4x)
	v_4x.add_child(label_4x)
	hbox.add_child(v_4x)
	
	# 1x Preview
	var v_1x = VBoxContainer.new()
	var label_1x = Label.new()
	label_1x.text = "1x"
	label_1x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_texture_rect_1x = TextureRect.new()
	preview_texture_rect_1x.custom_minimum_size = Vector2(16, 48) # 1x3 tiles (16px * 48px)
	preview_texture_rect_1x.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_texture_rect_1x.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Background for 1x
	var bg_1x = ColorRect.new()
	bg_1x.custom_minimum_size = Vector2(20, 52)
	bg_1x.color = Color(0.1, 0.1, 0.1)
	bg_1x.add_child(preview_texture_rect_1x)
	preview_texture_rect_1x.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	v_1x.add_child(bg_1x)
	v_1x.add_child(label_1x)
	hbox.add_child(v_1x)
	
	preview_container.add_child(hbox)
	
	# Insert at top
	visual_lib_panel.add_child(preview_container)
	visual_lib_panel.move_child(preview_container, 0)

func _on_visual_grid_changed():
	if not current_wand: return
	
	# Sync Data
	current_wand.visual_grid = visual_grid.grid_data.duplicate()
	
	# Update Preview
	_update_wand_preview()

func _update_wand_preview():
	if not current_wand: return
	var tex = WandTextureGenerator.generate_texture(current_wand)
	if preview_texture_rect_1x:
		preview_texture_rect_1x.texture = tex
	if preview_texture_rect_4x:
		preview_texture_rect_4x.texture = tex

func _open_wand_selector():
	var player = get_tree().get_first_node_in_group("player")
	if player and player.get("inventory"):
		wand_selector.refresh(player.inventory)
		wand_selector.visible = true

func _on_wand_selected(item: WandItem):
	current_wand_item = item
	edit_wand(item.wand_data)
	if has_node("VBoxContainer/Header/WandNameLabel"):
		$VBoxContainer/Header/WandNameLabel.text = "Editing: " + item.display_name
	wand_selector.visible = false

func edit_wand(wand: WandData):
	current_wand = wand
	if logic_board:
		logic_board.set_data(wand)
	
	if current_wand_item and has_node("VBoxContainer/Header/WandNameLabel"):
		$VBoxContainer/Header/WandNameLabel.text = "Editing: " + current_wand_item.display_name
	
	if visual_grid:
		# Use standard vertically long wand spec: 16x48
		visual_grid.setup(16, 48)
		visual_grid.grid_data = wand.visual_grid.duplicate()
		visual_grid._rebuild_grid()
	
	visible = true

func _on_visibility_changed():
	if visible:
		if not current_wand:
			var player = get_tree().get_first_node_in_group("player")
			if player and player.inventory:
				var item = player.inventory.get_equipped_item()
				if item and item is WandItem:
					_on_wand_selected(item)
				else:
					_open_wand_selector()

func _on_test_spell_pressed():
	if not current_wand: return
	# Sync Logic Data from Board to Resource (Memory Only)
	var logic_data = logic_board.get_logic_data()
	current_wand.logic_nodes = logic_data["nodes"]
	current_wand.logic_connections = logic_data["connections"]
	
	simulation_box.setup(current_wand)

func _setup_libraries():
	# --- Logic Library ---
	# Pure color blocks. Using null for icon_path to trigger default behavior in _create_mock_item/Slot.
	# Or using a simple white square/circle if needed, but slot logic below handles null icon by not showing one, 
	# effectively showing just the color block. Or we can use generic icon.
	
	var logic_items = [
		_create_mock_item("Source", "generator", Color(0.2, 1.0, 0.4), {}, null),
		_create_mock_item("Trigger (Cast)", "trigger", Color(1, 0.84, 0.0), {"trigger_type": "cast"}, null), 
		_create_mock_item("Trigger (Impact)", "trigger", Color(1, 0.5, 0.0), {"trigger_type": "collision"}, null),
		_create_mock_item("Trigger (Timer)", "trigger", Color(1, 0.8, 0.3), {"trigger_type": "timer", "duration": 0.5}, null),
		_create_mock_item("Fire Core", "modifier_element", Color(0.8, 0.2, 0.2), {"element": "fire"}, null),
		_create_mock_item("Ice Core", "modifier_element", Color(0.2, 0.6, 0.9), {"element": "ice"}, null),
		_create_mock_item("Amp", "modifier_damage", Color(0.6, 0.6, 0.6), {"amount": 20}, null),
		_create_mock_item("Splitter", "splitter", Color(0.0, 0.9, 0.9), {}, null),
		_create_mock_item("Blaster", "action_projectile", Color(0.9, 0.4, 0.4), {}, null)
	]
	
	for child in palette_grid.get_children():
		child.queue_free()
		
	for item in logic_items:
		_add_logic_palette_button(palette_grid, item)

	# --- Module Library (Visual) ---
	var module_items = [
		# Structure - Grays/Metals
		_create_mock_item("Hull (Dark)", "hull", Color(0.2, 0.2, 0.25), {}, null), 
		_create_mock_item("Hull (Gray)", "hull", Color(0.5, 0.53, 0.6), {}, null), 
		_create_mock_item("Hull (Light)", "hull", Color(0.7, 0.75, 0.8), {}, null),
		_create_mock_item("Frame (Rusty)", "structure", Color(0.45, 0.3, 0.2), {}, null),
		_create_mock_item("Frame (Steel)", "structure", Color(0.3, 0.35, 0.4), {}, null),
		_create_mock_item("Gold Trim", "structure", Color(0.8, 0.6, 0.2), {}, null),
		
		# Energy / Magic - Brights
		_create_mock_item("Core (Blue)", "battery", Color(0.2, 0.6, 1.0), {}, null),
		_create_mock_item("Core (Red)", "battery", Color(0.9, 0.2, 0.2), {}, null),
		_create_mock_item("Core (Green)", "battery", Color(0.2, 0.9, 0.4), {}, null),
		_create_mock_item("Crystal (Purple)", "battery", Color(0.7, 0.2, 0.9), {}, null),
		_create_mock_item("Crystal (Cyan)", "battery", Color(0.2, 0.9, 1.0), {}, null),
		
		# Wood / Nature
		_create_mock_item("Wood (Dark)", "structure", Color(0.4, 0.25, 0.1), {}, null),
		_create_mock_item("Wood (Light)", "structure", Color(0.6, 0.4, 0.2), {}, null),
		_create_mock_item("Leaf", "decoration", Color(0.2, 0.6, 0.2), {}, null),
		
		# Misc
		_create_mock_item("Vent", "vent", Color(0.1, 0.1, 0.1), {}, null),
		_create_mock_item("Screen", "screen", Color(0.0, 0.8, 0.8), {}, null),
		_create_mock_item("Light", "light", Color(1.0, 1.0, 0.6), {}, null)
	]
	
	for child in module_palette.get_children():
		child.queue_free()
		
	for item in module_items:
		_add_visual_palette_button(module_palette, item)

func _add_visual_palette_button(parent, item):
	var btn = PanelContainer.new()
	btn.custom_minimum_size = Vector2(50, 50) # Compact square
	parent.add_child(btn)
	
	if not FileAccess.file_exists("res://src/ui/wand_editor/components/visual_palette_button.gd"):
		push_error("Visual Palette Button script missing!")
		return
		
	btn.set_script(load("res://src/ui/wand_editor/components/visual_palette_button.gd"))
	btn.setup(item)
	
	# Connect Selection Signal
	if btn.has_signal("item_selected"):
		btn.item_selected.connect(_on_palette_item_selected)

func _add_logic_palette_button(parent, item):
	var btn = PanelContainer.new()
	btn.custom_minimum_size = Vector2(110, 80)
	parent.add_child(btn)
	
	if not FileAccess.file_exists("res://src/ui/wand_editor/components/logic_palette_button.gd"):
		# Fallback if I haven't created it yet, but I just did.
		push_error("Logic Palette Button script missing!")
		return
	
	btn.set_script(load("res://src/ui/wand_editor/components/logic_palette_button.gd"))
	btn.setup(item)

func _on_palette_item_selected(item):
	if visual_grid:
		visual_grid.selected_material = item
		print("Selected material: ", item.id)

# _create_palette_button_script REMOVED as files are now static

func _create_mock_item(name, type, color, val = {}, icon_path = null):
	var item = BaseItem.new()
	item.display_name = name
	item.wand_logic_type = type
	item.wand_visual_color = color
	item.wand_logic_value = val
	
	if icon_path and FileAccess.file_exists(icon_path):
		item.icon = load(icon_path)
	elif icon_path and FileAccess.file_exists(icon_path + ".import"):
		item.icon = load(icon_path)
	else:
		# Use a default texture or nothing. 
		# If nothing, the button will just be colored.
		pass
	return item

func _on_save_pressed():
	if not current_wand:
		return
		
	# Update Logic Data
	var logic_data = logic_board.get_logic_data()
	current_wand.logic_nodes = logic_data["nodes"]
	current_wand.logic_connections = logic_data["connections"]
	
	# COMPILER VALIDATION
	var program = WandCompiler.compile(current_wand)
	if not program.is_valid:
		push_warning("Wand Logic Invalid: " + str(program.compilation_errors))
		# In a real UI, show a popup here.
		# For now, we block saving? Or just print warning?
		# Let's print and allow save (so work isn't lost), but cache won't be valid.
	else:
		current_wand.compiled_program = program
	
	# Update Visual Data
	current_wand.visual_grid = visual_grid.grid_data.duplicate()
	
	# Persist to disk
	if current_wand.resource_path:
		var err = ResourceSaver.save(current_wand, current_wand.resource_path)
		if err == OK:
			print("Wand resource saved to: ", current_wand.resource_path)
		else:
			push_error("Failed to save wand resource: %d" % err)
	
	if UIManager:
		UIManager.close_window("WandEditor")
		# Toggle HUD back on handled by UIManager


func _on_logic_changed():
	# Optional: Validate graph live?
	pass

func _on_visual_grid_cell_clicked(coords, btn_index):
	# Logic to place "Currently Selected Material"
	# For now, let's assume we have a test material
	var test_mat = BaseItem.new()
	test_mat.wand_visual_color = Color.RED
	test_mat.id = "test_red_block"
	visual_grid.set_cell(coords, test_mat)
