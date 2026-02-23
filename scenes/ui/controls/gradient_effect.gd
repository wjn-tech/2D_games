extends RichTextEffect
class_name GradientEffect

@export var top_color: Color = Color(0.98,0.86,1.0)
@export var mid_color: Color = Color(0.68,0.52,1.0)
@export var bottom_color: Color = Color(0.35,0.20,0.80)
@export var speed: float = 1.0
@export var wobble_amplitude: float = 4.0

# Per-character RichTextEffect implementation using the CharFXTransform API.
# This implementation is defensive: it probes for common properties (char_index, char_count,
# modulate, offset) via `get` and uses `set` to apply results when available.
func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	if char_fx == null:
		return false
	var idx = 0
	var count = 1
	# Try read common indices/counts
	if char_fx.has_method("get"):
		var v = char_fx.get("char_index")
		if typeof(v) == TYPE_INT:
			idx = v
		else:
			v = char_fx.get("index")
			if typeof(v) == TYPE_INT:
				idx = v
		var vc = char_fx.get("char_count")
		if typeof(vc) == TYPE_INT and vc > 0:
			count = vc

	var rel = 0.0
	if count > 1:
		rel = float(idx) / float(max(1, count - 1))

	# compute gradient color
	var col: Color
	if rel < 0.5:
		col = top_color.lerp(mid_color, rel / 0.5)
	else:
		col = mid_color.lerp(bottom_color, (rel - 0.5) / 0.5)

	# apply subtle pulse/wobble
	var t = Time.get_ticks_msec() / 1000.0
	var pulse = 0.12 * sin(t * speed + float(idx) * 0.35)
	col = Color(clamp(col.r + pulse, 0.0, 1.0), clamp(col.g + pulse, 0.0, 1.0), clamp(col.b + pulse, 0.0, 1.0))

	# set modulate/color if supported
	if char_fx.has_method("set"):
		# try common property names
		if char_fx.get("modulate") != null:
			char_fx.set("modulate", col)
		elif char_fx.get("color") != null:
			char_fx.set("color", col)

	# apply small vertical offset wobble if offset property exists
	var wob = sin(t * speed + float(idx) * 0.4) * wobble_amplitude
	var off = null
	if char_fx.has_method("get"):
		off = char_fx.get("offset")
	if off != null and typeof(off) == TYPE_VECTOR2:
		off.y += wob
		if char_fx.has_method("set"):
			char_fx.set("offset", off)
	elif char_fx.has_method("set"):
		# fallback: try small translation fields if present
		var ox = char_fx.get("offset_x")
		if typeof(ox) == TYPE_FLOAT:
			var oy = char_fx.get("offset_y")
			if typeof(oy) == TYPE_FLOAT:
				char_fx.set("offset_x", ox)
				char_fx.set("offset_y", oy + wob)
	return true
