@tool
extends Node2D
class_name MinimalistEntity

enum Shape { RECT, CIRCLE, TRIANGLE, DIAMOND, HEXAGON }

@export var shape: Shape = Shape.RECT:
	set(v): shape = v; queue_redraw()
@export var color: Color = Color.WHITE:
	set(v): color = v; queue_redraw()
@export var size: Vector2 = Vector2(16, 16):
	set(v): size = v; queue_redraw()
@export var outline_width: float = 1.0:
	set(v): outline_width = v; queue_redraw()
@export var pulse_speed: float = 0.0:
	set(v): pulse_speed = v; queue_redraw()

# --- New Visual Features (Occupation) ---
@export var occupation_type: String = "": # "Merchant", "Guard", etc.
	set(v): occupation_type = v; queue_redraw()

var _pulse_phase: float = 0.0

# --- User Configurable Style Map ---
const STYLE_MAP = {
	"Player": {"shape": Shape.RECT, "color": Color(0.2, 0.5, 0.9), "size": Vector2(14, 26), "outline_width": 2.0},
	"公主": {"shape": Shape.RECT, "color": Color(0.9, 0.4, 0.7), "size": Vector2(14, 26), "outline_width": 2.0},
	"Child": {"shape": Shape.RECT, "color": Color(0.5, 0.7, 1.0), "size": Vector2(14, 26), "outline_width": 1.5},
	"Child of": {"shape": Shape.RECT, "color": Color(0.5, 0.7, 1.0), "size": Vector2(14, 26), "outline_width": 1.5},
	"Slime": {"shape": Shape.TRIANGLE, "color": Color(1.0, 0.3, 0.3), "pulse": 2.0},
	"Skeleton": {"shape": Shape.RECT, "color": Color(0.8, 0.8, 0.8), "size": Vector2(14, 24)},
	"Zombie": {"shape": Shape.RECT, "color": Color(0.3, 0.5, 0.3), "size": Vector2(16, 26)},
	"Bat": {"shape": Shape.DIAMOND, "color": Color(0.4, 0.3, 0.5), "pulse": 5.0, "size": Vector2(16, 12)},
	"Ghost": {"shape": Shape.CIRCLE, "color": Color(0.8, 0.9, 1.0, 0.7), "pulse": 1.0},
	
	# Type Fallbacks (Ark-style/Role-style)
	"Town": {"shape": Shape.RECT, "color": Color(0.9, 0.9, 0.9), "size": Vector2(14, 26), "outline_width": 2.0},
	"Animal": {"shape": Shape.CIRCLE, "color": Color(0.7, 0.7, 0.7), "size": Vector2(16, 10)},
	
	# Default Defaults
	"Hostile": {"shape": Shape.DIAMOND, "color": Color(0.9, 0.3, 0.3)},
	"Friendly": {"shape": Shape.RECT, "color": Color(0.9, 0.9, 0.9), "size": Vector2(14, 26)},
	"Neutral": {"shape": Shape.RECT, "color": Color(0.9, 0.9, 0.5), "size": Vector2(14, 26)}
}

func _enter_tree() -> void:
	queue_redraw()

func _ready() -> void:
	queue_redraw()

func setup_from_npc(npc_data_name: String, alignment: String, _ai_type: int, npc_type: String = "") -> void:
	# 1. Look for specific name match
	var config = {}
	if STYLE_MAP.has(npc_data_name):
		config = STYLE_MAP[npc_data_name]
	else:
		# 2. Look for partial match (e.g. "Blue Slime" -> "Slime")
		for key in STYLE_MAP:
			if npc_data_name.contains(key):
				config = STYLE_MAP[key]
				break
	
	# 3. Look for type match (e.g. "Town", "Animal")
	if config.is_empty() and STYLE_MAP.has(npc_type):
		config = STYLE_MAP[npc_type]
	
	# 4. Fallback to alignment
	if config.is_empty():
		config = STYLE_MAP.get(alignment, STYLE_MAP["Neutral"])
	
	# Apply
	if config.has("shape"): shape = config.shape
	if config.has("color"): color = config.color
	if config.has("size"): size = config.size
	if config.has("pulse"): pulse_speed = config.pulse
	
	queue_redraw()

func _process(delta: float) -> void:
	if pulse_speed > 0:
		_pulse_phase += delta * pulse_speed
		queue_redraw()

func _draw() -> void:
	var draw_color = color
	if pulse_speed > 0:
		# Breathing effect
		var alpha_mod = 1.0
		if draw_color.a < 1.0: # If already transparent, modulate that
			draw_color.a = draw_color.a * (0.8 + 0.2 * sin(_pulse_phase))
		else:
			draw_color = draw_color.lightened(0.1 * sin(_pulse_phase))
	
	var bal_scale = 1.0
	if pulse_speed > 2.0: # Fast pulse modifies scale slightly (like beating heart)
		bal_scale = 1.0 + 0.05 * sin(_pulse_phase)
		
	var s = size * bal_scale
	var half = s / 2.0
	
	# Draw Shadow (simple offset)
	var shadow_offset = Vector2(2, 2)
	_draw_shape_primitive(shape, Vector2.ZERO + shadow_offset, s, Color(0,0,0, 0.3 * draw_color.a), false)
	
	# Draw Main
	_draw_shape_primitive(shape, Vector2.ZERO, s, draw_color, true)
	
	if occupation_type != "":
		_draw_occupation_badge(s)

func _draw_occupation_badge(main_size: Vector2) -> void:
	# Draw badge at bottom-right corner
	var badge_pos = main_size * 0.35
	
	# Simple primitive icons based on string
	match occupation_type:
		"Merchant", "Trader":
			# Coin shape (Yellow Circle)
			draw_circle(badge_pos, 4, Color.GOLD)
			draw_arc(badge_pos, 4, 0, TAU, 8, Color.BLACK, 1.0)
			# $ sign
			draw_line(badge_pos + Vector2(0, -2), badge_pos + Vector2(0, 2), Color.BLACK, 1.0)
		"Guard", "Soldier":
			# Shield shape (Blue Rect)
			var rect = Rect2(badge_pos - Vector2(3,4), Vector2(6, 8))
			draw_rect(rect, Color.CORNFLOWER_BLUE)
			draw_rect(rect, Color.BLACK, false, 1.0)
		"Blacksmith":
			# Anvilish (Gray Rect)
			var rect = Rect2(badge_pos - Vector2(4,2), Vector2(8, 4))
			draw_rect(rect, Color.DIM_GRAY)
			draw_rect(rect, Color.BLACK, false, 1.0)
		_:
			# Generic Badge (White Dot)
			draw_circle(badge_pos, 3, Color.WHITE)
			draw_arc(badge_pos, 3, 0, TAU, 8, Color.BLACK, 1.0)

func _draw_shape_primitive(shp: Shape, center: Vector2, sz: Vector2, col: Color, outline: bool) -> void:
	var h = sz / 2.0
	match shp:
		Shape.RECT:
			draw_rect(Rect2(center - h, sz), col, true)
			if outline: draw_rect(Rect2(center - h, sz), Color.BLACK, false, outline_width)
			
		Shape.CIRCLE:
			var r = min(h.x, h.y)
			draw_circle(center, r, col)
			if outline: draw_arc(center, r, 0, TAU, 32, Color.BLACK, outline_width)
			
		Shape.TRIANGLE:
			# Isosceles pointing up
			# Top, BottomRight, BottomLeft
			var pts = PackedVector2Array([
				center + Vector2(0, -h.y),
				center + Vector2(h.x, h.y),
				center + Vector2(-h.x, h.y)
			])
			draw_colored_polygon(pts, col)
			if outline: 
				pts.append(pts[0]) # Close loop
				draw_polyline(pts, Color.BLACK, outline_width)
				
		Shape.DIAMOND:
			var pts = PackedVector2Array([
				center + Vector2(0, -h.y),
				center + Vector2(h.x, 0),
				center + Vector2(0, h.y),
				center + Vector2(-h.x, 0)
			])
			draw_colored_polygon(pts, col)
			if outline:
				pts.append(pts[0])
				draw_polyline(pts, Color.BLACK, outline_width)
