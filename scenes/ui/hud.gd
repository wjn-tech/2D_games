extends Control

@onready var time_label: Label = $MarginContainer/TopRight/TimeLabel
@onready var quest_list: VBoxContainer = $MarginContainer/TopRight/QuestList

func _ready() -> void:
	# 初始更新
	_update_hud()
	
	# 监听事件
	EventBus.time_passed.connect(_on_time_passed)
	
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

func _process(_delta: float) -> void:
	_update_hud()

func _update_hud() -> void:
	if GameState.player_data:
		pass # 金币显示已迁移或需重新挂载
		
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
	time_label.text = "时间: %02d:%02d" % [hours, minutes]

func _on_power_updated(_prod: float, _cons: float) -> void:
	# 电力显示节点已移除，待重新设计
	pass
