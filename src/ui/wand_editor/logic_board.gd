extends GraphEdit
class_name WandLogicBoard

signal nodes_changed

var wand_data: WandData
var cell_size = 64
var grid_resolution = 8 # Default
var board_offset = Vector2.ZERO # The top-left of the grid in graph space

func _ready():
	right_disconnects = true
	connection_request.connect(_on_connection_request)
	disconnection_request.connect(_on_disconnection_request)
	delete_nodes_request.connect(_on_delete_nodes_request)
	
	# Enable GraphEdit Standard Features
	minimap_enabled = true
	show_grid = true
	snapping_enabled = true
	snapping_distance = 64
	zoom_min = 0.5
	zoom_max = 2.0
	
	# Improve Port Interaction (Larger Hotzones)
	add_theme_constant_override("port_hotzone_inner_extent", 24)
	add_theme_constant_override("port_hotzone_outer_extent", 32)
	
	# Try to hide the top toolbar if present (optional cleanup)
	var menu = get_menu_hbox()
	if menu:
		menu.visible = false
		
func _process(delta):
	# No longer locking scroll or forcing layout
	pass

func _draw():
	# Standard GraphEdit handles the background and grid now.
	# We only draw custom overlay if needed.
	# Currently disabling custom draw to rely on native infinite canvas.
	pass

func set_data(data: WandData):
	wand_data = data
	grid_resolution = wand_data.embryo.grid_resolution if (wand_data and wand_data.embryo) else 8
	
	# No more board_offset calc
	board_offset = Vector2.ZERO 
	
	load_from_data(wand_data.logic_nodes, wand_data.logic_connections)

var _hover_slot = Vector2(-1, -1)

func _notification(what):
	pass

func _can_drop_data(at_position, data):
	return data is BaseItem

func _drop_data(at_position, data):
	# Mouse is local to GraphEdit top-left
	# Convert to Graph Space
	var canvas_pos = (at_position + scroll_offset) / zoom
	
	# Snap to Grid
	var snapped_pos = canvas_pos.snapped(Vector2(snapping_distance, snapping_distance))
	
	# Check Occupancy
	for child in get_children():
		if child is GraphNode:
			if child.position_offset.distance_to(snapped_pos) < (snapping_distance * 0.5):
				print("Slot Occupied")
				return

	# Capacity Check
	var current_count = 0
	for c in get_children(): if c is GraphNode: current_count += 1
	if wand_data.embryo and current_count >= wand_data.embryo.logic_capacity:
		print("Max Capacity!")
		return

	var node_data = {
		"id": str(Time.get_ticks_msec()) + "_" + str(randi() % 1000),
		"type": data.wand_logic_type,
		"position": snapped_pos,
		"display_name": data.display_name,
		"value": data.wand_logic_value,
		"icon_path": data.icon.resource_path if data.icon else "",
		"visual_color": data.wand_visual_color if "wand_visual_color" in data else Color.GRAY
	}
	add_logic_node(node_data, data)
	nodes_changed.emit()

func _on_connection_request(from_node_name, from_port, to_node_name, to_port):
	connect_node(from_node_name, from_port, to_node_name, to_port)
	nodes_changed.emit()

func _on_disconnection_request(from_node_name, from_port, to_node_name, to_port):
	disconnect_node(from_node_name, from_port, to_node_name, to_port)
	nodes_changed.emit()

func _on_delete_nodes_request(nodes: Array):
	# Remove connections involving these nodes first
	var to_disconnect = []
	for conn in get_connection_list():
		if conn["from_node"] in nodes or conn["to_node"] in nodes:
			to_disconnect.append(conn)
	
	for conn in to_disconnect:
		disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])
	
	for node_name in nodes:
		var node = get_node_or_null(str(node_name))
		if node:
			node.queue_free()
	
	nodes_changed.emit()

func clear_board():
	clear_connections()
	for child in get_children():
		if child is GraphNode:
			child.queue_free()

func load_from_data(nodes: Array, connections: Array):
	clear_board()
	# Create nodes first
	for node_data in nodes:
		add_logic_node(node_data)
	
	# Create connections
	for conn in connections:
		if has_node(str(conn["from_id"])) and has_node(str(conn["to_id"])):
			connect_node(str(conn["from_id"]), conn["from_port"], str(conn["to_id"]), conn["to_port"])

func add_logic_node(node_data: Dictionary, item: BaseItem = null):
	var gnode = GraphNode.new()
	gnode.name = str(node_data.get("id"))
	
	# Use raw position (Graph Space) with snapping
	var raw_pos = node_data.get("position", Vector2.ZERO)
	gnode.position_offset = raw_pos.snapped(Vector2(snapping_distance, snapping_distance))
	
	gnode.resizable = false
	
	# Force fixed size for grid
	gnode.custom_minimum_size = Vector2(64, 64)
	gnode.size = Vector2(64, 64)
	
	# Store key data in meta for retrieval
	gnode.set_meta("node_type", node_data.get("type", "modifier"))
	gnode.set_meta("node_value", node_data.get("value", {}))
	gnode.set_meta("display_name", node_data.get("display_name", "Node"))
	gnode.set_meta("icon_path", node_data.get("icon_path", ""))
	
	# Visual Styling
	var type = node_data.get("type", "modifier")
	
	# Color Coding
	var border_color = Color.GRAY
	if item and item.wand_visual_color:
		border_color = item.wand_visual_color
	elif node_data.has("visual_color"):
		var vc = node_data.get("visual_color")
		if vc is Color:
			border_color = vc
		elif vc is String:
			border_color = Color.html(vc)
	else:
		# Fallbacks for legacy/undefined
		match type:
			"trigger": border_color = Color(1.0, 0.8, 0.2)
			"modifier_damage": border_color = Color(1.0, 0.3, 0.3)
			"modifier_element": border_color = Color(0.2, 0.5, 1.0)
			"splitter": border_color = Color(0.2, 1.0, 0.8)
			"action_projectile": border_color = Color(1.0, 0.4, 0.8)
			"generator": border_color = Color(0.1, 0.9, 0.1) # Default Generator to Green

	gnode.set_meta("visual_color", border_color)

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.1, 0.9) # Dark background matching palette icon style
	sb.border_color = border_color
	# Make it look like a chip
	sb.border_width_bottom = 2
	sb.border_width_top = 2
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	# Compact Margins
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	
	# Selected Style (Glow)
	var sb_selected = sb.duplicate()
	sb_selected.border_color = Color(1.2, 1.2, 1.2) # Brighter
	sb_selected.shadow_size = 4
	sb_selected.shadow_color = border_color
	
	# Remove standard TitleBar
	gnode.add_theme_stylebox_override("panel", sb)
	gnode.add_theme_stylebox_override("panel_selected", sb_selected)
	gnode.add_theme_stylebox_override("titlebar", StyleBoxEmpty.new()) 
	gnode.add_theme_stylebox_override("titlebar_selected", StyleBoxEmpty.new())
	gnode.add_theme_stylebox_override("slot", StyleBoxEmpty.new()) # Fix odd port graphics if any
	gnode.add_theme_constant_override("separation", 0)

	# Content Layout
	var box = CenterContainer.new()
	# Size properly - ensure it fits inside grid
	box.custom_minimum_size = Vector2(64, 64)
	
	# Text Code
	var lbl = Label.new()
	var code = type.left(1).to_upper() # Match Palette Single Char Style
	if type == "action_projectile": code = "!"
	elif type == "modifier_damage": code = "%"
	elif type == "modifier_element": code = "E"
	elif type == "trigger": code = "T"
	elif type == "splitter": code = "Y"
	elif type == "generator": code = "G"
	
	if item and item.display_name:
		# Use first letter of display name if generic
		if code.length() > 1: code = item.display_name.left(1)
	
	lbl.text = code
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", border_color) # Colored text
	box.add_child(lbl)
	
	gnode.add_child(box)

	# --- Tooltip Logic Start ---
	gnode.set_script(preload("res://src/ui/wand_editor/components/logic_node_script.gd"))
	
	var t_title = node_data.get("display_name", "Node")
	var t_desc = ""
	match type:
		"generator": t_desc = "核心组件: 提供魔力源"
		"trigger": t_desc = "触发器: 响应输入信号"
		"modifier_damage": t_desc = "修正: 强化伤害"
		"modifier_speed": t_desc = "修正: 提升飞行速度"
		"modifier_pierce": t_desc = "修正: 增加穿透力"
		"logic_splitter": t_desc = "逻辑: 并行分流"
		"logic_sequence": t_desc = "逻辑: 顺序执行"
		"projectile_tnt": t_desc = "法术: 高爆TNT"
		"projectile_blackhole": t_desc = "法术: 奇点黑洞"
		"projectile_teleport": t_desc = "法术: 传送道标"

	var tooltip = "[b][font_size=18][color=#ffffff]%s[/color][/font_size][/b]" % t_title
	if t_desc != "": tooltip += "\n[color=#cccccc]%s[/color]" % t_desc
	
	var val = node_data.get("value", {})
	if not val.is_empty():
		tooltip += "\n[color=#555555]----------------[/color]"
		for k in val:
			var v = val[k]
			var k_map = {
				"amount": "数值", "damage": "伤害", "speed": "速度", 
				"duration": "持续", "radius": "半径", "force": "力度",
				"cost": "魔耗"
			}
			var k_display = k_map.get(k, k.capitalize())
			
			var v_display = str(v)
			if typeof(v) in [TYPE_INT, TYPE_FLOAT]:
				# Highlight Numbers in Bold Pink
				v_display = "[b][color=#ff88cc]%s[/color][/b]" % str(v)
			
			tooltip += "\n[color=#aaaaaa]%s:[/color] %s" % [k_display, v_display]
	
	# 使用元数据存储 Tooltip 内容，完美避开系统默认黑框提示
	gnode.set_meta("custom_tooltip", tooltip)
	# 显式清空系统内置属性
	gnode.tooltip_text = ""
	
	gnode.mouse_filter = Control.MOUSE_FILTER_STOP # 确保接收鼠标事件
	
	# 仅设置鼠标穿透，不再设置内置 Tooltip 文本，防止系统默认黑框出现
	box.tooltip_text = ""
	box.mouse_filter = Control.MOUSE_FILTER_PASS # 允许穿透给父级节点
	
	# 修正 RichTextLabel 解析：
	# GraphNode 的内置 Tooltip 渲染器可能不支持 BBCode，或者 _make_custom_tooltip 需要正确处理
	# --- Tooltip Logic End ---

	# Interaction: Port Hotzones Only (Removed Scaling)
	# User requested distinct entities, but GraphNode constraint applies.
	# We rely on the theme overrides in _ready for port interaction.

	# Ports styling
	var flow_color = Color(0.0, 1.0, 0.5)
	var branch_color = Color(0.0, 0.8, 1.0)
	
	match type:
		"trigger":
			# Input Enabled (User Request: Trigger is part of chain)
			gnode.set_slot(0, true, 0, flow_color, true, 0, flow_color)
		"splitter":
			gnode.set_slot(0, true, 0, flow_color, true, 0, flow_color)
			# Spacer for branch port
			# Slot 1 is the branch
			gnode.set_slot(1, false, 0, Color.BLACK, true, 0, branch_color)
		"logic_sequence":
			# Sequence: 1 Input, 3 Outputs (Sequential)
			gnode.set_slot(0, true, 0, flow_color, true, 0, flow_color)
			gnode.set_slot(1, false, 0, Color.BLACK, true, 0, flow_color) # Sequence 2
			gnode.set_slot(2, false, 0, Color.BLACK, true, 0, flow_color) # Sequence 3
		"action_projectile":
			gnode.set_slot(0, true, 0, flow_color, false, 0, Color.BLACK)
		"generator":
			# Source node: Output ONLY
			gnode.set_slot(0, false, 0, Color.BLACK, true, 0, flow_color)
		_:
			gnode.set_slot(0, true, 0, flow_color, true, 0, flow_color)
			
	add_child(gnode)

func get_logic_data() -> Dictionary:
	var nodes_out = []
	var conns_out = []
	
	for conn in get_connection_list():
		conns_out.append({
			"from_id": conn["from_node"],
			"from_port": conn["from_port"],
			"to_id": conn["to_node"],
			"to_port": conn["to_port"]
		})
	
	for child in get_children():
		if child is GraphNode:
			var n = {
				"id": child.name,
				"type": child.get_meta("node_type", "modifier"),
				"display_name": child.get_meta("display_name", "Node"),
				"value": child.get_meta("node_value", {}),
				"position": child.position_offset,
				"visual_color": child.get_meta("visual_color", Color.GRAY),
				"icon_path": child.get_meta("icon_path", "")
			}
			nodes_out.append(n)
			
	return { "nodes": nodes_out, "connections": conns_out }
