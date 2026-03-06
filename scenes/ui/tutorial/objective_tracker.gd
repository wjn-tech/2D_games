extends CanvasLayer
class_name ObjectiveTracker

@onready var container: PanelContainer = $Container
@onready var label: Label = $Container/HBox/Label
@onready var check: TextureRect = $Container/HBox/Check
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	container.visible = false
	current_objective = ""

var current_objective: String = ""

func show_objective(text: String) -> void:
	current_objective = text
	label.text = text
	check.visible = false
	container.visible = true
	
	if anim.has_animation("slide_in"):
		anim.play("slide_in")
	else:
		# Fallback visuals
		container.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(container, "modulate:a", 1.0, 0.3)

func complete_objective() -> void:
	check.visible = true
	label.add_theme_color_override("font_color", Color.GREEN)
	
	if anim.has_animation("complete"):
		anim.play("complete")
	
	# Auto-hide after delay (Revised safe logic)
	if is_inside_tree() and get_tree():
		var timer = get_tree().create_timer(3.0)
		timer.timeout.connect(hide_objective)
	else:
		# Fallback: Create standalone timer node
		var timer_node = Timer.new()
		timer_node.wait_time = 3.0
		timer_node.one_shot = true
		timer_node.autostart = true
		add_child(timer_node)
		timer_node.timeout.connect(func(): 
			hide_objective()
			timer_node.queue_free()
		)

func hide_objective() -> void:
	var tween = create_tween()
	tween.tween_property(container, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): container.visible = false)
