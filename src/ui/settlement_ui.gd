extends Control

@onready var stats_label = $Panel/VBoxContainer/StatsLabel
@onready var npc_list = $Panel/VBoxContainer/ScrollContainer/NPCList
@onready var close_button = $Panel/CloseButton

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	SettlementManager.stats_changed.connect(_update_stats)
	_update_stats(SettlementManager.stats)
	_update_npc_list()

func _update_stats(stats: Dictionary):
	var text = "--- 城邦概况 ---\n"
	text += "等级: %d\n" % stats.level
	text += "繁荣度: %d\n" % stats.prosperity
	text += "人口: %d / %d\n" % [stats.population_current, stats.population_max]
	text += "食物产量: %.1f\n" % stats.food_production
	text += "防御力: %d\n" % stats.defense
	stats_label.text = text

func _update_npc_list():
	# 清理旧列表
	for child in npc_list.get_children():
		child.queue_free()
	
	for npc in SettlementManager.recruited_npcs:
		var label = Label.new()
		var job = SettlementManager.get_npc_job(npc)
		var home = SettlementManager.npc_homes.get(npc.display_name, null)
		var home_str = home.name if home else "无"
		label.text = "%s (职业: %s, 住所: %s)" % [npc.display_name, job, home_str]
		npc_list.add_child(label)

func _on_close_pressed():
	UIManager.close_window("SettlementUI")
