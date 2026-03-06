extends CanvasLayer
class_name HighlightOverlay

@onready var dimmer: ColorRect = $Dimmer
@onready var focus_frame: ReferenceRect = $FocusFrame
@onready var hint_label: Label = $FocusFrame/HintLabel

var target_control: Control

func highlight(control: Control, message: String = ""):
	target_control = control
	if hint_label: hint_label.text = message
	visible = true
	_update_rect()
	
	# IMPROVED: Detect when drag starts to hide highlight immediately
	# This avoids a "stuck" box while the item is mid-air
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node):
	# In Godot 4, DragPreview is usually a temporary node
	if node.name == "DragPreview" or node is Control and node.has_meta("drag_data"):
		clear()

func clear():
	visible = false
	target_control = null
	# Disconnect tree listener
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)

func _process(_delta):
	if visible and target_control:
		# 1. 检查目标是否失效或不可见
		if not is_instance_valid(target_control) or not target_control.is_visible_in_tree():
			clear()
			return

		# 2. 深度检测：由于 GridContainer 会管理子节点，直接检查 target_control 是否还有效
		# 如果 target_control 是槽位，它被 queue_free 或移除时，is_instance_valid 会捕捉到
		
		# 3. 特殊逻辑：针对物品槽位，如果物品被拖走（槽位数据变为空），立即清除
		if target_control.has_method("get_slot_data"):
			var slot_data = target_control.get_slot_data()
			# 只要 item 为空就清除
			if slot_data.is_empty() or not slot_data.get("item"):
				print("HighlightOverlay: Target slot item is missing, clearing.")
				clear()
				return
		
		# 4. 万全之策：检查当前是否正在拖拽
		# 注意：在 Godot 4 中，gui_is_dragging() 是检查当前窗口是否正在进行拖拽操作的正确方法
		if get_viewport().gui_is_dragging():
			clear()
			return

		_update_rect()

func _update_rect():
	# (Double check internal safety)
	if not is_instance_valid(target_control):
		return

	var rect = target_control.get_global_rect()
	if focus_frame:
		focus_frame.global_position = rect.position
		focus_frame.size = rect.size
	
	if dimmer and dimmer.material:
		# Pass x,y,w,h as vec4
		dimmer.material.set_shader_parameter("target_rect", Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y))
		dimmer.material.set_shader_parameter("screen_size", get_viewport().get_visible_rect().size)
