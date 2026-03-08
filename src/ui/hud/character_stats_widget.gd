extends PanelContainer
class_name CharacterStatsWidget

@onready var grid = %GridContainer

func _ready() -> void:
	add_theme_stylebox_override("panel", HUDStyles.get_panel_style())
	_update_stats()
	
	if EventBus:
		if not EventBus.is_connected("player_data_refreshed", _update_stats):
			EventBus.player_data_refreshed.connect(_update_stats)

func _update_stats() -> void:
	# Clear old
	for c in %GridContainer.get_children(): c.queue_free()
	
	if not GameState.player_data: return
	var pd = GameState.player_data
	
	# Extract stats
	var stats = pd.get("BASE_STATS") if "BASE_STATS" in pd else {}
	# If empty, try other props
	
	# Add Age
	var age = pd.get("age")
	if age: _add_stat_row("Age", str(age))
	
	# Add Wealth if exists
	# _add_stat_row("Gold", str(pd.get("gold", 0)))
	
	# Add Attributes (STR, AGI...)
	var attrs = ["strength", "agility", "intelligence", "constitution"]
	for attr in attrs:
		# Check both direct prop and BASE_STATS dict
		var val = stats.get(attr)
		if val == null: val = pd.get(attr)
		if val == null: val = 10 # Default
		
		# Shorten names
		var short_name = attr.substr(0, 3).to_upper()
		_add_stat_row(short_name, str(val))

func _add_stat_row(label: String, value: String) -> void:
	var lbl = Label.new()
	lbl.text = "%s: %s" % [label, value]
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 2)
	grid.add_child(lbl)
