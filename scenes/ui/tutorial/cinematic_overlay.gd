extends CanvasLayer
class_name CinematicOverlay

signal sequence_finished
signal step_changed(step: int)

@onready var bg: ColorRect = $BG
@onready var image: TextureRect = $Image
@onready var content: MarginContainer = $Content
@onready var text_panel: PanelContainer = $Content/TextPanel
@onready var subtitle: RichTextLabel = $Content/TextPanel/Subtitle

# Current state
var _sequence_data: Array = []
var _current_index: int = 0
var _timer: Timer

func _ready() -> void:
	visible = false
	if not bg: bg = get_node_or_null("BG")
	if bg:
		bg.color = Color.BLACK
	
	if not _timer:
		_timer = Timer.new()
		_timer.one_shot = true
		add_child(_timer)
		_timer.timeout.connect(_on_timer_timeout)

func play_sequence(data: Array) -> void:
	if not is_node_ready():
		await ready
		
	if data.is_empty():
		sequence_finished.emit()
		return
	
	_sequence_data = data
	_current_index = 0
	visible = true
	
	# Initial Setup: Fade in BG
	if bg:
		bg.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(bg, "modulate:a", 1.0, 0.5)
	
	_show_step(_sequence_data[0])

func _show_step(step: Dictionary) -> void:
	var img = step.get("image", null)
	var txt = step.get("text", "")
	var dur = step.get("duration", 3.0)
	
	if image:
		if img and img is Texture2D:
			image.texture = img
			image.visible = true
		else:
			image.visible = false
			
	if subtitle:
		subtitle.text = "[center][color=white]%s[/color][/center]" % txt
		
	if text_panel:
		text_panel.visible = not txt.is_empty()
		
	step_changed.emit(_current_index)
	_timer.start(dur)

func _on_timer_timeout() -> void:
	_current_index += 1
	if _current_index < _sequence_data.size():
		# Crossfade image logic could go here, for now just swap
		_show_step(_sequence_data[_current_index])
	else:
		_finish_sequence()

func _finish_sequence() -> void:
	# Fade out before closing
	var tween = create_tween()
	if bg:
		tween.tween_property(bg, "modulate:a", 0.0, 0.8)
	if content:
		tween.parallel().tween_property(content, "modulate:a", 0.0, 0.5)
		
	tween.tween_callback(func():
		visible = false
		sequence_finished.emit())

func _process(delta: float) -> void:
	if visible and Input.is_action_just_pressed("ui_accept"):
		if _timer.time_left > 0.5:
			_timer.stop()
			_on_timer_timeout()
