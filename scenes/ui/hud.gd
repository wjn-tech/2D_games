extends Control

@onready var time_label: Label = $MarginContainer/TopRight/TimeLabel
@onready var quest_list: VBoxContainer = $MarginContainer/TopRight/QuestList
@onready var damage_overlay: ColorRect = $DamageOverlay
@onready var top_right_container: VBoxContainer = $MarginContainer/TopRight
@onready var guide_button: Button = $MarginContainer/TopLeft/GuideButton

var wand_mana_bar: ProgressBar # Kept for backward compat or if needed
var wand_mana_label: Label
var player_status: PlayerStatusWidget
var stats_widget: Control # V3: Reference to the toggleable stats panel
var item_tooltip_label: Label
var guide_window: GameplayGuideWindow

func _ready() -> void:
	# Load Styles
	_apply_global_styles()
	
	# Setup Guide System
	_setup_guide_system()
	
	# Instantiate Status Widget
	var status_scene = preload("res://src/ui/hud/player_status_widget.tscn")
	player_status = status_scene.instantiate()
	
	# Create Top Left Wrapper
	var top_left_container = $MarginContainer/TopLeft  # Use existing TopLeft from scene
	# Use shrunk flags for the container itself so it adheres to Top-Left of MarginContainer
	top_left_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	top_left_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	# Force it to be minimal size
	top_left_container.custom_minimum_size = Vector2(250, 100)
	
	# Add player status
	# Note: GuideButton is already in TopLeft from the scene
	var existing_guide_btn = top_left_container.get_child(0)  # GuideButton should be first
	top_left_container.add_child(player_status)
	if existing_guide_btn:
		top_left_container.move_child(player_status, 1)  # Move status after guide button

	
	# Instantiate Hotbar (Bottom Center)
	_create_hotbar()
	
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

func _setup_guide_system() -> void:
	## Setup the gameplay guide window and connect button signal
	if guide_button:
		guide_button.guide_requested.connect(_on_guide_requested)
	
	# Instantiate and setup the guide window
	guide_window = preload("res://scenes/ui/gameplay_guide_window.tscn").instantiate()
	add_child(guide_window)
	guide_window.hide()  # Hidden by default

func _on_guide_requested() -> void:
	## Called when the guide button is pressed
	if guide_window:
		guide_window.open()

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
