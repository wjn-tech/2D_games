extends Control

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var load_button: Button = $CenterContainer/VBoxContainer/LoadButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ExitButton
@onready var title_label: Label = $CenterContainer/VBoxContainer/Title

var welcome_label: Label

func _ready() -> void:
	# 确保菜单全屏并置于最顶层
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_right = 0
	offset_bottom = 0
	
	_setup_smart_ui()
	
	# 递归修复背景遮挡导致按钮失效的问题
	_fix_mouse_filter(self)
	
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# 监听可见性变化，确保从游戏返回时恢复颜色
	visibility_changed.connect(_on_visibility_changed)
	
	# 初始状态
	_on_visibility_changed()
	
	# 按钮悬停动画
	for btn in [start_button, load_button, settings_button, exit_button]:
		btn.mouse_entered.connect(func(): _on_button_hover(btn))
		btn.mouse_exited.connect(func(): _on_button_unhover(btn))

func _on_visibility_changed() -> void:
	if visible:
		modulate = Color.WHITE
		$CenterContainer.modulate.a = 1.0
		# 恢复按钮状态
		start_button.disabled = false
		load_button.disabled = false
		exit_button.disabled = false

func _setup_smart_ui() -> void:
	# 1. Personalized Welcome
	welcome_label = Label.new()
	var time = Time.get_time_dict_from_system()
	var greeting = "冒险者"
	if time.hour < 6: greeting = "夜深了"
	elif time.hour < 12: greeting = "早上好"
	elif time.hour < 18: greeting = "下午好"
	else: greeting = "晚上好"
	
	welcome_label.text = "%s，冒险者。" % greeting
	welcome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	# Insert after Title
	$CenterContainer/VBoxContainer.add_child(welcome_label)
	$CenterContainer/VBoxContainer.move_child(welcome_label, title_label.get_index() + 1)
	
	# 2. Smart Buttons (Check for saves)
	var has_save = false
	for i in range(1, 4):
		if FileAccess.file_exists("user://save_%d.save" % i):
			has_save = true
			break
	
	if has_save:
		start_button.text = "继续旅程"
		# Logic to load latest would go here, currently just maps to start logic which shows standard flow
	else:
		start_button.text = "新的开始"
		# 即使没有存档，也应该允许用户打开存档菜单查看或确认
		# load_button.visible = false 

func _fix_mouse_filter(node: Node) -> void:
	if node is Control:
		if node is TextureRect or node is ColorRect or "Background" in node.name:
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif node is Button:
			node.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			# 容器类节点设为 PASS，允许点击穿透到子节点
			node.mouse_filter = Control.MOUSE_FILTER_PASS
			
	for child in node.get_children():
		_fix_mouse_filter(child)

func _on_button_hover(btn: Button) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "custom_minimum_size:x", 220.0, 0.2)
	tween.parallel().tween_property(btn, "modulate", Color(1.2, 1.2, 1.0), 0.2) # 稍微发光

func _on_button_unhover(btn: Button) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "custom_minimum_size:x", 200.0, 0.2)
	tween.parallel().tween_property(btn, "modulate", Color.WHITE, 0.2)

func _on_start_pressed() -> void:
	print("MainMenu: 开始按钮被点击")
	
	# 禁用交互
	start_button.disabled = true
	load_button.disabled = true
	exit_button.disabled = true
	
	# 播放过渡动画
	var tween = create_tween()
	# UI淡出
	tween.tween_property($CenterContainer, "modulate:a", 0.0, 0.3)
	# 整体变黑
	tween.parallel().tween_property(self, "modulate", Color(0,0,0,1), 0.8)
	
	await tween.finished
	
	# 如果是"新的开始"，调用 start_new_game
	if start_button.text == "新的开始":
		GameManager.start_new_game()
		GameManager.change_state(GameManager.State.PLAYING)
	else:
		# TODO: 这里应该加载最新的存档
		# 目前暂时当做新游戏处理，或者打开加载界面
		print("MainMenu: 继续旅程 - 功能待连接到 SaveManager")
		GameManager.start_new_game()
		GameManager.change_state(GameManager.State.PLAYING)

func _on_load_pressed() -> void:
	print("MainMenu: 加载按钮被点击")
	UIManager.open_window("SaveSelection", "res://scenes/ui/SaveSelection.tscn")

func _on_settings_pressed() -> void:
	print("MainMenu: 设置按钮被点击")
	UIManager.open_window("SettingsWindow", "res://scenes/ui/settings/SettingsWindow.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
