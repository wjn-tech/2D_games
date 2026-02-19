extends Control

@onready var start_button: Control = $CenterContainer/VBoxContainer/StartButton
@onready var load_button: Control = $CenterContainer/VBoxContainer/LoadButton
@onready var settings_button: Control = $CenterContainer/VBoxContainer/SettingsButton
@onready var exit_button: Control = $CenterContainer/VBoxContainer/ExitButton
@onready var title_label: Label = $CenterContainer/VBoxContainer/Title

var welcome_label: Label
var _hidden_backgrounds: Array = []
var ui_palette: Dictionary = {}

func _ready() -> void:
	# 确保菜单全屏并置于最顶层
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_right = 0
	offset_bottom = 0
	
	# 强制应用 startmenu 主题以确保字体和颜色覆盖被正确加载
	var start_theme_path = "res://ui/theme/theme_startmenu.tres"
	if ResourceLoader.exists(start_theme_path):
		var st = ResourceLoader.load(start_theme_path)
		if st:
			self.theme = st

	# Replace built-in Buttons with RoundedTextureButton instances to avoid rectangular artifacts
	_replace_buttons_with_rounded()

	_setup_smart_ui()

	# create decorative magic circle behind title
	_create_magic_circle()

	# apply gradient shader to title label if available
	_apply_title_gradient()

	# hide other scene backgrounds so our menu background is the only visible one
	_hide_external_backgrounds()
	
	# 递归修复背景遮挡导致按钮失效的问题
	_fix_mouse_filter(self)
	
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# 监听可见性变化，确保从游戏返回时恢复颜色
	visibility_changed.connect(_on_visibility_changed)
	
	# 初始状态
	_on_visibility_changed()
	
	# 按钮悬停动画
	for btn in [start_button, load_button, settings_button, exit_button]:
		btn.mouse_entered.connect(Callable(self, "_on_button_hover").bind(btn))
		btn.mouse_exited.connect(Callable(self, "_on_button_unhover").bind(btn))

	# Ensure glow backgrounds for buttons
	for btn in [start_button, load_button, settings_button, exit_button]:
		_ensure_button_glow(btn)

	# Debug: report whether DynamicBackground child is present and its script
	var dbg = get_node_or_null("DynamicBackground")
	if dbg:
		print("MainMenu: found DynamicBackground child ->", dbg, " script:", dbg.get_script())
		# listen for period changes to update button glow/colors
		if dbg.has_signal("period_changed"):
			dbg.connect("period_changed", Callable(self, "_on_bg_period_changed"))
		# ensure preset applied if the DynamicBackground supports it
		if dbg.has_method("_load_and_apply_preset"):
			var pp = ""
			if dbg.has_method("get"):
				# try read exported preset_path; safe-check type
				pp = dbg.get("preset_path")
				if typeof(pp) != TYPE_STRING:
					pp = ""
			if not pp or pp == "":
				pp = "res://assets/ui/presets/day.tres"
			dbg.call("_load_and_apply_preset", pp)
		# if instance exposes sky_rect, print its binding status
		if dbg.has_method("get"):
			var bound = null
			if dbg.has_node("SkyLayer"):
				bound = dbg.get_node("SkyLayer")
			print("MainMenu: DynamicBackground SkyLayer bound:", bound != null)
	else:
		print("MainMenu: DynamicBackground child NOT found in scene")

	# DEBUG: temporarily clear the Overlay to reveal background during debugging
	# Ensure Overlay alpha is preserved; only hide it if DynamicBackground explicitly requested debug visibility
	var ov = get_node_or_null("Overlay")
	if ov and ov is ColorRect and dbg and dbg.has_method("get"):
		var dbg_hide = false
		if dbg.has_meta("enable_debug_prints"):
			dbg_hide = dbg.get("enable_debug_prints")
		if dbg_hide:
			ov.color = Color(0,0,0,0)

	# report sky material (if instance exists)
	dbg = get_node_or_null("DynamicBackground")
	if dbg and dbg.has_node("SkyLayer"):
		var sky = dbg.get_node("SkyLayer")
		# attempt to ensure shader attached (no verbose prints)
		if dbg.has_method("force_attach_shader"):
			dbg.call("force_attach_shader")
		# Final fallback: if still null, attach shader material directly from here
			# If material missing, prefer to let DynamicBackground handle fallbacks; avoid creating permanent scene fallbacks here.
			if not sky.material:
				if dbg and dbg.has_method("apply_day_override"):
					dbg.call("apply_day_override")

func _process(delta: float) -> void:
	# update title shader time parameter if present
	# compute continuous time once per frame for animated text shaders
	var t = Time.get_ticks_msec() / 1000.0
	if title_label and title_label.material and title_label.material is ShaderMaterial:
		title_label.material.set_shader_parameter("time", t)

	# also update any other controls using the text gradient shader (buttons / welcome label)
	for node in [welcome_label, start_button, load_button, settings_button, exit_button]:
		if node and node.material and node.material is ShaderMaterial:
			node.material.set_shader_parameter("time", t)

func _create_magic_circle() -> void:
	# Try to load an external magic circle texture (SVG/PNG). If missing, fall back to procedural Control.
	var svg_path = "res://assets/ui/startmenu/textures/magic_circle.svg"
	var png_path = "res://assets/ui/startmenu/textures/magic_circle.png"
	if ResourceLoader.exists(svg_path):
		var tex = load(svg_path)
		if tex:
			var tr = TextureRect.new()
			tr.name = "MagicCircleSprite"
			tr.texture = tex
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.size = Vector2(900, 600)
			tr.z_index = -50
			add_child(tr)
			move_child(tr, 0)
			return
	elif ResourceLoader.exists(png_path):
		var tex = load(png_path)
		if tex:
			var tr = TextureRect.new()
			tr.name = "MagicCircleSprite"
			tr.texture = tex
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.size = Vector2(900, 600)
			tr.z_index = -50
			add_child(tr)
			move_child(tr, 0)
			return

	# fallback: procedural magic circle control
	var mc = Control.new()
	mc.name = "MagicCircle"
	mc.set_script(load("res://ui/controls/magic_circle.gd"))
	mc.size = Vector2(900, 600)
	add_child(mc)
	move_child(mc, 0)

func _ensure_button_glow(btn: Control) -> void:
	if not btn: return
	if btn.get_node_or_null("GlowRect"): return
	# Outer glow layer (soft, sits behind the button)
	var glow = ColorRect.new()
	glow.name = "GlowRect"
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.anchor_left = 0
	glow.anchor_top = 0
	glow.anchor_right = 1
	glow.anchor_bottom = 1
	# prefer shader-based glow for smoother falloff
	var glow_mat_path = "res://ui/shaders/button_glow.shader"
	var accent_col = ui_palette.get("accent", Color(0.435294,0.764706,1,1)) if ui_palette else Color(0.435294,0.764706,1,1)
	var glow_col = ui_palette.get("glow", Color(0.52549,0.780392,1,1)) if ui_palette else Color(0.52549,0.780392,1,1)
	if ResourceLoader.exists(glow_mat_path):
		var sh = load(glow_mat_path)
		if sh:
			var mat = ShaderMaterial.new()
			mat.shader = sh
			mat.set_shader_parameter("glow_color", glow_col)
			mat.set_shader_parameter("intensity", 0.45)
			mat.set_shader_parameter("round_radius", 0.12)
			mat.set_shader_parameter("falloff", 0.18)
			glow.material = mat
			glow.modulate = Color(1,1,1,0.04)
			glow.z_index = -2
			glow.scale = Vector2(1.06, 1.06)
	else:
		glow.color = Color(0.48, 0.78, 1.0, 0.28)
		glow.z_index = -2
		glow.scale = Vector2(1.08, 1.08)
	btn.add_child(glow)

	# Inner highlight layer (uses shader to simulate gradient inner glow)
	# Remove per-button child inner highlight if present (use stylebox-based highlight instead)
	var existing_inner = btn.get_node_or_null("InnerHighlight")
	if existing_inner:
		existing_inner.queue_free()

	# Remove per-button inner shadow if present; rely on stylebox shadowing to avoid rectangular artifacts
	var existing_shadow = btn.get_node_or_null("InnerShadow")
	if existing_shadow:
		existing_shadow.queue_free()

	# Corner decorations (small brackets) to match reference if assets exist
	if not btn.get_node_or_null("CornerTL"):
		var corner_tl_path = "res://assets/ui/startmenu/icons/corner_tl.svg"
		if ResourceLoader.exists(corner_tl_path):
			var ct = TextureRect.new()
			ct.name = "CornerTL"
			ct.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ct.anchor_left = 0.0
			ct.anchor_top = 0.0
			ct.anchor_right = 0.08
			ct.anchor_bottom = 0.12
			ct.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ct.texture = load(corner_tl_path)
			ct.z_index = 2
			btn.add_child(ct)

	if not btn.get_node_or_null("CornerBR"):
		var corner_br_path = "res://assets/ui/startmenu/icons/corner_br.svg"
		if ResourceLoader.exists(corner_br_path):
			var cb = TextureRect.new()
			cb.name = "CornerBR"
			cb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cb.anchor_left = 0.92
			cb.anchor_top = 0.88
			cb.anchor_right = 1.0
			cb.anchor_bottom = 1.0
			cb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			cb.texture = load(corner_br_path)
			cb.z_index = 2
			btn.add_child(cb)

	# light outer stroke overlay (subtle, placed above background but below inner highlight)
	if not btn.get_node_or_null("OuterStroke"):
		var stroke = ColorRect.new()
		stroke.name = "OuterStroke"
		stroke.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stroke.anchor_left = 0.01
		stroke.anchor_top = 0.01
		stroke.anchor_right = 0.99
		stroke.anchor_bottom = 0.99
		# keep outer stroke transparent to avoid any visible rectangular artifacts
		stroke.color = Color(1.0, 0.9, 1.0, 0.0)
		stroke.z_index = -1
		btn.add_child(stroke)

func _apply_title_gradient() -> void:
	var shader_path = "res://ui/shaders/text_gradient.shader"
	if ResourceLoader.exists(shader_path):
		var sh = load(shader_path)
		if sh:
			var mat = ShaderMaterial.new()
			mat.shader = sh
			title_label.material = mat


func _replace_buttons_with_rounded() -> void:
	# load class
	var rb_path = "res://scenes/ui/controls/rounded_texture_button.gd"
	if not ResourceLoader.exists(rb_path):
		print("MainMenu: RoundedTextureButton class not found:", rb_path)
		return
	var rb_script = load(rb_path)

	var btn_paths = {
		"StartButton": $CenterContainer/VBoxContainer/StartButton,
		"LoadButton": $CenterContainer/VBoxContainer/LoadButton,
		"SettingsButton": $CenterContainer/VBoxContainer/SettingsButton,
		"ExitButton": $CenterContainer/VBoxContainer/ExitButton,
	}

	for name in btn_paths.keys():
		var old_btn = btn_paths[name]
		if old_btn and is_instance_valid(old_btn):
			var parent = old_btn.get_parent()
			var idx = parent.get_children().find(old_btn)
			# instantiate new rounded button
			var nb = rb_script.new()
			nb.name = old_btn.name
			# copy size
			nb.custom_minimum_size = old_btn.custom_minimum_size
			# copy anchors
			nb.anchor_left = old_btn.anchor_left
			nb.anchor_top = old_btn.anchor_top
			nb.anchor_right = old_btn.anchor_right
			nb.anchor_bottom = old_btn.anchor_bottom
			# Buttons don't expose get_margin/set_margin reliably in GDScript; preserve layout by
			# keeping the same parent/child index and copying anchors + minimum size.
			# prepare visuals using palette if available
			var bg = ui_palette.get("panel", Color(0.15,0.4,0.78,1)) if ui_palette else ui_palette.get("ui_panel", Color(0.027451,0.101961,0.168627,1))
			var hover = ui_palette.get("grad_top", Color(0.14902,0.423529,0.745098,1)) if ui_palette else Color(0.14902,0.423529,0.745098,1)
			var pressed = ui_palette.get("bg_mid", Color(0.0313725,0.121569,0.203922,1)) if ui_palette else Color(0.0313725,0.121569,0.203922,1)
			# find icon texture if present in original
			var icon_tex = null
			var icon_node = old_btn.get_node_or_null("Icon")
			if icon_node and icon_node is TextureRect:
				icon_tex = icon_node.texture
			parent.add_child(nb)
			parent.move_child(nb, idx)
			# now that node is in tree, call setup so _ready() has run and children exist
			nb.setup(old_btn.text, icon_tex, bg, hover, pressed, old_btn.custom_minimum_size)
			# reconnect signals to existing handlers (map StartButton -> start, etc.)
			var base = name.replace("Button", "").to_lower()
			var handler = "_on_" + base + "_pressed"
			if has_method(handler):
				nb.pressed.connect(Callable(self, handler))
			# remove old
			old_btn.queue_free()
			# rebind onready vars
			if name == "StartButton":
				start_button = nb
			elif name == "LoadButton":
				load_button = nb
			elif name == "SettingsButton":
				settings_button = nb
			elif name == "ExitButton":
				exit_button = nb

func _on_visibility_changed() -> void:
	if visible:
		modulate = Color.WHITE
		$CenterContainer.modulate.a = 1.0
		# 恢复按钮状态
		start_button.disabled = false
		load_button.disabled = false
		exit_button.disabled = false
		# when showing menu, ensure external backgrounds remain hidden
		_hide_external_backgrounds()
	else:
		# restore backgrounds when menu hidden
		_show_external_backgrounds()

func _setup_smart_ui() -> void:
	# 1. Personalized Welcome
	welcome_label = Label.new()
	var time = Time.get_time_dict_from_system()
	var greeting = "冒险者"
	if time.hour < 6: greeting = "夜深了"
	elif time.hour < 12: greeting = "早上好"
	elif time.hour < 18: greeting = "下午好"
	else: greeting = "晚上好"
	
	welcome_label.text = "%s，冒险者。" % greeting
	welcome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	# apply text gradient shader to welcome label if available
	var _text_sh = "res://ui/shaders/text_gradient.shader"
	if ResourceLoader.exists(_text_sh):
		var _sh = load(_text_sh)
		if _sh:
			var _mat = ShaderMaterial.new()
			_mat.shader = _sh
			_mat.set_shader_parameter("noise_strength", 0.03)
			welcome_label.material = _mat
	# Insert after Title
	$CenterContainer/VBoxContainer.add_child(welcome_label)
	$CenterContainer/VBoxContainer.move_child(welcome_label, title_label.get_index() + 1)

	# Attempt to apply Poppins if present; otherwise fall back to project's theme default font
	var base_font = null
	# preferred Poppins paths (user-provided)
	var font_paths = ["res://assets/fonts/Poppins-Bold.ttf", "res://assets/fonts/Poppins-Medium.ttf", "res://assets/fonts/Poppins-Regular.ttf"]
	for p in font_paths:
		if ResourceLoader.exists(p):
			print("MainMenu: Found font file:", p)
			# loading the raw font file returns a DynamicFontData/FontFile resource which is used by theme fonts
			var fd = ResourceLoader.load(p)
			if fd:
				print("MainMenu: loaded font data resource type:", typeof(fd), fd)
				# Try to create a DynamicFont resource by loading an existing theme font and swapping its data
				var theme_path = "res://ui/theme/theme_default.tres"
				if ResourceLoader.exists(theme_path):
					var tref = ResourceLoader.load(theme_path)
					if tref and tref.has("default_font"):
						base_font = tref.get("default_font")
						# attempt to set font_data if available
						print("MainMenu: theme default_font type:", typeof(base_font), base_font)
						if base_font and base_font.has("font_data"):
							base_font.set("font_data", fd)
							print("MainMenu: set font_data on base_font")
						else:
							print("MainMenu: base_font has no 'font_data' property; will attempt later fallback.")
						break
	# fallback: use theme default font if present
	if not base_font:
		var theme_path2 = "res://ui/theme/theme_default.tres"
		if ResourceLoader.exists(theme_path2):
			var tref2 = ResourceLoader.load(theme_path2)
			if tref2 and tref2.has("default_font"):
				base_font = tref2.get("default_font")

	# apply fonts if loaded
	# Additionally try to load a direct font file and create explicit Font resources
	var explicit_fd = null
	for p in font_paths:
		if ResourceLoader.exists(p):
			explicit_fd = ResourceLoader.load(p)
			break

	var forced_title_font = null
	var forced_welcome_font = null
	var forced_button_font = null

	if explicit_fd:
		# Try several theme files to find a DynamicFont template to duplicate
		var theme_candidates = ["res://ui/theme/theme_default.tres", "res://ui/theme/theme_startmenu.tres", "res://ui/theme/theme_default.tres"]
		var template_font = null
		for tp in theme_candidates:
			if ResourceLoader.exists(tp):
				print("MainMenu: trying theme template", tp)
				var tref3 = ResourceLoader.load(tp)
				if tref3 and tref3.has("default_font"):
					template_font = tref3.get("default_font")
					break
		# If we found a template DynamicFont, duplicate and swap font_data
		if template_font:
			forced_title_font = template_font.duplicate()
			forced_title_font.set("font_data", explicit_fd)
			forced_title_font.size = 112
			forced_welcome_font = template_font.duplicate()
			forced_welcome_font.set("font_data", explicit_fd)
			forced_welcome_font.size = 22
			forced_button_font = template_font.duplicate()
			forced_button_font.set("font_data", explicit_fd)
			forced_button_font.size = 28
		else:
			print("MainMenu: no DynamicFont template found; fonts will fall back to theme or remain unchanged")

	if base_font or forced_button_font:
		print("MainMenu: applying base_font to title/welcome/buttons; base_font type:", typeof(base_font))
		# Title: larger size
		if forced_title_font:
			title_label.add_theme_font_override("font", forced_title_font)
		elif base_font:
			var title_font = base_font.duplicate()
			title_font.size = 112
			title_label.add_theme_font_override("font", title_font)
		# welcome label
		if forced_welcome_font:
			welcome_label.add_theme_font_override("font", forced_welcome_font)
		elif base_font:
			var welcome_font = base_font.duplicate()
			welcome_font.size = 22
			welcome_label.add_theme_font_override("font", welcome_font)
		# buttons
		for btn in [start_button, load_button, settings_button, exit_button]:
			if not btn:
				continue
			# prefer applying forced button font directly to child Label
			if forced_button_font:
				var child_lbl2 = btn.get_node_or_null("Label")
				if child_lbl2 and child_lbl2 is Label:
					child_lbl2.add_theme_font_override("font", forced_button_font)
				else:
					btn.add_theme_font_override("font", forced_button_font)
			elif base_font:
				var bfont = base_font.duplicate()
				bfont.size = 28
				var child_lbl = btn.get_node_or_null("Label")
				if child_lbl and child_lbl is Label:
					child_lbl.add_theme_font_override("font", bfont)
				else:
					btn.add_theme_font_override("font", bfont)

	# Load UI palette resource so runtime styleboxes/shaders use consistent colors
	var pal_path = "res://assets/ui/palette.tres"

	# 强制分配 Poppins 字体以确保在所有环境中可见
	_force_apply_poppins()

	if ResourceLoader.exists(pal_path):
		var pres = ResourceLoader.load(pal_path)
		if pres:
			var cols = null
			# try safe property access
			if pres.has_meta("colors"):
				cols = pres.get("colors")
			else:
				cols = pres.get("colors")
			if cols:
				ui_palette = cols

	# increase button size and spacing for better visual weight
	var vbox = $CenterContainer/VBoxContainer
	if vbox:
		vbox.add_theme_constant_override("separation", 26.0)

	# create reusable StyleBox and color overrides for a magical look
	var sb_normal = StyleBoxFlat.new()
	# palette-driven background/border
	var panel_col = ui_palette.get("ui_panel", Color(0.027451,0.101961,0.168627,1)) if ui_palette else Color(0.12, 0.05, 0.22, 0.94)
	var border_col = ui_palette.get("accent_dark", Color(0.164706,0.517647,0.780392,1)) if ui_palette else Color(0.45, 0.65, 0.95, 0.98)
	# normal state: no visible border to avoid rectangular frame showing
	var normal_border = border_col
	normal_border.a = 0.0
	# ensure fully opaque background so underlying parent doesn't show through corners
	panel_col.a = 1.0
	sb_normal.bg_color = panel_col
	sb_normal.border_color = normal_border
	sb_normal.border_width_left = 0
	sb_normal.border_width_top = 0
	sb_normal.border_width_right = 0
	sb_normal.border_width_bottom = 0
	sb_normal.corner_radius_top_left = 14
	sb_normal.corner_radius_top_right = 14
	sb_normal.corner_radius_bottom_right = 14
	sb_normal.corner_radius_bottom_left = 14
	sb_normal.content_margin_left = 18.0
	sb_normal.content_margin_right = 18.0
	sb_normal.shadow_size = 0
	sb_normal.shadow_offset = Vector2(0, 0)

	var sb_hover = StyleBoxFlat.new()
	var hover_bg = ui_palette.get("grad_top", Color(0.20, 0.50, 0.90, 0.98)) if ui_palette else Color(0.20, 0.50, 0.90, 0.98)
	var hover_border = ui_palette.get("accent", Color(0.435294,0.764706,1,1)) if ui_palette else Color(0.90, 0.98, 1.00, 1.00)
	# ensure hover background opaque
	hover_bg.a = 1.0
	sb_hover.bg_color = hover_bg
	sb_hover.border_color = hover_border
	sb_hover.border_width_left = 1
	sb_hover.border_width_top = 1
	sb_hover.border_width_right = 1
	sb_hover.border_width_bottom = 1
	sb_hover.corner_radius_top_left = 14
	sb_hover.corner_radius_top_right = 14
	sb_hover.corner_radius_bottom_right = 14
	sb_hover.corner_radius_bottom_left = 14
	sb_hover.content_margin_left = 18.0
	sb_hover.content_margin_right = 18.0
	sb_hover.shadow_size = 10
	sb_hover.shadow_offset = Vector2(0,2)

	var sb_pressed = StyleBoxFlat.new()
	var pressed_bg = ui_palette.get("bg_mid", Color(0.04, 0.06, 0.10, 1.0)) if ui_palette else Color(0.04, 0.06, 0.10, 1.0)
	var pressed_border = ui_palette.get("accent", Color(0.92, 0.76, 1.0, 0.98)) if ui_palette else Color(0.92, 0.76, 1.0, 0.98)
	# ensure pressed background opaque
	pressed_bg.a = 1.0
	sb_pressed.bg_color = pressed_bg
	sb_pressed.border_color = pressed_border
	sb_pressed.border_width_left = 1
	sb_pressed.border_width_top = 1
	sb_pressed.border_width_right = 1
	sb_pressed.border_width_bottom = 1
	sb_pressed.corner_radius_top_left = 12
	sb_pressed.corner_radius_top_right = 12
	sb_pressed.corner_radius_bottom_right = 12
	sb_pressed.corner_radius_bottom_left = 12
	sb_pressed.content_margin_left = 18.0
	sb_pressed.content_margin_right = 18.0
	sb_pressed.shadow_size = 6
	sb_pressed.shadow_offset = Vector2(0, 3)

	# icon map for buttons
	var icon_map = {start_button: "res://assets/ui/startmenu/icons/icon_start.svg", load_button: "res://assets/ui/startmenu/icons/icon_load.svg", settings_button: "res://assets/ui/startmenu/icons/icon_settings.svg", exit_button: "res://assets/ui/startmenu/icons/icon_exit.svg"}

	for btn in [start_button, load_button, settings_button, exit_button]:
		if not btn:
			continue
		# ensure button uses the menu theme so fonts/colors come from the applied theme
		if self.theme:
			btn.theme = self.theme
		# apply explicit size and stylebox overrides so editor/theme resources cannot hide changes
		btn.custom_minimum_size = Vector2(420, 72)
		# Apply styleboxes using property path (Godot 4 compatible)
		# Skip applying rectangular StyleBox overrides to TextureButton-derived controls
		if not (btn is TextureButton):
			btn.set("custom_styles/normal", sb_normal.duplicate())
			btn.set("custom_styles/hover", sb_hover.duplicate())
			btn.set("custom_styles/pressed", sb_pressed.duplicate())
		# Ensure child controls are clipped to the button rect so icons don't float above other panels
		btn.clip_contents = true
		btn.add_theme_color_override("font_color", Color(0.95, 0.92, 1.0))
		print("MainMenu: applied visual overrides to ", btn.name)
		# try assign icon if available and align it left
		var p = icon_map.get(btn, "")
		if p != "" and ResourceLoader.exists(p):
			var tex = load(p)
			if tex:
				# 使用专用 TextureRect 子节点来精确放置图标，确保左侧对齐并垂直居中
				var icon_node: TextureRect = btn.get_node_or_null("Icon")
				if not icon_node:
					icon_node = TextureRect.new()
					icon_node.name = "Icon"
					icon_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
					icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					# 通过锚点范围将图标垂直居中（约占按钮高度的中间 70% 区域）
					icon_node.anchor_left = 0.03
					icon_node.anchor_top = 0.15
					icon_node.anchor_right = 0.09
					icon_node.anchor_bottom = 0.85
					# 使用锚点宽度来为图标留白并设置固定最小尺寸，避免直接操作可能不存在的位置属性
					icon_node.custom_minimum_size = Vector2(36, 36)
					icon_node.z_index = 0
					btn.add_child(icon_node)
				# 更新纹理
				icon_node.texture = tex
		# apply animated text gradient shader to button text (use same shader as title)
		var text_sh_path = "res://ui/shaders/text_gradient.shader"
		if ResourceLoader.exists(text_sh_path):
			var sh = load(text_sh_path)
			if sh:
				var text_mat = ShaderMaterial.new()
				text_mat.shader = sh
				# slightly subtler noise for small text
				text_mat.set_shader_parameter("noise_strength", 0.04)
				# apply text shader to the button's label child so it doesn't override button drawing
				var lbl = btn.get_node_or_null("Label")
				if lbl and lbl is Label:
					lbl.material = text_mat
		# connect press/release visual effects (keep existing pressed handlers intact)
		btn.pressed.connect(Callable(self, "_on_button_pressed_effect").bind(btn))
		if btn.has_signal("released"):
			btn.released.connect(Callable(self, "_on_button_released_effect").bind(btn))
	# 2. Smart Buttons (Check for saves)
	var has_save = false
	for i in range(1, 4):
		if FileAccess.file_exists("user://save_%d.save" % i):
			has_save = true
			break
	
	if has_save:
		var _lbl = start_button.get_node_or_null("Label")
		if _lbl and _lbl is Label:
			_lbl.text = "继续旅程"
		else:
			if start_button.has_method("set"):
				start_button.set("text", "继续旅程")
		# Logic to load latest would go here, currently just maps to start logic which shows standard flow
	else:
		var _lbl2 = start_button.get_node_or_null("Label")
		if _lbl2 and _lbl2 is Label:
			_lbl2.text = "新的开始"
		else:
			if start_button.has_method("set"):
				start_button.set("text", "新的开始")
		# 即使没有存档，也应该允许用户打开存档菜单查看或确认
		# load_button.visible = false 

func _fix_mouse_filter(node: Node) -> void:
	if node is Control:
		if node is TextureRect or node is ColorRect or "Background" in node.name:
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif node is Button:
			node.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			# 容器类节点设为 PASS，允许点击穿透到子节点
			node.mouse_filter = Control.MOUSE_FILTER_PASS
			
	for child in node.get_children():
		_fix_mouse_filter(child)

func _on_button_hover(btn: Control) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "custom_minimum_size", Vector2(436, 78), 0.12)
	tween.parallel().tween_property(btn, "modulate", Color(1.04, 1.03, 1.0), 0.12) # 稍微发光
	# glow fade in
	var glow = btn.get_node_or_null("GlowRect")
	if glow:
		var gt = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# animate modulate alpha for compatibility; if shader material present, also animate intensity
		gt.tween_property(glow, "modulate:a", 0.28, 0.14)
		gt.parallel().tween_property(glow, "scale", Vector2(1.10, 1.10), 0.14)
		if glow.material and glow.material is ShaderMaterial:
			gt.parallel().tween_property(glow.material, "shader_param/intensity", 0.9, 0.14)

	# inner highlight fade in
	var inner = btn.get_node_or_null("InnerHighlight")
	if inner:
		var it = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		it.tween_property(inner, "modulate:a", 0.18, 0.12)

	# inner shadow fade in
	var shadow = btn.get_node_or_null("InnerShadow")
	if shadow:
		var st = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		st.tween_property(shadow, "modulate:a", 0.06, 0.10)

func _on_button_unhover(btn: Control) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "custom_minimum_size", Vector2(420, 72), 0.12)
	tween.parallel().tween_property(btn, "modulate", Color.WHITE, 0.12)
	# glow fade out
	var glow = btn.get_node_or_null("GlowRect")
	if glow:
		var gt = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		gt.tween_property(glow, "modulate:a", 0.04, 0.12)
		gt.parallel().tween_property(glow, "scale", Vector2(1.06, 1.06), 0.12)
		if glow.material and glow.material is ShaderMaterial:
			gt.parallel().tween_property(glow.material, "shader_param/intensity", 0.45, 0.12)

	# inner highlight fade out
	var inner = btn.get_node_or_null("InnerHighlight")
	if inner:
		var it = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		it.tween_property(inner, "modulate:a", 0.0, 0.12)

	# inner shadow fade out
	var shadow = btn.get_node_or_null("InnerShadow")
	if shadow:
		var st = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		st.tween_property(shadow, "modulate:a", 0.0, 0.12)

func _on_button_pressed_effect(btn: Control) -> void:
	# quick press animation to give tactile feedback
	var t = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.08)
	t.parallel().tween_property(btn, "modulate", Color(0.92, 0.9, 0.94), 0.08)

	# intensify inner shadow if present
	var shadow = btn.get_node_or_null("InnerShadow")
	if shadow:
		var gt = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		gt.tween_property(shadow, "color:a", min(shadow.color.a + 0.12, 0.9), 0.08)

func _on_button_released_effect(btn: Control) -> void:
	# revert press animation quickly; if hovered, keep hover size
	var target_scale = Vector2(1, 1)
	var target_mod = Color.WHITE
	if btn.get_tree().is_input_handled():
		# preserve default
		target_scale = Vector2(1, 1)
	# animate back
	var t = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(btn, "scale", target_scale, 0.12)
	t.parallel().tween_property(btn, "modulate", target_mod, 0.12)

	# relax inner shadow
	var shadow = btn.get_node_or_null("InnerShadow")
	if shadow:
		var gt = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		gt.tween_property(shadow, "color:a", 0.18, 0.12)

func _on_start_pressed() -> void:
	print("MainMenu: 开始按钮被点击")
	
	# 禁用交互
	start_button.disabled = true
	load_button.disabled = true
	exit_button.disabled = true
	
	# 播放过渡动画
	var tween = create_tween()
	# UI淡出
	tween.tween_property($CenterContainer, "modulate:a", 0.0, 0.3)
	# 整体变黑
	tween.parallel().tween_property(self, "modulate", Color(0,0,0,1), 0.8)
	
	await tween.finished
	
	GameManager.start_new_game()

func _hide_external_backgrounds() -> void:
	_hidden_backgrounds.clear()
	var root = get_tree().get_root()
	var self_path = str(self.get_path())

	_recurse_hide(root, self_path)

func _recurse_hide(node: Node, self_path: String) -> void:
	for child in node.get_children():
		# skip nodes that are part of this MainMenu instance
		var p = str(child.get_path())
		if p.begins_with(self_path):
			# skip our own children
			continue
		var name_l = str(child.name).to_lower()
		if name_l.find("background") != -1 or child is ParallaxBackground or child is TextureRect:
			if child.visible:
				child.visible = false
				_hidden_backgrounds.append(child)
		_recurse_hide(child, self_path)

func _show_external_backgrounds() -> void:
	for n in _hidden_backgrounds:
		if is_instance_valid(n):
			n.visible = true
	_hidden_backgrounds.clear()

func _on_load_pressed() -> void:
	print("MainMenu: 加载按钮被点击")
	UIManager.open_window("SaveSelection", "res://scenes/ui/SaveSelection.tscn")

func _on_settings_pressed() -> void:
	print("MainMenu: 设置按钮被点击")
	UIManager.open_window("SettingsWindow", "res://scenes/ui/settings/SettingsWindow.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_bg_period_changed(period: String, halo_color: Color) -> void:
	# Animate button glows to match background halo color
	for btn in [start_button, load_button, settings_button, exit_button]:
		if not btn: continue
		var glow = btn.get_node_or_null("GlowRect")
		if glow:
			var target = Color(halo_color.r, halo_color.g, halo_color.b, 0.28)
			var t = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			t.tween_property(glow, "color", target, 0.36)
		# update inner highlight shader params if present
		var inner = btn.get_node_or_null("InnerHighlight")
		if inner and inner.material and inner.material is ShaderMaterial:
			var mat: ShaderMaterial = inner.material
			var top = Color(halo_color.r, halo_color.g, halo_color.b, 0.30)
			var bottom = Color(halo_color.r * 0.78, halo_color.g * 0.78, halo_color.b * 0.78, 0.10)
			mat.set_shader_parameter("top_color", top)
			mat.set_shader_parameter("bottom_color", bottom)


func _force_apply_poppins() -> void:
	var font_paths = ["res://assets/fonts/Poppins-Bold.ttf", "res://assets/fonts/Poppins-Medium.ttf", "res://assets/fonts/Poppins-Regular.ttf"]
	var fd = null
	var found_path = ""
	for p in font_paths:
		if ResourceLoader.exists(p):
			fd = ResourceLoader.load(p)
			found_path = p
			break
	if not fd:
		print("MainMenu: Poppins font not found to force-assign")
		return

	# Create explicit DynamicFont instances and assign directly to controls
	# `fd` is expected to be a `FontFile`/font resource in Godot 4. Duplicate it for per-control sizes.
	var template_font = null
	var theme_candidates = ["res://ui/theme/theme_default.tres", "res://ui/theme/theme_startmenu.tres"]
	for tp in theme_candidates:
		if ResourceLoader.exists(tp):
			var tref = ResourceLoader.load(tp)
			if tref and tref.has("default_font"):
				template_font = tref.get("default_font")
				break

	var title_f = null
	var welcome_f = null
	var btn_f = null
	if template_font:
		title_f = template_font.duplicate()
		title_f.set("font_data", fd)
		title_f.set("size", 112)
		welcome_f = template_font.duplicate()
		welcome_f.set("font_data", fd)
		welcome_f.set("size", 22)
		btn_f = template_font.duplicate()
		btn_f.set("font_data", fd)
		btn_f.set("size", 28)
	else:
		# Fallback: assign the raw FontFile (no per-control size)
		title_f = fd
		welcome_f = fd
		btn_f = fd

	if title_label and title_label is Label:
		title_label.set("custom_fonts/font", title_f)

	if welcome_label and welcome_label is Label:
		welcome_label.set("custom_fonts/font", welcome_f)

	for btn in [start_button, load_button, settings_button, exit_button]:
		if not btn:
			continue
		var lbl = btn.get_node_or_null("Label")
		if lbl and lbl is Label:
			lbl.set("custom_fonts/font", btn_f)
		else:
			btn.set("custom_fonts/font", btn_f)

	print("MainMenu: forced Poppins font assigned from", found_path)
