extends Control

@onready var resume_button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var quit_button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_resume_pressed() -> void:
	GameManager.change_state(GameManager.State.PLAYING)

func _on_quit_pressed() -> void:
    # 打开存档选择界面，处于“保存模式”
	var win = UIManager.open_window("SaveSelection", "res://scenes/ui/SaveSelection.tscn")
	if win:
		win.set_mode("save")

