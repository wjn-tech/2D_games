extends Control
class_name WandEditor

const SimulationBoxScene = preload("res://src/ui/wand_editor/components/simulation_box.tscn")
const WandSelectorScene = preload("res://src/ui/wand_editor/components/wand_selector.tscn")
const WEB_EDITOR_RESOURCE_PATH := "ui/web/wand_editor_shell/index.html"

@onready var visual_grid: WandVisualGrid = $VBoxContainer/MainSplit/RightSplit/CenterWorkspace/VisualGrid
@onready var module_palette: GridContainer = $VBoxContainer/MainSplit/LeftSidebar/LibraryPanel/ModuleScroll/ModulePalette

@onready var logic_board: WandLogicBoard = $VBoxContainer/MainSplit/RightSplit/CenterWorkspace/LogicBoard
@onready var palette_grid: GridContainer = $VBoxContainer/MainSplit/LeftSidebar/LibraryContainer/ScrollContainer/PaletteGrid

@onready var library_panel: VBoxContainer = $VBoxContainer/MainSplit/LeftSidebar/LibraryPanel
@onready var library_container: VBoxContainer = $VBoxContainer/MainSplit/LeftSidebar/LibraryContainer
@onready var stats_container: VBoxContainer = $VBoxContainer/MainSplit/RightSplit/RightSidebar/StatsPanel/StatsContainer

@onready var header: HBoxContainer = find_child("Header", true, false)
@onready var wand_name_label: Label = find_child("WandNameLabel", true, false)

var current_wand: WandData
var current_wand_item: WandItem
var simulation_box
var wand_selector

var preview_texture_rect_1x: TextureRect
var preview_texture_rect_4x: TextureRect
var stats_label: RichTextLabel
var _logic_search_text: String = ""
var _web_editor_webview_node: Node = null
var _using_web_editor: bool = false
var _web_active_tab: String = "logic"
var _web_logic_item_map: Dictionary = {}
var _web_visual_item_map: Dictionary = {}
var _web_sync_lock: bool = false

const WEB_PROTOCOL_VERSION := "1.0"

# Sci-Fi shell colors aligned to the new blue/cyan direction.
const COLOR_BG_MAIN = Color("#0b1020")
const COLOR_ACCENT = Color("#2aa7ff")
const COLOR_ACCENT_DIM = Color("#1b2f58")
const COLOR_TEXT_SEC = Color("#d9ecff")
const COLOR_GLOW = Color(0.18, 0.74, 1.0, 0.45)
const COLOR_WARN = Color("#ffc65a")

func _ready():
	# Ensure WandEditor is always on top of other UI elements (like Hotbar which is z_index 10, Minimap potentially 100)
	z_index = 120
	
	# 让窗口支持在暂停时接收输入
	process_mode = Node.PROCESS_MODE_ALWAYS

	_using_web_editor = _try_setup_web_editor_webview()
	if _using_web_editor:
		_set_native_editor_visible(false)
	else:
		_apply_sci_fi_theme()
		call_deferred("_apply_layout_polish") # Deferred to ensure nodes are ready for reparenting

	_setup_libraries()
	if logic_board:
		logic_board.nodes_changed.connect(_on_logic_changed)
	
	if visual_grid:
		visual_grid.grid_changed.connect(_on_visual_grid_changed)

	visibility_changed.connect(_on_visibility_changed)
	
	# Setup Preview UI
	_setup_preview_ui()
	
	# 初始化属性显示容器
	_setup_stats_ui()
	
	# Setup Simulation Box
	simulation_box = SimulationBoxScene.instantiate()
	simulation_box.visible = false
	simulation_box.set_anchors_preset(Control.PRESET_CENTER)
	simulation_box.custom_minimum_size = Vector2(800, 600)
	add_child(simulation_box)
	
	# Setup Wand Selector
	wand_selector = WandSelectorScene.instantiate()
	wand_selector.visible = false
	wand_selector.set_anchors_preset(Control.PRESET_FULL_RECT) # 改为全屏覆盖
	add_child(wand_selector)
	wand_selector.wand_selected.connect(_on_wand_selected)
	if wand_selector.has_signal("selector_closed"):
		wand_selector.selector_closed.connect(_on_wand_selector_closed)

	if visible:
		_on_visibility_changed()

	_setup_action_row()
	_ensure_logic_search_ui()

func _try_setup_web_editor_webview() -> bool:
	var webview_url := _resolve_webview_url(WEB_EDITOR_RESOURCE_PATH, "WandEditor")
	if webview_url == "":
		return false

	if not ClassDB.class_exists("WebView"):
		push_warning("WandEditor: WebView class unavailable. Check godot-wry plugin enabled, exported addons/godot_wry runtime files, WebView2 runtime, and VC++ x64 redistributable; using native fallback.")
		return false

	var candidate: Object = ClassDB.instantiate("WebView")
	if candidate == null or not (candidate is Node):
		push_warning("WandEditor: Failed to instantiate WebView, using native fallback.")
		return false

	var webview := candidate as Node
	if webview is Control:
		var webview_control := webview as Control
		webview_control.set_anchors_preset(Control.PRESET_FULL_RECT)
		webview_control.mouse_filter = Control.MOUSE_FILTER_STOP

	if _has_property(candidate, &"full_window_size"):
		candidate.set(&"full_window_size", false)
	if _has_property(candidate, &"url"):
		candidate.set(&"url", webview_url)
	if webview.has_method("set_focused_when_created"):
		webview.call("set_focused_when_created", false)
	if webview.has_method("set_forward_input_events"):
		webview.call("set_forward_input_events", false)

	if webview.has_signal("ipc_message"):
		webview.connect("ipc_message", Callable(self, "_on_wand_web_ipc_message"))

	add_child(webview)
	move_child(webview, get_child_count() - 1)

	if webview.has_method("load_url"):
		webview.call("load_url", webview_url)

	_web_editor_webview_node = webview
	return true

func _set_native_editor_visible(make_visible: bool) -> void:
	var root = get_node_or_null("VBoxContainer")
	if root and root is CanvasItem:
		(root as CanvasItem).visible = make_visible


func _resolve_webview_url(resource_path: String, owner_tag: String) -> String:
	var relative_path := resource_path
	if relative_path.begins_with("res://"):
		relative_path = relative_path.substr(6, relative_path.length() - 6)

	var res_path := "res://" + relative_path
	if FileAccess.file_exists(res_path):
		return res_path

	if FileAccess.file_exists(relative_path):
		return relative_path

	push_warning("%s: Web editor HTML missing (check export include_filter for ui/web/*), using native fallback." % owner_tag)
	return ""

func _set_web_editor_visible(make_visible: bool) -> void:
	if not is_instance_valid(_web_editor_webview_node):
		return

	if _web_editor_webview_node.has_method("set_forward_input_events"):
		_web_editor_webview_node.call("set_forward_input_events", make_visible)

	if not make_visible and _web_editor_webview_node.has_method("focus_parent"):
		_web_editor_webview_node.call("focus_parent")

	if _web_editor_webview_node.has_method("set_visible"):
		_web_editor_webview_node.call("set_visible", make_visible)
		return

	if _web_editor_webview_node is CanvasItem:
		(_web_editor_webview_node as CanvasItem).visible = make_visible
		return

	if make_visible:
		if _web_editor_webview_node.has_method("show"):
			_web_editor_webview_node.call("show")
	else:
		if _web_editor_webview_node.has_method("hide"):
			_web_editor_webview_node.call("hide")

func _release_web_editor_focus() -> void:
	if is_instance_valid(_web_editor_webview_node) and _web_editor_webview_node.has_method("set_forward_input_events"):
		_web_editor_webview_node.call("set_forward_input_events", false)

	if is_instance_valid(_web_editor_webview_node) and _web_editor_webview_node.has_method("focus_parent"):
		_web_editor_webview_node.call("focus_parent")

	if is_instance_valid(_web_editor_webview_node) and _web_editor_webview_node is Control:
		var webview_control := _web_editor_webview_node as Control
		if webview_control.has_focus():
			webview_control.release_focus()

	var viewport := get_viewport()
	if viewport:
		viewport.gui_release_focus()

func _sync_web_editor_state() -> void:
	if _web_sync_lock:
		return
	if not is_instance_valid(_web_editor_webview_node):
		return
	if not _web_editor_webview_node.has_method("post_message"):
		return

	var payload := _build_web_editor_state_payload()
	_web_editor_webview_node.call("post_message", JSON.stringify(payload))

	# Legacy minimal payload for compatibility with older shells.
	_web_editor_webview_node.call("post_message", JSON.stringify({
		"type": "wand_state",
		"wand_name": payload.get("wand_name", "未知法杖"),
		"logic_nodes": payload.get("logic_node_count", 0),
		"logic_capacity": payload.get("logic_capacity", 0),
		"mana": payload.get("mana", 0),
		"mana_capacity": payload.get("mana_capacity", 0)
	}))

func _on_wand_web_ipc_message(message: String) -> void:
	var data := _normalize_wand_web_ipc_payload(message)
	if data.is_empty():
		return
	var msg_type := String(data.get("type", ""))

	match msg_type:
		"wand_ready":
			_setup_libraries()
			_sync_web_editor_state()
		"wand_request_state":
			_sync_web_editor_state()
		"wand_close":
			if UIManager:
				UIManager.close_window("WandEditor")
		"wand_test":
			_apply_web_pending_state(data)
			_on_test_spell_pressed()
			_update_stats_display()
		"wand_save":
			_apply_web_pending_state(data)
			_on_save_pressed()
		"wand_switch", "wand_open_selector":
			_open_wand_selector()
		"wand_set_active_tab":
			_set_editor_mode(String(data.get("tab", "logic")))
		"wand_set_name":
			_apply_web_wand_name(String(data.get("wand_name", "")))
		"wand_graph_changed":
			_apply_web_graph_data(data.get("nodes", []), data.get("connections", []))
		"wand_visual_changed":
			_apply_web_visual_cells(data.get("cells", []))
		"wand_clear":
			var mode = String(data.get("mode", _web_active_tab))
			if mode == "visual":
				_set_editor_mode("visual")
			else:
				_set_editor_mode("logic")
			_on_clear_pressed()
			_sync_web_editor_state()

func _normalize_wand_web_ipc_payload(raw_message: String) -> Dictionary:
	var payload = JSON.parse_string(raw_message)
	for _i in range(6):
		if typeof(payload) == TYPE_STRING:
			payload = JSON.parse_string(String(payload))
			continue

		if typeof(payload) != TYPE_DICTIONARY:
			return {}

		var data: Dictionary = payload
		if data.has("type"):
			return data

		if data.has("raw_payload") and typeof(data.get("raw_payload")) == TYPE_STRING:
			payload = JSON.parse_string(String(data.get("raw_payload", "")))
			continue

		var stepped := false
		for key in ["detail", "data", "payload", "message"]:
			if data.has(key):
				payload = data.get(key)
				stepped = true
				break

		if stepped:
			continue

		return data

	return {}

func _setup_action_row() -> void:
	var controls = get_node_or_null("VBoxContainer/HBoxControls")
	if controls == null or not (controls is HBoxContainer):
		return

	var row := controls as HBoxContainer
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 8)

	var save_button = row.get_node_or_null("SaveButton")
	if save_button and save_button is Button:
		var save_btn := save_button as Button
		save_btn.text = "保存"
		save_btn.custom_minimum_size = Vector2(86, 34)

	if row.get_node_or_null("ClearButton") == null:
		var clear_btn := Button.new()
		clear_btn.name = "ClearButton"
		clear_btn.text = "清空"
		clear_btn.custom_minimum_size = Vector2(86, 34)
		clear_btn.pressed.connect(_on_clear_pressed)
		row.add_child(clear_btn)

	if row.get_node_or_null("TestButton") == null:
		var test_btn := Button.new()
		test_btn.name = "TestButton"
		test_btn.text = "测试"
		test_btn.custom_minimum_size = Vector2(86, 34)
		test_btn.pressed.connect(_on_test_spell_pressed)
		row.add_child(test_btn)

	if row.get_node_or_null("SwitchButton") == null:
		var switch_btn := Button.new()
		switch_btn.name = "SwitchButton"
		switch_btn.text = "切换法杖"
		switch_btn.custom_minimum_size = Vector2(106, 34)
		switch_btn.pressed.connect(_open_wand_selector)
		row.add_child(switch_btn)

func _ensure_logic_search_ui() -> void:
	if library_container == null:
		return
	if library_container.get_node_or_null("LogicSearch") != null:
		return

	var search := LineEdit.new()
	search.name = "LogicSearch"
	search.placeholder_text = "搜索..."
	search.custom_minimum_size.y = 30
	search.text_changed.connect(_on_logic_search_changed)
	library_container.add_child(search)
	library_container.move_child(search, 1)

func _on_logic_search_changed(text: String) -> void:
	_logic_search_text = text.strip_edges().to_lower()
	_setup_libraries()

func _on_clear_pressed() -> void:
	if visual_grid and visual_grid.visible:
		visual_grid.grid_data.clear()
		visual_grid._rebuild_grid()
		if current_wand:
			current_wand.visual_grid.clear()
		_update_stats_display()
		return

	if logic_board and logic_board.visible:
		logic_board.clear_board()
		if current_wand:
			current_wand.logic_nodes.clear()
			current_wand.logic_connections.clear()
		_update_stats_display()

func _setup_preview_ui():
	# Add Preview to Visual Library Panel
	var visual_lib_panel = library_panel
	
	var preview_container = VBoxContainer.new()
	preview_container.name = "PreviewContainer"
	
	var label = Label.new()
	label.text = "外观预览"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_container.add_child(label)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	
	# 4x Preview
	var v_4x = VBoxContainer.new()
	var label_4x = Label.new()
	label_4x.text = "4x"
	label_4x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_texture_rect_4x = TextureRect.new()
	preview_texture_rect_4x.custom_minimum_size = Vector2(32, 96) # Aspect ratio 1:3
	preview_texture_rect_4x.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_texture_rect_4x.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
	# Force initial preview update
	_update_wand_preview()
	
	# Background for 4x
	var bg_4x = ColorRect.new()
	bg_4x.custom_minimum_size = Vector2(40, 100)
	bg_4x.color = Color(0.1, 0.1, 0.1)
	bg_4x.add_child(preview_texture_rect_4x)
	preview_texture_rect_4x.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	v_4x.add_child(bg_4x)
	v_4x.add_child(label_4x)
	hbox.add_child(v_4x)
	
	# 1x Preview
	var v_1x = VBoxContainer.new()
	var label_1x = Label.new()
	label_1x.text = "1x"
	label_1x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_texture_rect_1x = TextureRect.new()
	preview_texture_rect_1x.custom_minimum_size = Vector2(16, 48) # 1x3 tiles (16px * 48px)
	preview_texture_rect_1x.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_texture_rect_1x.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Background for 1x
	var bg_1x = ColorRect.new()
	bg_1x.custom_minimum_size = Vector2(20, 52)
	bg_1x.color = Color(0.1, 0.1, 0.1)
	bg_1x.add_child(preview_texture_rect_1x)
	preview_texture_rect_1x.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	v_1x.add_child(bg_1x)
	v_1x.add_child(label_1x)
	hbox.add_child(v_1x)
	
	preview_container.add_child(hbox)
	
	# Insert at top
	visual_lib_panel.add_child(preview_container)
	visual_lib_panel.move_child(preview_container, 0)

func _on_visual_grid_changed():
	if not current_wand: return
	
	# Sync Data and Normalize
	current_wand.visual_grid = visual_grid.grid_data.duplicate()
	current_wand.normalize_grid() # Always ensure Vector2i keys
	
	# Update Preview
	_update_wand_preview()
	# 更新统计数据（模块数量等）
	_update_stats_display()
	if _using_web_editor:
		_sync_web_editor_state()

func _update_wand_preview():
	if not current_wand: return
	var tex = WandTextureGenerator.generate_texture(current_wand)
	if preview_texture_rect_1x:
		preview_texture_rect_1x.texture = tex
	if preview_texture_rect_4x:
		preview_texture_rect_4x.texture = tex

func _resolve_inventory_manager() -> InventoryManager:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var player_inventory = player.get("inventory")
		if player_inventory and player_inventory is InventoryManager:
			return player_inventory

	if GameState and GameState.inventory and GameState.inventory is InventoryManager:
		return GameState.inventory

	return null

func _resolve_equipped_wand_item() -> WandItem:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_equipped_wand"):
		var equipped_from_player = player.get_equipped_wand()
		if equipped_from_player is WandItem:
			return equipped_from_player

	var inventory_manager = _resolve_inventory_manager()
	if inventory_manager and inventory_manager.has_method("get_equipped_item"):
		var equipped_from_inventory = inventory_manager.get_equipped_item()
		if equipped_from_inventory is WandItem:
			return equipped_from_inventory

	return null

func _sync_opened_wand_context() -> void:
	_setup_libraries()

	var equipped_item := _resolve_equipped_wand_item()
	if equipped_item:
		if current_wand_item != equipped_item:
			_on_wand_selected(equipped_item)
		else:
			_update_stats_display()
	elif current_wand:
		_update_stats_display()
	else:
		_open_wand_selector(true)

func _open_wand_selector(force: bool = false):
	if wand_selector == null:
		return

	if _using_web_editor:
		# WebView is an OS-level overlay on some backends; hide it so native selector stays interactive.
		_set_web_editor_visible(false)

	var inventory_manager = _resolve_inventory_manager()
	if inventory_manager == null:
		if _using_web_editor:
			_set_web_editor_visible(true)
		if force:
			push_warning("WandEditor: No inventory manager available when opening wand selector.")
		return

	wand_selector.refresh(inventory_manager)
	wand_selector.visible = true

	# Force fullscreen modal behavior
	wand_selector.set_anchors_preset(Control.PRESET_FULL_RECT)
	wand_selector.custom_minimum_size = Vector2(0, 0) # Reset min size constraint

	# Hide other UI? No, just cover them.
	wand_selector.move_to_front()

	# If forced (initial open), maybe hide close button?
	pass

func _on_wand_selected(item: WandItem):
	current_wand_item = item
	
	# 首先同步 UI 关键信息
	if wand_name_label:
		wand_name_label.text = "正在编辑: " + item.display_name
		
	if header:
		var rename_edit = header.get_node_or_null("RenameEdit")
		if rename_edit:
			rename_edit.text = item.display_name
	
	# 应用数据并刷新展示
	edit_wand(item.wand_data)
	_setup_libraries()
	_update_stats_display()
	
	wand_selector.visible = false
	if _using_web_editor:
		_set_web_editor_visible(true)
		# Some WebView backends can drop messages while hidden; sync after visible.
		call_deferred("_sync_web_editor_state")

func _on_wand_selector_closed() -> void:
	if _using_web_editor:
		_set_web_editor_visible(true)
		call_deferred("_sync_web_editor_state")

func _setup_rename_ui():
	if not header: return
	if header.has_node("RenameEdit"): return
	
	var edit = LineEdit.new()
	edit.name = "RenameEdit"
	edit.placeholder_text = "法杖名称..."
	edit.custom_minimum_size.x = 150
	edit.text_changed.connect(_on_rename_changed)
	header.add_child(edit)
	header.move_child(edit, 0)

func _on_rename_changed(new_text: String):
	if current_wand_item:
		current_wand_item.display_name = new_text
		if wand_name_label:
			wand_name_label.text = "正在编辑: " + new_text

func _setup_stats_ui():
	if not header: return
	if header.has_node("StatsLabel"): 
		stats_label = header.get_node("StatsLabel")
		return
	
	# 确保名字标签不会挤占所有空间
	if wand_name_label:
		wand_name_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		wand_name_label.custom_minimum_size.x = 200

	stats_label = RichTextLabel.new()
	stats_label.name = "StatsLabel"
	stats_label.bbcode_enabled = true
	stats_label.fit_content = true
	stats_label.scroll_active = false
	stats_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stats_label.add_theme_font_size_override("normal_font_size", 16)
	stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stats_label.custom_minimum_size.x = 450
	
	header.add_child(stats_label)

func _process(_delta):
	# Update real-time mana display if visible
	if visible and current_wand:
		_update_mana_display()

func _update_mana_display():
	if not stats_container: return
	var label = stats_container.get_node_or_null("ManaTicker")
	if not label:
		label = RichTextLabel.new()
		label.name = "ManaTicker"
		label.bbcode_enabled = true
		label.fit_content = true
		stats_container.add_child(label)
		stats_container.move_child(label, 0)
	
	var m_color = "cyan" if current_wand.current_mana > current_wand.embryo.mana_capacity * 0.2 else "red"
	label.text = "[center][b]Mana: [color=%s]%.0f[/color] / %d[/b][/center]" % [m_color, current_wand.current_mana, int(current_wand.embryo.mana_capacity)]

func _create_stat_row(icon_path: String, label_text: String, value_text: String, value_color: Color = Color.WHITE) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size.y = 24
	hbox.add_theme_constant_override("separation", 8)
	
	if icon_path != "":
		var icon = TextureRect.new()
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		icon.custom_minimum_size = Vector2(16, 16)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(icon)
	
	var label = Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color("#95b7df"))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)
	
	var value = Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", value_color)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.custom_minimum_size.x = 90
	hbox.add_child(value)
	
	return hbox


func _create_stat_header(text: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size.y = 30
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.08, 0.15, 0.92)
	style.border_color = COLOR_ACCENT
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)

	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", COLOR_ACCENT)
	label.add_theme_font_size_override("font_size", 12)
	panel.add_child(label)
	return panel

func _update_stats_display():
	if not current_wand: return
	
	# 如果胚料丢失，尝试补充默认（防御性编程）
	if not current_wand.embryo:
		current_wand.embryo = WandEmbryo.new()
		current_wand.embryo.recharge_time = 0.5
		current_wand.embryo.mana_capacity = 100
		current_wand.embryo.logic_capacity = 5

	if not stats_label:
		_setup_stats_ui()
	
	var embryo = current_wand.embryo
	
	# Icons
	var i_level = "[img=16]res://assets/ui/icons/icon_level.svg[/img]"
	var i_time = "[img=16]res://assets/ui/icons/icon_time.svg[/img]"
	var i_mana = "[img=16]res://assets/ui/icons/icon_mana.svg[/img]"
	var i_node = "[img=16]res://assets/ui/icons/icon_node.svg[/img]"
	
	# Colors
	var c_val = "[color=#33CCFF]"
	var c_end = "[/color]"
	
	# Top Bar
	var top_text = "[right]%s %s%d%s   %s %s%.2fs%s   %s %s%d%s   %s %s%d/%d%s[/right]" % [
		i_level, c_val, embryo.level, c_end,
		i_time, c_val, embryo.recharge_time, c_end,
		i_mana, c_val, embryo.mana_capacity, c_end,
		i_node, c_val, current_wand.logic_nodes.size(), embryo.logic_capacity, c_end
	]

	if stats_label:
		stats_label.text = top_text
	
	# Sidebar
	if stats_container:
		# Clear existing stats except ManaTicker
		for child in stats_container.get_children():
			if child.name != "ManaTicker":
				child.queue_free()
		
		var debug_plan = SpellProcessor.debug_build_cast_plan(current_wand)
		var plan_valid = bool(debug_plan.get("is_valid", false))
		var compile_errors: Array = debug_plan.get("errors", []) if debug_plan is Dictionary else []
		var sim_stats = SpellProcessor.get_wand_stats(current_wand)
		var sim_duration = sim_stats.get("duration", 0.0) if sim_stats is Dictionary else 0.0
		var sim_dmg = sim_stats.get("total_damage", 0.0) if sim_stats is Dictionary else 0.0
		var sim_projs = sim_stats.get("projectile_count", 0) if sim_stats is Dictionary else 0
		var sim_mana = sim_stats.get("simulated_mana_usage", 0.0) if sim_stats is Dictionary else 0.0
		var diag_label = ""
		var diag_value = ""
		var diag_color = Color("#66ff66")
		if plan_valid:
			sim_duration = float(debug_plan.get("max_fire_delay", sim_duration))
			sim_mana = float(debug_plan.get("total_mana_cost", sim_mana))
			sim_projs = debug_plan.get("emissions", []).size()
			var cycle_mana = float(debug_plan.get("total_mana_cost", 0.0))
			var current_mana = float(current_wand.current_mana)
			if sim_projs <= 0:
				diag_label = "预览异常:"
				diag_value = "没有编译出可发射投射物"
				diag_color = Color("#ff6666")
			else:
				diag_label = "需蓝 / 当前:"
				diag_value = "%.0f / %.0f" % [cycle_mana, current_mana]
				diag_color = Color("#66ff66") if current_mana >= cycle_mana else Color("#ff6666")
		else:
			diag_label = "编译失败:"
			diag_value = str(compile_errors[0]) if not compile_errors.is_empty() else "未知错误"
			diag_color = Color("#ff6666")
		
		stats_container.add_child(_create_stat_header("法杖详细属性"))
		stats_container.add_child(_create_stat_row("res://assets/ui/icons/icon_level.svg", "等级:", str(embryo.level)))
		stats_container.add_child(_create_stat_row("res://assets/ui/icons/icon_time.svg", "施法延迟:", "%.2fs" % embryo.cast_delay, Color("#66ff66")))
		stats_container.add_child(_create_stat_row("res://assets/ui/icons/icon_time.svg", "充能时间:", "%.2fs" % embryo.recharge_time, Color("#66ff66")))
		stats_container.add_child(_create_stat_row("res://assets/ui/icons/icon_mana.svg", "法力容量:", str(int(embryo.mana_capacity)), Color("#66aaff")))
		stats_container.add_child(_create_stat_row("", "  法力回复:", "%d/s" % int(embryo.mana_recharge_speed), Color("#66ffff")))
		stats_container.add_child(_create_stat_row("", "  充能回复:", "+%d" % int(embryo.mana_recharge_burst), Color("#66ffff")))
		stats_container.add_child(_create_stat_row("res://assets/ui/icons/icon_node.svg", "逻辑容量:", "%d 节点" % embryo.logic_capacity, Color.WHITE))
		
		stats_container.add_child(_create_stat_header("法术预览"))
		stats_container.add_child(_create_stat_row("", "单次爆发耗时:", "%.2fs" % sim_duration, Color("#ffff44")))
		stats_container.add_child(_create_stat_row("", "单次爆发法力:", "%.0f" % sim_mana, Color("#66aaff")))
		stats_container.add_child(_create_stat_row("", "理论全额伤害:", "%.1f" % sim_dmg, Color("#ff4444")))
		stats_container.add_child(_create_stat_row("", "投射物数量:", str(sim_projs), Color("#ccccff")))
		stats_container.add_child(_create_stat_row("", diag_label, diag_value, diag_color))
		
		stats_container.add_child(_create_stat_header("实时状态"))
		var block_count = current_wand.visual_grid.size()
		stats_container.add_child(_create_stat_row("", "外观模块:", str(block_count)))
		
		var logic_count = current_wand.logic_nodes.size()
		var logic_color = Color.WHITE if logic_count <= embryo.logic_capacity else Color("#ff4444")
		stats_container.add_child(_create_stat_row("", "已用节点:", "%d / %d" % [logic_count, embryo.logic_capacity], logic_color))

func edit_wand(wand: WandData):
	current_wand = wand
	if current_wand:
		current_wand.normalize_grid()
	
	if logic_board:
		logic_board.set_data(wand)
	
	if current_wand_item and wand_name_label:
		wand_name_label.text = "正在编辑: " + current_wand_item.display_name
	
	if current_wand_item and header:
		var rename_edit = header.get_node_or_null("RenameEdit")
		if rename_edit:
			rename_edit.text = current_wand_item.display_name
	
	# 添加改名输入框（如果不存在）
	_setup_rename_ui()
	# 更新属性显示
	_update_stats_display()
	
	if visual_grid:
		# Use standard vertically long wand spec: 16x48
		visual_grid.setup(16, 48)
		visual_grid.grid_data = wand.visual_grid.duplicate()
		visual_grid._rebuild_grid()
	
	visible = true

func _exit_tree():
	# FAILSAFE: Ensure game is unpaused and input restored when this node is destroyed
	# This handles queue_free() from UIManager which might bypass visibility signals
	_release_web_editor_focus()
	if is_instance_valid(_web_editor_webview_node):
		_web_editor_webview_node.queue_free()
		_web_editor_webview_node = null

	if get_tree():
		get_tree().paused = false
	if EventBus:
		EventBus.player_input_enabled.emit(true)
		# 确保即使 UIManager 没有发出信号，这里也会发出，作为双重保险
		EventBus.wand_editor_closed.emit()

func _input(event: InputEvent) -> void:
	# 允许按 K 键关闭编辑器，即使在暂停状态下
	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		if _using_web_editor:
			_set_web_editor_visible(false)
			_release_web_editor_focus()
		if UIManager:
			UIManager.close_window("WandEditor")
		get_viewport().set_input_as_handled()

func _on_visibility_changed():
	if visible:
		EventBus.wand_editor_opened.emit()
		get_tree().paused = true # Diegetic UI Pause

		if not _using_web_editor:
			_apply_sci_fi_theme() # Refresh theme

		_sync_opened_wand_context()
		if _using_web_editor:
			_set_web_editor_visible(true)
			_sync_web_editor_state()
			
		_animate_open()
	else:
		# This branch might not run if queue_free happens immediately, 
		# so we rely on _exit_tree for critical cleanup too.
		if _using_web_editor:
			_set_web_editor_visible(false)
			_release_web_editor_focus()
		get_tree().paused = false 
		EventBus.player_input_enabled.emit(true)
		EventBus.wand_editor_closed.emit()
		
		if UIManager:
			UIManager.close_window("WandEditor")

func _time_str(val):
	return "%.2fs" % val

func _on_test_spell_pressed():
	if not current_wand: return
	# Sync Logic Data from Board to Resource (Memory Only)
	var logic_data = logic_board.get_logic_data()
	current_wand.logic_nodes = logic_data["nodes"]
	current_wand.logic_connections = logic_data["connections"]
	
	simulation_box.setup(current_wand)

func _setup_libraries():
	if palette_grid:
		palette_grid.columns = 1
		palette_grid.add_theme_constant_override("h_separation", 6)
		palette_grid.add_theme_constant_override("v_separation", 6)

	# --- Logic Library ---
	# 1. Define all possible logic items
	var logic_items = [
		_create_mock_item(tr("generator"), "generator", Color(0.2, 1.0, 0.4), {"mana_cost": 0, "delay": 0.05, "damage": 0}, null),
		_create_mock_item(tr("trigger") + " (释放)", "trigger", Color(1, 0.84, 0.0), {"mana_cost": 2, "trigger_type": "cast", "delay": 0.1}, null), 
		_create_mock_item(tr("trigger") + " (命中)", "trigger", Color(1, 0.5, 0.0), {"mana_cost": 5, "trigger_type": "collision", "delay": 0.0}, null),
		_create_mock_item(tr("trigger") + " (定时)", "trigger", Color(1, 0.8, 0.3), {"mana_cost": 5, "trigger_type": "timer", "duration": 0.5, "delay": 0.0}, null),
		
		_create_mock_item(tr("fire"), "modifier_element", Color(0.8, 0.2, 0.2), {"mana_cost": 10, "element": "fire", "damage_add": 5, "delay": 0.1}, null),
		_create_mock_item(tr("ice"), "modifier_element", Color(0.2, 0.6, 0.9), {"mana_cost": 10, "element": "ice", "damage_add": 2, "delay": 0.05}, null),
		_create_mock_item(tr("modifier_damage"), "modifier_damage", Color(0.6, 0.6, 0.6), {"mana_cost": 15, "amount": 10, "delay": 0.05}, null),
		_create_mock_item(tr("modifier_damage"), "modifier_damage", Color(1.0, 0.2, 0.2), {"mana_cost": 25, "amount": 25, "delay": 0.15}, null),
		_create_mock_item(tr("modifier_pierce"), "modifier_pierce", Color(0.8, 0.2, 0.8), {"mana_cost": 30, "pierce": 1, "delay": 0.1}, null),
		_create_mock_item(tr("modifier_speed"), "modifier_speed", Color(0.2, 0.8, 0.6), {"mana_cost": 5, "speed_add": 200, "delay": -0.05}, null),
		_create_mock_item(tr("modifier_speed"), "modifier_speed", Color(0.5, 1.0, 0.5), {"mana_cost": 10, "multiplier": 1.5, "delay": -0.01}, null),
		_create_mock_item(tr("modifier_delay"), "modifier_delay", Color(0.4, 0.4, 0.4), {"mana_cost": 0, "recharge": -0.15, "delay": -0.05}, null),
		_create_mock_item("增加法力", "modifier_add_mana", Color(0.0, 0.6, 1.0), {"mana_cost": -30, "delay": 0.05}, null),
		
		_create_mock_item(tr("splitter"), "splitter", Color(0.0, 0.9, 0.9), {"mana_cost": 2, "delay": 0.0}, null),
		_create_mock_item(tr("logic_sequence"), "logic_sequence", Color(0.5, 0.5, 0.5), {"mana_cost": 1, "delay": 0.1}, null),
		
		_create_mock_item(tr("action_projectile"), "action_projectile", Color(0.9, 0.4, 0.4), {"mana_cost": 10, "speed": 500.0, "damage": 10.0, "delay": 0.2}, null),
		_create_mock_item(tr("spark_bolt"), "action_projectile", Color(0.8, 0.9, 10.0), {"projectile_id": "spark_bolt", "mana_cost": 5, "speed": 800.0, "damage": 3.0, "delay": 0.05}, null),
		_create_mock_item(tr("magic_bolt"), "action_projectile", Color(10.0, 1.5, 30.0), {"projectile_id": "magic_bolt", "mana_cost": 25, "speed": 600.0, "damage": 15.0, "delay": 0.1}, null),
		_create_mock_item(tr("bouncing_burst"), "action_projectile", Color(10.0, 10.0, 1.0), {"projectile_id": "bouncing_burst", "mana_cost": 15, "speed": 400.0, "damage": 5.0, "delay": 0.1}, null),
		_create_mock_item(tr("tri_bolt"), "action_projectile", Color(0.1, 30.0, 10.0), {"projectile_id": "tri_bolt", "mana_cost": 35, "speed": 500.0, "damage": 8.0, "delay": 0.2}, null),
		_create_mock_item(tr("chainsaw"), "action_projectile", Color(20.0, 20.0, 20.0), {"projectile_id": "chainsaw", "mana_cost": 1, "speed": 100.0, "damage": 1.0, "delay": 0.0, "recharge": -0.17}, null),
		_create_mock_item(tr("slime"), "action_projectile", Color(0.0, 1.0, 0.0), {"projectile_id": "slime", "mana_cost": 12, "speed": 400.0, "damage": 12.0, "element": "slime", "delay": 0.15}, null),
		_create_mock_item(tr("tnt"), "action_projectile", Color(0.9, 0.2, 0.2), {"projectile_id": "tnt", "mana_cost": 40, "damage": 50, "lifetime": 3.0, "speed": 200.0, "delay": 0.5}, null),
		_create_mock_item(tr("blackhole"), "action_projectile", Color(0.1, 0.0, 0.2), {"projectile_id": "blackhole", "mana_cost": 180, "damage": 5, "lifetime": 8.0, "speed": 50.0, "delay": 0.8}, null),
		_create_mock_item(tr("teleport"), "action_projectile", Color(0.6, 0.2, 0.8), {"projectile_id": "teleport", "mana_cost": 15, "damage": 0, "lifetime": 1.0, "speed": 800.0, "delay": 0.3}, null),
		
		# New Spells V1
		_create_mock_item(tr("vampire_bolt"), "action_projectile", Color(0.55, 0.0, 0.0), {"projectile_id": "vampire_bolt", "mana_cost": 50, "damage": 5.0, "speed": 600.0, "delay": 0.2}, null),
		_create_mock_item(tr("healing_circle"), "action_projectile", Color(0.3, 0.8, 0.5), {"projectile_id": "healing_circle", "mana_cost": 100, "lifetime": 1.5, "speed": 0.0, "delay": 0.5}, null)
	]

	# Additional Noita-like modifiers and projectiles (from Noita wiki inspiration)
	# Projectile modifiers
	logic_items.append(_create_mock_item(tr("heavy_shot"), "modifier_damage", Color(0.9, 0.4, 0.2), {"mana_cost": 20, "damage_add": 30, "speed_multiplier": 0.6, "delay": 0.05}, null))
	logic_items.append(_create_mock_item(tr("light_shot"), "modifier_damage", Color(0.6, 0.9, 0.6), {"mana_cost": 12, "damage_add": -5, "speed_multiplier": 1.5, "delay": 0.02}, null))
	logic_items.append(_create_mock_item(tr("modifier_lifetime"), "modifier_lifetime", Color(0.3, 0.6, 1.0), {"mana_cost": 8, "lifetime_add": 1.5, "delay": 0.02}, null))
	logic_items.append(_create_mock_item(tr("modifier_pierce"), "modifier_pierce", Color(0.8, 0.2, 0.8), {"mana_cost": 25, "pierce": 2, "delay": 0.05}, null))
	logic_items.append(_create_mock_item(tr("homing"), "modifier_homing", Color(0.9, 0.7, 0.2), {"mana_cost": 30, "homing_strength": 0.8, "delay": 0.05}, null))
	logic_items.append(_create_mock_item("爆炸反弹", "modifier_bounce_explosive", Color(1.0, 0.4, 0.1), {"mana_cost": 18, "explode_on_bounce": true, "delay": 0.05}, null))
	logic_items.append(_create_mock_item("火弧", "modifier_arc_fire", Color(0.9, 0.2, 0.1), {"mana_cost": 14, "arc_type": "fire", "delay": 0.02}, null))
	logic_items.append(_create_mock_item("法力转伤", "modifier_mana_to_damage", Color(0.7, 0.2, 0.9), {"mana_cost": 0, "damage_multiplier": 1.2, "delay": 0.0}, null))
	logic_items.append(_create_mock_item(tr("modifier_orbit"), "modifier_orbit", Color(0.5, 0.0, 0.5), {"mana_cost": 30, "delay": 0.1}, null))

	# Additional projectile spells
	logic_items.append(_create_mock_item(tr("fireball"), "action_projectile", Color(1.0, 0.45, 0.1), {"projectile_id": "fireball", "mana_cost": 35, "damage": 22, "lifetime": 2.5, "speed": 300.0, "delay": 0.25}, null))
	logic_items.append(_create_mock_item(tr("magic_arrow"), "action_projectile", Color(0.8, 0.5, 1.0), {"projectile_id": "magic_arrow", "mana_cost": 18, "damage": 12, "lifetime": 1.8, "speed": 700.0, "delay": 0.08}, null))
	logic_items.append(_create_mock_item("能量球", "action_projectile", Color(0.6, 0.9, 1.0), {"projectile_id": "energy_sphere", "mana_cost": 28, "damage": 18, "lifetime": 2.2, "speed": 450.0, "delay": 0.12}, null))
	logic_items.append(_create_mock_item("分裂弹", "action_projectile", Color(0.9, 0.6, 0.1), {"projectile_id": "cluster_bomb", "mana_cost": 45, "damage": 12, "lifetime": 1.2, "speed": 250.0, "delay": 0.4}, null))

	
	for child in palette_grid.get_children():
		child.queue_free()
	
	# 2. Filter based on Unlocked Status
	var always_unlocked = [
		"generator", "trigger_cast", "action_projectile", 
		"modifier_speed", "modifier_delay"
	] # Basic set: Only source, cast trigger, base projectile and basic speed/delay
	
	# Fix: Currently forcing everything unlocked for testing because GameState unlock logic is incomplete
	# To restore limited spell set: is_unlocked = false by default, then check always_unlocked + GameState.
	# The user requested "Back to only basic spells".
	
	if GameState:
		# Add GameState unlocks to allowed list
		# (Or check against them)
		pass

	for item in logic_items:
		var item_id = _get_item_id(item)
		if _logic_search_text != "" and not item.display_name.to_lower().contains(_logic_search_text):
			continue
		
		# Restoring Proper Lock Logic
		var is_unlocked = false
		if item_id in always_unlocked: 
			is_unlocked = true
		elif GameState and item_id in GameState.unlocked_spells:
			is_unlocked = true
		
		# DEBUG OVERRIDE WAS HERE. REMOVING IT per user request.
		
		if is_unlocked:
			_add_logic_palette_button(palette_grid, item)

	# --- Module Library (Visual) ---
	var module_items = [
		# Structure - Grays/Metals
		_create_mock_item("外壳 (深色)", "hull", Color(0.2, 0.2, 0.25), {}, null), 
		_create_mock_item("外壳 (灰色)", "hull", Color(0.5, 0.53, 0.6), {}, null), 
		_create_mock_item("外壳 (浅色)", "hull", Color(0.7, 0.75, 0.8), {}, null),
		_create_mock_item("框架 (锈迹)", "structure", Color(0.45, 0.3, 0.2), {}, null),
		_create_mock_item("框架 (钢材)", "structure", Color(0.3, 0.35, 0.4), {}, null),
		_create_mock_item("黄金装饰", "structure", Color(0.8, 0.6, 0.2), {}, null),
		
		# Energy / Magic - Brights
		_create_mock_item("蓝动力源", "battery", Color(0.2, 0.6, 1.0), {}, null),
		_create_mock_item("红动力源", "battery", Color(0.9, 0.2, 0.2), {}, null),
		_create_mock_item("绿动力源", "battery", Color(0.2, 0.9, 0.4), {}, null),
		_create_mock_item("紫色水晶", "battery", Color(0.7, 0.2, 0.9), {}, null),
		_create_mock_item("青色水晶", "battery", Color(0.2, 0.9, 1.0), {}, null),
		
		# Wood / Nature
		_create_mock_item("木材 (深色)", "structure", Color(0.4, 0.25, 0.1), {}, null),
		_create_mock_item("木材 (浅色)", "structure", Color(0.6, 0.4, 0.2), {}, null),
		_create_mock_item("叶片", "decoration", Color(0.2, 0.6, 0.2), {}, null),
		
		# Misc
		_create_mock_item("通风口", "vent", Color(0.1, 0.1, 0.1), {}, null),
		_create_mock_item("显示屏", "screen", Color(0.0, 0.8, 0.8), {}, null),
		_create_mock_item("等离子灯", "light", Color(1.0, 1.0, 0.6), {}, null)
	]
	
	for child in module_palette.get_children():
		child.queue_free()
		
	for item in module_items:
		_add_visual_palette_button(module_palette, item)

	_rebuild_web_item_maps()

func _get_item_id(item: Resource) -> String:
	var type = item.wand_logic_type
	var val = item.wand_logic_value
	
	if type == "generator": return "generator"
	if type == "trigger":
		if val.get("trigger_type") == "cast": return "trigger_cast"
		if val.get("trigger_type") == "collision": return "trigger_collision"
		if val.get("trigger_type") == "timer": return "trigger_timer"
	
	if type == "modifier_element":
		var elem = val.get("element", "")
		# BaseNPC code handles standard modifier prefixes
		return "modifier_element_" + elem
		
	if type == "modifier_damage": 
		if val.get("amount", 0) > 10: return "modifier_damage_plus"
		return "modifier_damage"
	if type == "modifier_pierce": return "modifier_pierce"
	if type == "modifier_speed": 
		if val.has("multiplier"): return "modifier_speed_plus"
		return "modifier_speed"
	if type == "modifier_delay": return "modifier_delay"
	if type == "modifier_add_mana": return "modifier_add_mana"
	if type == "modifier_mana_to_damage": return "modifier_mana_to_damage"
	if type == "modifier_orbit": return "modifier_orbit"
	
	if type == "splitter": return "logic_splitter"
	if type == "logic_sequence": return "logic_sequence"
	
	if type == "action_projectile":
		var pid = val.get("projectile_id", "")
		if pid == "": return "action_projectile"
		return "projectile_" + pid
		if pid == "" or pid == "basic": return "action_projectile"
	
	return item.id # Fallback

func _add_visual_palette_button(parent, item):
	var btn = PanelContainer.new()
	btn.custom_minimum_size = Vector2(50, 50)
	parent.add_child(btn)

	_setup_interactive_glow(btn)
	
	if not ResourceLoader.exists("res://src/ui/wand_editor/components/visual_palette_button.gd"):
		push_error("Visual Palette Button script missing!")
		return

	var vscr = load("res://src/ui/wand_editor/components/visual_palette_button.gd")
	if vscr:
		btn.set_script(vscr)
	btn.setup(item)
	
	# Connect Selection Signal
	if btn.has_signal("item_selected"):
		btn.item_selected.connect(_on_palette_item_selected)

func _add_logic_palette_button(parent, item):
	var btn = PanelContainer.new()
	btn.custom_minimum_size = Vector2(110, 80)
	parent.add_child(btn)
	_setup_interactive_glow(btn)
	
	if not ResourceLoader.exists("res://src/ui/wand_editor/components/logic_palette_button.gd"):
		# Fallback if I haven't created it yet, but I just did.
		push_error("Logic Palette Button script missing!")
		return

	var lscr = load("res://src/ui/wand_editor/components/logic_palette_button.gd")
	if lscr:
		btn.set_script(lscr)
	
	# Add metadata for Tutorial System lookup
	if has_method("_get_item_id"):
		btn.set_meta("item_id", _get_item_id(item))
	
	btn.setup(item)

func _on_palette_item_selected(item):
	if visual_grid:
		visual_grid.selected_material = item
		print("Selected material: ", item.id)

# _create_palette_button_script REMOVED as files are now static

func _create_mock_item(name, type, color, val = {}, icon_path = null):
	var item = BaseItem.new()
	item.display_name = name
	item.wand_logic_type = type
	item.wand_visual_color = color
	item.wand_logic_value = val
	if item.description.strip_edges() == "":
		var detail_parts: Array[String] = []
		if val is Dictionary:
			if val.has("mana_cost"):
				detail_parts.append("法力: %s" % str(val.get("mana_cost", 0)))
			if val.has("delay"):
				detail_parts.append("延迟: %ss" % str(val.get("delay", 0)))
			if val.has("damage"):
				detail_parts.append("伤害: %s" % str(val.get("damage", 0)))
			if val.has("projectile_id"):
				detail_parts.append("弹体: %s" % str(val.get("projectile_id", "")))
		item.description = "%s\n%s" % [name, " | ".join(detail_parts)] if not detail_parts.is_empty() else name
	if item.id == null or String(item.id).strip_edges() == "":
		item.id = _make_item_slug(name, type)
	
	if icon_path:
		if ResourceLoader.exists(icon_path):
			item.icon = ResourceLoader.load(icon_path)
		elif FileAccess.file_exists(icon_path):
			item.icon = load(icon_path)
		elif ResourceLoader.exists(icon_path + ".import"):
			item.icon = ResourceLoader.load(icon_path + ".import")
		elif FileAccess.file_exists(icon_path + ".import"):
			item.icon = load(icon_path + ".import")
		else:
			# fallback to no icon; button will be colored
			pass
	return item

func _on_save_pressed():
	if not current_wand:
		return
		
	# Update Logic Data
	var logic_data = logic_board.get_logic_data()
	current_wand.logic_nodes = logic_data["nodes"]
	current_wand.logic_connections = logic_data["connections"]
	
	# COMPILER VALIDATION
	var program = WandCompiler.compile(current_wand)
	if not program.is_valid:
		push_warning("Wand Logic Invalid: " + str(program.compilation_errors))
		# In a real UI, show a popup here.
		# For now, we block saving? Or just print warning?
		# Let's print and allow save (so work isn't lost), but cache won't be valid.
	else:
		current_wand.compiled_program = program
	
	# Update Visual Data
	current_wand.visual_grid = visual_grid.grid_data.duplicate()
	
	# Persist to disk
	if current_wand.resource_path:
		var err = ResourceSaver.save(current_wand, current_wand.resource_path)
		if err == OK:
			print("Wand resource saved to: ", current_wand.resource_path)
		else:
			push_error("Failed to save wand resource: %d" % err)
	
	if UIManager:
		UIManager.close_window("WandEditor")
		# Toggle HUD back on handled by UIManager


func _on_logic_changed():
	if not current_wand or not logic_board: return
	# 同步逻辑数据以更新统计信息
	var logic_data = logic_board.get_logic_data()
	current_wand.logic_nodes = logic_data["nodes"]
	current_wand.logic_connections = logic_data["connections"]
	_update_stats_display()
	if _using_web_editor:
		_sync_web_editor_state()
	EventBus.spell_logic_updated.emit(current_wand)

func _on_visual_grid_cell_clicked(coords, btn_index):
	# Logic to place "Currently Selected Material"
	# For now, let's assume we have a test material
	var test_mat = BaseItem.new()
	test_mat.wand_visual_color = Color.RED
	test_mat.id = "test_red_block"
	visual_grid.set_cell(coords, test_mat)

func _apply_sci_fi_theme():
	var runtime_theme := Theme.new()

	var bg_node = get_node_or_null("BackgroundColor")
	if bg_node and bg_node is ColorRect:
		var bg_rect := bg_node as ColorRect
		bg_rect.color = Color(0.02, 0.04, 0.08, 0.96)

	# Buttons
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.04, 0.09, 0.16, 0.78)
	btn_normal.border_width_left = 1
	btn_normal.border_width_top = 1
	btn_normal.border_width_right = 1
	btn_normal.border_width_bottom = 1
	btn_normal.border_color = COLOR_ACCENT_DIM
	btn_normal.corner_radius_top_left = 6
	btn_normal.corner_radius_top_right = 6
	btn_normal.corner_radius_bottom_left = 6
	btn_normal.corner_radius_bottom_right = 6
	btn_normal.content_margin_left = 10
	btn_normal.content_margin_right = 10
	btn_normal.content_margin_top = 6
	btn_normal.content_margin_bottom = 6

	var btn_hover := btn_normal.duplicate()
	btn_hover.bg_color = Color(0.06, 0.16, 0.27, 0.92)
	btn_hover.border_color = COLOR_ACCENT
	btn_hover.border_width_left = 2
	btn_hover.border_width_top = 2
	btn_hover.border_width_right = 2
	btn_hover.border_width_bottom = 2
	btn_hover.shadow_color = COLOR_GLOW
	btn_hover.shadow_size = 8

	var btn_pressed := btn_normal.duplicate()
	btn_pressed.bg_color = Color(0.12, 0.27, 0.45, 0.95)
	btn_pressed.border_color = Color(0.78, 0.92, 1.0, 0.95)
	btn_pressed.shadow_color = COLOR_GLOW
	btn_pressed.shadow_size = 4

	runtime_theme.set_stylebox("normal", "Button", btn_normal)
	runtime_theme.set_stylebox("hover", "Button", btn_hover)
	runtime_theme.set_stylebox("pressed", "Button", btn_pressed)
	runtime_theme.set_stylebox("focus", "Button", btn_hover)

	# LineEdit
	var edit_style := StyleBoxFlat.new()
	edit_style.bg_color = Color(0.01, 0.05, 0.1, 0.9)
	edit_style.border_width_left = 1
	edit_style.border_width_top = 1
	edit_style.border_width_right = 1
	edit_style.border_width_bottom = 1
	edit_style.border_color = COLOR_ACCENT_DIM
	edit_style.corner_radius_top_left = 5
	edit_style.corner_radius_top_right = 5
	edit_style.corner_radius_bottom_left = 5
	edit_style.corner_radius_bottom_right = 5
	edit_style.content_margin_left = 8
	edit_style.content_margin_right = 8
	edit_style.content_margin_top = 6
	edit_style.content_margin_bottom = 6
	runtime_theme.set_stylebox("normal", "LineEdit", edit_style)
	runtime_theme.set_stylebox("focus", "LineEdit", edit_style)

	# Graph board
	var graph_bg := StyleBoxFlat.new()
	graph_bg.bg_color = Color(0.01, 0.05, 0.1, 0.94)
	runtime_theme.set_stylebox("bg", "GraphEdit", graph_bg)
	runtime_theme.set_color("grid_major", "GraphEdit", Color(0.22, 0.72, 1.0, 0.22))
	runtime_theme.set_color("grid_minor", "GraphEdit", Color(0.22, 0.72, 1.0, 0.08))
	runtime_theme.set_color("activity", "GraphEdit", COLOR_ACCENT)

	# Label / text colors
	runtime_theme.set_color("font_color", "Label", COLOR_TEXT_SEC)
	runtime_theme.set_color("font_color", "Button", COLOR_TEXT_SEC)
	runtime_theme.set_color("font_color_disabled", "Button", COLOR_TEXT_SEC.darkened(0.45))

	# Scroll bars
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.05, 0.08, 0.7)
	sb.border_color = COLOR_ACCENT_DIM
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.corner_radius_top_left = 4
	sb.corner_radius_bottom_right = 4
	runtime_theme.set_stylebox("vertical", "ScrollBar", sb)
	runtime_theme.set_stylebox("horizontal", "ScrollBar", sb)

	self.theme = runtime_theme
	if header:
		header.theme = runtime_theme
	if logic_board:
		logic_board.theme = runtime_theme
	if visual_grid:
		visual_grid.theme = runtime_theme
	if module_palette:
		module_palette.theme = runtime_theme
	if palette_grid:
		palette_grid.theme = runtime_theme

	_ensure_section_frame("VBoxContainer/MainSplit/LeftSidebar", Color(0.03, 0.09, 0.16, 0.86), COLOR_ACCENT_DIM, COLOR_GLOW)
	_ensure_section_frame("VBoxContainer/MainSplit/RightSplit/CenterWorkspace", Color(0.01, 0.06, 0.11, 0.92), COLOR_ACCENT, COLOR_GLOW)
	_ensure_section_frame("VBoxContainer/MainSplit/RightSplit/RightSidebar", Color(0.03, 0.09, 0.16, 0.86), COLOR_ACCENT_DIM, COLOR_GLOW)

	if wand_name_label:
		wand_name_label.add_theme_color_override("font_color", COLOR_WARN)


func _ensure_section_frame(path: String, fill_color: Color, border_color: Color, glow_color: Color) -> void:
	var node := get_node_or_null(path)
	if node == null or not (node is Control):
		return

	var target := node as Control
	var frame = target.get_node_or_null("__SectionFrame")
	if frame == null:
		var panel := Panel.new()
		panel.name = "__SectionFrame"
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		target.add_child(panel)
		target.move_child(panel, 0)
		frame = panel

	if frame is Panel:
		var panel_frame := frame as Panel
		panel_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var style := StyleBoxFlat.new()
		style.bg_color = fill_color
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = border_color
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.shadow_color = glow_color
		style.shadow_size = 10
		panel_frame.add_theme_stylebox_override("panel", style)

func _animate_open():
	# Origin at center
	set_pivot_offset(size / 2)
	scale = Vector2(0.95, 0.95) # Slight zoom in
	modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.3)
	tw.tween_property(self, "modulate:a", 1.0, 0.25)

func _setup_interactive_glow(node: Control):
	# Assuming node can receive mouse events. 
	# If PanelContainer logic/visual script consumes them, we might need to filter = PASS
	node.mouse_filter = Control.MOUSE_FILTER_PASS
	
	node.mouse_entered.connect(func():
		var tw = create_tween()
		tw.tween_property(node, "modulate", Color(1.3, 1.3, 1.5), 0.1)
	)
	node.mouse_exited.connect(func():
		var tw = create_tween()
		tw.tween_property(node, "modulate", Color.WHITE, 0.2)
	)

func _apply_layout_polish():
	# 1. Padding via MarginContainer
	var vbox = get_node_or_null("VBoxContainer")
	if vbox and vbox.get_parent() == self:
		var margin = MarginContainer.new()
		margin.name = "MainPadding"
		# Set full rect
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_top", 20)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_theme_constant_override("margin_bottom", 20)
		
		# Reparent VBoxContainer (careful with references)
		remove_child(vbox)
		margin.add_child(vbox)
		add_child(margin)
		
		# Index 0 is Panel, we want Margin at index 1
		move_child(margin, 1)
		
		# Ensure VBox expands
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 2. Sidebar Min Sizes
	var left_sidebar = find_child("LeftSidebar", true, false)
	if left_sidebar:
		left_sidebar.custom_minimum_size.x = 250
		
	var right_sidebar = find_child("RightSidebar", true, false)
	if right_sidebar:
		right_sidebar.custom_minimum_size.x = 290

	var main_split = find_child("MainSplit", true, false)
	if main_split and main_split is HSplitContainer:
		(main_split as HSplitContainer).split_offset = 260

	var right_split = find_child("RightSplit", true, false)
	if right_split and right_split is HSplitContainer:
		(right_split as HSplitContainer).split_offset = -300

	var visual_title = get_node_or_null("VBoxContainer/MainSplit/LeftSidebar/LibraryPanel/Title")
	if visual_title and visual_title is Label:
		var vt := visual_title as Label
		vt.text = "外观模块库"
		vt.add_theme_color_override("font_color", Color("#9bc4f2"))

	var logic_title = get_node_or_null("VBoxContainer/MainSplit/LeftSidebar/LibraryContainer/Label")
	if logic_title and logic_title is Label:
		var lt := logic_title as Label
		lt.text = "逻辑节点库"
		lt.add_theme_color_override("font_color", Color("#9bc4f2"))

	# 3. Apply ButtonGroup styles
	var mode_switcher = find_child("ModeSwitcher", true, false)
	if mode_switcher:
		for btn in mode_switcher.get_children():
			if btn is Button:
				var mode_btn := btn as Button
				if mode_btn.name == "VisualModeButton":
					mode_btn.text = "外观"
				elif mode_btn.name == "LogicModeButton":
					mode_btn.text = "逻辑"
				mode_btn.custom_minimum_size = Vector2(0, 34)
				btn.add_theme_stylebox_override("normal", theme.get_stylebox("normal", "Button"))
				btn.add_theme_stylebox_override("pressed", theme.get_stylebox("pressed", "Button"))
				btn.add_theme_stylebox_override("hover", theme.get_stylebox("hover", "Button"))
				btn.add_theme_stylebox_override("focus", theme.get_stylebox("focus", "Button"))
				
				# Custom toggle logic for visual feedback
				btn.toggled.connect(func(is_pressed):
					if is_pressed:
						btn.add_theme_color_override("font_color", COLOR_ACCENT)
					else:
						btn.add_theme_color_override("font_color", COLOR_TEXT_SEC)
				)
				# Initialize color
				if btn.button_pressed:
					btn.add_theme_color_override("font_color", COLOR_ACCENT)
				else:
					btn.add_theme_color_override("font_color", COLOR_TEXT_SEC)

func _on_visual_mode_toggled(toggled_on: bool):
	if toggled_on:
		_set_editor_mode("visual")

func _on_logic_mode_toggled(toggled_on: bool):
	if toggled_on:
		_set_editor_mode("logic")

func get_palette_button_by_item_id(item_id: String) -> Control:
	if not palette_grid: return null
	for child in palette_grid.get_children():
		if child.has_meta("item_id"):
			if child.get_meta("item_id") == item_id:
				return child
	return null

func get_logic_node_by_type(node_type: String) -> Control:
	if not logic_board: return null
	for child in logic_board.get_children():
		if child is GraphNode and child.has_meta("node_type"):
			if child.get_meta("node_type") == node_type:
				return child
	return null

func get_grid_cell_global_position(x: int, y: int) -> Vector2:
	if not logic_board: return Vector2.ZERO
	if logic_board.has_method("get_grid_global_position"):
		return logic_board.get_grid_global_position(x, y)
	return Vector2.ZERO

func _set_editor_mode(mode: String) -> void:
	var normalized := mode.to_lower()
	if normalized != "visual":
		normalized = "logic"

	_web_active_tab = normalized

	if library_panel:
		library_panel.visible = normalized == "visual"
	if library_container:
		library_container.visible = normalized == "logic"
	if visual_grid:
		visual_grid.visible = normalized == "visual"
	if logic_board:
		logic_board.visible = normalized == "logic"

	var visual_btn = get_node_or_null("VBoxContainer/MainSplit/LeftSidebar/ModeSwitcher/VisualModeButton")
	var logic_btn = get_node_or_null("VBoxContainer/MainSplit/LeftSidebar/ModeSwitcher/LogicModeButton")
	if visual_btn and visual_btn is Button:
		(visual_btn as Button).button_pressed = normalized == "visual"
	if logic_btn and logic_btn is Button:
		(logic_btn as Button).button_pressed = normalized == "logic"

	if _using_web_editor:
		_sync_web_editor_state()

func _apply_web_wand_name(new_name: String) -> void:
	var final_name := new_name.strip_edges()
	if final_name == "":
		return

	if current_wand_item:
		current_wand_item.display_name = final_name

	if wand_name_label:
		wand_name_label.text = "正在编辑: " + final_name

	if header:
		var rename_edit = header.get_node_or_null("RenameEdit")
		if rename_edit and rename_edit is LineEdit:
			(rename_edit as LineEdit).text = final_name

func _apply_web_pending_state(data: Dictionary) -> void:
	if data.has("nodes") and data.has("connections"):
		_apply_web_graph_data(data.get("nodes", []), data.get("connections", []))
	if data.has("cells"):
		_apply_web_visual_cells(data.get("cells", []))

func _apply_web_graph_data(nodes_raw, conns_raw) -> void:
	if not current_wand:
		return
	if typeof(nodes_raw) != TYPE_ARRAY or typeof(conns_raw) != TYPE_ARRAY:
		return

	var nodes: Array = []
	for raw in nodes_raw:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var node: Dictionary = raw
		var pos = node.get("position", Vector2.ZERO)
		var pos_vec := Vector2.ZERO
		if pos is Vector2:
			pos_vec = pos
		elif typeof(pos) == TYPE_DICTIONARY:
			pos_vec = Vector2(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)))

		var normalized := {
			"id": str(node.get("id", "")),
			"type": str(node.get("type", "modifier")),
			"display_name": str(node.get("display_name", node.get("name", "Node"))),
			"value": node.get("value", {}),
			"position": pos_vec,
			"visual_color": _color_from_any(node.get("visual_color", node.get("color", "#66aaff")), Color(0.4, 0.66, 1.0, 1.0)),
			"icon_path": str(node.get("icon_path", ""))
		}
		if normalized["id"] == "":
			normalized["id"] = "web_%d_%d" % [Time.get_ticks_msec(), randi() % 1000]
		nodes.append(normalized)

	var logic_capacity := int(current_wand.embryo.logic_capacity) if (current_wand and current_wand.embryo) else 0
	if logic_capacity > 0 and nodes.size() > logic_capacity:
		nodes = nodes.slice(0, logic_capacity)
		push_warning("WandEditor(Web): graph node payload exceeded logic capacity, clamped to %d." % logic_capacity)

	var allowed_node_ids := {}
	for node_entry in nodes:
		if typeof(node_entry) == TYPE_DICTIONARY:
			var node_id := str((node_entry as Dictionary).get("id", ""))
			if node_id != "":
				allowed_node_ids[node_id] = true

	var conns: Array = []
	for raw_conn in conns_raw:
		if typeof(raw_conn) != TYPE_DICTIONARY:
			continue
		var conn: Dictionary = raw_conn
		var from_id := str(conn.get("from_id", conn.get("from_node", "")))
		var to_id := str(conn.get("to_id", conn.get("to_node", "")))
		if from_id == "" or to_id == "":
			continue
		if not allowed_node_ids.has(from_id) or not allowed_node_ids.has(to_id):
			continue
		conns.append({
			"from_id": from_id,
			"from_port": int(conn.get("from_port", 0)),
			"to_id": to_id,
			"to_port": int(conn.get("to_port", 0))
		})

	current_wand.logic_nodes = nodes
	current_wand.logic_connections = conns

	if logic_board:
		_web_sync_lock = true
		logic_board.load_from_data(nodes, conns)
		_web_sync_lock = false

	_update_stats_display()
	EventBus.spell_logic_updated.emit(current_wand)

	# Keep Web shell right panel (compile/stats cards) in sync with the latest wiring.
	# load_from_data may emit logic-changed while _web_sync_lock is true, so we defer one explicit push.
	if _using_web_editor and not _web_sync_lock:
		call_deferred("_sync_web_editor_state")

func _apply_web_visual_cells(cells_raw) -> void:
	if not current_wand:
		return
	if typeof(cells_raw) != TYPE_ARRAY:
		return

	var next_grid := {}
	for raw in cells_raw:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var cell: Dictionary = raw
		var x := int(cell.get("x", -1))
		var y := int(cell.get("y", -1))
		if x < 0 or y < 0:
			continue
		var coords := Vector2i(x, y)
		var item := _material_from_visual_cell(cell)
		if item:
			next_grid[coords] = item

	if visual_grid:
		visual_grid.grid_data = next_grid.duplicate(true)
		visual_grid._rebuild_grid()

	current_wand.visual_grid = next_grid.duplicate(true)
	current_wand.normalize_grid()
	_update_wand_preview()
	_update_stats_display()

func _material_from_visual_cell(cell: Dictionary) -> BaseItem:
	var item_id := str(cell.get("item_id", ""))
	if item_id != "" and _web_visual_item_map.has(item_id):
		return _web_visual_item_map[item_id]

	var color_val = cell.get("color", "#66ccff")
	var mat = BaseItem.new()
	mat.id = item_id if item_id != "" else "visual_web"
	mat.display_name = str(cell.get("name", "模块"))
	mat.wand_logic_type = str(cell.get("visual_type", "hull"))
	mat.wand_visual_color = _color_from_any(color_val, Color(0.4, 0.8, 1.0, 1.0))
	mat.wand_logic_value = {}
	return mat

func _build_web_editor_state_payload() -> Dictionary:
	var wand_name := "未知法杖"
	if current_wand_item:
		wand_name = current_wand_item.display_name

	var logic_pack := _collect_logic_graph_for_web()
	var visual_cells := _collect_visual_cells_for_web()
	var compile_info := _collect_compile_info_for_web()
	var active_tab := "logic"
	if visual_grid and visual_grid.visible:
		active_tab = "visual"
	elif logic_board and logic_board.visible:
		active_tab = "logic"
	_web_active_tab = active_tab

	return {
		"type": "wand_state_full",
		"protocol_version": WEB_PROTOCOL_VERSION,
		"wand_name": wand_name,
		"active_tab": active_tab,
		"logic_nodes": logic_pack.get("nodes", []),
		"logic_connections": logic_pack.get("connections", []),
		"logic_node_count": logic_pack.get("nodes", []).size(),
		"visual_cells": visual_cells,
		"logic_palette": _collect_logic_palette_for_web(),
		"visual_palette": _collect_visual_palette_for_web(),
		"mana": int(current_wand.current_mana) if current_wand else 0,
		"mana_capacity": int(current_wand.embryo.mana_capacity) if (current_wand and current_wand.embryo) else 0,
		"logic_capacity": int(current_wand.embryo.logic_capacity) if (current_wand and current_wand.embryo) else 0,
		"layout_ratios": _collect_layout_ratio_snapshot(),
		"compile": compile_info
	}

func _collect_logic_graph_for_web() -> Dictionary:
	if logic_board:
		var graph = logic_board.get_logic_data()
		var nodes_out: Array = []
		for raw in graph.get("nodes", []):
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var node: Dictionary = raw
			var pos = node.get("position", Vector2.ZERO)
			var pos_dict := {"x": 0.0, "y": 0.0}
			if pos is Vector2:
				pos_dict = {"x": pos.x, "y": pos.y}
			nodes_out.append({
				"id": str(node.get("id", "")),
				"type": str(node.get("type", "modifier")),
				"display_name": str(node.get("display_name", "Node")),
				"value": node.get("value", {}),
				"position": pos_dict,
				"visual_color": _color_to_html(_color_from_any(node.get("visual_color", "#66aaff"), Color(0.4, 0.66, 1.0, 1.0))),
				"icon_path": str(node.get("icon_path", ""))
			})

		var conns_out: Array = []
		for raw_conn in graph.get("connections", []):
			if typeof(raw_conn) != TYPE_DICTIONARY:
				continue
			var conn: Dictionary = raw_conn
			conns_out.append({
				"from_id": str(conn.get("from_id", "")),
				"from_port": int(conn.get("from_port", 0)),
				"to_id": str(conn.get("to_id", "")),
				"to_port": int(conn.get("to_port", 0))
			})

		return {"nodes": nodes_out, "connections": conns_out}

	return {"nodes": [], "connections": []}

func _collect_visual_cells_for_web() -> Array:
	var out: Array = []
	var source := current_wand.visual_grid if current_wand else {}
	for key in source.keys():
		var coords := Vector2i.ZERO
		if key is Vector2i:
			coords = key
		elif key is Vector2:
			coords = Vector2i(int((key as Vector2).x), int((key as Vector2).y))
		else:
			continue

		var item = source[key]
		if not (item is BaseItem):
			continue

		var mat := item as BaseItem
		out.append({
			"x": coords.x,
			"y": coords.y,
			"item_id": str(mat.id),
			"name": mat.display_name,
			"visual_type": mat.wand_logic_type,
			"color": _color_to_html(mat.wand_visual_color)
		})

	out.sort_custom(func(a, b):
		if a["y"] == b["y"]:
			return a["x"] < b["x"]
		return a["y"] < b["y"]
	)
	return out

func _collect_compile_info_for_web() -> Dictionary:
	if not current_wand:
		return {
			"is_valid": false,
			"errors": ["未加载法杖"],
			"total_mana_cost": 0.0,
			"projectile_count": 0,
			"total_damage": 0.0,
			"cycle_delay": 0.0
		}

	var debug_plan = SpellProcessor.debug_build_cast_plan(current_wand)
	var sim_stats = SpellProcessor.get_wand_stats(current_wand)

	var plan_valid := bool(debug_plan.get("is_valid", false)) if debug_plan is Dictionary else false
	var compile_errors: Array = []
	var emissions: Array = []

	if debug_plan is Dictionary:
		var raw_errors = debug_plan.get("errors", [])
		if raw_errors is Array:
			compile_errors = (raw_errors as Array).duplicate()
		var raw_emissions = debug_plan.get("emissions", [])
		if raw_emissions is Array:
			emissions = raw_emissions as Array

	if plan_valid and emissions.is_empty():
		plan_valid = false
		if compile_errors.is_empty():
			compile_errors.append("缺少可发射投射物或连线路径不完整")

	return {
		"is_valid": plan_valid,
		"errors": compile_errors,
		"total_mana_cost": float(debug_plan.get("total_mana_cost", sim_stats.get("simulated_mana_usage", 0.0))),
		"projectile_count": emissions.size(),
		"total_damage": float(sim_stats.get("total_damage", 0.0)),
		"cycle_delay": float(debug_plan.get("max_fire_delay", sim_stats.get("duration", 0.0)))
	}

func _collect_logic_palette_for_web() -> Array:
	var out: Array = []
	for key in _web_logic_item_map.keys():
		var item = _web_logic_item_map[key]
		if not (item is BaseItem):
			continue
		var base := item as BaseItem
		var ports := _infer_ports_for_logic_type(base.wand_logic_type)
		out.append({
			"item_id": str(key),
			"name": base.display_name,
			"description": base.description,
			"type": base.wand_logic_type,
			"color": _color_to_html(base.wand_visual_color),
			"value": base.wand_logic_value,
			"mana_cost": int(base.wand_logic_value.get("mana_cost", 0)),
			"inputs": ports.get("inputs", 1),
			"outputs": ports.get("outputs", 1)
		})
	return out

func _collect_visual_palette_for_web() -> Array:
	var out: Array = []
	for key in _web_visual_item_map.keys():
		var item = _web_visual_item_map[key]
		if not (item is BaseItem):
			continue
		var base := item as BaseItem
		out.append({
			"item_id": str(key),
			"name": base.display_name,
			"visual_type": base.wand_logic_type,
			"color": _color_to_html(base.wand_visual_color)
		})
	return out

func _infer_ports_for_logic_type(node_type: String) -> Dictionary:
	match node_type:
		"generator", "source":
			return {"inputs": 0, "outputs": 1}
		"action_projectile":
			return {"inputs": 1, "outputs": 0}
		"splitter":
			return {"inputs": 1, "outputs": 2}
		"logic_sequence":
			return {"inputs": 1, "outputs": 3}
		_:
			return {"inputs": 1, "outputs": 1}

func _collect_layout_ratio_snapshot() -> Dictionary:
	var left: Control = get_node_or_null("VBoxContainer/MainSplit/LeftSidebar") as Control
	var center: Control = get_node_or_null("VBoxContainer/MainSplit/RightSplit/CenterWorkspace") as Control
	var right: Control = get_node_or_null("VBoxContainer/MainSplit/RightSplit/RightSidebar") as Control
	var top: Control = get_node_or_null("VBoxContainer/Header") as Control

	var left_w: float = left.size.x if left else 0.0
	var center_w: float = center.size.x if center else 0.0
	var right_w: float = right.size.x if right else 0.0
	var total_w: float = maxf(left_w + center_w + right_w, 1.0)

	var top_h: float = top.size.y if top else 0.0
	var total_h: float = maxf(size.y, 1.0)

	return {
		"left_ratio": left_w / total_w,
		"center_ratio": center_w / total_w,
		"right_ratio": right_w / total_w,
		"top_ratio": top_h / total_h,
		"left_min": 250,
		"right_min": 290
	}

func _rebuild_web_item_maps() -> void:
	_web_logic_item_map.clear()
	_web_visual_item_map.clear()

	if palette_grid:
		for child in palette_grid.get_children():
			var item = child.get("item_data")
			if item is BaseItem:
				var item_id := _get_item_id(item)
				_web_logic_item_map[item_id] = item
				child.set_meta("item_id", item_id)

	if module_palette:
		for child in module_palette.get_children():
			var item = child.get("item_data")
			if item is BaseItem:
				var visual_id := str(item.id)
				if visual_id.strip_edges() == "":
					visual_id = _make_item_slug(item.display_name, item.wand_logic_type)
				if _web_visual_item_map.has(visual_id):
					visual_id = "%s_%d" % [visual_id, _web_visual_item_map.size()]
				item.id = visual_id
				_web_visual_item_map[visual_id] = item
				child.set_meta("item_id", visual_id)

func _make_item_slug(name: String, kind: String) -> String:
	var slug = (kind + "_" + name).to_lower()
	var chars = [" ", "(", ")", "（", "）", "/", "\\", ":", ".", ",", "!", "?", "+", "-"]
	for ch in chars:
		slug = slug.replace(ch, "_")
	while slug.find("__") != -1:
		slug = slug.replace("__", "_")
	return slug.strip_edges().trim_suffix("_").trim_prefix("_")

func _color_from_any(value, fallback: Color) -> Color:
	if value is Color:
		return value
	if typeof(value) == TYPE_STRING:
		var str_val := String(value).strip_edges()
		if str_val != "":
			if not str_val.begins_with("#"):
				str_val = "#" + str_val
			return Color.html(str_val)
	return fallback

func _color_to_html(color: Color) -> String:
	return "#" + color.to_html(false)

func _has_property(instance: Object, property_name: StringName) -> bool:
	for entry in instance.get_property_list():
		if StringName(entry.name) == property_name:
			return true
	return false
