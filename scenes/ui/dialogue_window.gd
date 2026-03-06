extends Control

@onready var name_label = find_child("NameLabel")
@onready var text_label = find_child("TextLabel")
@onready var next_button = find_child("NextButton")
@onready var options_container = find_child("OptionsContainer")

var _lines: Array = []
var _options: Array = []
var _current_line: int = 0
var _paused: bool = false

func _ready() -> void:
	if next_button:
		next_button.pressed.connect(_on_next_pressed)

func pause() -> void:
	_paused = true
	if next_button:
		next_button.visible = false
		next_button.disabled = true
		if next_button.has_focus():
			next_button.release_focus()
	if options_container:
		options_container.visible = false

func resume() -> void:
	_paused = false
	if next_button:
		next_button.disabled = false
		next_button.visible = true
		# 不要获取焦点，防止 Space 键被按钮自带的 ui_accept 逻辑捕获
		if next_button.has_focus():
			next_button.release_focus()

func setup(npc_name: String, lines: Array, options: Array = []) -> void:
	if name_label: name_label.text = npc_name
	_lines = lines
	_options = options
	_current_line = 0
	_show_line()

func _show_line() -> void:
	if _current_line < _lines.size():
		var line_text: String = _lines[_current_line]
		
		# --- Parse Embedded Action Tags <emit:event_name> ---
		var regex = RegEx.new()
		# Allow alphanumeric, underscore, colon, and hyphen in tag names
		regex.compile("<emit:([\\w:-]+)>")
		var results = regex.search_all(line_text)
		line_text = regex.sub(line_text, "", true) # Remove tags from visible text
		
		if text_label: text_label.text = line_text
		if options_container: options_container.hide()
		if next_button: 
			next_button.show()
			# 确保按钮不持有焦点，防止它捕获 Space 键
			if next_button.has_focus():
				next_button.release_focus()
			
		# Emit events AFTER setting text to ensure logical order
		for result in results:
			var event_name = result.get_string(1)
			DialogueManager.dialogue_event.emit(event_name)
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
		# Check condition (Relationship gating etc.)
		if opt.has("condition") and not opt.condition.call():
			continue # precise filtering
			
		var btn = Button.new()
		btn.text = opt.text
		btn.pressed.connect(func(): 
			if opt.has("action"): opt.action.call()
			
			# Check if we should close (Standard behavior: yes, unless specified otherwise)
			var should_close = opt.get("close_after", true)
			if should_close:
				DialogueManager.end_dialogue()
		)
		options_container.add_child(btn)
		
	# Focus first option
	if options_container.get_child_count() > 0:
		options_container.get_child(0).grab_focus()
	
	# 自动聚焦第一个选项，方便键盘操作
	if options_container.get_child_count() > 0:
		options_container.get_child(0).grab_focus()

func _on_next_pressed() -> void:
	_current_line += 1
	_show_line()

func _input(event: InputEvent) -> void:
	if not visible or _paused: return
	
	if event.is_action_pressed("ui_cancel"):
		DialogueManager.end_dialogue()
		get_viewport().set_input_as_handled()
		return

	# 仅在“继续”按钮可见时响应快捷键
	if next_button and next_button.visible:
		# 处理 F 键 (execute) 和 鼠标左键
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_next_pressed()
			get_viewport().set_input_as_handled()
			return
			
		if event is InputEventKey and event.pressed and event.keycode == KEY_F:
			_on_next_pressed()
			get_viewport().set_input_as_handled()
			return
			
		# 注意：ui_accept (Space) 在此处可能会导致跳跃冲突，因此我们如果检测到 ui_accept 且是 Space，就不响应
		if event.is_action_pressed("ui_accept"):
			# 如果是 Enter 键，仍然允许继续对话
			if event is InputEventKey and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
				_on_next_pressed()
				get_viewport().set_input_as_handled()

