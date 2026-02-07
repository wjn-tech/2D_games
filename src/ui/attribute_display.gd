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
	add_child(stats_label)
	
	# 加入信号监听，确保属性更新时立即刷新，而不是只靠 _process
	if EventBus:
		EventBus.player_data_refreshed.connect(_update_full_display)
	
	_update_full_display()

func _update_full_display() -> void:
	var player_data = GameState.player_data
	if not player_data: return
	
	# Disconnect old data if exists (for safe replacement)
	if player_data.stat_changed.is_connected(_on_stat_changed):
		player_data.stat_changed.disconnect(_on_stat_changed)
	
	player_data.stat_changed.connect(_on_stat_changed)
	_refresh_visuals(player_data)

func _on_stat_changed(_name: String, _val: Variant) -> void:
	_refresh_visuals(GameState.player_data)

func _refresh_visuals(player_data: CharacterData) -> void:
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

func _process(_delta: float) -> void:
	# 仍然保留 _process 兜底，但主要逻辑已移至信号驱动
	_refresh_visuals(GameState.player_data)
