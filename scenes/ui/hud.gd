extends Control

@onready var time_label: Label = $MarginContainer/TopRight/TimeLabel
@onready var quest_list: VBoxContainer = $MarginContainer/TopRight/QuestList
@onready var damage_overlay: ColorRect = $DamageOverlay

var item_tooltip_label: Label

func _ready() -> void:
	add_to_group("hud")
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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("settlement"):
		_on_housing_btn_pressed()

func _on_housing_btn_pressed():
	if UIManager:
		# Toggle 逻辑兼容
		if UIManager.active_windows.has("HousingMenu"):
			UIManager.close_window("HousingMenu")
		else:
			UIManager.open_window("HousingMenu", "res://src/ui/housing/housing_menu.tscn")

func _on_inventory_btn_pressed():
	if UIManager:
		if UIManager.active_windows.has("CharacterPanel"):
			UIManager.close_window("CharacterPanel")
		else:
			UIManager.open_window("CharacterPanel", "res://scenes/ui/CharacterPanel.tscn")

func _process(_delta: float) -> void:
	_update_hud()

func _update_hud() -> void:
	if GameState.player_data:
		pass # 金币显示已迁移或需重新挂载

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
