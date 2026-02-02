extends Control

@onready var name_label = find_child("NameLabel")
@onready var text_label = find_child("TextLabel")
@onready var next_button = find_child("NextButton")
@onready var options_container = find_child("OptionsContainer")

var _lines: Array = []
var _options: Array = []
var _current_line: int = 0

func _ready() -> void:
	if next_button:
		next_button.pressed.connect(_on_next_pressed)

func setup(npc_name: String, lines: Array, options: Array = []) -> void:
	if name_label: name_label.text = npc_name
	_lines = lines
	_options = options
	_current_line = 0
	_show_line()

func _show_line() -> void:
	if _current_line < _lines.size():
		if text_label: text_label.text = _lines[_current_line]
		if options_container: options_container.hide()
		if next_button: 
			next_button.show()
			next_button.grab_focus()
	else:
		if _options.is_empty():
			DialogueManager.end_dialogue()
		else:
			_show_options()

func _show_options() -> void:
	if not options_container: return
	
	options_container.show()
	if next_button: next_button.hide()
	
	for child in options_container.get_children():
		child.queue_free()
		
	for opt in _options:
		var btn = Button.new()
		btn.text = opt.text
		btn.pressed.connect(func(): 
			opt.action.call()
			DialogueManager.end_dialogue()
		)
		options_container.add_child(btn)
	
	# 自动聚焦第一个选项，方便键盘操作
	if options_container.get_child_count() > 0:
		options_container.get_child(0).grab_focus()

func _on_next_pressed() -> void:
	_current_line += 1
	_show_line()

func _input(event: InputEvent) -> void:
	if not visible: return
	
	if event.is_action_pressed("ui_cancel"):
		DialogueManager.end_dialogue()
		get_viewport().set_input_as_handled()
		return

	# 仅在“继续”按钮可见时响应快捷键
	# 注意：ui_accept (Space/Enter) 会由聚焦的按钮自动处理，这里主要处理 interact (E)
	if next_button and next_button.visible:
		if event.is_action_pressed("interact"):
			_on_next_pressed()
			get_viewport().set_input_as_handled()
