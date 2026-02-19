extends TextureButton

# RoundedTextureButton: generates rounded rect textures for normal/hover/pressed
# Usage: call `setup(text, icon_texture, colors, size)` after creating instance

@export var corner_radius: float = 14.0
@export var texture_size: int = 128

var label: Label
var icon_node: TextureRect
static var _tex_cache: Dictionary = {}
static var _warned_zero_image: bool = false

func _init():
	pass

func _ready():
	# ensure children exist
	if not label:
		label = Label.new()
		label.name = "Label"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.anchor_left = 0.0
		label.anchor_top = 0.0
		label.anchor_right = 1.0
		label.anchor_bottom = 1.0
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
	if not icon_node:
		icon_node = TextureRect.new()
		icon_node.name = "Icon"
		icon_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_node.anchor_left = 0.03
		icon_node.anchor_top = 0.15
		icon_node.anchor_right = 0.09
		icon_node.anchor_bottom = 0.85
		icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(icon_node)

	# performance / visual tweaks
	# Prevent editor/theme focus rectangle from drawing a rectangular outline over our rounded texture
	focus_mode = Control.FOCUS_NONE
	# ensure child content is clipped to rounded texture alpha region
	clip_contents = true

func setup(text: String, icon_tex: Texture, bg_color: Color, hover_color: Color, pressed_color: Color, size: Vector2):
	# set sizes
	custom_minimum_size = size
	# set label text
	if not label:
		label = get_node_or_null("Label")
		if not label:
			label = Label.new()
			label.name = "Label"
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.anchor_left = 0.0
			label.anchor_top = 0.0
			label.anchor_right = 1.0
			label.anchor_bottom = 1.0
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(label)
	label.text = text
	# set icon
	if icon_tex:
		if not icon_node:
			icon_node = get_node_or_null("Icon")
			if not icon_node:
				icon_node = TextureRect.new()
				icon_node.name = "Icon"
				icon_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
				icon_node.anchor_left = 0.03
				icon_node.anchor_top = 0.15
				icon_node.anchor_right = 0.09
				icon_node.anchor_bottom = 0.85
				icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				add_child(icon_node)
		icon_node.texture = icon_tex
	# generate textures
	var normal_tex = _gen_rounded_texture(bg_color)
	var hover_tex = _gen_rounded_texture(hover_color)
	var pressed_tex = _gen_rounded_texture(pressed_color)
	self.texture_normal = normal_tex
	self.texture_hover = hover_tex
	self.texture_pressed = pressed_tex


func _gen_rounded_texture(color: Color) -> Texture2D:
	# Ensure a valid texture size (editor might set exported `texture_size` to 0)
	var tex_size = int(texture_size)
	if tex_size < 2:
		# try to derive reasonable size from the control's minimum size
		var w = int(custom_minimum_size.x) if custom_minimum_size else 0
		var h = int(custom_minimum_size.y) if custom_minimum_size else 0
		tex_size = max(2, w, h, 128)

	# cap texture size to avoid very expensive generation and huge images
	var MAX_TEX = 256
	tex_size = int(clamp(tex_size, 32, MAX_TEX))

	# simple cache key based on color, size and radius
	var key = "%f_%f_%f_%f_%d_%f" % [color.r, color.g, color.b, color.a, tex_size, corner_radius]
	if _tex_cache.has(key):
		return _tex_cache[key]

	var img = Image.new()
	img.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)

	# defensive: ensure image was created with expected dimensions
	if img.get_width() <= 0 or img.get_height() <= 0:
		if not _warned_zero_image:
			_warned_zero_image = true
			printerr("RoundedTextureButton: Image.create() returned zero size (tex_size=", tex_size, "). Falling back to 1x1 placeholder.")
		# return a 1x1 transparent texture to avoid repeated crashes
		var tiny = Image.new()
		tiny.create(1, 1, false, Image.FORMAT_RGBA8)
		tiny.set_pixel(0, 0, Color(0,0,0,0))
		var ttex = ImageTexture.create_from_image(tiny)
		_tex_cache[key] = ttex
		return ttex

	var denom = float(max(tex_size - 1, 1))
	for y in range(tex_size):
		for x in range(tex_size):
			var uv = Vector2(float(x) / denom, float(y) / denom)
			# signed distance to rounded rect
			var center = Vector2(0.5, 0.5)
			var r = corner_radius / float(tex_size) * 0.5 * 2.0
			var q = (uv - center).abs() - (Vector2(0.5, 0.5) - Vector2(r, r))
			var mq = Vector2(max(q.x, 0.0), max(q.y, 0.0))
			var dist = mq.length() - min(max(q.x, q.y), 0.0)
			# anti-aliased edge
			var aa = 1.0 / float(tex_size) * 2.0
			var alpha = clamp(1.0 - smoothstep(0.0, aa, dist), 0.0, 1.0)
			img.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * alpha))

	var tex = ImageTexture.create_from_image(img)
	_tex_cache[key] = tex
	return tex

# utility smoothstep
func smoothstep(edge0: float, edge1: float, x: float) -> float:
	if x <= edge0:
		return 0.0
	elif x >= edge1:
		return 1.0
	x = (x - edge0) / (edge1 - edge0)
	return x * x * (3.0 - 2.0 * x)
