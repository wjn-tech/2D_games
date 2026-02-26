extends Control
class_name WandEditor

const SimulationBoxScene = preload("res://src/ui/wand_editor/components/simulation_box.tscn")
const WandSelectorScene = preload("res://src/ui/wand_editor/components/wand_selector.tscn")

@onready var visual_grid: WandVisualGrid = $VBoxContainer/MainSplit/RightSplit/CenterWorkspace/VisualGrid
@onready var module_palette: GridContainer = $VBoxContainer/MainSplit/LeftSidebar/LibraryPanel/ModuleScroll/ModulePalette

@onready var logic_board: WandLogicBoard = $VBoxContainer/MainSplit/RightSplit/CenterWorkspace/LogicBoard
@onready var palette_grid: GridContainer = $VBoxContainer/MainSplit/LeftSidebar/LibraryContainer/ScrollContainer/PaletteGrid

@onready var library_panel: VBoxContainer = $VBoxContainer/MainSplit/LeftSidebar/LibraryPanel
@onready var library_container: VBoxContainer = $VBoxContainer/MainSplit/LeftSidebar/LibraryContainer
@onready var stats_container: VBoxContainer = $VBoxContainer/MainSplit/RightSplit/RightSidebar/StatsPanel/StatsContainer

@onready var header: HBoxContainer = find_child("Header", true, false)
@onready var wand_name_label: Label = find_child("WandNameLabel", true, false)

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
	wand_selector.set_anchors_preset(Control.PRESET_FULL_RECT) # 改为全屏覆盖
	add_child(wand_selector)
	wand_selector.wand_selected.connect(_on_wand_selected)

	if visible:
		_on_visibility_changed()
	
	# Add Simulation Button to Header
	if header:
		var btn_sim = Button.new()
		btn_sim.text = "► 测试法术"
		btn_sim.add_theme_color_override("font_color", Color.GREEN)
		btn_sim.custom_minimum_size = Vector2(100, 32)
		btn_sim.pressed.connect(_on_test_spell_pressed)
		header.add_child(btn_sim)
		
		# Add "Change Wand" Button to Header
		var btn_change = Button.new()
		btn_change.text = "切换法杖"
		btn_change.custom_minimum_size = Vector2(100, 32)
		btn_change.pressed.connect(_open_wand_selector)
		header.add_child(btn_change)

func _setup_preview_ui():
	# Add Preview to Visual Library Panel
	var visual_lib_panel = library_panel
	
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
	
	# Sync Data and Normalize
	current_wand.visual_grid = visual_grid.grid_data.duplicate()
	current_wand.normalize_grid() # Always ensure Vector2i keys
	
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

func _open_wand_selector(force: bool = false):
	var player = get_tree().get_first_node_in_group("player")
	if player and player.get("inventory"):
		wand_selector.refresh(player.inventory)
		wand_selector.visible = true
		
		# Force fullscreen modal behavior
		wand_selector.set_anchors_preset(Control.PRESET_FULL_RECT)
		wand_selector.custom_minimum_size = Vector2(0, 0) # Reset min size constraint
		
		# Hide other UI? No, just cover them.
		wand_selector.move_to_front()
		
		# If forced (initial open), maybe hide close button?
		pass

func _on_wand_selected(item: WandItem):
	current_wand_item = item
	
	# 首先同步 UI 关键信息
	if wand_name_label:
		wand_name_label.text = "正在编辑: " + item.display_name
		
	if header:
		var rename_edit = header.get_node_or_null("RenameEdit")
		if rename_edit:
			rename_edit.text = item.display_name
	
	# 应用数据并刷新展示
	edit_wand(item.wand_data)
	_setup_libraries()
	_update_stats_display()
	
	wand_selector.visible = false

func _setup_rename_ui():
	if not header: return
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
		if wand_name_label:
			wand_name_label.text = "正在编辑: " + new_text

func _setup_stats_ui():
	if not header: return
	if header.has_node("StatsLabel"): 
		stats_label = header.get_node("StatsLabel")
		return
	
	# 确保名字标签不会挤占所有空间
	if wand_name_label:
		wand_name_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		wand_name_label.custom_minimum_size.x = 200

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

func _process(_delta):
	# Update real-time mana display if visible
	if visible and current_wand:
		_update_mana_display()

func _update_mana_display():
	if not stats_container: return
	var label = stats_container.get_node_or_null("ManaTicker")
	if not label:
		label = RichTextLabel.new()
		label.name = "ManaTicker"
		label.bbcode_enabled = true
		label.fit_content = true
		stats_container.add_child(label)
		stats_container.move_child(label, 0)
	
	var m_color = "cyan" if current_wand.current_mana > current_wand.embryo.mana_capacity * 0.2 else "red"
	label.text = "[center][b]Mana: [color=%s]%.0f[/color] / %d[/b][/center]" % [m_color, current_wand.current_mana, int(current_wand.embryo.mana_capacity)]

func _create_stat_row(icon_path: String, label_text: String, value_text: String, value_color: Color = Color.WHITE) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	
	if icon_path != "":
		var icon = TextureRect.new()
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		icon.custom_minimum_size = Vector2(16, 16)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(icon)
	
	var label = Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)
	
	var value = Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", value_color)
	hbox.add_child(value)
	
	return hbox

func _create_stat_header(text: String) -> MarginContainer:
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 5)
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", COLOR_ACCENT)
	# label.add_theme_font_size_override("font_size", 14)
	margin.add_child(label)
	return margin

func _update_stats_display():
	if not current_wand: return
	
	# 如果胚料丢失，尝试补充默认（防御性编程）
	if not current_wand.embryo:
		current_wand.embryo = WandEmbryo.new()
		current_wand.embryo.recharge_time = 0.5
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
		i_time, c_val, embryo.recharge_time, c_end,
		i_mana, c_val, embryo.mana_capacity, c_end,
		i_node, c_val, current_wand.logic_nodes.size(), embryo.logic_capacity, c_end
	]

	if stats_label:
		stats_label.text = top_text
	
	# Sidebar
	if stats_container:
		# Clear existing stats except ManaTicker
		for child in stats_container.get_children():
			if child.name != "ManaTicker":
				child.queue_free()
		
		var sim_stats = SpellProcessor.get_wand_stats(current_wand)
		var sim_duration = sim_stats.get("duration", 0.0) if sim_stats is Dictionary else 0.0
		var sim_dmg = sim_stats.get("total_damage", 0.0) if sim_stats is Dictionary else 0.0
		var sim_projs = sim_stats.get("projectile_count", 0) if sim_stats is Dictionary else 0
		var sim_mana = sim_stats.get("simulated_mana_usage", 0.0) if sim_stats is Dictionary else 0.0
		
		stats_container.add_child(_create_stat_header("法杖详细属性"))
		stats_container.add_child(_create_stat_row("res://assets/ui/icons/icon_level.svg", "等级:", str(embryo.level)))
		stats_container.add_child(_create_stat_row("res://assets/ui/icons/icon_time.svg", "施法延迟:", "%.2fs" % embryo.cast_delay, Color("#66ff66")))
		stats_container.add_child(_create_stat_row("res://assets/ui/icons/icon_time.svg", "充能时间:", "%.2fs" % embryo.recharge_time, Color("#66ff66")))
		stats_container.add_child(_create_stat_row("res://assets/ui/icons/icon_mana.svg", "法力容量:", str(int(embryo.mana_capacity)), Color("#66aaff")))
		stats_container.add_child(_create_stat_row("", "  法力回复:", "%d/s" % int(embryo.mana_recharge_speed), Color("#66ffff")))
		stats_container.add_child(_create_stat_row("", "  充能回复:", "+%d" % int(embryo.mana_recharge_burst), Color("#66ffff")))
		stats_container.add_child(_create_stat_row("res://assets/ui/icons/icon_node.svg", "逻辑容量:", "%d 节点" % embryo.logic_capacity, Color.WHITE))
		
		stats_container.add_child(_create_stat_header("法术预览"))
		stats_container.add_child(_create_stat_row("", "单次爆发耗时:", "%.2fs" % sim_duration, Color("#ffff44")))
		stats_container.add_child(_create_stat_row("", "单次爆发法力:", "%.0f" % sim_mana, Color("#66aaff")))
		stats_container.add_child(_create_stat_row("", "理论全额伤害:", "%.1f" % sim_dmg, Color("#ff4444")))
		stats_container.add_child(_create_stat_row("", "投射物数量:", str(sim_projs), Color("#ccccff")))
		
		stats_container.add_child(_create_stat_header("实时状态"))
		var block_count = current_wand.visual_grid.size()
		stats_container.add_child(_create_stat_row("", "外观模块:", str(block_count)))
		
		var logic_count = current_wand.logic_nodes.size()
		var logic_color = Color.WHITE if logic_count <= embryo.logic_capacity else Color("#ff4444")
		stats_container.add_child(_create_stat_row("", "已用节点:", "%d / %d" % [logic_count, embryo.logic_capacity], logic_color))

func edit_wand(wand: WandData):
	current_wand = wand
	if current_wand:
		current_wand.normalize_grid()
	
	if logic_board:
		logic_board.set_data(wand)
	
	if current_wand_item and wand_name_label:
		wand_name_label.text = "正在编辑: " + current_wand_item.display_name
	
	if current_wand_item and header:
		var rename_edit = header.get_node_or_null("RenameEdit")
		if rename_edit:
			rename_edit.text = current_wand_item.display_name
	
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
		var player = get_tree().get_first_node_in_group("player")
		var equipped_item = null
		if player and player.inventory:
			equipped_item = player.inventory.get_equipped_item()
		
		if equipped_item and equipped_item is WandItem:
			# 如果当前没在编辑或者装备的法杖变了，自动切换到新装备的法杖
			if current_wand_item != equipped_item:
				_on_wand_selected(equipped_item)
			else:
				_update_stats_display()
		elif current_wand:
			_update_stats_display()
		else:
			_open_wand_selector(true)
			
		_animate_open()

func _time_str(val):
	return "%.2fs" % val

func _on_test_spell_pressed():
	if not current_wand: return
	# Sync Logic Data from Board to Resource (Memory Only)
	var logic_data = logic_board.get_logic_data()
	current_wand.logic_nodes = logic_data["nodes"]
	current_wand.logic_connections = logic_data["connections"]
	
	simulation_box.setup(current_wand)

func _setup_libraries():
	# --- Logic Library ---
	# 1. Define all possible logic items
	var logic_items = [
		_create_mock_item("能量源", "generator", Color(0.2, 1.0, 0.4), {"mana_cost": 0, "delay": 0.05, "damage": 0}, null),
		_create_mock_item("触发器 (法术释放)", "trigger", Color(1, 0.84, 0.0), {"mana_cost": 2, "trigger_type": "cast", "delay": 0.1}, null), 
		_create_mock_item("触发器 (命中)", "trigger", Color(1, 0.5, 0.0), {"mana_cost": 5, "trigger_type": "collision", "delay": 0.0}, null),
		_create_mock_item("触发器 (定时)", "trigger", Color(1, 0.8, 0.3), {"mana_cost": 5, "trigger_type": "timer", "duration": 0.5, "delay": 0.0}, null),
		
		_create_mock_item("火焰核心", "modifier_element", Color(0.8, 0.2, 0.2), {"mana_cost": 10, "element": "fire", "damage_add": 5, "delay": 0.1}, null),
		_create_mock_item("寒冰核心", "modifier_element", Color(0.2, 0.6, 0.9), {"mana_cost": 10, "element": "ice", "damage_add": 2, "delay": 0.05}, null),
		_create_mock_item("增幅器", "modifier_damage", Color(0.6, 0.6, 0.6), {"mana_cost": 15, "amount": 10, "delay": 0.05}, null),
		_create_mock_item("伤害强化", "modifier_damage", Color(1.0, 0.2, 0.2), {"mana_cost": 25, "amount": 25, "delay": 0.15}, null),
		_create_mock_item("穿透强化", "modifier_pierce", Color(0.8, 0.2, 0.8), {"mana_cost": 30, "pierce": 1, "delay": 0.1}, null),
		_create_mock_item("速度修正", "modifier_speed", Color(0.2, 0.8, 0.6), {"mana_cost": 5, "speed_add": 200, "delay": -0.05}, null),
		_create_mock_item("加速修正", "modifier_speed", Color(0.5, 1.0, 0.5), {"mana_cost": 10, "multiplier": 1.5, "delay": -0.01}, null),
		_create_mock_item("充能修正", "modifier_delay", Color(0.4, 0.4, 0.4), {"mana_cost": 0, "recharge": -0.15, "delay": -0.05}, null),
		_create_mock_item("增加法力", "modifier_add_mana", Color(0.0, 0.6, 1.0), {"mana_cost": -30, "delay": 0.05}, null),
		
		_create_mock_item("分流器", "splitter", Color(0.0, 0.9, 0.9), {"mana_cost": 2, "delay": 0.0}, null),
		_create_mock_item("顺序释放", "logic_sequence", Color(0.5, 0.5, 0.5), {"mana_cost": 1, "delay": 0.1}, null),
		
		_create_mock_item("发射器", "action_projectile", Color(0.9, 0.4, 0.4), {"mana_cost": 10, "speed": 500.0, "damage": 10.0, "delay": 0.2}, null),
		_create_mock_item("火花弹 (Spark Bolt)", "action_projectile", Color(0.8, 0.9, 10.0), {"projectile_id": "spark_bolt", "mana_cost": 5, "speed": 800.0, "damage": 3.0, "delay": 0.05}, null),
		_create_mock_item("魔法弹 (Magic Bolt)", "action_projectile", Color(10.0, 1.5, 30.0), {"projectile_id": "magic_bolt", "mana_cost": 25, "speed": 600.0, "damage": 15.0, "delay": 0.1}, null),
		_create_mock_item("反弹爆发", "action_projectile", Color(10.0, 10.0, 1.0), {"projectile_id": "bouncing_burst", "mana_cost": 15, "speed": 400.0, "damage": 5.0, "delay": 0.1}, null),
		_create_mock_item("三叉弹", "action_projectile", Color(0.1, 30.0, 10.0), {"projectile_id": "tri_bolt", "mana_cost": 35, "speed": 500.0, "damage": 8.0, "delay": 0.2}, null),
		_create_mock_item("电锯 (Chainsaw)", "action_projectile", Color(20.0, 20.0, 20.0), {"projectile_id": "chainsaw", "mana_cost": 1, "speed": 100.0, "damage": 1.0, "delay": 0.0, "recharge": -0.17}, null),
		_create_mock_item("史莱姆弹", "action_projectile", Color(0.0, 1.0, 0.0), {"projectile_id": "slime", "mana_cost": 12, "speed": 400.0, "damage": 12.0, "element": "slime", "delay": 0.15}, null),
		_create_mock_item("TNT", "action_projectile", Color(0.9, 0.2, 0.2), {"projectile_id": "tnt", "mana_cost": 40, "damage": 50, "lifetime": 3.0, "speed": 200.0, "delay": 0.5}, null),
		_create_mock_item("黑洞", "action_projectile", Color(0.1, 0.0, 0.2), {"projectile_id": "blackhole", "mana_cost": 180, "damage": 5, "lifetime": 8.0, "speed": 50.0, "delay": 0.8}, null),
		_create_mock_item("传送", "action_projectile", Color(0.6, 0.2, 0.8), {"projectile_id": "teleport", "mana_cost": 15, "damage": 0, "lifetime": 1.0, "speed": 800.0, "delay": 0.3}, null)
	]

	# Additional Noita-like modifiers and projectiles (from Noita wiki inspiration)
	# Projectile modifiers
	logic_items.append(_create_mock_item("重击 (Heavy Shot)", "modifier_damage", Color(0.9, 0.4, 0.2), {"mana_cost": 20, "damage_add": 30, "speed_multiplier": 0.6, "delay": 0.05}, null))
	logic_items.append(_create_mock_item("轻击 (Light Shot)", "modifier_damage", Color(0.6, 0.9, 0.6), {"mana_cost": 12, "damage_add": -5, "speed_multiplier": 1.5, "delay": 0.02}, null))
	logic_items.append(_create_mock_item("增加寿命 (Increase Lifetime)", "modifier_lifetime", Color(0.3, 0.6, 1.0), {"mana_cost": 8, "lifetime_add": 1.5, "delay": 0.02}, null))
	logic_items.append(_create_mock_item("穿透 (Piercing Shot)", "modifier_pierce", Color(0.8, 0.2, 0.8), {"mana_cost": 25, "pierce": 2, "delay": 0.05}, null))
	logic_items.append(_create_mock_item("追踪 (Homing)", "modifier_homing", Color(0.9, 0.7, 0.2), {"mana_cost": 30, "homing_strength": 0.8, "delay": 0.05}, null))
	logic_items.append(_create_mock_item("爆炸反弹 (Explosive Bounce)", "modifier_bounce_explosive", Color(1.0, 0.4, 0.1), {"mana_cost": 18, "explode_on_bounce": true, "delay": 0.05}, null))
	logic_items.append(_create_mock_item("火弧 (Fire Arc)", "modifier_arc_fire", Color(0.9, 0.2, 0.1), {"mana_cost": 14, "arc_type": "fire", "delay": 0.02}, null))
	logic_items.append(_create_mock_item("法力转伤 (Mana To Damage)", "modifier_mana_to_damage", Color(0.7, 0.2, 0.9), {"mana_cost": 0, "damage_multiplier": 1.2, "delay": 0.0}, null))

	# Additional projectile spells
	logic_items.append(_create_mock_item("火球 (Fireball)", "action_projectile", Color(1.0, 0.45, 0.1), {"projectile_id": "fireball", "mana_cost": 35, "damage": 22, "lifetime": 2.5, "speed": 300.0, "delay": 0.25}, null))
	logic_items.append(_create_mock_item("魔法箭 (Magic Arrow)", "action_projectile", Color(0.8, 0.5, 1.0), {"projectile_id": "magic_arrow", "mana_cost": 18, "damage": 12, "lifetime": 1.8, "speed": 700.0, "delay": 0.08}, null))
	logic_items.append(_create_mock_item("能量球 (Energy Sphere)", "action_projectile", Color(0.6, 0.9, 1.0), {"projectile_id": "energy_sphere", "mana_cost": 28, "damage": 18, "lifetime": 2.2, "speed": 450.0, "delay": 0.12}, null))
	logic_items.append(_create_mock_item("分裂弹 (Cluster)", "action_projectile", Color(0.9, 0.6, 0.1), {"projectile_id": "cluster_bomb", "mana_cost": 45, "damage": 12, "lifetime": 1.2, "speed": 250.0, "delay": 0.4}, null))
	
	for child in palette_grid.get_children():
		child.queue_free()
	
	# 2. Filter based on Unlocked Status
	var always_unlocked = [
		"generator", "trigger_cast", "action_projectile", 
		"modifier_speed", "modifier_delay"
	] # Basic set: Only source, cast trigger, base projectile and basic speed/delay
	
	# Fix: Currently forcing everything unlocked for testing because GameState unlock logic is incomplete
	# To restore limited spell set: is_unlocked = false by default, then check always_unlocked + GameState.
	# The user requested "Back to only basic spells".
	
	if GameState:
		# Add GameState unlocks to allowed list
		# (Or check against them)
		pass

	for item in logic_items:
		var item_id = _get_item_id(item)
		
		# Restoring Proper Lock Logic
		var is_unlocked = false
		if item_id in always_unlocked: 
			is_unlocked = true
		elif GameState and item_id in GameState.unlocked_spells:
			is_unlocked = true
		
		# DEBUG OVERRIDE WAS HERE. REMOVING IT per user request.
		
		if is_unlocked:
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

func _get_item_id(item: Resource) -> String:
	var type = item.wand_logic_type
	var val = item.wand_logic_value
	
	if type == "generator": return "generator"
	if type == "trigger":
		if val.get("trigger_type") == "cast": return "trigger_cast"
		if val.get("trigger_type") == "collision": return "trigger_collision"
		if val.get("trigger_type") == "timer": return "trigger_timer"
	
	if type == "modifier_element":
		var elem = val.get("element", "")
		if elem == "fire": return "element_fire" # Mismatch with BaseNPC "modifier_element_fire" vs "element_fire"
		# BaseNPC code was: "projectile_slime", "modifier_pierce", "logic_splitter"
		# It didn't handle elements.
		return "modifier_element_" + elem
		
	if type == "modifier_damage": 
		if val.get("amount", 0) > 10: return "modifier_damage_plus"
		return "modifier_damage"
	if type == "modifier_pierce": return "modifier_pierce"
	if type == "modifier_speed": 
		if val.has("multiplier"): return "modifier_speed_plus"
		return "modifier_speed"
	if type == "modifier_delay": return "modifier_delay"
	if type == "modifier_add_mana": return "modifier_add_mana"
	
	if type == "splitter": return "logic_splitter"
	if type == "logic_sequence": return "logic_sequence"
	
	if type == "action_projectile":
		var pid = val.get("projectile_id", "")
		if pid == "": return "action_projectile"
		return "projectile_" + pid
		if pid == "" or pid == "basic": return "action_projectile"
	
	return item.id # Fallback

func _add_visual_palette_button(parent, item):
	var btn = PanelContainer.new()
	btn.custom_minimum_size = Vector2(50, 50)
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
	
	# --- ButtonGroup (Mode Switcher) ---
	var btn_group_normal = StyleBoxFlat.new()
	btn_group_normal.bg_color = Color(0.05, 0.07, 0.1, 0.8)
	btn_group_normal.border_width_bottom = 2
	btn_group_normal.border_color = Color(0.1, 0.2, 0.3)
	btn_group_normal.content_margin_top = 8
	btn_group_normal.content_margin_bottom = 8
	
	var btn_group_pressed = StyleBoxFlat.new()
	btn_group_pressed.bg_color = Color(0.1, 0.2, 0.3, 0.9)
	btn_group_pressed.border_width_bottom = 2
	btn_group_pressed.border_color = COLOR_ACCENT
	btn_group_pressed.content_margin_top = 8
	btn_group_pressed.content_margin_bottom = 8
	
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
	# Apply Theme to Root
	self.theme = theme

	# Additional stronger visual polish to make changes more noticeable
	panel_style.bg_color = Color(0.03, 0.045, 0.06, 0.95)
	panel_style.shadow_color = COLOR_GLOW
	panel_style.shadow_size = 12
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6

	# Button: larger corner radius + subtle inner glow
	btn_normal.corner_radius_top_left = 8
	btn_normal.corner_radius_top_right = 8
	btn_normal.corner_radius_bottom_left = 8
	btn_normal.corner_radius_bottom_right = 8
	btn_normal.content_margin_left = 10
	btn_normal.content_margin_right = 10
	btn_normal.content_margin_top = 6
	btn_normal.content_margin_bottom = 6

	# Give hover state a pronounced neon outline
	btn_hover.border_width_left = 2
	btn_hover.border_width_right = 2
	btn_hover.border_width_top = 2
	btn_hover.border_width_bottom = 2

	# Tab visuals: stronger contrast
	tab_selected.bg_color = Color(0.12, 0.25, 0.4, 0.95)
	tab_unselected.bg_color = Color(0.02, 0.03, 0.04, 0.6)

	# LineEdit: slightly larger padding for readability
	edit_style.content_margin_left = 8
	edit_style.content_margin_right = 8
	edit_style.content_margin_top = 6
	edit_style.content_margin_bottom = 6

	# GraphEdit grid contrast
	theme.set_color("grid_major", "GraphEdit", Color(0.12, 0.6, 1.0, 0.18))
	theme.set_color("grid_minor", "GraphEdit", Color(0.12, 0.6, 1.0, 0.06))

	# Font / Label colors
	theme.set_color("font_color", "Label", COLOR_TEXT_SEC)
	theme.set_color("font_color", "Button", COLOR_TEXT_SEC)
	theme.set_color("font_color_disabled", "Button", COLOR_TEXT_SEC.darkened(0.5))

	# Scrollbar style (thin neon track)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.02, 0.03, 0.5)
	sb.border_color = COLOR_ACCENT_DIM
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.corner_radius_top_left = 4
	sb.corner_radius_bottom_right = 4
	theme.set_stylebox("vertical", "ScrollBar", sb)
	theme.set_stylebox("horizontal", "ScrollBar", sb)

	# RichTextLabel default size for better legibility
	theme.set_constant("normal_font_size", "RichTextLabel", 15)

	# Re-apply theme to root and key subcomponents so changes are visible immediately
	self.theme = theme
	if header: header.theme = theme
	if logic_board: logic_board.theme = theme
	if visual_grid: visual_grid.theme = theme
	if module_palette: module_palette.theme = theme
	if palette_grid: palette_grid.theme = theme

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
	var left_sidebar = find_child("LeftSidebar", true, false)
	if left_sidebar:
		left_sidebar.custom_minimum_size.x = 220
		
	var right_sidebar = find_child("RightSidebar", true, false)
	if right_sidebar:
		right_sidebar.custom_minimum_size.x = 260 # Slightly wider for BBCode

	# 3. Apply ButtonGroup styles
	var mode_switcher = find_child("ModeSwitcher", true, false)
	if mode_switcher:
		for btn in mode_switcher.get_children():
			if btn is Button:
				btn.add_theme_stylebox_override("normal", theme.get_stylebox("normal", "Button"))
				btn.add_theme_stylebox_override("pressed", theme.get_stylebox("pressed", "Button"))
				btn.add_theme_stylebox_override("hover", theme.get_stylebox("hover", "Button"))
				btn.add_theme_stylebox_override("focus", theme.get_stylebox("focus", "Button"))
				
				# Custom toggle logic for visual feedback
				btn.toggled.connect(func(is_pressed):
					if is_pressed:
						btn.add_theme_color_override("font_color", COLOR_ACCENT)
					else:
						btn.add_theme_color_override("font_color", COLOR_TEXT_SEC)
				)
				# Initialize color
				if btn.button_pressed:
					btn.add_theme_color_override("font_color", COLOR_ACCENT)
				else:
					btn.add_theme_color_override("font_color", COLOR_TEXT_SEC)

func _on_visual_mode_toggled(toggled_on: bool):
	if toggled_on:
		if library_panel: library_panel.visible = true
		if library_container: library_container.visible = false
		if visual_grid: visual_grid.visible = true
		if logic_board: logic_board.visible = false

func _on_logic_mode_toggled(toggled_on: bool):
	if toggled_on:
		if library_panel: library_panel.visible = false
		if library_container: library_container.visible = true
		if visual_grid: visual_grid.visible = false
		if logic_board: logic_board.visible = true
