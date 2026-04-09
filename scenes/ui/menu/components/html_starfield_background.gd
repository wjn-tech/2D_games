extends Control

# HTML canvas-style menu background transplanted from mainmenu00/src/app/page.tsx.

@export var star_count: int = 200
@export var max_meteors: int = 3
@export var meteor_spawn_rate: float = 1.2 # approx 0.02 per 60fps frame
@export var galaxy_center_ratio: Vector2 = Vector2(0.7, 0.3)
@export var galaxy_base_radius: float = 150.0
@export var galaxy_rotation_speed: float = 0.06 # approx 0.001 per frame @ 60fps

const BG_COLOR := Color(0.039, 0.039, 0.102, 1.0) # #0a0a1a
const GALAXY_COLOR := Color(0.541, 0.169, 0.886, 1.0) # #8a2be2

var _stars: Array = []
var _meteors: Array = []
var _galaxy_rotation: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_reset_stars()
	set_process(true)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_reset_stars()


func _reset_stars() -> void:
	_stars.clear()
	var width := maxf(size.x, 1.0)
	var height := maxf(size.y, 1.0)
	for i in range(star_count):
		_stars.append({
			"x": randf() * width,
			"y": randf() * height,
			"size": randf() * 2.0 + 0.5,
			"speed": randf() * 30.0 + 6.0,
			"opacity": randf(),
			"twinkle": randf() * TAU
		})


func _process(delta: float) -> void:
	var width := maxf(size.x, 1.0)
	var height := maxf(size.y, 1.0)

	_galaxy_rotation += galaxy_rotation_speed * delta

	for star in _stars:
		star.twinkle += 0.6 * delta
		star.opacity = 0.5 + sin(star.twinkle) * 0.5
		star.y += star.speed * delta
		if star.y > height:
			star.y = 0.0
			star.x = randf() * width

	if _meteors.size() < max_meteors and randf() < meteor_spawn_rate * delta:
		_meteors.append({
			"x": randf() * width,
			"y": 0.0,
			"length": randf() * 80.0 + 40.0,
			"speed": randf() * 480.0 + 240.0,
			"opacity": 1.0,
			"angle": PI / 4.0 + randf() * 0.2
		})

	for i in range(_meteors.size() - 1, -1, -1):
		var meteor = _meteors[i]
		meteor.x += cos(meteor.angle) * meteor.speed * delta
		meteor.y += sin(meteor.angle) * meteor.speed * delta
		meteor.opacity -= 0.6 * delta
		if meteor.opacity <= 0.0 or meteor.y > height:
			_meteors.remove_at(i)

	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR, true)
	_draw_galaxy_layers()
	_draw_stars()
	_draw_meteors()


func _draw_galaxy_layers() -> void:
	var center := Vector2(size.x * galaxy_center_ratio.x, size.y * galaxy_center_ratio.y)
	for layer in range(3):
		var radius := galaxy_base_radius + layer * 50.0
		var direction := 1.0 if layer % 2 == 0 else -1.0
		var layer_rot := _galaxy_rotation * direction * (1.0 + layer * 0.2)
		for i in range(200):
			var t := float(i) / 200.0
			var angle := t * PI * 4.0 + layer_rot
			var dist := t * radius
			var p := center + Vector2(cos(angle), sin(angle)) * dist
			var alpha := (0.1 + t * 0.2) * (0.3 + layer * 0.2)
			var dot_size := 1.0 + randf() * 2.0
			draw_rect(Rect2(p, Vector2(dot_size, dot_size)), Color(GALAXY_COLOR.r, GALAXY_COLOR.g, GALAXY_COLOR.b, alpha), true)


func _draw_stars() -> void:
	for star in _stars:
		var c := Color(1.0, 1.0, 1.0, star.opacity)
		var pos := Vector2(star.x, star.y)
		var s := float(star.size)
		draw_rect(Rect2(pos, Vector2(s, s)), c, true)
		if s > 1.5:
			var glow := Color(1.0, 1.0, 1.0, star.opacity * 0.3)
			draw_rect(Rect2(Vector2(pos.x - s * 2.0, pos.y), Vector2(s * 4.0, s)), glow, true)
			draw_rect(Rect2(Vector2(pos.x, pos.y - s * 2.0), Vector2(s, s * 4.0)), glow, true)


func _draw_meteors() -> void:
	for meteor_value in _meteors:
		var meteor: Dictionary = meteor_value
		var head: Vector2 = Vector2(float(meteor.x), float(meteor.y))
		var angle: float = float(meteor.angle)
		var length: float = float(meteor.length)
		var tail: Vector2 = head - Vector2(cos(angle), sin(angle)) * length
		var segments: int = 14
		for i in range(segments):
			var t0: float = float(i) / float(segments)
			var t1: float = float(i + 1) / float(segments)
			var p0: Vector2 = head.lerp(tail, t0)
			var p1: Vector2 = head.lerp(tail, t1)
			var a: float = float(meteor.opacity) * (1.0 - t0)
			draw_line(p0, p1, Color(1.0, 1.0, 1.0, a), 2.0)
		draw_rect(Rect2(head - Vector2.ONE, Vector2(3.0, 3.0)), Color(1.0, 1.0, 1.0, float(meteor.opacity)), true)
