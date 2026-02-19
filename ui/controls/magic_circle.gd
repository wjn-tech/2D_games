extends Control

@export var ring_count: int = 3
@export var base_radius: float = 220.0
@export var spacing: float = 18.0
@export var thickness: float = 4.0
@export var rotate_speed: float = 0.02
@export var color: Color = Color(0.6, 0.4, 1.0, 0.28)

var t: float = 0.0

func _ready() -> void:
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	t += delta
	rotation += rotate_speed * delta
	queue_redraw()

func _draw() -> void:
	var center = Vector2(size.x * 0.5, size.y * 0.45)
	for i in range(ring_count):
		var r = base_radius - i * spacing
		var alpha = color.a * (1.0 - float(i) * 0.18)
		var col = Color(color.r, color.g, color.b, alpha)
		# draw subtle segmented arc for mystic feel
		var segments = 48
		var seg_angle = TAU / float(segments)
		for s in range(segments):
			var start_a = float(s) * seg_angle + t * (0.1 + 0.02 * i)
			var end_a = start_a + seg_angle * 0.6
			draw_arc(center, r, start_a, end_a, segments, col, thickness)
