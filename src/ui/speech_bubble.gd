extends Control
class_name SpeechBubble

@onready var label: Label = $PanelContainer/MarginContainer/Label
@onready var timer: Timer = $Timer
@onready var panel: PanelContainer = $PanelContainer

func _ready():
	hide()
	panel.scale = Vector2.ZERO

func show_text(text: String, duration: float = 3.0):
	label.text = text
	show()
	
	# 简单的弹出动画
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	timer.start(duration)

func _on_timer_timeout():
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	hide()
