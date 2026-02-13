extends GraphNode

var _tooltip_instance: PanelContainer
var _custom_tooltip_content: String = ""

func _ready():
	# 捕获并清除内置 tooltip，防止系统默认黑框显示
	if tooltip_text != "":
		_custom_tooltip_content = tooltip_text
		tooltip_text = ""
		
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# 确保父级不拦截
	mouse_filter = Control.MOUSE_FILTER_PASS

func _exit_tree():
	if _tooltip_instance and is_instance_valid(_tooltip_instance):
		_tooltip_instance.queue_free()

func _on_mouse_entered():
	# 优先从元数据读取，彻底解决截图中的默认黑框叠加问题
	var text = get_meta("custom_tooltip", "")
	if text == "": return
	_show_custom_tooltip(text)

func _on_mouse_exited():
	_hide_custom_tooltip()

func _show_custom_tooltip(text: String):
	if _tooltip_instance and is_instance_valid(_tooltip_instance):
		_tooltip_instance.queue_free()
		
	var container = PanelContainer.new()
	container.top_level = true
	container.z_index = 100 # 确保最上层
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE # 不拦截鼠标
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_color = Color(0.3, 0.3, 0.3)
	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	container.add_theme_stylebox_override("panel", style)
	
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = text
	# 显式刷新 BBCode 渲染
	label.parse_bbcode(text)
	
	label.scroll_active = false
	label.selection_enabled = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(240, 0)
	label.fit_content = true
	
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("outline_color", Color.BLACK)
	
	container.add_child(label)
	add_child(container)
	_tooltip_instance = container
	
	# 下一帧设置位置，确保尺寸已计算
	await get_tree().process_frame
	if is_instance_valid(container) and is_instance_valid(label):
		# 跟随鼠标或固定在节点旁
		var mouse_pos = get_global_mouse_position()
		container.global_position = mouse_pos + Vector2(16, 16) # 鼠标右下偏移

func _hide_custom_tooltip():
	if _tooltip_instance and is_instance_valid(_tooltip_instance):
		_tooltip_instance.queue_free()
		_tooltip_instance = null
