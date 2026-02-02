extends Control

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var load_button: Button = $CenterContainer/VBoxContainer/LoadButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ExitButton

func _ready() -> void:
	# 确保菜单全屏并置于最顶层
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_right = 0
	offset_bottom = 0
	
	# 递归修复背景遮挡导致按钮失效的问题
	_fix_mouse_filter(self)
	
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# 初始动画
	modulate.a = 1.0
	# var tween = create_tween()
	# if tween:
	# 	modulate.a = 0
	# 	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# 按钮悬停动画
	for btn in [start_button, load_button, exit_button]:
		btn.mouse_entered.connect(func(): _on_button_hover(btn))
		btn.mouse_exited.connect(func(): _on_button_unhover(btn))

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
	# 先切换状态，GameManager 会负责关闭所有窗口
	GameManager.start_new_game()

func _on_load_pressed() -> void:
	print("MainMenu: 加载按钮被点击")
	UIManager.open_window("SaveSelection", "res://scenes/ui/SaveSelection.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
