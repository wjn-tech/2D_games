extends VBoxContainer

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/Label
@onready var age_bar: ProgressBar = $AgeBar
@onready var age_label: Label = $AgeBar/Label

var stats_label: Label

func _ready() -> void:
	add_to_group("hud_stats")
	# 动态创建一个用于显示详细属性的 Label
	stats_label = Label.new()
	stats_label.name = "StatsLabel"
	# 设置字体大小或者样式（如果需要）
	# stats_label.add_theme_font_size_override("font_size", 12)
	add_child(stats_label)

func _process(_delta: float) -> void:
	var player_data = GameState.player_data
	if not player_data: return
	
	# 更新生命值 UI
	if health_bar:
		health_bar.max_value = player_data.max_health
		health_bar.value = player_data.health
	if health_label:
		health_label.text = "HP: %d/%d" % [int(player_data.health), int(player_data.max_health)]
	
	# 更新年龄/寿命 UI
	if age_bar:
		age_bar.max_value = player_data.max_life_span
		age_bar.value = player_data.current_age
	if age_label:
		age_label.text = "Age: %.1f / %.0f" % [player_data.current_age, player_data.max_life_span]
	
	# 更新详细属性 UI
	if is_instance_valid(stats_label):
		stats_label.text = "STR: %.1f | AGI: %.1f | INT: %.1f | CON: %.1f" % [
			player_data.strength,
			player_data.agility,
			player_data.intelligence,
			player_data.constitution
		]
