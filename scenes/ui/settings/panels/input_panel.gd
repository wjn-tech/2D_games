extends VBoxContainer

var _scroll: ScrollContainer
var _container: VBoxContainer
var _listening_action: String = ""
var _listening_button: Button = null

func _ready() -> void:
	# Input panel needs scrolling because there might be many actions
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(_scroll)
	
	_container = VBoxContainer.new()
	_container.size_flags_horizontal = SIZE_EXPAND_FILL
	_container.add_theme_constant_override("separation", 10)
	_scroll.add_child(_container)
	
	refresh_ui()

func refresh_ui() -> void:
	# Clear existing
	for child in get_children():
		if child is ScrollContainer: continue
		child.queue_free()
	
	for child in _container.get_children():
		child.queue_free()
	
	var actions = InputMap.get_actions()
	actions.sort()
	
	for action in actions:
		if action.begins_with("ui_"): continue
		
		_add_action_row(action)
		
	# Reset Defaults Button
	var reset_btn = Button.new()
	reset_btn.text = "重置为默认 (Reset to Defaults)"
	reset_btn.custom_minimum_size = Vector2(0, 40)
	reset_btn.pressed.connect(func():
		SettingsManager.reset_input_to_defaults()
		refresh_ui()
	)
	add_child(reset_btn)

func _add_action_row(action: String) -> void:
	var hbox = HBoxContainer.new()
	
	var label = Label.new()
	# 把按键名称翻译为中文
	var action_name = action
	match action:
		"left": action_name = "左移 (Left)"
		"right": action_name = "右移 (Right)"
		"up": action_name = "上移 (Up)"
		"down": action_name = "下移 (Down)"
		"interact": action_name = "交互 (Interact)"
		"jump": action_name = "跳跃 (Jump)"
		"attack": action_name = "攻击 (Attack)"
		"inventory": action_name = "背包 (Inventory)"
	
	label.text = action_name.capitalize() if action_name == action else action_name
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(label)
	
	var events = InputMap.action_get_events(action)
	var btn_text = "无 (None)"
	if events.size() > 0:
		btn_text = events[0].as_text().split(" (")[0] # Simple text representation
	
	var btn = Button.new()
	btn.text = btn_text
	btn.custom_minimum_size = Vector2(150, 0)
	btn.toggle_mode = true # Use toggle state to indicate listening
	
	btn.toggled.connect(func(pressed):
		if pressed:
			# Cancel any other listening
			if _listening_button and _listening_button != btn:
				_listening_button.button_pressed = false
				_listening_button.text = _get_event_text(_listening_action)
			
			_listening_action = action
			_listening_button = btn
			btn.text = "请按任意键... (Press any key...)"
		else:
			# User cancelled manually by clicking again? 
			# Or we finished listening.
			if _listening_button == btn:
				_listening_action = ""
				_listening_button = null
				btn.text = _get_event_text(action)
	)
	
	hbox.add_child(btn)
	_container.add_child(hbox)

func _input(event: InputEvent) -> void:
	if _listening_action == "" or _listening_button == null:
		return
		
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		if not event.is_pressed(): return
		
		# Consume event
		get_viewport().set_input_as_handled()
		
		# Clear old events for this action (single bind for now for simplicity, or we could add to list)
		InputMap.action_erase_events(_listening_action)
		InputMap.action_add_event(_listening_action, event)
		
		# Save
		SettingsManager.save_settings()
		
		# Update UI
		var btn = _listening_button
		_listening_action = ""
		_listening_button = null
		
		btn.button_pressed = false
		btn.text = event.as_text().split(" (")[0]

func _get_event_text(action: String) -> String:
	var events = InputMap.action_get_events(action)
	if events.size() > 0:
		return events[0].as_text().split(" (")[0]
	return "无 (None)"
