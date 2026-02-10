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
var stats_label: RichTextLabel

# Sci-Fi Theme Colors
const COLOR_BG_MAIN = Color(0.05, 0.07, 0.1, 0.85) # Dark Translucent Blue
const COLOR_ACCENT = Color(0.2, 0.8, 1.0) # Cyan/Electric Blue
const COLOR_ACCENT_DIM = Color(0.2, 0.8, 1.0, 0.5)
const COLOR_TEXT_SEC = Color(0.6, 0.8, 0.9) # Light Blue-Grey
const COLOR_GLOW = Color(0.2, 0.8, 1.0, 0.4)

func _ready():
	_apply_sci_fi_theme()
	call_deferred("_apply_layout_polish") # Deferred to ensure nodes are ready for reparenting
	_setup_libraries()
	if logic_board:
		logic_board.nodes_changed.connect(_on_logic_changed)
	
	if visual_grid:
		visual_grid.grid_changed.connect(_on_visual_grid_changed)

	visibility_changed.connect(_on_visibility_changed)
	
	# Setup Preview UI
	_setup_preview_ui()
	
	# 初始化属性显示容器
	_setup_stats_ui()
	
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
	btn_sim.text = "► 测试法术"
	btn_sim.add_theme_color_override("font_color", Color.GREEN)
	btn_sim.custom_minimum_size.y = 40
	btn_sim.pressed.connect(_on_test_spell_pressed)
	lib_container.add_child(btn_sim)
	lib_container.move_child(btn_sim, 0)
	
	# Add "Change Wand" Button
	var btn_change = Button.new()
	btn_change.text = "切换法杖"
	btn_change.pressed.connect(_open_wand_selector)
	lib_container.add_child(btn_change)
	lib_container.move_child(btn_change, 0)

func _setup_preview_ui():
	# Add Preview to Visual Library Panel
	var visual_lib_panel = $VBoxContainer/TabContainer/Visual/MainLayout/LibraryPanel
	
	var preview_container = VBoxContainer.new()
	preview_container.name = "PreviewContainer"
	
	var label = Label.new()
	label.text = "外观预览"
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
	# 更新统计数据（模块数量等）
	_update_stats_display()

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
		$VBoxContainer/Header/WandNameLabel.text = "正在编辑: " + item.display_name
	
	# 更新属性显示
	_update_stats_display()
		
	# 更新重命名输入框内容
	if has_node("VBoxContainer/Header/RenameEdit"):
		$VBoxContainer/Header/RenameEdit.text = item.display_name
		
	wand_selector.visible = false

func _setup_rename_ui():
	var header = $VBoxContainer/Header
	if header.has_node("RenameEdit"): return
	
	var edit = LineEdit.new()
	edit.name = "RenameEdit"
	edit.placeholder_text = "法杖名称..."
	edit.custom_minimum_size.x = 150
	edit.text_changed.connect(_on_rename_changed)
	header.add_child(edit)
	header.move_child(edit, 0)

func _on_rename_changed(new_text: String):
	if current_wand_item:
		current_wand_item.display_name = new_text
		if has_node("VBoxContainer/Header/WandNameLabel"):
			$VBoxContainer/Header/WandNameLabel.text = "正在编辑: " + new_text

func _setup_stats_ui():
	var header = $VBoxContainer/Header
	if header.has_node("StatsLabel"): 
		stats_label = header.get_node("StatsLabel")
		return
	
	# 确保名字标签不会挤占所有空间
	var name_label = header.get_node_or_null("WandNameLabel")
	if name_label:
		name_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		name_label.custom_minimum_size.x = 200

	stats_label = RichTextLabel.new()
	stats_label.name = "StatsLabel"
	stats_label.bbcode_enabled = true
	stats_label.fit_content = true
	stats_label.scroll_active = false
	stats_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stats_label.add_theme_font_size_override("normal_font_size", 16)
	stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stats_label.custom_minimum_size.x = 450
	
	header.add_child(stats_label)

func _update_stats_display():
	if not current_wand: return
	
	# 如果胚料丢失，尝试补充默认（防御性编程）
	if not current_wand.embryo:
		current_wand.embryo = WandEmbryo.new()
		current_wand.embryo.recharge_rate = 0.5
		current_wand.embryo.mana_capacity = 100
		current_wand.embryo.logic_capacity = 5

	if not stats_label:
		_setup_stats_ui()
	
	var embryo = current_wand.embryo
	
	# Icons
	var i_level = "[img=16]res://assets/ui/icons/icon_level.svg[/img]"
	var i_time = "[img=16]res://assets/ui/icons/icon_time.svg[/img]"
	var i_mana = "[img=16]res://assets/ui/icons/icon_mana.svg[/img]"
	var i_node = "[img=16]res://assets/ui/icons/icon_node.svg[/img]"
	
	# Colors
	var c_val = "[color=#33CCFF]"
	var c_end = "[/color]"
	
	# Top Bar
	var top_text = "[right]%s %s%d%s   %s %s%.2fs%s   %s %s%d%s   %s %s%d/%d%s[/right]" % [
		i_level, c_val, embryo.level, c_end,
		i_time, c_val, embryo.recharge_rate, c_end,
		i_mana, c_val, embryo.mana_capacity, c_end,
		i_node, c_val, current_wand.logic_nodes.size(), embryo.logic_capacity, c_end
	]

	if stats_label:
		stats_label.text = top_text
	
	# Sidebar
	var side_panel = get_node_or_null("VBoxContainer/TabContainer/外观设计/MainLayout/WorkspaceSplit/StatsPanel")
	if not side_panel:
		# 兼容旧路径（如果还未重命名完成）
		side_panel = get_node_or_null("VBoxContainer/TabContainer/Visual/MainLayout/WorkspaceSplit/StatsPanel")
		
	if side_panel:
		var side_display = side_panel.get_node_or_null("StatsDisplay")
		if side_display and side_display is RichTextLabel:
			var stats_text = "[center][b][color=#20CCFF]法杖详细属性[/color][/b][/center]\n\n"
			stats_text += "%s [color=#aaaaaa]等级:[/color] %s\n" % [i_level, embryo.level]
			stats_text += "%s [color=#aaaaaa]施法延迟:[/color] [color=#66ff66]%.2fs[/color]\n" % [i_time, embryo.recharge_rate]
			stats_text += "%s [color=#aaaaaa]法力容量:[/color] [color=#66aaff]%d[/color]\n" % [i_mana, embryo.mana_capacity]
			stats_text += "• [color=#aaaaaa]基础耗能:[/color] [color=#ffaa66]%d[/color]\n" % embryo.base_mana_cost
			stats_text += "%s [color=#aaaaaa]逻辑容量:[/color] [color=#ffffff]%d[/color] 节点\n" % [i_node, embryo.logic_capacity]
			
			stats_text += "\n[center][b][color=#20CCFF]实时状态[/color][/b][/center]\n\n"
			var block_count = current_wand.visual_grid.size()
			stats_text += "• [color=#aaaaaa]外观模块:[/color] %d\n" % block_count
			
			var logic_count = current_wand.logic_nodes.size()
			var logic_color = "#ffffff" if logic_count <= embryo.logic_capacity else "#ff4444"
			stats_text += "• [color=#aaaaaa]已用节点:[/color] [color=%s]%d / %d[/color]\n" % [logic_color, logic_count, embryo.logic_capacity]
			
			side_display.bbcode_enabled = true
			side_display.text = stats_text
			
		var side_title = side_panel.get_node_or_null("StatsTitle")
		if side_title:
			side_title.text = "构造详情"

func edit_wand(wand: WandData):
	current_wand = wand
	if logic_board:
		logic_board.set_data(wand)
	
	if current_wand_item and has_node("VBoxContainer/Header/WandNameLabel"):
		$VBoxContainer/Header/WandNameLabel.text = "正在编辑: " + current_wand_item.display_name
	
	# 添加改名输入框（如果不存在）
	_setup_rename_ui()
	# 更新属性显示
	_update_stats_display()
	
	if visual_grid:
		# Use standard vertically long wand spec: 16x48
		visual_grid.setup(16, 48)
		visual_grid.grid_data = wand.visual_grid.duplicate()
		visual_grid._rebuild_grid()
	
	visible = true

func _on_visibility_changed():
	if visible:
		if current_wand:
			_update_stats_display()
			_animate_open()
		else:
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
	var logic_items = [
		_create_mock_item("能量源", "generator", Color(0.2, 1.0, 0.4), {}, null),
		_create_mock_item("触发器 (法术释放)", "trigger", Color(1, 0.84, 0.0), {"trigger_type": "cast"}, null), 
		_create_mock_item("触发器 (命中)", "trigger", Color(1, 0.5, 0.0), {"trigger_type": "collision"}, null),
		_create_mock_item("触发器 (定时)", "trigger", Color(1, 0.8, 0.3), {"trigger_type": "timer", "duration": 0.5}, null),
		_create_mock_item("火焰核心", "modifier_element", Color(0.8, 0.2, 0.2), {"element": "fire"}, null),
		_create_mock_item("寒冰核心", "modifier_element", Color(0.2, 0.6, 0.9), {"element": "ice"}, null),
		_create_mock_item("增幅器", "modifier_damage", Color(0.6, 0.6, 0.6), {"amount": 20}, null),
		_create_mock_item("分流器", "splitter", Color(0.0, 0.9, 0.9), {}, null),
		_create_mock_item("发射器", "action_projectile", Color(0.9, 0.4, 0.4), {}, null)
	]
	
	for child in palette_grid.get_children():
		child.queue_free()
		
	for item in logic_items:
		_add_logic_palette_button(palette_grid, item)

	# --- Module Library (Visual) ---
	var module_items = [
		# Structure - Grays/Metals
		_create_mock_item("外壳 (深色)", "hull", Color(0.2, 0.2, 0.25), {}, null), 
		_create_mock_item("外壳 (灰色)", "hull", Color(0.5, 0.53, 0.6), {}, null), 
		_create_mock_item("外壳 (浅色)", "hull", Color(0.7, 0.75, 0.8), {}, null),
		_create_mock_item("框架 (锈迹)", "structure", Color(0.45, 0.3, 0.2), {}, null),
		_create_mock_item("框架 (钢材)", "structure", Color(0.3, 0.35, 0.4), {}, null),
		_create_mock_item("黄金装饰", "structure", Color(0.8, 0.6, 0.2), {}, null),
		
		# Energy / Magic - Brights
		_create_mock_item("蓝动力源", "battery", Color(0.2, 0.6, 1.0), {}, null),
		_create_mock_item("红动力源", "battery", Color(0.9, 0.2, 0.2), {}, null),
		_create_mock_item("绿动力源", "battery", Color(0.2, 0.9, 0.4), {}, null),
		_create_mock_item("紫色水晶", "battery", Color(0.7, 0.2, 0.9), {}, null),
		_create_mock_item("青色水晶", "battery", Color(0.2, 0.9, 1.0), {}, null),
		
		# Wood / Nature
		_create_mock_item("木材 (深色)", "structure", Color(0.4, 0.25, 0.1), {}, null),
		_create_mock_item("木材 (浅色)", "structure", Color(0.6, 0.4, 0.2), {}, null),
		_create_mock_item("叶片", "decoration", Color(0.2, 0.6, 0.2), {}, null),
		
		# Misc
		_create_mock_item("通风口", "vent", Color(0.1, 0.1, 0.1), {}, null),
		_create_mock_item("显示屏", "screen", Color(0.0, 0.8, 0.8), {}, null),
		_create_mock_item("等离子灯", "light", Color(1.0, 1.0, 0.6), {}, null)
	]
	
	for child in module_palette.get_children():
		child.queue_free()
		
	for item in module_items:
		_add_visual_palette_button(module_palette, item)

func _add_visual_palette_button(parent, item):
	var btn = PanelContainer.new()
	btn.custom_minimum_size = Vector2(50, 50) # Compact square
	parent.add_child(btn)
	_setup_interactive_glow(btn)
	
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
	_setup_interactive_glow(btn)
	
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
	if not current_wand or not logic_board: return
	# 同步逻辑数据以更新统计信息
	var logic_data = logic_board.get_logic_data()
	current_wand.logic_nodes = logic_data["nodes"]
	current_wand.logic_connections = logic_data["connections"]
	_update_stats_display()

func _on_visual_grid_cell_clicked(coords, btn_index):
	# Logic to place "Currently Selected Material"
	# For now, let's assume we have a test material
	var test_mat = BaseItem.new()
	test_mat.wand_visual_color = Color.RED
	test_mat.id = "test_red_block"
	visual_grid.set_cell(coords, test_mat)

func _apply_sci_fi_theme():
	# Create a runtime Theme
	var theme = Theme.new()
	
	# --- Panel ---
	# Background Panel style
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_BG_MAIN
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = COLOR_ACCENT
	panel_style.border_blend = true
	# Glow effect (Neon)
	panel_style.shadow_color = COLOR_GLOW
	panel_style.shadow_size = 8
	theme.set_stylebox("panel", "Panel", panel_style)
	
	# Apply directly to the main background panel if plain Panel is used
	var main_bg = get_node_or_null("Panel")
	if main_bg:
		main_bg.add_theme_stylebox_override("panel", panel_style)

	# --- Button ---
	# Normal
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.05, 0.1, 0.15, 0.6)
	btn_normal.border_width_left = 1
	btn_normal.border_width_top = 1
	btn_normal.border_width_right = 1
	btn_normal.border_width_bottom = 1
	btn_normal.border_color = COLOR_ACCENT_DIM
	btn_normal.corner_radius_top_left = 4
	btn_normal.corner_radius_bottom_right = 4
	
	# Hover
	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = Color(0.1, 0.2, 0.3, 0.8)
	btn_hover.border_color = COLOR_ACCENT
	btn_hover.shadow_color = COLOR_GLOW
	btn_hover.shadow_size = 6
	
	# Pressed
	var btn_pressed = btn_normal.duplicate()
	btn_pressed.bg_color = COLOR_ACCENT
	btn_pressed.border_color = Color(1, 1, 1, 1)
	btn_pressed.shadow_color = COLOR_GLOW
	btn_pressed.shadow_size = 2
	
	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("focus", "Button", btn_hover) # Same as hover for focus

	# --- TabContainer ---
	var tab_panel = StyleBoxFlat.new()
	tab_panel.bg_color = COLOR_BG_MAIN
	tab_panel.border_width_top = 2
	tab_panel.border_color = COLOR_ACCENT
	theme.set_stylebox("panel", "TabContainer", tab_panel)
	
	var tab_selected = StyleBoxFlat.new()
	tab_selected.bg_color = Color(0.2, 0.8, 1.0, 0.15)
	tab_selected.border_width_top = 3
	tab_selected.border_color = COLOR_ACCENT
	tab_selected.content_margin_left = 20
	tab_selected.content_margin_right = 20
	tab_selected.content_margin_top = 5
	tab_selected.content_margin_bottom = 5
	
	var tab_unselected = StyleBoxFlat.new()
	tab_unselected.bg_color = Color(0.05, 0.05, 0.1, 0.4)
	tab_unselected.content_margin_left = 20
	tab_unselected.content_margin_right = 20
	tab_unselected.content_margin_top = 5
	tab_unselected.content_margin_bottom = 5
	
	theme.set_stylebox("tab_selected", "TabContainer", tab_selected)
	theme.set_stylebox("tab_unselected", "TabContainer", tab_unselected)
	
	# --- LineEdit ---
	var edit_style = StyleBoxFlat.new()
	edit_style.bg_color = Color(0.0, 0.0, 0.0, 0.5)
	edit_style.border_width_bottom = 1
	edit_style.border_color = COLOR_ACCENT_DIM
	theme.set_stylebox("normal", "LineEdit", edit_style)
	theme.set_stylebox("focus", "LineEdit", edit_style)

	# --- GraphEdit ---
	var graph_bg = StyleBoxFlat.new()
	graph_bg.bg_color = COLOR_BG_MAIN # Semi-transparent
	# GraphEdit uses a solid background usually, but let's try
	theme.set_stylebox("bg", "GraphEdit", graph_bg)
	theme.set_color("grid_major", "GraphEdit", Color(0.2, 0.8, 1.0, 0.15))
	theme.set_color("grid_minor", "GraphEdit", Color(0.2, 0.8, 1.0, 0.05))
	theme.set_color("activity", "GraphEdit", COLOR_ACCENT)

	# Apply Theme to Root
	self.theme = theme

func _animate_open():
	# Origin at center
	set_pivot_offset(size / 2)
	scale = Vector2(0.95, 0.95) # Slight zoom in
	modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.3)
	tw.tween_property(self, "modulate:a", 1.0, 0.25)

func _setup_interactive_glow(node: Control):
	# Assuming node can receive mouse events. 
	# If PanelContainer logic/visual script consumes them, we might need to filter = PASS
	node.mouse_filter = Control.MOUSE_FILTER_PASS
	
	node.mouse_entered.connect(func():
		var tw = create_tween()
		tw.tween_property(node, "modulate", Color(1.3, 1.3, 1.5), 0.1)
	)
	node.mouse_exited.connect(func():
		var tw = create_tween()
		tw.tween_property(node, "modulate", Color.WHITE, 0.2)
	)

func _apply_layout_polish():
	# 1. Padding via MarginContainer
	var vbox = get_node_or_null("VBoxContainer")
	if vbox and vbox.get_parent() == self:
		var margin = MarginContainer.new()
		margin.name = "MainPadding"
		# Set full rect
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_top", 20)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_theme_constant_override("margin_bottom", 20)
		
		# Reparent VBoxContainer (careful with references)
		remove_child(vbox)
		margin.add_child(vbox)
		add_child(margin)
		
		# Index 0 is Panel, we want Margin at index 1
		move_child(margin, 1)
		
		# Ensure VBox expands
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 2. Sidebar Min Sizes
	var lib_panel = find_child("LibraryPanel", true, false)
	if lib_panel:
		lib_panel.custom_minimum_size.x = 220
		
	var stats_panel = find_child("StatsPanel", true, false)
	if stats_panel:
		stats_panel.custom_minimum_size.x = 260 # Slightly wider for BBCode
