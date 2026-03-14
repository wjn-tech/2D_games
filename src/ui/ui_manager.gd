extends Node

## UIManager (Autoload)
## 负责管理所有 UI 窗口的打开、关闭、层级与输入拦截。

const HighlightOverlayScene = preload("res://scenes/ui/tutorial/highlight_overlay.tscn")

signal window_opened(window_name: String)
signal window_closed(window_name: String)

@export var ui_root_path: NodePath = "UI" # 默认路径，可在编辑器修改
@export var main_theme: Theme = preload("res://assets/ui/main_theme.tres")

var active_windows: Dictionary = {}
var blocking_windows: Array = [] # 存储正在拦截输入的窗口名称
var highlight_overlay: Node = null
var loading_overlay: Control = null
var loading_title_label: Label = null
var loading_stage_label: Label = null
var loading_status_label: Label = null
var loading_error_label: Label = null
var loading_progress_bar: ProgressBar = null
var loading_progress_tween: Tween = null

var is_ui_focused: bool = false:
	set(value):
		if is_ui_focused == value: return
		is_ui_focused = value
		# 当 UI 聚焦时，也通过 CursorManager 重置指针
		if value and is_instance_valid(CursorManager):
			CursorManager.set_cursor(CursorManager.CursorType.DEFAULT)
		# 当 UI 聚焦时，可以通过信号通知玩家脚本禁用移动
		EventBus.player_input_enabled.emit(!value)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## 高亮指定 UI 元素 (Tutorial Only)
func highlight_element(control: Control, message: String = "") -> void:
	if not highlight_overlay:
		highlight_overlay = HighlightOverlayScene.instantiate()
		add_child(highlight_overlay)
	
	if highlight_overlay.has_method("highlight"):
		highlight_overlay.highlight(control, message)

## 清除高亮
func clear_highlight() -> void:
	if highlight_overlay and highlight_overlay.has_method("clear"):
		highlight_overlay.clear()

## 强制清理所有 UI 引用 (用于场景重载)
func clear_all_references() -> void:
	print("UIManager: Clearing all UI references due to scene reload.")
	active_windows.clear()
	blocking_windows.clear()
	is_ui_focused = false

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
					parent.layer = 1

	# 3. 如果还是没找到，则实例化新窗口
	if not window:
		if not get_tree() or not get_tree().current_scene:
			print("UIManager: 当前场景尚未加载，无法打开窗口: ", window_name)
			return null

		if not ResourceLoader.exists(scene_path):
			push_error("UIManager: 找不到场景文件: " + scene_path + "。请确保资源路径正确且已包含在导出中。")
			return null
		
		var scene = ResourceLoader.load(scene_path)
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
				ui_root.layer = 1
				ui_root.process_mode = Node.PROCESS_MODE_ALWAYS
			elif ui_root is Control:
				ui_root.process_mode = Node.PROCESS_MODE_ALWAYS
				
			ui_root.add_child(window)
			active_windows[window_name] = window
			
			if window is Control:
				window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				# 修复：主窗口实例化后延迟应用主题，避免因为 Variation 尚未加载导致的警告
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
		else:
			# 如果明确不拦截输入，确保 mouse_filter 为 IGNORE
			window.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
		_play_open_animation(window)
		window_opened.emit(window_name)
		if window_name == "InventoryWindow":
			EventBus.inventory_opened.emit()
			
		print("UIManager: 窗口已就绪: ", window_name)
		return window

		
	return null

## 播放转场淡入淡出
func play_fade(to_black: bool, duration: float = 0.5) -> Signal:
	var fade_layer = get_tree().root.get_node_or_null("GlobalFadeLayer")
	var fade_node: ColorRect = null
	
	if not fade_layer:
		var canvas = CanvasLayer.new()
		canvas.name = "GlobalFadeLayer"
		canvas.layer = 128 # 最高的层级，盖过所有 UI
		canvas.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().root.add_child(canvas)
		
		var rect = ColorRect.new()
		rect.name = "ColorRect"
		rect.color = Color(0, 0, 0, 0)
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(rect)
		fade_node = rect
	else:
		fade_node = fade_layer.get_node("ColorRect")
		
	var target_alpha = 1.0 if to_black else 0.0
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_node, "color:a", target_alpha, duration)
	return tween.finished

func show_loading_overlay(title: String = "世界加载中", stage_text: String = "", progress: float = 0.0, status_text: String = "") -> void:
	_ensure_loading_overlay()
	if not is_instance_valid(loading_overlay):
		return
	loading_overlay.visible = true
	loading_overlay.modulate.a = 1.0
	if is_instance_valid(loading_title_label):
		loading_title_label.text = title
	if is_instance_valid(loading_error_label):
		loading_error_label.visible = false
	update_loading_overlay(progress, stage_text, status_text)

func update_loading_overlay(progress: float, stage_text: String = "", status_text: String = "") -> void:
	_ensure_loading_overlay()
	if not is_instance_valid(loading_overlay):
		return
	loading_overlay.visible = true
	if is_instance_valid(loading_stage_label) and stage_text != "":
		loading_stage_label.text = stage_text
	if is_instance_valid(loading_status_label) and status_text != "":
		loading_status_label.text = status_text
	if is_instance_valid(loading_progress_bar):
		var target_value := clampf(progress, 0.0, 1.0) * 100.0
		if is_instance_valid(loading_progress_tween):
			loading_progress_tween.kill()
		loading_progress_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		loading_progress_tween.tween_property(loading_progress_bar, "value", target_value, 0.12)

func show_loading_failure(message: String) -> void:
	_ensure_loading_overlay()
	if not is_instance_valid(loading_overlay):
		return
	loading_overlay.visible = true
	loading_overlay.modulate.a = 1.0
	if is_instance_valid(loading_stage_label):
		loading_stage_label.text = "加载失败"
	if is_instance_valid(loading_status_label):
		loading_status_label.text = message
	if is_instance_valid(loading_error_label):
		loading_error_label.visible = true
		loading_error_label.text = "正在返回主菜单..."

func hide_loading_overlay(duration: float = 0.2) -> Signal:
	_ensure_loading_overlay()
	if not is_instance_valid(loading_overlay) or not loading_overlay.visible:
		return get_tree().create_timer(0.0).timeout
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(loading_overlay, "modulate:a", 0.0, duration)
	tween.tween_callback(_finalize_loading_overlay_hide)
	return tween.finished

func dismiss_loading_overlay() -> void:
	if not is_instance_valid(loading_overlay):
		return
	if is_instance_valid(loading_progress_tween):
		loading_progress_tween.kill()
	_finalize_loading_overlay_hide()

func _ensure_loading_overlay() -> void:
	if is_instance_valid(loading_overlay):
		return

	var root := get_tree().root
	var loading_layer = root.get_node_or_null("GlobalLoadingLayer")
	if not loading_layer:
		var canvas := CanvasLayer.new()
		canvas.name = "GlobalLoadingLayer"
		canvas.layer = 129
		canvas.process_mode = Node.PROCESS_MODE_ALWAYS
		root.add_child(canvas)
		loading_layer = canvas

	var overlay := Control.new()
	overlay.name = "LoadingOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	loading_layer.add_child(overlay)

	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.03, 0.05, 0.09, 0.92)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(background)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -260
	panel.offset_top = -120
	panel.offset_right = 260
	panel.offset_bottom = 120
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.12, 0.18, 0.96)
	panel_style.border_color = Color(0.36, 0.62, 0.86, 0.9)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.content_margin_left = 24
	panel_style.content_margin_top = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "世界加载中"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	content.add_child(title)

	var stage := Label.new()
	stage.name = "StageLabel"
	stage.text = "正在准备场景"
	stage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage.add_theme_font_size_override("font_size", 20)
	content.add_child(stage)

	var status := Label.new()
	status.name = "StatusLabel"
	status.text = "请稍候..."
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(status)

	var progress_bar := ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.custom_minimum_size = Vector2(420, 22)
	progress_bar.show_percentage = true
	content.add_child(progress_bar)

	var error_label := Label.new()
	error_label.name = "ErrorLabel"
	error_label.visible = false
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
	content.add_child(error_label)

	loading_overlay = overlay
	loading_title_label = title
	loading_stage_label = stage
	loading_status_label = status
	loading_error_label = error_label
	loading_progress_bar = progress_bar
	loading_overlay.visible = false

func _finalize_loading_overlay_hide() -> void:
	if not is_instance_valid(loading_overlay):
		return
	loading_overlay.visible = false
	loading_overlay.modulate.a = 1.0
	if is_instance_valid(loading_error_label):
		loading_error_label.visible = false

## 显示漂浮文字
func show_floating_text(text_content: String, global_pos: Vector2, color: Color = Color.WHITE) -> void:
	var label = Label.new()
	# 关键修复 1: 强制忽略输入
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 关键修复 2: 确保脚本正确挂载并初始化
	label.set_script(load("res://src/ui/floating_text.gd"))
	
	# 将全局坐标转换为 UI 坐标
	var ui_root = get_tree().current_scene.find_child("UI", true, false)
	if ui_root:
		# 关键修复 3: 检查 UI 根节点是否拦截了输入
		if ui_root is Control and ui_root.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			# 如果是主 UI 容器，但只是用来挂载漂浮文字，它不应该拦截
			if ui_root.name == "UI": ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		ui_root.add_child(label)
		# 如果 UI 是 CanvasLayer，我们需要将世界坐标转换为屏幕坐标
		var canvas_transform = get_tree().root.get_viewport().get_canvas_transform()
		label.global_position = canvas_transform * global_pos
	else:
		get_tree().current_scene.add_child(label)
		label.global_position = global_pos
	
	if label.has_method("setup"):
		label.setup(text_content, color)
	else:
		label.text = text_content
		label.add_theme_color_override("font_color", color)

## 关闭窗口
func close_window(window_name: String) -> void:
	if not active_windows.has(window_name):
		# 增强：场景重载后可能丢失字典引用，尝试在当前场景中寻找预置节点
		var scene_root = get_tree().current_scene
		if scene_root:
			var found = scene_root.find_child(window_name, true, false)
			if is_instance_valid(found) and found is Control:
				print("UIManager: 探测并同步场景中的预置窗口: ", window_name)
				active_windows[window_name] = found

	var window: Control = null
	if active_windows.has(window_name):
		var potential_window = active_windows[window_name]
		if is_instance_valid(potential_window):
			window = potential_window
		else:
			active_windows.erase(window_name)

	if not is_instance_valid(window):
		active_windows.erase(window_name)
		blocking_windows.erase(window_name)
		return
		
	# 如果窗口已经在关闭过程中，直接返回
	if window.get_meta("ui_target_state", "open") == "closed":
		return
		
	# 设置目标状态为关闭
	window.set_meta("ui_target_state", "closed")
	
	if window_name in blocking_windows:
		blocking_windows.erase(window_name)
	
	# 播放关闭动画
	var tween = _play_close_animation(window)
	if tween:
		# 修改：不再在此处 await，避免长期阻塞导致后续逻辑顺序混乱。
		# 改为在回调中处理真正的节点清理。
		tween.finished.connect(func(): _on_window_close_animation_finished(window, window_name))
	else:
		_on_window_close_animation_finished(window, window_name)

func _on_window_close_animation_finished(window: Control, window_name: String) -> void:
	# 再次检查窗口有效性，因为动画期间可能发生场景重载或销毁
	if not is_instance_valid(window):
		if active_windows.has(window_name):
			active_windows.erase(window_name)
		return
		
	if window_name == "InventoryWindow":
		EventBus.inventory_closed.emit()
	
	if window_name == "WandEditor":
		EventBus.wand_editor_closed.emit()

	# 检查在等待期间是否被重新打开了
	if window.get_meta("ui_target_state", "closed") == "open":
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
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(window, "scale", Vector2.ONE, 0.3)
	tween.tween_property(window, "modulate:a", 1.0, 0.2)

func _play_close_animation(window: Node) -> Tween:
	if not window is Control: return null
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(window, "scale", Vector2(0.8, 0.8), 0.2)
	tween.tween_property(window, "modulate:a", 0.0, 0.2)
	return tween

## 关闭所有窗口
func close_all_windows(only_blocking: bool = true, exclude: Array = []) -> void:
	# 即使 active_windows 是空的（如刚重传场景），也要确保探测并关闭场景中的基础 UI
	var window_names = active_windows.keys()
	for common in ["MainMenu", "SaveSelection", "SettingsWindow", "InGameMenu"]:
		if not common in window_names and not common in exclude:
			window_names.append(common)
			
	for window_name in window_names:
		if window_name in exclude:
			continue
		if only_blocking and not window_name in blocking_windows and window_name != "MainMenu":
			# 特例：MainMenu 通常被认为是 blocking 的，即使在重载后丢失了记录也该关闭
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

## 显示简短通知 (如获得新法术提示)
func show_notification(message: String) -> void:
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 设置样式
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	
	# 置于屏幕中央稍靠上的位置
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	label.reset_size()
	label.position.y += 100
	
	# 重要：防止通知文字阻挡鼠标点击输入
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var canvas = CanvasLayer.new()
	canvas.name = "NotificationLayer"
	canvas.layer = 120
	# 关键修复：CanvasLayer 不是 Control，没有 mouse_filter 属性，
	# 但它会创建一个新的独立渲染层。我们需要确保它下面的子节点统统不拦截。
	add_child(canvas)
	canvas.add_child(label)
	
	# 居中校准 (在添加到 tree 之后计算 size 准确)
	label.position.x -= label.get_combined_minimum_size().x / 2
	
	# 动画
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 50, 2.0).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 2.0).set_delay(1.0)
	tween.tween_callback(canvas.queue_free)
