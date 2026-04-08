extends Node

## UIManager (Autoload)
## 负责管理所有 UI 窗口的打开、关闭、层级与输入拦截。

const HighlightOverlayScene = preload("res://scenes/ui/tutorial/highlight_overlay.tscn")
const LOADING_SHELL_THEME_PATH := "res://assets/ui/start_menu_shell/loading_theme.json"
const STARTMENU_FALLBACK_ICON_PATH := "res://assets/ui/startmenu/icons/icon_start.svg"

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
var loading_subtitle_label: Label = null
var loading_percent_label: Label = null
var loading_segment_cells: Array[ColorRect] = []
var loading_panel_style: StyleBoxFlat = null
var loading_progress_bg_style: StyleBoxFlat = null
var loading_progress_fill_style: StyleBoxFlat = null
var loading_theme_tokens: Dictionary = {}

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

func _get_active_window_if_valid(window_name: String) -> Control:
	if not active_windows.has(window_name):
		return null
	var cached_window = active_windows[window_name]
	if is_instance_valid(cached_window) and cached_window is Control:
		return cached_window
	active_windows.erase(window_name)
	blocking_windows.erase(window_name)
	return null

## 打开窗口
func open_window(window_name: String, scene_path: String, blocks_input: bool = true) -> Control:
	print("UIManager: 尝试打开窗口: ", window_name, " 路径: ", scene_path)
	
	var window: Control = null
	
	# 1. 优先从已激活窗口中找
	window = _get_active_window_if_valid(window_name)
	
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

func _theme_float(tokens: Dictionary, key: String, fallback: float) -> float:
	if not tokens.has(key):
		return fallback
	var value = tokens.get(key)
	if value is int or value is float:
		return float(value)
	return fallback

func _theme_color(tokens: Dictionary, key: String, fallback: Color) -> Color:
	if not tokens.has(key):
		return fallback
	var raw = tokens.get(key)
	if raw is Array and raw.size() >= 3:
		var r := float(raw[0])
		var g := float(raw[1])
		var b := float(raw[2])
		var a := float(raw[3]) if raw.size() >= 4 else 255.0
		if r > 1.0 or g > 1.0 or b > 1.0 or a > 1.0:
			return Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0)
		return Color(r, g, b, a)
	if raw is Color:
		return raw
	return fallback

func _load_loading_shell_theme() -> Dictionary:
	var defaults := {
		"overlay_bg": [8, 14, 24, 234],
		"panel_bg": [15, 22, 36, 246],
		"panel_border": [86, 160, 210, 232],
		"title_color": [82, 224, 255, 255],
		"subtitle_color": [152, 174, 198, 255],
		"header_bg": [75, 89, 116, 222],
		"header_text_color": [225, 232, 242, 245],
		"chrome_accent": [61, 86, 112, 255],
		"stage_color": [193, 214, 232, 255],
		"status_color": [154, 184, 214, 245],
		"progress_bg": [19, 32, 52, 255],
		"progress_fill": [70, 205, 245, 255],
		"progress_border": [130, 216, 255, 255],
		"segment_empty": [25, 35, 54, 255],
		"segment_fill": [72, 208, 246, 255],
		"percent_box_bg": [13, 27, 43, 255],
		"percent_box_border": [116, 180, 228, 230],
		"footer_bg": [47, 63, 85, 220],
		"footer_text": [169, 184, 201, 240],
		"error_color": [255, 108, 108, 255],
		"panel_radius": 4,
		"panel_width": 760,
		"panel_height": 520,
		"progress_height": 16,
		"segment_count": 22,
		"progress_tween_sec": 0.12,
		"icon_path": STARTMENU_FALLBACK_ICON_PATH
	}

	if not FileAccess.file_exists(LOADING_SHELL_THEME_PATH):
		return defaults

	var file := FileAccess.open(LOADING_SHELL_THEME_PATH, FileAccess.READ)
	if file == null:
		return defaults

	var content := file.get_as_text()
	var parsed = JSON.parse_string(content)
	if not (parsed is Dictionary):
		return defaults

	for key in parsed.keys():
		defaults[key] = parsed[key]
	return defaults

func show_loading_overlay(title: String = "世界加载中", stage_text: String = "", progress: float = 0.0, status_text: String = "") -> void:
	_ensure_loading_overlay()
	if not is_instance_valid(loading_overlay):
		return
	loading_overlay.visible = true
	loading_overlay.modulate.a = 1.0
	if is_instance_valid(loading_title_label):
		loading_title_label.text = title
		loading_title_label.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "title_color", Color(0.86, 0.95, 1.0)))
	if is_instance_valid(loading_subtitle_label):
		loading_subtitle_label.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "subtitle_color", Color(0.74, 0.81, 0.88)))
	if is_instance_valid(loading_stage_label):
		loading_stage_label.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "stage_color", Color(0.58, 0.82, 1.0)))
	if is_instance_valid(loading_status_label):
		loading_status_label.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "status_color", Color(0.78, 0.86, 0.95)))
	if is_instance_valid(loading_error_label):
		loading_error_label.visible = false
	if is_instance_valid(loading_panel_style):
		loading_panel_style.border_color = _theme_color(loading_theme_tokens, "panel_border", Color(0.36, 0.62, 0.86, 0.9))
	if is_instance_valid(loading_progress_fill_style):
		loading_progress_fill_style.bg_color = _theme_color(loading_theme_tokens, "progress_fill", Color(0.27, 0.77, 0.96))
	update_loading_overlay(progress, stage_text, status_text)
	_sync_loading_progress_visuals(loading_progress_bar.value if is_instance_valid(loading_progress_bar) else 0.0)

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
		target_value = maxf(loading_progress_bar.value, target_value)
		var current_value := loading_progress_bar.value
		if is_instance_valid(loading_progress_tween):
			loading_progress_tween.kill()
		loading_progress_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		var tween_sec := clampf(_theme_float(loading_theme_tokens, "progress_tween_sec", 0.12), 0.05, 0.3)
		loading_progress_tween.tween_property(loading_progress_bar, "value", target_value, tween_sec)
		loading_progress_tween.parallel().tween_method(_sync_loading_progress_visuals, current_value, target_value, tween_sec)

func show_loading_failure(message: String) -> void:
	_ensure_loading_overlay()
	if not is_instance_valid(loading_overlay):
		return
	loading_overlay.visible = true
	loading_overlay.modulate.a = 1.0
	if is_instance_valid(loading_stage_label):
		loading_stage_label.text = "加载失败"
		loading_stage_label.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "error_color", Color(1.0, 0.45, 0.45)))
	if is_instance_valid(loading_status_label):
		loading_status_label.text = message
		loading_status_label.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "error_color", Color(1.0, 0.45, 0.45)))
	if is_instance_valid(loading_percent_label):
		loading_percent_label.text = "ERR"
		loading_percent_label.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "error_color", Color(1.0, 0.45, 0.45)))
	if is_instance_valid(loading_error_label):
		loading_error_label.visible = true
		loading_error_label.text = "正在返回主菜单..."
		loading_error_label.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "error_color", Color(1.0, 0.45, 0.45)))
	if is_instance_valid(loading_panel_style):
		loading_panel_style.border_color = _theme_color(loading_theme_tokens, "error_color", Color(1.0, 0.45, 0.45))
	if is_instance_valid(loading_progress_fill_style):
		loading_progress_fill_style.bg_color = _theme_color(loading_theme_tokens, "error_color", Color(1.0, 0.45, 0.45))

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

func _sync_loading_progress_visuals(value: float) -> void:
	var clamped := clampf(value, 0.0, 100.0)
	if is_instance_valid(loading_percent_label):
		loading_percent_label.text = "%d%%" % int(round(clamped))
		loading_percent_label.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "title_color", Color(0.32, 0.88, 1.0)))
	_update_loading_segment_cells(clamped)

func _update_loading_segment_cells(percent_value: float) -> void:
	if loading_segment_cells.is_empty():
		return
	var lit_count := int(round((percent_value / 100.0) * float(loading_segment_cells.size())))
	var fill_color := _theme_color(loading_theme_tokens, "segment_fill", Color(0.28, 0.81, 0.96, 1.0))
	var empty_color := _theme_color(loading_theme_tokens, "segment_empty", Color(0.10, 0.15, 0.23, 1.0))
	for i in range(loading_segment_cells.size()):
		var cell := loading_segment_cells[i]
		if not is_instance_valid(cell):
			continue
		cell.color = fill_color if i < lit_count else empty_color

func _ensure_loading_overlay() -> void:
	if is_instance_valid(loading_overlay):
		return
	loading_theme_tokens = _load_loading_shell_theme()

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
	background.color = _theme_color(loading_theme_tokens, "overlay_bg", Color(0.03, 0.05, 0.09, 0.92))
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(background)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	var panel_width := clampf(_theme_float(loading_theme_tokens, "panel_width", 760.0), 560.0, 920.0)
	var panel_height := clampf(_theme_float(loading_theme_tokens, "panel_height", 520.0), 360.0, 700.0)
	panel.offset_left = -panel_width * 0.5
	panel.offset_top = -panel_height * 0.5
	panel.offset_right = panel_width * 0.5
	panel.offset_bottom = panel_height * 0.5
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = _theme_color(loading_theme_tokens, "panel_bg", Color(0.08, 0.12, 0.18, 0.96))
	panel_style.border_color = _theme_color(loading_theme_tokens, "panel_border", Color(0.36, 0.62, 0.86, 0.9))
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	var panel_radius := int(clampf(_theme_float(loading_theme_tokens, "panel_radius", 10.0), 6.0, 28.0))
	panel_style.corner_radius_top_left = panel_radius
	panel_style.corner_radius_top_right = panel_radius
	panel_style.corner_radius_bottom_left = panel_radius
	panel_style.corner_radius_bottom_right = panel_radius
	panel_style.content_margin_left = 0
	panel_style.content_margin_top = 0
	panel_style.content_margin_right = 0
	panel_style.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)

	var frame := VBoxContainer.new()
	frame.name = "Frame"
	frame.add_theme_constant_override("separation", 0)
	panel.add_child(frame)

	var header_panel := PanelContainer.new()
	header_panel.name = "HeaderBar"
	header_panel.custom_minimum_size = Vector2(0, 42)
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = _theme_color(loading_theme_tokens, "header_bg", Color(0.28, 0.36, 0.46, 0.9))
	header_style.border_width_bottom = 2
	header_style.border_color = _theme_color(loading_theme_tokens, "chrome_accent", Color(0.24, 0.34, 0.44, 1.0))
	header_style.content_margin_left = 16
	header_style.content_margin_right = 16
	header_style.content_margin_top = 8
	header_style.content_margin_bottom = 6
	header_panel.add_theme_stylebox_override("panel", header_style)
	frame.add_child(header_panel)

	var header_row := HBoxContainer.new()
	header_row.name = "HeaderRow"
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_panel.add_child(header_row)

	var header_left := HBoxContainer.new()
	header_left.add_theme_constant_override("separation", 6)
	header_row.add_child(header_left)

	for color in [Color(0.88, 0.29, 0.29), Color(0.92, 0.73, 0.20), Color(0.38, 0.81, 0.47)]:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(14, 14)
		dot.color = color
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header_left.add_child(dot)

	var spacer_left := Control.new()
	spacer_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(spacer_left)

	var header_title := Label.new()
	header_title.text = "LOADING"
	header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_title.add_theme_font_size_override("font_size", 30)
	header_title.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "header_text_color", Color(0.9, 0.94, 0.98)))
	header_row.add_child(header_title)

	var spacer_right := Control.new()
	spacer_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(spacer_right)

	var header_right := HBoxContainer.new()
	header_right.add_theme_constant_override("separation", 8)
	header_row.add_child(header_right)
	for i in range(3):
		var box := ColorRect.new()
		box.custom_minimum_size = Vector2(16, 12)
		box.color = _theme_color(loading_theme_tokens, "chrome_accent", Color(0.34, 0.43, 0.54, 1.0))
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header_right.add_child(box)

	var body_margin := MarginContainer.new()
	body_margin.name = "BodyMargin"
	body_margin.add_theme_constant_override("margin_left", 34)
	body_margin.add_theme_constant_override("margin_top", 24)
	body_margin.add_theme_constant_override("margin_right", 34)
	body_margin.add_theme_constant_override("margin_bottom", 16)
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(body_margin)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 16)
	body_margin.add_child(content)

	var title_row := HBoxContainer.new()
	title_row.name = "TitleRow"
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 10)
	content.add_child(title_row)

	var icon_path := String(loading_theme_tokens.get("icon_path", STARTMENU_FALLBACK_ICON_PATH))
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var icon := TextureRect.new()
		icon.name = "TitleIcon"
		icon.custom_minimum_size = Vector2(22, 22)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = load(icon_path)
		title_row.add_child(icon)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "世界加载中"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "title_color", Color(0.86, 0.95, 1.0)))
	title_row.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "SubtitleLabel"
	subtitle.text = "LOADING UNIVERSE"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 34)
	subtitle.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "subtitle_color", Color(0.62, 0.7, 0.8, 0.95)))
	content.add_child(subtitle)

	var stage := Label.new()
	stage.name = "StageLabel"
	stage.text = "正在准备场景"
	stage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage.add_theme_font_size_override("font_size", 30)
	stage.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "stage_color", Color(0.58, 0.82, 1.0)))
	content.add_child(stage)

	var status := Label.new()
	status.name = "StatusLabel"
	status.text = "请稍候..."
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 23)
	status.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "status_color", Color(0.78, 0.86, 0.95)))
	content.add_child(status)

	var progress_bar := ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.step = 1.0
	progress_bar.custom_minimum_size = Vector2(640, clampf(_theme_float(loading_theme_tokens, "progress_height", 16.0), 12.0, 24.0))
	progress_bar.show_percentage = false
	progress_bar.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	var progress_bg := StyleBoxFlat.new()
	progress_bg.bg_color = _theme_color(loading_theme_tokens, "progress_bg", Color(0.07, 0.13, 0.2, 0.95))
	progress_bg.border_color = _theme_color(loading_theme_tokens, "progress_border", Color(0.46, 0.74, 0.98, 0.88))
	progress_bg.border_width_left = 1
	progress_bg.border_width_top = 1
	progress_bg.border_width_right = 1
	progress_bg.border_width_bottom = 1
	progress_bg.corner_radius_top_left = 3
	progress_bg.corner_radius_top_right = 3
	progress_bg.corner_radius_bottom_left = 3
	progress_bg.corner_radius_bottom_right = 3
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = _theme_color(loading_theme_tokens, "progress_fill", Color(0.27, 0.77, 0.96))
	progress_fill.corner_radius_top_left = 2
	progress_fill.corner_radius_top_right = 2
	progress_fill.corner_radius_bottom_left = 2
	progress_fill.corner_radius_bottom_right = 2
	progress_bar.add_theme_stylebox_override("background", progress_bg)
	progress_bar.add_theme_stylebox_override("fill", progress_fill)
	content.add_child(progress_bar)

	var segment_frame := PanelContainer.new()
	segment_frame.name = "SegmentFrame"
	var segment_frame_style := StyleBoxFlat.new()
	segment_frame_style.bg_color = _theme_color(loading_theme_tokens, "progress_bg", Color(0.08, 0.13, 0.2, 1.0))
	segment_frame_style.border_color = _theme_color(loading_theme_tokens, "progress_border", Color(0.48, 0.72, 0.9, 0.85))
	segment_frame_style.border_width_left = 3
	segment_frame_style.border_width_top = 3
	segment_frame_style.border_width_right = 3
	segment_frame_style.border_width_bottom = 3
	segment_frame_style.content_margin_left = 10
	segment_frame_style.content_margin_right = 10
	segment_frame_style.content_margin_top = 10
	segment_frame_style.content_margin_bottom = 10
	segment_frame.add_theme_stylebox_override("panel", segment_frame_style)
	content.add_child(segment_frame)

	var segment_row := HBoxContainer.new()
	segment_row.name = "SegmentRow"
	segment_row.add_theme_constant_override("separation", 4)
	segment_frame.add_child(segment_row)

	loading_segment_cells.clear()
	var segment_count := int(clampi(int(_theme_float(loading_theme_tokens, "segment_count", 22.0)), 10, 40))
	for i in range(segment_count):
		var cell := ColorRect.new()
		cell.custom_minimum_size = Vector2(24, 38)
		cell.color = _theme_color(loading_theme_tokens, "segment_empty", Color(0.10, 0.15, 0.23, 1.0))
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		segment_row.add_child(cell)
		loading_segment_cells.append(cell)

	var percent_badge := PanelContainer.new()
	percent_badge.name = "PercentBadge"
	percent_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = _theme_color(loading_theme_tokens, "percent_box_bg", Color(0.06, 0.13, 0.2, 0.95))
	badge_style.border_color = _theme_color(loading_theme_tokens, "percent_box_border", Color(0.41, 0.63, 0.84, 0.9))
	badge_style.border_width_left = 2
	badge_style.border_width_top = 2
	badge_style.border_width_right = 2
	badge_style.border_width_bottom = 2
	badge_style.content_margin_left = 26
	badge_style.content_margin_right = 26
	badge_style.content_margin_top = 14
	badge_style.content_margin_bottom = 14
	percent_badge.add_theme_stylebox_override("panel", badge_style)
	content.add_child(percent_badge)

	var percent_label := Label.new()
	percent_label.name = "PercentLabel"
	percent_label.text = "0%"
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	percent_label.add_theme_font_size_override("font_size", 58)
	percent_label.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "title_color", Color(0.32, 0.88, 1.0)))
	percent_badge.add_child(percent_label)

	var error_label := Label.new()
	error_label.name = "ErrorLabel"
	error_label.visible = false
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.add_theme_font_size_override("font_size", 25)
	error_label.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "error_color", Color(1.0, 0.55, 0.55)))
	content.add_child(error_label)

	var body_spacer := Control.new()
	body_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body_spacer)

	var footer_panel := PanelContainer.new()
	footer_panel.name = "FooterBar"
	footer_panel.custom_minimum_size = Vector2(0, 40)
	var footer_style := StyleBoxFlat.new()
	footer_style.bg_color = _theme_color(loading_theme_tokens, "footer_bg", Color(0.23, 0.28, 0.36, 0.92))
	footer_style.border_width_top = 2
	footer_style.border_color = _theme_color(loading_theme_tokens, "chrome_accent", Color(0.24, 0.34, 0.44, 1.0))
	footer_style.content_margin_left = 14
	footer_style.content_margin_right = 14
	footer_style.content_margin_top = 8
	footer_style.content_margin_bottom = 8
	footer_panel.add_theme_stylebox_override("panel", footer_style)
	frame.add_child(footer_panel)

	var footer_row := HBoxContainer.new()
	footer_row.name = "FooterRow"
	footer_panel.add_child(footer_row)

	var footer_left := Label.new()
	footer_left.text = "READY"
	footer_left.add_theme_font_size_override("font_size", 20)
	footer_left.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "footer_text", Color(0.72, 0.78, 0.86, 0.95)))
	footer_row.add_child(footer_left)

	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_row.add_child(footer_spacer)

	var footer_right := Label.new()
	footer_right.text = "ESC: CANCEL"
	footer_right.add_theme_font_size_override("font_size", 20)
	footer_right.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "footer_text", Color(0.72, 0.78, 0.86, 0.95)))
	footer_row.add_child(footer_right)

	loading_overlay = overlay
	loading_title_label = title
	loading_subtitle_label = subtitle
	loading_stage_label = stage
	loading_status_label = status
	loading_error_label = error_label
	loading_progress_bar = progress_bar
	loading_percent_label = percent_label
	loading_panel_style = panel_style
	loading_progress_bg_style = progress_bg
	loading_progress_fill_style = progress_fill
	loading_overlay.visible = false
	_sync_loading_progress_visuals(0.0)

func _finalize_loading_overlay_hide() -> void:
	if not is_instance_valid(loading_overlay):
		return
	loading_overlay.visible = false
	loading_overlay.modulate.a = 1.0
	if is_instance_valid(loading_panel_style):
		loading_panel_style.border_color = _theme_color(loading_theme_tokens, "panel_border", Color(0.36, 0.62, 0.86, 0.9))
	if is_instance_valid(loading_progress_fill_style):
		loading_progress_fill_style.bg_color = _theme_color(loading_theme_tokens, "progress_fill", Color(0.27, 0.77, 0.96))
	if is_instance_valid(loading_stage_label):
		loading_stage_label.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "stage_color", Color(0.58, 0.82, 1.0)))
	if is_instance_valid(loading_status_label):
		loading_status_label.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "status_color", Color(0.78, 0.86, 0.95)))
	if is_instance_valid(loading_percent_label):
		loading_percent_label.add_theme_color_override("font_color", _theme_color(loading_theme_tokens, "title_color", Color(0.32, 0.88, 1.0)))
		loading_percent_label.text = "0%"
	_update_loading_segment_cells(0.0)
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
	window = _get_active_window_if_valid(window_name)

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
		await tween.finished
	
	# 再次检查窗口有效性，因为 await 期间可能发生场景重载或销毁
	if not is_instance_valid(window):
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
	if _get_active_window_if_valid(window_name) != null:
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
