extends Node2D
class_name LightningVisualizer

# --- CONFIGURATION ---
@export var segments: int = 10
@export var jitter_width: float = 10.0
@export var thickness: float = 2.0
@export var color: Color = Color(2, 2, 5) # HDR Blue

# --- INTERNAL ---
var _line: Line2D
var _light: PointLight2D
var _fragments: GPUParticles2D

func _ready():
	_line = Line2D.new()
	_line.width = thickness
	_line.default_color = color
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_line.texture_mode = Line2D.LINE_TEXTURE_NONE
	# Additive blending for electricity
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_line.material = mat
	add_child(_line)
	
	_light = PointLight2D.new()
	_light.texture = _create_soft_glow_texture()
	_light.color = color
	_light.texture_scale = 2.0
	_light.energy = 2.0
	add_child(_light)

func play_zap(start_pos: Vector2, end_pos: Vector2):
	# Generate ZigZag Points
	var points = []
	points.append(start_pos)
	
	var segment_vec = (end_pos - start_pos) / segments
	var current_pos = start_pos
	
	for i in range(1, segments):
		var base_point = start_pos + segment_vec * i
		# Offset perpendicular to direction?
		# Simple random offset is enough for chaos
		var offset = Vector2(randf_range(-jitter_width, jitter_width), randf_range(-jitter_width, jitter_width))
		points.append(base_point + offset)
	
	points.append(end_pos)
	_line.points = PackedVector2Array(points)
	
	# Light at mid point
	_light.position = (start_pos + end_pos) / 2.0
	
	# Animate Dissolve
	var tween = create_tween()
	# Flash bright then fade
	tween.tween_property(_line, "width", 0.0, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_line, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(_light, "energy", 0.0, 0.2)
	tween.tween_callback(queue_free)

func _create_soft_glow_texture() -> Texture2D:
	var grad = Gradient.new()
	grad.colors = [Color(1,1,1,1), Color(1,1,1,0)]
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1, 1)
	tex.width = 64
	tex.height = 64
	return tex
