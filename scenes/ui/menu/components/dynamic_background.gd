extends Control
class_name MenuDynamicBackground

## Dynamic Background Component
##根据系统时间或游戏进度显示不同的背景氛围

# 颜色配置（调整以匹配项目主题）
# 白天使用明亮天空蓝，避免覆盖着色器默认日色
const COLOR_DAY = Color(0.53, 0.80, 0.95) # Bright sky blue for midday
const COLOR_NIGHT = Color(0.08, 0.08, 0.10) # Deep night
const COLOR_DUSK = Color(0.92, 0.48, 0.26) # Warm sunset orange
const COLOR_DAWN = Color(1.0, 0.86, 0.66) # Soft dawn warm

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
@export var cloud_texture: Texture2D
@export var max_cloud_layers: int = 3

@export var debug_force_visible_clouds: bool = true
@export var enable_debug_prints: bool = false

# cloud scroll tuning
@export var cloud_scroll_speed: float = 16.0

# current period state exposed
signal period_changed(period: String, halo_color: Color)
var current_period: String = ""
var current_halo_color: Color = Color(1,1,1,0)
# Quality preset: 0=Low,1=Medium,2=High
@export var quality_preset: int = 1

# Debug: force a specific hour in Inspector (-1 = use system time)
@export var debug_hour: int = -1
@export var scene_palette_path: String = "res://assets/ui/palette.tres"
@export var preset_path: String = "res://assets/ui/presets/day.tres"

var _palette = {}

func _ready() -> void:
	# attach shader-based background and update initial state
	# resolve sky_rect if scene binding used (PackedScene node_paths may set a NodePath)
	if typeof(sky_rect) == TYPE_NODE_PATH or typeof(sky_rect) == TYPE_STRING:
		var _sr = get_node_or_null(sky_rect)
		if _sr:
			sky_rect = _sr
			if enable_debug_prints:
				print("DynamicBackground: sky_rect resolved to node ->", sky_rect)
		else:
			if enable_debug_prints:
				print("DynamicBackground: could NOT resolve sky_rect from", sky_rect)

	_attach_time_shader()
	# attempt to load a preset if provided (allows immediate visible change)
	if preset_path and preset_path != "":
		_load_and_apply_preset(preset_path)
	# try load shared palette for unified colors
	# try load shared palette for unified colors (supports .json or .tres Resource)
	if ResourceLoader.exists(scene_palette_path):
		var res = ResourceLoader.load(scene_palette_path)
		if res:
			# if resource has a colors property (our palette.tres), read it
			if typeof(res) != TYPE_NIL and res.has_method("get") and res.get("colors") != null:
				_palette = res.get("colors")
				# normalize keys to friendly names if needed
				# example: res.colors may be a dictionary of Color values already
				for k in _palette.keys():
					# if value is Color, keep; if Color8 etc, convert
					var v = _palette[k]
					if typeof(v) == TYPE_COLOR:
						# store as Color directly for easier use
						_palette[k] = v
					elif typeof(v) == TYPE_ARRAY and v.size() >= 3:
						_palette[k] = Color(float(v[0])/255.0, float(v[1])/255.0, float(v[2])/255.0)
				if enable_debug_prints:
					print("DynamicBackground: loaded palette resource ->", scene_palette_path)
			# otherwise, try reading as JSON file (legacy)
			else:
				var f = FileAccess.open(scene_palette_path, FileAccess.READ)
				if f:
					var txt = f.get_as_text()
					f.close()
					var js = JSON.parse(txt)
					if js.error == OK:
						_palette = js.result
						if enable_debug_prints:
							print("DynamicBackground: loaded scene palette JSON ->", scene_palette_path)
					else:
						if enable_debug_prints:
							print("DynamicBackground: failed to parse palette JSON")
				else:
					if enable_debug_prints:
						print("DynamicBackground: failed to open palette file")
	else:
		if enable_debug_prints:
			print("DynamicBackground: palette file not found at", scene_palette_path)
	print("DynamicBackground: ready. sky_rect bound:", sky_rect != null)
	# DEBUG: force a very visible sky color so user sees script ran
	if sky_rect:
		# keep debug color only if no shader present; otherwise shader driven
		if not (sky_rect.material and sky_rect.material is ShaderMaterial):
			sky_rect.color = Color(0.53, 0.80, 0.95)
			print("DynamicBackground: debug sky color applied")
	# create simple cloud layers if texture provided
	if cloud_texture:
		_create_cloud_layers()
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
		if debug_hour >= 0 and debug_hour <= 23:
			hour = debug_hour
			print("DynamicBackground: debug_hour forced to", hour)
		var t = _hour_to_timefactor(hour)
		# pass a continuous time value (seconds) for animation in shader
		var ticks = Time.get_ticks_msec() / 1000.0

		var mat: ShaderMaterial = sky_rect.material
		mat.set_shader_parameter("time_factor", t)
		mat.set_shader_parameter("global_time", ticks)

		# keep exported tuning parameters in sync with shader
		mat.set_shader_parameter("star_density", star_density)
		mat.set_shader_parameter("ring_count", ring_count)
		mat.set_shader_parameter("ring_thickness", ring_thickness)
		mat.set_shader_parameter("nebula_strength", nebula_strength)
		mat.set_shader_parameter("use_noise", use_noise)
		mat.set_shader_parameter("ring_intensity", ring_intensity)
		mat.set_shader_parameter("ring_chroma", ring_chroma)
		mat.set_shader_parameter("star_bloom", star_bloom)
		mat.set_shader_parameter("day_color", COLOR_DAY)
		mat.set_shader_parameter("night_color", COLOR_NIGHT)
		# gradient and halo will be set per time period below

		# compute sun position/color/intensity based on hour (6..18 is sun path)
		var normalized = clamp((float(hour) - 6.0) / 12.0, 0.0, 1.0)
		var sun_x = lerp(-0.45, 0.45, normalized)
		# arc height: highest at midday (normalized=0.5)
		var arc_peak = 1.0 - abs(normalized - 0.5) * 2.0
		var sun_y = -0.25 + 0.9 * arc_peak
		mat.set_shader_parameter("sun_pos", Vector2(sun_x, sun_y))
		# sun intensity stronger near midday, fades at dawn/dusk
		var sun_int = clamp(1.0 - abs(normalized - 0.5) * 2.0, 0.0, 1.0)
		# reduce intensity slightly during early/late hours
		sun_int *= mix(0.6, 1.0, clamp((hour - 8) / 8.0, 0.0, 1.0))
		mat.set_shader_parameter("sun_intensity", sun_int)
		# choose sun color (warm at dawn/dusk)
		var s_color = Color(1.0, 0.98, 0.85)
		if hour >= 16 and hour < 20:
			s_color = Color(1.0, 0.65, 0.28)
		elif hour >= 5 and hour < 8:
			s_color = Color(1.0, 0.82, 0.6)
		mat.set_shader_parameter("sun_color", Vector3(s_color.r, s_color.g, s_color.b))

		# set gradient top/bottom and halo color & particles according to time segment
		var period = _hour_to_period(hour)
		var cfg = _get_period_cfg(period)
		# gradient - if palette loaded, prefer scene blue for DAY to unify look
		if _palette.size() > 0 and period == "DAY":
			var top = Color(_palette.scene_blue_top[0]/255.0, _palette.scene_blue_top[1]/255.0, _palette.scene_blue_top[2]/255.0)
			var bottom = Color(_palette.scene_blue_bottom[0]/255.0, _palette.scene_blue_bottom[1]/255.0, _palette.scene_blue_bottom[2]/255.0)
			mat.set_shader_parameter("grad_top", top)
			mat.set_shader_parameter("grad_bottom", bottom)
		else:
			mat.set_shader_parameter("grad_top", cfg.gradient_top)
			mat.set_shader_parameter("grad_bottom", cfg.gradient_bottom)
		# halo/sun color
		mat.set_shader_parameter("sun_color", Vector3(cfg.halo_color.r, cfg.halo_color.g, cfg.halo_color.b))
		mat.set_shader_parameter("sun_intensity", cfg.halo_color.a * 2.0)
		# tune nebula and star density per-period to ensure daytime looks clean
		if cfg.has("nebula_mul"):
			mat.set_shader_parameter("nebula_strength", nebula_strength * cfg.nebula_mul)
		if cfg.has("star_mul"):
			mat.set_shader_parameter("star_density", star_density * cfg.star_mul)
		# sun pulse control
		if cfg.has("sun_pulse"):
			mat.set_shader_parameter("sun_pulse", cfg.sun_pulse)
		# set particle amount
		if particles:
			particles.amount = int(cfg.star_count)
			particles.emitting = cfg.star_count > 0
		# cloud visibility
		_set_clouds_visible(period == "MORNING" or period == "EVENING")

		# apply cloud opacity tweaking if present
		var pb2 = get_node_or_null("ParallaxBackground")
		if pb2:
			for child in pb2.get_children():
				if typeof(child.name) == TYPE_STRING and child.name.begins_with("CloudLayer"):
					# ParallaxLayer contains TextureRect as child named 'CloudSprite' or fallback ColorRect
					for sub in child.get_children():
						if sub is TextureRect or sub is ColorRect:
							var target_alpha = cfg.cloud_opacity if cfg.has("cloud_opacity") else sub.modulate.a
							sub.modulate.a = target_alpha

		# emit signal if period changed so UI can react (button glow, etc.)
		if period != current_period:
			current_period = period
			current_halo_color = cfg.halo_color
			emit_signal("period_changed", period, cfg.halo_color)

		# advance parallax background scroll for cloud layers
		var pb = get_node_or_null("ParallaxBackground")
		if pb and pb is ParallaxBackground and max_cloud_layers > 0:
			# subtle continuous horizontal scroll
			pb.scroll_offset = pb.scroll_offset + Vector2(delta * cloud_scroll_speed, 0)


func _hour_to_timefactor(hour: int) -> float:
	# map hour [0..23] to factor 0 (day) .. 1 (night)
	if hour >= 7 and hour < 18:
		return 0.0
	elif hour >= 18 and hour < 21:
		return 0.5
	else:
		return 1.0


func _hour_to_period(hour: int) -> String:
	if hour >= 6 and hour < 9:
		return "MORNING"
	elif hour >= 9 and hour < 17:
		return "DAY"
	elif hour >= 17 and hour < 20:
		return "EVENING"
	else:
		return "NIGHT"


func _get_period_cfg(period: String) -> Dictionary:
	var cfg = {}
	match period:
		"MORNING":
			cfg.gradient_top = Color8(0x4a,0x5f,0x7a)
			cfg.gradient_bottom = Color8(0x7a,0x9c,0xb8)
			cfg.halo_color = Color(122/255.0,156/255.0,184/255.0,0.3)
			cfg.star_count = 50
			cfg.star_mul = 0.6
			cfg.nebula_mul = 0.7
			cfg.sun_pulse = 0.9
			cfg.cloud_opacity = 0.18
		"DAY":
			# brighter, cleaner daytime palette
			cfg.gradient_top = Color8(0x7A,0xC9,0xFF)
			cfg.gradient_bottom = Color8(0xB3,0xE1,0xFF)
			cfg.halo_color = Color(0.92,0.97,1.0,0.28)
			cfg.star_count = 5
			cfg.star_mul = 0.12
			cfg.nebula_mul = 0.18
			cfg.sun_pulse = 0.95
			cfg.cloud_opacity = 0.06
		"EVENING":
			cfg.gradient_top = Color8(0x5a,0x2d,0x5a)
			cfg.gradient_bottom = Color8(0xd9,0x83,0x2e)
			cfg.halo_color = Color(217/255.0,131/255.0,46/255.0,0.4)
			cfg.star_count = 80
			cfg.star_mul = 0.9
			cfg.nebula_mul = 0.8
			cfg.sun_pulse = 0.85
			cfg.cloud_opacity = 0.22
		"NIGHT":
			cfg.gradient_top = Color8(0x1a,0x1e,0x2b)
			cfg.gradient_bottom = Color8(0x2d,0x3b,0x55)
			cfg.halo_color = Color(45/255.0,59/255.0,85/255.0,0.5)
			cfg.star_count = 150
			cfg.star_mul = 1.0
			cfg.nebula_mul = 1.0
			cfg.sun_pulse = 0.6
			cfg.cloud_opacity = 0.18
	return cfg


func _create_cloud_layers() -> void:
	# create ParallaxLayer cloud layers under ParallaxBackground if present
	var pb = get_node_or_null("ParallaxBackground")
	if not pb:
		return
	# clear any existing CloudLayer_* children first
	for child in pb.get_children():
		if typeof(child.name) == TYPE_STRING and child.name.begins_with("CloudLayer"):
			child.queue_free()
	# create ParallaxLayer + tiled TextureRect so motion_mirroring works
	for i in range(max_cloud_layers):
		var layer = ParallaxLayer.new()
		layer.name = "CloudLayer_%d" % i
		# motion scale controls relative speed per layer
		layer.motion_scale = Vector2(0.25 + i * 0.18, 1)
		# mirroring allows seamless horizontal tiling; fallback width 1024
		var mirror_x = 1024
		if cloud_texture and cloud_texture.get_width():
			mirror_x = int(cloud_texture.get_width())
		layer.motion_mirroring = Vector2(mirror_x, 0)
		# texture rect child
		var tr = TextureRect.new()
		tr.name = "CloudSprite"
		tr.texture = cloud_texture
		tr.expand = true
		# use tile/stretch mode so texture repeats
		tr.stretch_mode = TextureRect.STRETCH_TILE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.modulate = Color(1,1,1, 0.12 + float(i) * 0.06)
		tr.z_index = -5 + i
		layer.add_child(tr)
		pb.add_child(layer)
	# ensure starting offset
	pb.scroll_offset = Vector2.ZERO
	# if no cloud texture provided, create simple ColorRect fallback layers so changes are visible
	if not cloud_texture and debug_force_visible_clouds:
		for i in range(max_cloud_layers):
			var cr = ColorRect.new()
			cr.name = "CloudLayer_Fallback_%d" % i
			cr.anchor_left = 0
			cr.anchor_top = 0
			cr.anchor_right = 1
			cr.anchor_bottom = 1
			cr.color = Color(0.9, 0.9, 0.95, 0.06 + float(i) * 0.03)
			cr.z_index = -10 + i
			cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pb.add_child(cr)


func _set_clouds_visible(visible: bool) -> void:
	var pb = get_node_or_null("ParallaxBackground")
	if not pb:
		return
	for child in pb.get_children():
		if child.name.begins_with("CloudLayer"):
			child.visible = visible

func _attach_time_shader() -> void:
	var shader_path = "res://ui/shaders/menu_bg.shader"
	# check shader file exists first
	if not ResourceLoader.exists(shader_path):
		if enable_debug_prints:
			print("DynamicBackground: shader file not found:", shader_path)
		return

	var sh = load(shader_path)
	if not sh:
		if enable_debug_prints:
			print("DynamicBackground: failed to load shader at", shader_path)
		return

	var mat = ShaderMaterial.new()
	mat.shader = sh

	# resolve sky_rect node if still a path
	var sky_node = sky_rect
	if typeof(sky_node) == TYPE_NODE_PATH or typeof(sky_node) == TYPE_STRING:
		sky_node = get_node_or_null(sky_node)
	# fallback: try direct child lookup by common node name
	if not sky_node:
		sky_node = get_node_or_null("SkyLayer")
		if sky_node:
			if enable_debug_prints:
				print("DynamicBackground: found SkyLayer via fallback get_node('SkyLayer') ->", sky_node)
			# update exported binding for future calls
			sky_rect = sky_node
		else:
			if enable_debug_prints:
				print("DynamicBackground: no SkyLayer node available to attach shader. sky_rect:", sky_rect)
			return

	# attach material to the ColorRect (SkyLayer)
	if sky_node and sky_node is ColorRect:
		sky_node.material = mat
		# also ensure exported reference points to node
		sky_rect = sky_node
	else:
		if enable_debug_prints:
			print("DynamicBackground: SkyLayer node is not a ColorRect, cannot attach material ->", sky_node)
		return
	# initialize shader parameters from exported properties
	mat.set_shader_parameter("ring_count", ring_count)
	mat.set_shader_parameter("ring_thickness", ring_thickness)
	mat.set_shader_parameter("star_density", star_density)
	mat.set_shader_parameter("nebula_strength", nebula_strength)
	mat.set_shader_parameter("use_noise", use_noise)
	mat.set_shader_parameter("ring_intensity", ring_intensity)
	mat.set_shader_parameter("ring_chroma", ring_chroma)
	mat.set_shader_parameter("star_bloom", star_bloom)
	mat.set_shader_parameter("day_color", COLOR_DAY)
	mat.set_shader_parameter("night_color", COLOR_NIGHT)
	mat.set_shader_parameter("global_time", Time.get_ticks_msec() / 1000.0)
	if enable_debug_prints:
		print("DynamicBackground: shader loaded and material attached to SkyLayer ->", sky_node)
		print("DynamicBackground: SkyLayer.material ->", sky_node.material)
		print("DynamicBackground: initial params -> star_density:", star_density, "ring_count:", ring_count, "nebula_strength:", nebula_strength)


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


func force_attach_shader() -> void:
	# public helper to force attach shader from other scripts (MainMenu) for debugging
	if enable_debug_prints:
		print("DynamicBackground: force_attach_shader called")
	_attach_time_shader()
	# report whether material now present
	if sky_rect and sky_rect.material:
		if enable_debug_prints:
			print("DynamicBackground: force_attach_shader result - sky_rect.material ->", sky_rect.material)
	else:
		if enable_debug_prints:
			print("DynamicBackground: force_attach_shader result - material not attached")


func apply_day_override() -> void:
	# Force shader parameters to a clear daytime look for immediate preview
	var node = sky_rect
	if typeof(node) == TYPE_NODE_PATH or typeof(node) == TYPE_STRING:
		node = get_node_or_null(node)
	if not node or not node.material or not (node.material is ShaderMaterial):
		if enable_debug_prints:
			print("DynamicBackground: apply_day_override - shader not present")
		return
	var mat: ShaderMaterial = node.material
	# set clear daytime gradient and reduced stars/nebula
	mat.set_shader_parameter("grad_top", Color8(0x7A,0xC9,0xFF))
	mat.set_shader_parameter("grad_bottom", Color8(0xB3,0xE1,0xFF))
	mat.set_shader_parameter("star_density", 0.1)
	mat.set_shader_parameter("nebula_strength", 0.18)
	mat.set_shader_parameter("sun_intensity", 1.2)
	mat.set_shader_parameter("sun_pulse", 0.95)
	mat.set_shader_parameter("time_factor", 0.0)
	mat.set_shader_parameter("global_time", Time.get_ticks_msec() / 1000.0)
	if enable_debug_prints:
		print("DynamicBackground: apply_day_override applied to material ->", mat)

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


func _load_and_apply_preset(path: String) -> void:
	# Load a simple resource that contains a `params` dictionary and apply values to local exports and shader
	if not ResourceLoader.exists(path):
		if enable_debug_prints:
			print("DynamicBackground: preset not found:", path)
		return
	var res = ResourceLoader.load(path)
	if not res:
		if enable_debug_prints:
			print("DynamicBackground: failed to load preset resource:", path)
		return
	# expect resource.params to be a Dictionary
	if not res or not res.has_method("get") or res.get("params") == null:
		if enable_debug_prints:
			print("DynamicBackground: preset resource missing 'params' field:", path)
		return
	var p = res.get("params")
	if typeof(p) != TYPE_DICTIONARY:
		if enable_debug_prints:
			print("DynamicBackground: preset.params is not a Dictionary:", path)
		return
	# apply known parameters to exported variables
	if p.has("star_density"): star_density = float(p.star_density)
	if p.has("star_brightness"): # map to star_bloom as proxy
		star_bloom = float(p.star_brightness)
	if p.has("nebula_strength"): nebula_strength = float(p.nebula_strength)
	if p.has("sun_intensity"): # store as sun_intensity shader param
		# will be applied to shader below
		pass
	if p.has("cloud_opacity"): # affect cloud layers modulate alpha when applied
		# will be used when applying to child layers in _process
		pass
	# if shader attached, set shader params immediately
	if sky_rect and sky_rect.material and sky_rect.material is ShaderMaterial:
		var mat: ShaderMaterial = sky_rect.material
		for k in p.keys():
			var v = p[k]
			# only set simple numeric/color/vector values
			if typeof(v) in [TYPE_FLOAT, TYPE_INT, TYPE_BOOL, TYPE_VECTOR2, TYPE_COLOR, TYPE_NIL]:
				# map known names -> shader params
				if k == "grad_top" or k == "grad_bottom" or k == "glow_color":
					mat.set_shader_parameter(k, v)
				elif k == "star_density":
					mat.set_shader_parameter("star_density", float(v))
				elif k == "nebula_strength":
					mat.set_shader_parameter("nebula_strength", float(v))
				elif k == "sun_intensity":
					mat.set_shader_parameter("sun_intensity", float(v))
				elif k == "star_brightness":
					mat.set_shader_parameter("star_bloom", float(v))
				# else ignore unknown keys for now
	if enable_debug_prints:
		print("DynamicBackground: preset applied from", path)
