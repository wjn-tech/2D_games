extends Control
class_name CharacterPanelUI

## CharacterPanelUI
## 整合了属性分配与背包显示的综合面板

@onready var inv_container: Control = $HBoxContainer/InventorySection
@onready var stats_container: VBoxContainer = $HBoxContainer/StatsSection/ScrollContainer/VBoxContainer
@onready var stat_points_label: Label = $HBoxContainer/StatsSection/TitleContainer/StatPointsLabel
@onready var level_label: Label = $HBoxContainer/StatsSection/TitleContainer/LevelLabel
@onready var exp_bar: ProgressBar = $HBoxContainer/StatsSection/TitleContainer/ExpBar

var player_data: CharacterData

func _ready() -> void:
	_connect_to_player_data()
	
	if EventBus:
		EventBus.player_data_refreshed.connect(_on_player_data_refreshed)
	
	_setup_ui()
	_refresh_stats()
	_refresh_header()

func _connect_to_player_data() -> void:
	player_data = GameState.player_data
	if not player_data.stat_changed.is_connected(_on_stat_changed):
		player_data.stat_changed.connect(_on_stat_changed)

func _on_player_data_refreshed() -> void:
	_connect_to_player_data()
	_refresh_stats()
	_refresh_header()

const BackpackPanel = preload("res://src/systems/inventory/ui/backpack_panel.tscn")
const HotbarPanel = preload("res://src/systems/inventory/ui/hotbar_panel.tscn")

func _setup_ui() -> void:
	# 确保面板美观
	custom_minimum_size = Vector2(800, 500)
	
	# Setup Inventory Section (Hotbar + Backpack)
	var placeholder = inv_container.get_node_or_null("BackpackPlaceholder")
	if placeholder:
		# Clear existing
		for c in placeholder.get_children(): c.queue_free()
		
		# 使用 VBox 布局来垂直排列 快捷栏 和 背包
		var layout = VBoxContainer.new()
		layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layout.add_theme_constant_override("separation", 20)
		placeholder.add_child(layout)
		
		var player = get_tree().get_first_node_in_group("player")
		if player and player.get("inventory"):
			# 1. 显示快捷栏
			if player.inventory.get("hotbar"):
				var lbl = Label.new()
				lbl.text = "快捷栏"
				lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
				layout.add_child(lbl)
				
				var hb = HotbarPanel.instantiate()
				layout.add_child(hb)
				hb.setup(player.inventory.hotbar)
			
			# 2. 显示背包与合成
			if player.inventory.get("backpack"):
				var hsplit = HSplitContainer.new()
				hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
				layout.add_child(hsplit)
				
				# 左侧：背包面板
				var bp_vbox = VBoxContainer.new()
				bp_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hsplit.add_child(bp_vbox)
				
				var bp_lbl = Label.new()
				bp_lbl.text = "背包"
				bp_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
				bp_vbox.add_child(bp_lbl)
				
				var bp = BackpackPanel.instantiate()
				bp_vbox.add_child(bp)
				bp.size_flags_vertical = Control.SIZE_EXPAND_FILL
				bp.setup(player.inventory.backpack)
				
				# 右侧：合成面板
				var cp = CraftingPanel.new()
				cp.custom_minimum_size = Vector2(250, 0)
				cp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hsplit.add_child(cp)
				hsplit.split_offset = 50 # 稍微偏移一下平衡空间

	# 绑定加号按钮
	for stat in ["Strength", "Agility", "Intelligence", "Constitution"]:
		var btn = stats_container.get_node(stat + "/AddButton")
		if not btn.pressed.is_connected(_on_add_stat_pressed.bind(stat)):
			btn.pressed.connect(_on_add_stat_pressed.bind(stat))

func _on_stat_changed(_name: String, _val: Variant) -> void:
	_refresh_stats()
	_refresh_header()

func _refresh_header() -> void:
	if not player_data: return
	level_label.text = "等级: %d" % player_data.level
	stat_points_label.text = "可用属性点: %d" % player_data.stat_points
	
	var needed = player_data.get_next_level_experience()
	exp_bar.max_value = needed
	exp_bar.value = player_data.experience
	exp_bar.get_node("Label").text = "EXP: %d/%d" % [int(player_data.experience), int(needed)]

func _refresh_stats() -> void:
	if not player_data: return
	
	# 更新各个属性行
	_update_stat_row("Strength", player_data.strength, "力量 (影响伤害和跳跃)")
	_update_stat_row("Agility", player_data.agility, "敏捷 (影响移速和暴击)")
	_update_stat_row("Intelligence", player_data.intelligence, "智力 (影响采集和法术)")
	_update_stat_row("Constitution", player_data.constitution, "体质 (影响生命点数)")

func _update_stat_row(stat_id: String, value: float, hint: String) -> void:
	var row = stats_container.get_node_or_null(stat_id)
	if not row: return
	
	row.get_node("Value").text = str(int(value))
	row.get_node("AddButton").visible = player_data.stat_points > 0
	row.tooltip_text = hint
	
	# 添加预览值
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("AttributeComponent"):
		var attr = player.get_node("AttributeComponent")
		match stat_id:
			"Strength": row.tooltip_text += "\n当前物理增益: +%.1f%%" % ((attr.get_damage_multiplier(10.0)/10.0-1.0)*100.0)
			"Agility": row.tooltip_text += "\n当前速度增益: +%.1f%%" % ((attr.get_move_speed(200.0)/200.0-1.0)*100.0)
			"Constitution": row.tooltip_text += "\n生命上限加成: +%.0f" % (attr.get_max_hp(100.0)-100.0)

func _on_add_stat_pressed(stat_id: String) -> void:
	if player_data.stat_points <= 0: return
	
	match stat_id:
		"Strength": player_data.strength += 1
		"Agility": player_data.agility += 1
		"Intelligence": player_data.intelligence += 1
		"Constitution": player_data.constitution += 1
	
	player_data.stat_points -= 1
	
	# 简单的按钮动画反馈
	var row = stats_container.get_node(stat_id)
	var btn = row.get_node("AddButton")
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.2, 1.2), 0.05)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.1)
