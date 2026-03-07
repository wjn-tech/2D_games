extends PanelContainer
class_name PlayerStatusWidget

@onready var hp_bar: ProgressBar = %HPBar
@onready var mana_bar: ProgressBar = %ManaBar
@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var hp_label: Label = %HPLabel
@onready var mana_label: Label = %ManaLabel

# Internal state for shake effect
var _last_hp := -1.0
var _last_mana := -1.0
var _shake_strength := 0.0
var _shake_decay := 5.0
var _shake_target: Control = null

func _ready() -> void:
	# V3 Layout Adjustment: Add Icons and thicker bars
	_setup_v3_layout()
	_apply_styles()

	if EventBus:
		EventBus.player_data_refreshed.connect(_on_player_data_refreshed)
		if EventBus.has_signal("stats_changed"):
			EventBus.stats_changed.connect(_update_status)
			
	_on_player_data_refreshed()

func _on_player_data_refreshed() -> void:
	if GameState.player_data and not GameState.player_data.stat_changed.is_connected(_on_stat_changed):
		GameState.player_data.stat_changed.connect(_on_stat_changed)
	_update_status()

func _on_stat_changed(_stat_name: String, _new_value: float) -> void:
	_update_status()

func _process(delta: float) -> void:
	if _shake_strength > 0 and _shake_target:
		_shake_strength = move_toward(_shake_strength, 0, _shake_decay * delta)
		var offset = Vector2(randf_range(-_shake_strength, _shake_strength), randf_range(-_shake_strength, _shake_strength))
		_shake_target.position = _shake_target.get_meta("original_pos", Vector2.ZERO) + offset
	elif _shake_target and _shake_strength == 0:
		if _shake_target.has_meta("original_pos"):
			_shake_target.position = _shake_target.get_meta("original_pos")
		_shake_target = null
	
	_update_status()

func _setup_v3_layout() -> void:
	# V3.1 Overhaul: Strict Pixel Art Style
	# 1. Hide redundant text
	var vbox = $Margin/VBox
	if vbox.has_node("NameLabel"):
		vbox.get_node("NameLabel").visible = false 

	# 2. Configure Containers for tightness
	$Margin.add_theme_constant_override("margin_top", 4)
	$Margin.add_theme_constant_override("margin_bottom", 4)
	$Margin.add_theme_constant_override("margin_left", 4)
	$Margin.add_theme_constant_override("margin_right", 4)
	vbox.add_theme_constant_override("separation", 2)
	
	# 3. Apply Panel Style
	add_theme_stylebox_override("panel", HUDStyles.get_panel_style())
	
	# 4. Configure Bars (Unified Visuals)
	_style_pixel_bar(hp_bar, HUDStyles.COLOR_HP, 16)
	_style_pixel_bar(mana_bar, HUDStyles.COLOR_MANA, 16)
	
	# 5. Hide Stamina unless needed (default hidden in scene)
	# REPURPOSED: StaminaBar -> AgeBar (Life Span)
	if stamina_bar:
		stamina_bar.visible = true
		# Move Stamina Bar (Age Bar) below Mana Bar (User Request: "放在蓝条下面")
		var parent = stamina_bar.get_parent()
		if parent and mana_bar:
			parent.move_child(stamina_bar, mana_bar.get_index() + 1)
			
	# Apply style to Age Bar (Unified Height)
	if stamina_bar:
		_style_pixel_bar(stamina_bar, HUDStyles.COLOR_AGE, 16)
		# Ensure layout properties match HP/Mana bars exactly
		stamina_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _style_pixel_bar(bar: ProgressBar, color: Color, height: int) -> void:
	if not bar: return
	
	bar.custom_minimum_size.y = height
	bar.size_flags_horizontal = SIZE_EXPAND_FILL
	bar.show_percentage = false
	
	# Pixel Art Styles using StyleBoxFlat with anti_aliasing = false
	var fg = HUDStyles.get_bar_fg_style(color)
	var bg = HUDStyles.get_bar_bg_style()
	
	bar.add_theme_stylebox_override("fill", fg)
	bar.add_theme_stylebox_override("background", bg)
	
	# Text Overlay Configuration
	for child in bar.get_children():
		if child is Label:
			child.add_theme_color_override("font_shadow_color", Color.BLACK)
			child.add_theme_constant_override("shadow_offset_x", 1)
			child.add_theme_constant_override("shadow_offset_y", 1)
			child.add_theme_constant_override("outline_size", 0)
			child.add_theme_font_size_override("font_size", 16) # readable size

func _trigger_shake(strength: float = 5.0) -> void:
	_shake_strength = strength
	_shake_target = self 
	if not self.has_meta("original_pos"):
		self.set_meta("original_pos", self.position)

func _apply_styles() -> void:
	# Panel Style
	add_theme_stylebox_override("panel", HUDStyles.get_panel_style())
	
	# Bar Styles
	if hp_bar:
		hp_bar.add_theme_stylebox_override("background", HUDStyles.get_progress_bar_bg())
		hp_bar.add_theme_stylebox_override("fill", HUDStyles.get_progress_bar_fill(HUDStyles.COLOR_HP))
	if mana_bar:
		mana_bar.add_theme_stylebox_override("background", HUDStyles.get_progress_bar_bg())
		mana_bar.add_theme_stylebox_override("fill", HUDStyles.get_progress_bar_fill(HUDStyles.COLOR_MANA))
	if stamina_bar:
		stamina_bar.add_theme_stylebox_override("background", HUDStyles.get_progress_bar_bg())
		stamina_bar.add_theme_stylebox_override("fill", HUDStyles.get_progress_bar_fill(HUDStyles.COLOR_AGE))

func _update_status() -> void:
	if not GameState.player_data: return

	var pd = GameState.player_data

	# Fetch correct properties from CharacterData
	var max_hp = pd.max_health if "max_health" in pd else 100.0
	var cur_hp = pd.health if "health" in pd else max_hp

	var max_mana = pd.max_mana if "max_mana" in pd else 50.0
	var cur_mana = pd.mana if "mana" in pd else max_mana

	if "current_tool_max_mana" in pd and pd.current_tool_max_mana > 0:
		max_mana = pd.current_tool_max_mana
		cur_mana = pd.current_tool_mana

	if hp_bar:
		hp_bar.max_value = max_hp
		# Shake detection
		if _last_hp != -1 and cur_hp < _last_hp:
			_trigger_shake(10.0) # Shake on damage
		_last_hp = cur_hp
		
		hp_bar.value = cur_hp
		if hp_label: hp_label.text = "%d/%d" % [cur_hp, max_hp]
		
	if mana_bar:
		mana_bar.max_value = max_mana
		# Shake detection (minor)
		if _last_mana != -1 and cur_mana < _last_mana:
			_trigger_shake(2.0) # Small shake on spend
		_last_mana = cur_mana
		
		mana_bar.value = cur_mana
		if mana_label: mana_label.text = "%d/%d" % [cur_mana, max_mana]

	if stamina_bar:
		# Repurposed StaminaBar as Age/Lifespan Bar
		var age = pd.current_age if "current_age" in pd else 0.0
		var max_age = pd.max_life_span if "max_life_span" in pd else 100.0
		
		# FIX: The bar shows AGE (how much time has passed).
		# Fill amount should be the age itself, not the remaining life, 
		# for the visual length to match the number "20".
		stamina_bar.max_value = max_age
		stamina_bar.value = age 
		
		# Set text for age bar to match the others
		if not stamina_bar.has_node("AgeLabel"):
			var label = Label.new()
			label.name = "AgeLabel"
			label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 16)
			label.add_theme_color_override("font_shadow_color", Color.BLACK)
			label.add_theme_constant_override("shadow_offset_x", 1)
			label.add_theme_constant_override("shadow_offset_y", 1)
			stamina_bar.add_child(label)
		
		stamina_bar.get_node("AgeLabel").text = "Age: %d/%d" % [int(age), int(max_age)]
		stamina_bar.tooltip_text = "Age: %.1f / %.1f years" % [age, max_age]
