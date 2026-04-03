extends Control

@onready var time_label: Label = $MarginContainer/TopRight/TimeLabel
@onready var quest_list: VBoxContainer = $MarginContainer/TopRight/QuestList
@onready var damage_overlay: ColorRect = $DamageOverlay
@onready var top_right_container: VBoxContainer = $MarginContainer/TopRight

var wand_mana_bar: ProgressBar # Kept for backward compat or if needed
var wand_mana_label: Label
var player_status: PlayerStatusWidget
var stats_widget: Control # V3: Reference to the toggleable stats panel
var item_tooltip_label: Label
var boss_hp_panel: PanelContainer
var boss_hp_title_label: Label
var boss_hp_bar: ProgressBar
var boss_hp_value_label: Label

func _ready() -> void:
	# Load Styles
	_apply_global_styles()
	
	# Instantiate Status Widget
	var status_scene = preload("res://src/ui/hud/player_status_widget.tscn")
	player_status = status_scene.instantiate()
	
	# Create Top Left Wrapper
	var top_left_container = VBoxContainer.new()
	top_left_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$MarginContainer.add_child(top_left_container)
	# Use shrunk flags for the container itself so it adheres to Top-Left of MarginContainer
	top_left_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	top_left_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	# Force it to be minimal size
	top_left_container.custom_minimum_size = Vector2(250, 100)
	
	# Add Spacer to push it down
	# var spacer = Control.new()
	# spacer.custom_minimum_size = Vector2(0, 80)
	# top_left_container.add_child(spacer)
	
	top_left_container.add_child(player_status)
	
	# Ensure player status respects this
	player_status.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	player_status.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	
	# Instantiate Hotbar (Bottom Center)
	_create_hotbar()
	_create_boss_health_bar()
	
	# Instantiate Secondary Stats (Toggleable Modal)
	# Replace old AttributeDisplay
	var old_attr = $MarginContainer/TopRight/AttributeDisplay
	if old_attr:
		old_attr.visible = false # Hide old one
		old_attr.queue_free()
		
	var stats_scene = preload("res://src/ui/hud/character_stats_widget.tscn")
	stats_widget = stats_scene.instantiate()
	
	# Add to a CenterContainer to make it a modal overlay
	var center_cont = CenterContainer.new()
	center_cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE # Let clicks pass through if empty
	add_child(center_cont)
	center_cont.add_child(stats_widget)

	# V3: Start hidden
	stats_widget.visible = false
	
	add_to_group("hud")

func _create_boss_health_bar() -> void:
	boss_hp_panel = PanelContainer.new()
	boss_hp_panel.name = "BossHealthBar"
	boss_hp_panel.visible = false
	boss_hp_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_hp_panel.custom_minimum_size = Vector2(520, 78)
	boss_hp_panel.position = Vector2(0, 10)
	boss_hp_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_hp_panel.offset_left = 0
	boss_hp_panel.offset_right = 0
	boss_hp_panel.offset_top = 10
	boss_hp_panel.offset_bottom = 88
	add_child(boss_hp_panel)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	boss_hp_panel.add_child(center)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(520, 66)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 4)
	center.add_child(content)

	boss_hp_title_label = Label.new()
	boss_hp_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_hp_title_label.add_theme_font_size_override("font_size", 20)
	boss_hp_title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.62))
	boss_hp_title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	boss_hp_title_label.add_theme_constant_override("outline_size", 3)
	boss_hp_title_label.text = "BOSS"
	content.add_child(boss_hp_title_label)

	boss_hp_bar = ProgressBar.new()
	boss_hp_bar.custom_minimum_size = Vector2(520, 20)
	boss_hp_bar.show_percentage = false
	content.add_child(boss_hp_bar)

	boss_hp_value_label = Label.new()
	boss_hp_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_hp_value_label.add_theme_font_size_override("font_size", 14)
	boss_hp_value_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.9))
	boss_hp_value_label.add_theme_color_override("font_outline_color", Color.BLACK)
	boss_hp_value_label.add_theme_constant_override("outline_size", 2)
	boss_hp_value_label.text = "0 / 0"
	content.add_child(boss_hp_value_label)

	var style_bg := StyleBoxFlat.new()
	style_bg.bg_color = Color(0.1, 0.05, 0.08, 0.88)
	style_bg.set_corner_radius_all(8)
	style_bg.border_width_left = 2
	style_bg.border_width_top = 2
	style_bg.border_width_right = 2
	style_bg.border_width_bottom = 2
	style_bg.border_color = Color(0.55, 0.2, 0.2, 0.95)
	boss_hp_panel.add_theme_stylebox_override("panel", style_bg)

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.12, 0.12, 0.12, 0.95)
	bar_bg.set_corner_radius_all(6)
	boss_hp_bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.9, 0.16, 0.2, 0.95)
	bar_fill.set_corner_radius_all(6)
	boss_hp_bar.add_theme_stylebox_override("fill", bar_fill)

func show_boss_health_bar(boss_name: String, max_health: float, current_health: float = -1.0) -> void:
	if boss_hp_panel == null or boss_hp_bar == null:
		return
	var current := current_health if current_health >= 0.0 else max_health
	boss_hp_title_label.text = String(boss_name)
	boss_hp_bar.max_value = maxf(1.0, max_health)
	boss_hp_bar.value = clampf(current, 0.0, boss_hp_bar.max_value)
	boss_hp_value_label.text = "%d / %d" % [int(round(boss_hp_bar.value)), int(round(boss_hp_bar.max_value))]
	boss_hp_panel.visible = true

func update_boss_health_bar(current_health: float, max_health: float) -> void:
	if boss_hp_panel == null or boss_hp_bar == null:
		return
	if not boss_hp_panel.visible:
		return
	boss_hp_bar.max_value = maxf(1.0, max_health)
	boss_hp_bar.value = clampf(current_health, 0.0, boss_hp_bar.max_value)
	boss_hp_value_label.text = "%d / %d" % [int(round(boss_hp_bar.value)), int(round(boss_hp_bar.max_value))]

func hide_boss_health_bar() -> void:
	if boss_hp_panel:
		boss_hp_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_character_sheet"):
		if stats_widget:
			stats_widget.visible = not stats_widget.visible
			if stats_widget.visible:
				# Bring to front just in case
				stats_widget.get_parent().move_to_front()


func _create_hotbar() -> void:
	print("HUD: Creating HotbarWidget...")
	
	# 1. Remove any existing hotbars (cleanup old instances)
	for child in get_children():
		if child.name == "TopLeftHotbar":
			child.queue_free()

	# 2. Instantiate New Hotbar
	var hb_scene = load("res://src/ui/hud/hotbar_widget.tscn")
	if not hb_scene:
		print("HUD Error: Failed to load hotbar_widget.tscn")
		return
		
	var hb = hb_scene.instantiate()
	hb.name = "HotbarWidget"
	
	# 3. Create Container
	# We use a simple Control positioned absolutely to avoid layout conflicts
	var container = Control.new()
	container.name = "TopLeftHotbar"
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.z_index = 10
	add_child(container)
	
	# 4. Add Hotbar to Container
	container.add_child(hb)
	
	# 5. Position Hotbar
	# Absolute position: 290px from left (20px margin + 250px status width + 20px gap)
	hb.position = Vector2(290, 20)
	
	# 6. Ensure visibility
	hb.visible = true
	hb.modulate = Color(1, 1, 1, 1) # Ensure opacity
	
	print("HUD: Hotbar created at ", hb.position)
	
	# 7. Connect Data
	call_deferred("_setup_hotbar_data", hb)

func _setup_hotbar_data(hb) -> void:
	if GameState.inventory and GameState.inventory.hotbar:
		hb.setup(GameState.inventory.hotbar)
	
	# Start selection tracking
	if hb.has_method("_refresh_selection"):
		hb._refresh_selection()


	if damage_overlay:
		damage_overlay.modulate.a = 0.0
	# 初始更新
	_update_hud()
	
	# 监听事件
	EventBus.time_passed.connect(_on_time_passed)
	EventBus.item_hovered.connect(_on_item_hovered)
	EventBus.item_unhovered.connect(_on_item_unhovered)
	
	# 监听电力更新
	if PowerGridManager:
		PowerGridManager.power_updated.connect(_on_power_updated)
		
	# 监听任务更新
	if get_node_or_null("/root/QuestManager"):
		var qm = get_node("/root/QuestManager")
		qm.quest_accepted.connect(_on_quest_updated)
		qm.quest_completed.connect(_on_quest_updated)
		qm.quest_updated.connect(_on_quest_updated)
		_on_quest_updated(null)

	# 侧边栏按钮连接
	$Sidebar/HousingBtn.pressed.connect(_on_housing_btn_pressed)
	$Sidebar/InventoryBtn.pressed.connect(_on_inventory_btn_pressed)

func _on_housing_btn_pressed() -> void:
	if UIManager:
		if UIManager.active_windows.has("HousingMenu"):
			UIManager.close_window("HousingMenu")
		else:
			UIManager.open_window("HousingMenu", "res://src/ui/housing/housing_menu.tscn")

func _on_inventory_btn_pressed() -> void:
	if UIManager:
		if UIManager.active_windows.has("Inventory"):
			UIManager.close_window("Inventory")
		else:
			UIManager.open_window("Inventory", "res://scenes/ui/InventoryWindow.tscn")

func _apply_global_styles() -> void:
	# Apply pixel-art styles to existing nodes programmatically
	
	# 1. TopRight Background / Minimap Style
	var minimap = $MarginContainer/TopRight/Minimap
	if minimap:
		var panel = minimap.get_node_or_null("Panel")
		if panel:
			panel.add_theme_stylebox_override("panel", HUDStyles.get_panel_style())
			
	# Style World Info
	var world_info = $MarginContainer/TopRight/WorldInfoUI
	if world_info:
		# Add a background if possible, or just style labels
		# Since WorldInfoUI is a VBox, we can't add stylebox directly.
		# We can wrap it or just rely on text shadows (already present in tscn).
		# Let's ensure text shadows are strong
		for child in world_info.get_children():
			if child is Label:
				child.add_theme_color_override("font_outline_color", Color.BLACK)
				child.add_theme_constant_override("outline_size", 4)
	
	# Style TimeLabel (if it's separate from WorldInfo)
	if time_label:
		# V3 Change: Time is now shown in WorldInfoUI. Hide this redundant label.
		time_label.visible = false
		
		# time_label.add_theme_stylebox_override("normal", HUDStyles.get_panel_style())
		# time_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		# time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Add padding
		# time_label.add_theme_constant_override("margin_left", 8) 
		# Label doesn't support margin constants seamlessly without stylebox content margins
		# The stylebox defined in HUDStyles has content margins if we set them, let's check HUDStyles.

	var sidebar = $Sidebar
	for btn in sidebar.get_children():
		if btn is Button:
			btn.add_theme_stylebox_override("normal", HUDStyles.get_button_style_normal())
			btn.add_theme_stylebox_override("hover", HUDStyles.get_button_style_hover())
			btn.add_theme_stylebox_override("pressed", HUDStyles.get_button_style_pressed())
	# Update Status Widget logic is internal to it

func _update_hud() -> void:
	if GameState.player_data:
		pass 
	
	# _update_wand_mana_ui() # Deprecated, using PlayerStatusWidget

# Deprecated or repurposed
# func _update_wand_mana_ui() -> void:
# 	pass

func _update_wand_mana_ui() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.get("current_wand"):
		if wand_mana_bar: wand_mana_bar.visible = false
		return
	
	var wand = player.current_wand
	if not wand_mana_bar:
		_create_wand_mana_bar()

	
	wand_mana_bar.visible = true
	if wand.embryo:
		wand_mana_bar.max_value = wand.embryo.mana_capacity
		wand_mana_bar.value = wand.current_mana
		wand_mana_label.text = "MANA: %d/%d" % [int(wand.current_mana), int(wand.embryo.mana_capacity)]

func _create_wand_mana_bar() -> void:
	var container = VBoxContainer.new()
	container.name = "WandManaContainer"
	$MarginContainer.add_child(container)
	# Align to Bottom Center
	container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	container.size_flags_vertical = Control.SIZE_SHRINK_END
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Add a bit of bottom margin
	container.add_theme_constant_override("margin_bottom", 20)
	
	wand_mana_label = Label.new()
	wand_mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wand_mana_label.add_theme_font_size_override("font_size", 14)
	wand_mana_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	container.add_child(wand_mana_label)
	
	wand_mana_bar = ProgressBar.new()
	wand_mana_bar.custom_minimum_size.y = 12
	wand_mana_bar.show_percentage = false
	
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.1, 0.1, 0.1, 0.5)
	style_bg.set_corner_radius_all(4)
	wand_mana_bar.add_theme_stylebox_override("background", style_bg)
	
	var style_fg = StyleBoxFlat.new()
	style_fg.bg_color = Color(0.2, 0.6, 1.0)
	style_fg.set_corner_radius_all(4)
	style_fg.border_width_left = 1
	style_fg.border_width_top = 1
	style_fg.border_width_right = 1
	style_fg.border_width_bottom = 1
	style_fg.border_color = Color(0.5, 0.9, 1.0)
	wand_mana_bar.add_theme_stylebox_override("fill", style_fg)
	
	container.add_child(wand_mana_bar)

func show_damage_vignette() -> void:
	if not damage_overlay: return
	
	# Create a tween to flash red - intensified for feedback
	var tween = create_tween()
	damage_overlay.modulate.a = 0.8 # Increased from 0.5 for punchiness
	tween.tween_property(damage_overlay, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

		
	# 添加按键提示 (如果不存在)
	if not $MarginContainer.has_node("BottomLeft"):
		var bl = VBoxContainer.new()
		bl.name = "BottomLeft"
		$MarginContainer.add_child(bl)
		bl.size_flags_vertical = Control.SIZE_SHRINK_END
		
		var hint = Label.new()
		hint.text = "[I] 角色/物品栏 | [E] 交互 | [ESC] 菜单"
		hint.add_theme_font_size_override("font_size", 12)
		hint.modulate.a = 0.7
		bl.add_child(hint)

func _on_quest_updated(_quest) -> void:
	# 清空当前列表
	for child in quest_list.get_children():
		child.queue_free()
		
	var qm = get_node_or_null("/root/QuestManager")
	if not qm: return
	
	if qm.active_quests.is_empty():
		return
		
	var title = Label.new()
	title.text = "--- 任务 ---"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.add_theme_font_size_override("font_size", 14)
	quest_list.add_child(title)
	
	for quest in qm.active_quests:
		var q_label = Label.new()
		var status = "[完成]" if quest.is_completed else "[%d/%d]" % [quest.current_amount, quest.required_amount]
		q_label.text = "%s %s" % [quest.title, status]
		q_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		q_label.add_theme_font_size_override("font_size", 12)
		if quest.is_completed:
			q_label.modulate = Color.GREEN
		quest_list.add_child(q_label)

func _on_time_passed(total_time: float) -> void:
	var minutes = int(total_time / 60) % 60
	var hours = int(total_time / 3600) % 24
	time_label.text = "%02d:%02d" % [hours, minutes]

func _on_item_hovered(item_name: String, quality: String) -> void:
	# 暂时禁用 HUD 全局 Tooltip，改由物品格子内部各自显示，避免位置冲突
	return
	
	var br_container = $MarginContainer.get_node_or_null("BottomRight")
	
	if not br_container:
		br_container = VBoxContainer.new()
		br_container.name = "BottomRight"
		$MarginContainer.add_child(br_container)
		br_container.size_flags_vertical = Control.SIZE_SHRINK_END
		br_container.size_flags_horizontal = Control.SIZE_SHRINK_END
	
	# 如果 label 尚未创建或已丢失，重新创建
	if not item_tooltip_label or not is_instance_valid(item_tooltip_label):
		# 尝试从容器中查找现有的（防止重叠）
		if br_container.get_child_count() > 0:
			item_tooltip_label = br_container.get_child(0)
		else:
			item_tooltip_label = Label.new()
			item_tooltip_label.add_theme_font_size_override("font_size", 16)
			item_tooltip_label.add_theme_color_override("font_outline_color", Color.BLACK)
			item_tooltip_label.add_theme_constant_override("outline_size", 4)
			br_container.add_child(item_tooltip_label)
	
	if item_tooltip_label:
		item_tooltip_label.z_index = 100 # 确保顶层显示
		item_tooltip_label.text = item_name
		item_tooltip_label.visible = true
		
		# 根据品质改变颜色
		match quality:
			"Rare": item_tooltip_label.modulate = Color.CYAN
			"Epic": item_tooltip_label.modulate = Color.PURPLE
			"Legendary": item_tooltip_label.modulate = Color.ORANGE
			"Masterwork": item_tooltip_label.modulate = Color.GOLD
			_: item_tooltip_label.modulate = Color.WHITE

func _on_item_unhovered() -> void:
	if item_tooltip_label:
		item_tooltip_label.visible = false

func _on_power_updated(_prod: float, _cons: float) -> void:
	# 电力显示节点已移除，待重新设计
	pass
