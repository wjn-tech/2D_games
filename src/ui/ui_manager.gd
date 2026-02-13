extends Node

## UIManager (Autoload)
## 负责管理所有 UI 窗口的打开、关闭、层级与输入拦截。

signal window_opened(window_name: String)
signal window_closed(window_name: String)

@export var ui_root_path: NodePath = "UI" # 默认路径，可在编辑器修改
@export var main_theme: Theme = preload("res://assets/ui/main_theme.tres")

var active_windows: Dictionary = {}
var blocking_windows: Array = [] # 存储正在拦截输入的窗口名称

var is_ui_focused: bool = false:
	set(value):
		if is_ui_focused == value: return
		is_ui_focused = value
		# 当 UI 聚焦时，可以通过信号通知玩家脚本禁用移动
		EventBus.player_input_enabled.emit(!value)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## 打开窗口
func open_window(window_name: String, scene_path: String, blocks_input: bool = true) -> Control:
	print("UIManager: 尝试打开窗口: ", window_name, " 路径: ", scene_path)
	
	var window: Control = null
	
	# 1. 优先从已激活窗口中找
	if active_windows.has(window_name):
		window = active_windows[window_name]
		if not is_instance_valid(window):
			active_windows.erase(window_name)
			window = null
	
	# 2. 检查场景中是否已经存在该节点 (针对 Master Scene 预置节点)
	if not window:
		var pre_existing = get_tree().root.find_child(window_name, true, false)
		if pre_existing and pre_existing is Control:
			print("UIManager: 在场景中找到预置窗口: ", window_name)
			window = pre_existing
			active_windows[window_name] = window
			
			# 确保其父节点（通常是 UI CanvasLayer）也能在暂停时工作
			var parent = window.get_parent()
			if parent:
				parent.process_mode = Node.PROCESS_MODE_ALWAYS
				if parent is CanvasLayer:
					parent.layer = 100

	# 3. 如果还是没找到，则实例化新窗口
	if not window:
		if not get_tree().current_scene:
			print("UIManager: 当前场景尚未加载，延迟打开窗口")
			call_deferred("open_window", window_name, scene_path, blocks_input)
			return null

		if not FileAccess.file_exists(scene_path):
			push_error("UIManager: 找不到场景文件: " + scene_path + "。请确保你已经创建并保存了该场景。")
			return null
			
		var scene = load(scene_path)
		if not scene:
			push_error("UIManager: 无法加载 UI 场景 " + scene_path)
			return null
			
		window = scene.instantiate()
		var ui_root: Node = get_tree().current_scene.find_child("UI", true, false)
		if not ui_root:
			ui_root = get_tree().current_scene
			print("UIManager: 未找到名为 'UI' 的节点，将挂载到场景根节点: ", ui_root.name)
		
		if ui_root:
			if ui_root is CanvasLayer:
				ui_root.layer = 100
				ui_root.process_mode = Node.PROCESS_MODE_ALWAYS
			elif ui_root is Control:
				ui_root.process_mode = Node.PROCESS_MODE_ALWAYS
				
			ui_root.add_child(window)
			active_windows[window_name] = window
			
			if window is Control:
				window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				window.theme = main_theme

	# 4. 统一设置状态和显示
	if window:
		window.visible = true
		window.process_mode = Node.PROCESS_MODE_ALWAYS
		window.set_meta("ui_target_state", "open")
		
		if blocks_input:
			if not window_name in blocking_windows:
				blocking_windows.append(window_name)
			is_ui_focused = true
			
		_play_open_animation(window)
		window_opened.emit(window_name)
		print("UIManager: 窗口已就绪: ", window_name)
		return window
		
	return null

## 播放转场淡入淡出
func play_fade(to_black: bool, duration: float = 0.5) -> Signal:
	var fade_node = get_tree().root.get_node_or_null("FadeLayer/ColorRect")
	if not fade_node:
		var canvas = CanvasLayer.new()
		canvas.name = "FadeLayer"
		canvas.layer = 120 # 最高的层级
		canvas.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().root.add_child(canvas)
		
		var rect = ColorRect.new()
		rect.name = "ColorRect"
		rect.color = Color(0, 0, 0, 0)
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(rect)
		fade_node = rect
		
	var target_alpha = 1.0 if to_black else 0.0
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_node, "color:a", target_alpha, duration)
	return tween.finished

## 显示漂浮文字
func show_floating_text(text: String, global_pos: Vector2, color: Color = Color.WHITE) -> void:
	var label = Label.new()
	label.set_script(load("res://src/ui/floating_text.gd"))
	
	# 将全局坐标转换为 UI 坐标
	var ui_root = get_tree().current_scene.find_child("UI", true, false)
	if ui_root:
		ui_root.add_child(label)
		# 如果 UI 是 CanvasLayer，我们需要将世界坐标转换为屏幕坐标
		var canvas_transform = get_tree().root.get_viewport().get_canvas_transform()
		label.global_position = canvas_transform * global_pos
	else:
		get_tree().current_scene.add_child(label)
		label.global_position = global_pos
	
	label.setup(text, color)

## 关闭窗口
func close_window(window_name: String) -> void:
	if active_windows.has(window_name):
		var window = active_windows[window_name]
		
		# 设置目标状态为关闭
		window.set_meta("ui_target_state", "closed")
		
		if window_name in blocking_windows:
			blocking_windows.erase(window_name)
		
		# 播放关闭动画
		var tween = _play_close_animation(window)
		if tween:
			await tween.finished
			
		if is_instance_valid(window):
			# 检查在等待期间是否被重新打开了
			if window.has_meta("ui_target_state") and window.get_meta("ui_target_state") == "open":
				print("UIManager: 窗口 %s 在关闭动画期间被重新打开，取消隐藏动作。" % window_name)
				return
				
			# 只有 MainMenu 和 HUD 是真正持久的预置节点，其他的动态窗口即使在场景中找到也应该销毁
			var is_persistent = window_name == "MainMenu" or window_name == "HUD"
			
			if is_persistent:
				window.visible = false
			else:
				active_windows.erase(window_name)
				window.queue_free()
			
		if blocking_windows.is_empty():
			is_ui_focused = false
		
		window_closed.emit(window_name)

func _play_open_animation(window: Node) -> void:
	if not window is Control: return
	
	window.pivot_offset = window.size / 2
	window.scale = Vector2(0.8, 0.8)
	window.modulate.a = 0
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(window, "scale", Vector2.ONE, 0.3)
	tween.tween_property(window, "modulate:a", 1.0, 0.2)

func _play_close_animation(window: Node) -> Tween:
	if not window is Control: return null
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(window, "scale", Vector2(0.8, 0.8), 0.2)
	tween.tween_property(window, "modulate:a", 0.0, 0.2)
	return tween

## 关闭所有窗口
func close_all_windows(only_blocking: bool = true, exclude: Array = []) -> void:
	var names = active_windows.keys()
	for window_name in names:
		if window_name in exclude:
			continue
		if only_blocking and not window_name in blocking_windows:
			continue
		close_window(window_name)
	
	if only_blocking:
		blocking_windows.clear()
		is_ui_focused = false
	else:
		active_windows.clear()
		blocking_windows.clear()
		is_ui_focused = false

## 切换窗口状态
func toggle_window(window_name: String, scene_path: String, blocks_input: bool = true) -> void:
	if active_windows.has(window_name):
		close_window(window_name)
	else:
		open_window(window_name, scene_path, blocks_input)

## 显示简短通知 (如房屋合法性提示)
func show_notification(message: String) -> void:
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 设置样式
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	
	var canvas = CanvasLayer.new()
	canvas.layer = 120
	add_child(canvas)
	canvas.add_child(label)
	
	# 置于屏幕中央稍靠上的位置
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	label.position.y += 100
	
	# 动画
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 50, 2.0).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 2.0).set_delay(1.0)
	tween.tween_callback(canvas.queue_free)
