extends RichTextLabel
class_name GradientTitle

@export var top_color: Color = Color(0.98,0.86,1.0)
@export var mid_color: Color = Color(0.68,0.52,1.0)
@export var bottom_color: Color = Color(0.35,0.20,0.80)
@export var speed: float = 1.0
@export var wobble_amplitude: float = 2.0
@export var font_size: int = 96

var _plain_text: String = ""

func _ready() -> void:
	bbcode_enabled = true
	scroll_active = false

	# Attach low-level RichTextEffect for per-character transforms when available
	var eff = null
	# Attempt to instantiate the `GradientEffect` class (defined in gradient_effect.gd)
	if typeof(GradientEffect) != TYPE_NIL:
		eff = GradientEffect.new()
	if eff:
		eff.top_color = top_color
		eff.mid_color = mid_color
		eff.bottom_color = bottom_color
		eff.speed = speed
		# assign as sole custom effect (overwrites existing)
		if self.has_method("set"):
			self.set("custom_effects", [eff])
	# capture initial text if any
	_plain_text = (text if text != "" else "")
	if _plain_text == "":
		_plain_text = "星海之旅"
	set_v_size_flags(Control.SIZE_SHRINK_END)
	set_custom_minimum_size(Vector2(900, 160))

	# Center alignment and font sizing
	if has_method("set_h_size_flags"):
		horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if has_method("add_theme_font_size_override"):
		add_theme_font_size_override("normal_font_size", font_size)

	# If gradient shader exists, apply it to get per-glyph internal gradient fill
	var shader_path = "res://ui/shaders/text_gradient.shader"
	if ResourceLoader.exists(shader_path):
		var sh = ResourceLoader.load(shader_path)
		if sh:
			var mat = ShaderMaterial.new()
			mat.shader = sh
			# sensible defaults
			mat.set_shader_parameter("top_color", top_color)
			mat.set_shader_parameter("mid_color", mid_color)
			mat.set_shader_parameter("bottom_color", bottom_color)
			# assign material to this RichTextLabel so the shader shades glyph interior
			material = mat

func set_title_text(t: String) -> void:
	_plain_text = t
	_update_bbcode(0.0)

func _process(delta: float) -> void:
	var t = Time.get_ticks_msec() / 1000.0
	# update shader time if present
	if material and material is ShaderMaterial:
		material.set_shader_parameter("time", t)
		# when shader present we just ensure plain text is shown
		_update_bbcode(t)
		return
	_update_bbcode(t)
func _update_bbcode(time_s: float) -> void:
	var s = _plain_text
	var len = s.length()
	if len == 0:
		text = ""
		return
	# Prefer direct RichTextLabel API (push_color/add_text/pop) to avoid BBCode escaping issues.
	var use_rich_api = has_method("push_color") and has_method("add_text") and has_method("pop")
	var parts: Array = []
	if use_rich_api:
		# If a glyph-fill shader is active, just show plain text and let shader fill glyphs.
		if material and material is ShaderMaterial:
			text = _plain_text
			return
		clear()
		for i in range(len):
			var ch = s[i]
			# compute relative position 0..1
			var rel = 0.0
			if len > 1:
				rel = float(i) / float(len - 1)
			# mix top->mid->bottom at 0..0.5..1.0
			var col: Color
			if rel < 0.5:
				col = top_color.lerp(mid_color, rel / 0.5)
			else:
				col = mid_color.lerp(bottom_color, (rel - 0.5) / 0.5)
			# add time-based brightness pulse
			var pulse = 0.15 * sin(time_s * speed + float(i) * 0.35)
			col = Color(clamp(col.r + pulse, 0.0, 1.0), clamp(col.g + pulse, 0.0, 1.0), clamp(col.b + pulse, 0.0, 1.0))
			push_color(col)
			add_text(ch)
			pop()
	else:
		for i in range(len):
			var ch = s[i]
			var rel = 0.0
			if len > 1:
				rel = float(i) / float(len - 1)
			var col: Color
			if rel < 0.5:
				col = top_color.lerp(mid_color, rel / 0.5)
			else:
				col = mid_color.lerp(bottom_color, (rel - 0.5) / 0.5)
			var pulse = 0.15 * sin(time_s * speed + float(i) * 0.35)
			col = Color(clamp(col.r + pulse, 0.0, 1.0), clamp(col.g + pulse, 0.0, 1.0), clamp(col.b + pulse, 0.0, 1.0))
			var hex = "#%02x%02x%02x" % [int(col.r * 255), int(col.g * 255), int(col.b * 255)]
			var inner = ch
			if ch == '[' or ch == ']':
				inner = "[noparse]" + ch + "[/noparse]"
			parts.append("[color=" + hex + "]" + inner + "[/color]")
		text = "".join(parts)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		# keep font size responsive (not fully implemented)
		pass
