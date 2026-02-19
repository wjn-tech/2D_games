extends Control
class_name MenuDynamicBackground

## Dynamic Background Component
##根据系统时间或游戏进度显示不同的背景氛围

# 颜色配置（调整以匹配项目主题）
const COLOR_DAY = Color(0.18, 0.20, 0.25) # 柔和白天偏冷色
const COLOR_NIGHT = Color(0.12, 0.12, 0.14) # 与 assets/ui/main_theme.tres 面板 bg_color 保持一致
const COLOR_DUSK = Color(0.35, 0.15, 0.38) # 暗紫偏暖，用于黄昏过渡
const COLOR_DAWN = Color(0.40, 0.25, 0.30) # 早晨暖色调

@export var sky_rect: ColorRect
@export var particles: GPUParticles2D

# Exposed shader tuning parameters (can be adjusted in Inspector)
@export var star_density: float = 0.72
@export var ring_count: int = 4
@export var ring_thickness: float = 0.009
@export var nebula_strength: float = 0.90
@export var use_noise: bool = true

# visual extras exposed
@export var ring_intensity: float = 1.8
@export var ring_chroma: float = 0.14
@export var star_bloom: float = 1.6

# Quality preset: 0=Low,1=Medium,2=High
@export var quality_preset: int = 1

func _ready() -> void:
	# attach shader-based background and update initial state
	_attach_time_shader()
	# read stored preference from SettingsManager (user settings) if available, otherwise ProjectSettings
	var sv = null
	if typeof(SettingsManager) != TYPE_NIL:
		sv = SettingsManager.get_value("Graphics", "menu_visuals_quality")
	if sv != null:
		quality_preset = int(sv)
	elif ProjectSettings.has_setting("menu_visuals/quality_preset"):
		quality_preset = int(ProjectSettings.get_setting("menu_visuals/quality_preset"))
	_apply_quality_preset()

	# listen for live changes from SettingsManager UI if autoload present
	if typeof(SettingsManager) != TYPE_NIL:
		SettingsManager.connect("settings_changed", Callable(self, "_on_settings_changed"))
	update_based_on_time()

	# refresh periodically in case system time changes while the menu is open
	set_process(true)

func _process(delta: float) -> void:
	# update shader parameter each frame (light cost) to reflect current system time
	if sky_rect and sky_rect.material and sky_rect.material is ShaderMaterial:
		var system_time = Time.get_time_dict_from_system()
		var hour = system_time.hour
		var t = _hour_to_timefactor(hour)
		sky_rect.material.set_shader_parameter("time_factor", t)
		# pass a continuous time value (seconds) for animation in shader
		var ticks = Time.get_ticks_msec() / 1000.0
		sky_rect.material.set_shader_parameter("global_time", ticks)

		# also keep exported tuning parameters in sync with shader
		if sky_rect.material and sky_rect.material is ShaderMaterial:
			sky_rect.material.set_shader_parameter("star_density", star_density)
			sky_rect.material.set_shader_parameter("ring_count", ring_count)
			sky_rect.material.set_shader_parameter("ring_thickness", ring_thickness)
			sky_rect.material.set_shader_parameter("nebula_strength", nebula_strength)
			sky_rect.material.set_shader_parameter("use_noise", use_noise)
			sky_rect.material.set_shader_parameter("ring_intensity", ring_intensity)
			sky_rect.material.set_shader_parameter("ring_chroma", ring_chroma)
			sky_rect.material.set_shader_parameter("star_bloom", star_bloom)


func _hour_to_timefactor(hour: int) -> float:
	# map hour [0..23] to factor 0 (day) .. 1 (night)
	if hour >= 7 and hour < 18:
		return 0.0
	elif hour >= 18 and hour < 21:
		return 0.5
	else:
		return 1.0

func _attach_time_shader() -> void:
	var shader_path = "res://ui/shaders/menu_bg.shader"
	if ResourceLoader.exists(shader_path):
		var sh = load(shader_path)
		if sh:
			var mat = ShaderMaterial.new()
			mat.shader = sh
			if sky_rect:
				sky_rect.material = mat
				# initialize shader parameters from exported properties
				mat.set_shader_parameter("ring_count", ring_count)
				mat.set_shader_parameter("ring_thickness", ring_thickness)
				mat.set_shader_parameter("star_density", star_density)
				mat.set_shader_parameter("nebula_strength", nebula_strength)
				mat.set_shader_parameter("use_noise", use_noise)
				mat.set_shader_parameter("global_time", Time.get_ticks_msec() / 1000.0)


func _apply_quality_preset() -> void:
	match quality_preset:
		0:
			# Low
			star_density = 0.18
			ring_count = 2
			ring_thickness = 0.006
			nebula_strength = 0.20
			use_noise = false
		1:
			# Medium (default)
			star_density = 0.72
			ring_count = 4
			ring_thickness = 0.010
			nebula_strength = 0.90
			ring_intensity = 1.6
			ring_chroma = 0.12
			star_bloom = 1.2
			use_noise = true
		2:
			# High
			star_density = 1.4
			ring_count = 7
			ring_thickness = 0.015
			nebula_strength = 1.6
			ring_intensity = 2.4
			ring_chroma = 0.18
			star_bloom = 2.4
			use_noise = true
	# if shader already attached, propagate immediately
	if sky_rect and sky_rect.material and sky_rect.material is ShaderMaterial:
		sky_rect.material.set_shader_parameter("star_density", star_density)
		sky_rect.material.set_shader_parameter("ring_count", ring_count)
		sky_rect.material.set_shader_parameter("ring_thickness", ring_thickness)
		sky_rect.material.set_shader_parameter("nebula_strength", nebula_strength)
		sky_rect.material.set_shader_parameter("use_noise", use_noise)
		sky_rect.material.set_shader_parameter("ring_intensity", ring_intensity)
		sky_rect.material.set_shader_parameter("ring_chroma", ring_chroma)
		sky_rect.material.set_shader_parameter("star_bloom", star_bloom)

func set_quality_preset(preset: int, persist: bool = true) -> void:
	# public API to change preset at runtime (e.g., from settings UI)
	quality_preset = clamp(preset, 0, 2)
	_apply_quality_preset()
	if persist:
		ProjectSettings.set_setting("menu_visuals/quality_preset", quality_preset)
		ProjectSettings.save()
		# Also write into SettingsManager if present for UI persistence
		if typeof(SettingsManager) != TYPE_NIL:
			SettingsManager.set_value("Graphics", "menu_visuals_quality", quality_preset)
			SettingsManager.save_settings()


func _on_settings_changed(section: String, key: String, value: Variant) -> void:
	if section == "Graphics" and key == "menu_visuals_quality":
		set_quality_preset(int(value), false)

func update_based_on_time() -> void:
	var system_time = Time.get_time_dict_from_system()
	var hour = system_time.hour
	
	print("DynamicBackground: Current system hour is ", hour)
	
	var target_color = COLOR_DAY
	var particle_amount = 5
	
	if hour >= 5 and hour < 8:
		# Dawn
		target_color = COLOR_DAWN
	elif hour >= 8 and hour < 17:
		# Day
		target_color = COLOR_DAY
	elif hour >= 17 and hour < 20:
		# Dusk
		target_color = COLOR_DUSK
	else:
		# Night (20 - 5)
		target_color = COLOR_NIGHT
		particle_amount = 20 # More stars/fireflies
	
	if sky_rect:
		# 如果是第一次加载，直接设置；如果是运行时变化，可以 tween
		# prefer shader-driven gradient; also set fallback color for non-shader
		sky_rect.color = target_color
		if sky_rect.material and sky_rect.material is ShaderMaterial:
			var t = _hour_to_timefactor(hour)
			sky_rect.material.set_shader_parameter("time_factor", t)
			sky_rect.material.set_shader_parameter("day_color", COLOR_DAY)
			sky_rect.material.set_shader_parameter("night_color", COLOR_NIGHT)
		
	if particles:
		particles.amount_ratio = float(particle_amount) / 20.0
