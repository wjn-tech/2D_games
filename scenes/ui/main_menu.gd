extends Control

const MENU_SHELL_THEME_PATH := "res://assets/ui/start_menu_shell/menu_theme.json"
const WEB_MENU_RESOURCE_PATH := "res://ui/web/main_menu_shell/index.html"

@onready var center_group: Control = $CenterContainer
@onready var title_label: Label = $CenterContainer/MainColumn/Title
@onready var subtitle_label: Label = $CenterContainer/MainColumn/SubTitle
@onready var button_column: VBoxContainer = $CenterContainer/MainColumn/ButtonColumn
@onready var start_button: Button = $CenterContainer/MainColumn/ButtonColumn/StartButton
@onready var load_button: Button = $CenterContainer/MainColumn/ButtonColumn/LoadButton
@onready var settings_button: Button = $CenterContainer/MainColumn/ButtonColumn/SettingsButton
@onready var exit_button: Button = $CenterContainer/MainColumn/ButtonColumn/ExitButton
@onready var overlay_rect: ColorRect = $BackdropTint
@onready var left_decor: VBoxContainer = $DecorLayer/LeftDecor
@onready var right_decor: VBoxContainer = $DecorLayer/RightDecor
@onready var bottom_left_label: Label = $BottomLeftStatus
@onready var bottom_right_line1: Label = $BottomRightInfo/Line1
@onready var bottom_right_line2: Label = $BottomRightInfo/Line2

var menu_shell_tokens: Dictionary = {}
var _hidden_backgrounds: Array = []
var _menu_webview_node: Node = null
var _web_menu_active: bool = false
var _action_locked: bool = false


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_right = 0
	offset_bottom = 0

	menu_shell_tokens = _load_menu_shell_theme_tokens()
	_apply_menu_shell_theme_tokens()
	_sync_button_labels()
	_connect_button_signals()

	_web_menu_active = _try_setup_web_menu_webview()
	_set_native_menu_visible(not _web_menu_active)
	_hide_external_backgrounds()
	if _web_menu_active:
		_sync_web_menu_state()
	else:
		_play_entrance_animation()

	if not visibility_changed.is_connected(_on_visibility_changed):
		visibility_changed.connect(_on_visibility_changed)


func _load_menu_shell_theme_tokens() -> Dictionary:
	if not FileAccess.file_exists(MENU_SHELL_THEME_PATH):
		return {}
	var file := FileAccess.open(MENU_SHELL_THEME_PATH, FileAccess.READ)
	if file == null:
		return {}
	var raw := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _theme_float(key: String, fallback: float) -> float:
	if not menu_shell_tokens.has(key):
		return fallback
	var value = menu_shell_tokens.get(key)
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		return float(value)
	if typeof(value) == TYPE_STRING and String(value).is_valid_float():
		return String(value).to_float()
	return fallback


func _theme_color(key: String, fallback: Color) -> Color:
	if not menu_shell_tokens.has(key):
		return fallback
	var value = menu_shell_tokens.get(key)
	if typeof(value) == TYPE_COLOR:
		return value
	if typeof(value) == TYPE_STRING:
		return Color.from_string(String(value), fallback)
	if typeof(value) == TYPE_ARRAY:
		var arr: Array = value
		if arr.size() >= 3:
			var alpha := float(arr[3]) if arr.size() > 3 else 1.0
			return Color(float(arr[0]), float(arr[1]), float(arr[2]), alpha)
	return fallback


func _build_stylebox(bg: Color, border: Color, border_width: int, radius: int, shadow_alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0.0, 0.0, 0.0, shadow_alpha)
	style.shadow_size = 12
	return style


func _apply_menu_shell_theme_tokens() -> void:
	overlay_rect.color = _theme_color("overlay_bg", Color(0.02, 0.03, 0.10, 0.58))

	var title_size := int(clampi(int(_theme_float("title_size", 112.0)), 84, 144))
	var subtitle_size := int(clampi(int(_theme_float("subtitle_size", 34.0)), 22, 48))
	title_label.add_theme_font_size_override("font_size", title_size)
	title_label.add_theme_color_override("font_color", _theme_color("title_color", Color(0.74, 0.62, 1.0, 1.0)))
	subtitle_label.add_theme_font_size_override("font_size", subtitle_size)
	subtitle_label.add_theme_color_override("font_color", _theme_color("subtitle_color", Color(0.79, 0.73, 0.94, 1.0)))
	subtitle_label.text = String(menu_shell_tokens.get("subtitle_text", "✦ 一场跨越星系的冒险 ✦"))

	var button_width := _theme_float("button_width", 560.0)
	button_column.custom_minimum_size = Vector2(button_width, 0.0)
	button_column.add_theme_constant_override("separation", int(clampi(int(_theme_float("button_spacing", 16.0)), 10, 30)))

	start_button.custom_minimum_size = Vector2(button_width, _theme_float("primary_button_height", 82.0))
	start_button.add_theme_font_size_override("font_size", int(clampi(int(_theme_float("primary_button_font_size", 44.0)), 34, 56)))
	start_button.add_theme_color_override("font_color", _theme_color("primary_button_text", Color(0.98, 0.96, 0.92, 1.0)))
	start_button.add_theme_color_override("font_hover_color", _theme_color("primary_button_text", Color(1.0, 0.99, 0.95, 1.0)))
	start_button.add_theme_color_override("font_pressed_color", _theme_color("primary_button_text_pressed", Color(0.95, 0.94, 0.88, 1.0)))
	start_button.add_theme_color_override("icon_normal_color", _theme_color("primary_button_icon", Color(0.98, 0.96, 0.92, 1.0)))
	start_button.add_theme_color_override("icon_hover_color", _theme_color("primary_button_icon", Color(1.0, 1.0, 1.0, 1.0)))
	start_button.add_theme_color_override("icon_pressed_color", _theme_color("primary_button_icon", Color(0.95, 0.94, 0.88, 1.0)))

	for secondary in [load_button, settings_button, exit_button]:
		secondary.custom_minimum_size = Vector2(button_width, _theme_float("secondary_button_height", 66.0))
		secondary.add_theme_font_size_override("font_size", int(clampi(int(_theme_float("secondary_button_font_size", 38.0)), 28, 46)))
		secondary.add_theme_color_override("font_color", _theme_color("secondary_button_text", Color(0.88, 0.87, 0.96, 1.0)))
		secondary.add_theme_color_override("font_hover_color", _theme_color("secondary_button_text_hover", Color(1.0, 0.98, 1.0, 1.0)))
		secondary.add_theme_color_override("font_pressed_color", _theme_color("secondary_button_text_pressed", Color(0.82, 0.81, 0.92, 1.0)))
		secondary.add_theme_color_override("icon_normal_color", _theme_color("secondary_button_icon", Color(0.84, 0.80, 0.97, 1.0)))
		secondary.add_theme_color_override("icon_hover_color", _theme_color("secondary_button_icon_hover", Color(0.95, 0.92, 1.0, 1.0)))
		secondary.add_theme_color_override("icon_pressed_color", _theme_color("secondary_button_icon", Color(0.84, 0.80, 0.97, 1.0)))

	var border_width := int(clampi(int(_theme_float("button_border_width", 2.0)), 1, 4))
	var radius := int(clampi(int(_theme_float("button_radius", 10.0)), 6, 18))

	var primary_normal := _build_stylebox(
		_theme_color("primary_button_bg", Color(0.88, 0.58, 0.04, 1.0)),
		_theme_color("primary_button_border", Color(0.96, 0.86, 0.12, 1.0)),
		border_width,
		radius,
		0.30
	)
	var primary_hover := _build_stylebox(
		_theme_color("primary_button_hover_bg", Color(0.94, 0.64, 0.08, 1.0)),
		_theme_color("primary_button_border", Color(0.98, 0.90, 0.22, 1.0)),
		border_width,
		radius,
		0.35
	)
	var primary_pressed := _build_stylebox(
		_theme_color("primary_button_pressed_bg", Color(0.82, 0.50, 0.05, 1.0)),
		_theme_color("primary_button_border", Color(0.95, 0.82, 0.15, 1.0)),
		border_width,
		radius,
		0.22
	)
	start_button.add_theme_stylebox_override("normal", primary_normal)
	start_button.add_theme_stylebox_override("hover", primary_hover)
	start_button.add_theme_stylebox_override("pressed", primary_pressed)
	start_button.add_theme_stylebox_override("focus", primary_hover)

	var secondary_normal := _build_stylebox(
		_theme_color("secondary_button_bg", Color(0.08, 0.12, 0.27, 0.92)),
		_theme_color("secondary_button_border", Color(0.43, 0.30, 0.88, 1.0)),
		border_width,
		radius,
		0.18
	)
	var secondary_hover := _build_stylebox(
		_theme_color("secondary_button_hover_bg", Color(0.10, 0.15, 0.33, 0.95)),
		_theme_color("secondary_button_border_hover", Color(0.56, 0.42, 0.96, 1.0)),
		border_width,
		radius,
		0.24
	)
	var secondary_pressed := _build_stylebox(
		_theme_color("secondary_button_pressed_bg", Color(0.07, 0.11, 0.22, 0.95)),
		_theme_color("secondary_button_border", Color(0.43, 0.30, 0.88, 1.0)),
		border_width,
		radius,
		0.14
	)
	for secondary_btn in [load_button, settings_button, exit_button]:
		secondary_btn.add_theme_stylebox_override("normal", secondary_normal.duplicate())
		secondary_btn.add_theme_stylebox_override("hover", secondary_hover.duplicate())
		secondary_btn.add_theme_stylebox_override("pressed", secondary_pressed.duplicate())
		secondary_btn.add_theme_stylebox_override("focus", secondary_hover.duplicate())

	var decor_color := _theme_color("decor_color", Color(0.56, 0.36, 0.95, 0.92))
	for segment in left_decor.get_children():
		if segment is ColorRect:
			segment.color = decor_color
	for segment in right_decor.get_children():
		if segment is ColorRect:
			segment.color = decor_color

	bottom_left_label.text = String(menu_shell_tokens.get("bottom_left_text", "宇宙状态: 在线"))
	bottom_right_line1.text = String(menu_shell_tokens.get("bottom_right_line1", "Version 1.0.0 Beta"))
	bottom_right_line2.text = String(menu_shell_tokens.get("bottom_right_line2", "© 2025 星海工作室"))
	var bottom_color := _theme_color("bottom_text_color", Color(0.67, 0.68, 0.86, 0.92))
	bottom_left_label.add_theme_color_override("font_color", bottom_color)
	bottom_right_line1.add_theme_color_override("font_color", bottom_color)
	bottom_right_line2.add_theme_color_override("font_color", bottom_color)


func _sync_button_labels() -> void:
	start_button.text = "开始游戏"
	settings_button.text = "游戏设置"
	exit_button.text = "退出游戏"

	var has_save := _has_any_save_slot()
	load_button.text = "继续游戏" if has_save else "加载存档"


func _connect_button_signals() -> void:
	if not start_button.is_connected("pressed", Callable(self, "_on_start_pressed")):
		start_button.pressed.connect(Callable(self, "_on_start_pressed"))
	if not load_button.is_connected("pressed", Callable(self, "_on_load_pressed")):
		load_button.pressed.connect(Callable(self, "_on_load_pressed"))
	if not settings_button.is_connected("pressed", Callable(self, "_on_settings_pressed")):
		settings_button.pressed.connect(Callable(self, "_on_settings_pressed"))
	if not exit_button.is_connected("pressed", Callable(self, "_on_exit_pressed")):
		exit_button.pressed.connect(Callable(self, "_on_exit_pressed"))


func _has_any_save_slot() -> bool:
	var save_manager := _get_save_manager()
	if save_manager and save_manager.has_method("get_slot_info"):
		for i in range(1, 4):
			var slot_info = save_manager.call("get_slot_info", i)
			if typeof(slot_info) == TYPE_DICTIONARY and not (slot_info as Dictionary).is_empty():
				return true

	for i in range(1, 4):
		if FileAccess.file_exists("user://save_%d.save" % i):
			return true
	return false


func _set_native_menu_visible(make_visible: bool) -> void:
	for node in [
		$MenuEffects,
		$BackdropTint,
		$DecorLayer,
		center_group,
		bottom_left_label,
		$BottomRightInfo,
	]:
		if node and node is CanvasItem:
			var item := node as CanvasItem
			item.visible = make_visible
			if make_visible:
				item.modulate = Color(1, 1, 1, 1)


func _try_setup_web_menu_webview() -> bool:
	if not FileAccess.file_exists(WEB_MENU_RESOURCE_PATH):
		push_warning("MainMenu: Web menu HTML resource is missing, using native menu fallback.")
		return false

	if not ClassDB.class_exists("WebView"):
		push_warning("MainMenu: WebView class unavailable, using native menu fallback.")
		return false

	var candidate: Object = ClassDB.instantiate("WebView")
	if candidate == null or not (candidate is Node):
		push_warning("MainMenu: Failed to instantiate WebView, using native menu fallback.")
		return false

	var webview := candidate as Node
	if webview is Control:
		var webview_control := webview as Control
		webview_control.set_anchors_preset(Control.PRESET_FULL_RECT)
		webview_control.mouse_filter = Control.MOUSE_FILTER_STOP

	if candidate.has_method("set"):
		if _has_property(candidate, &"full_window_size"):
			candidate.set(&"full_window_size", false)
		if _has_property(candidate, &"url"):
			candidate.set(&"url", WEB_MENU_RESOURCE_PATH)

	if webview.has_signal("ipc_message"):
		webview.connect("ipc_message", Callable(self, "_on_menu_web_ipc_message"))

	add_child(webview)
	move_child(webview, get_child_count() - 1)

	if webview.has_method("load_url"):
		webview.call("load_url", WEB_MENU_RESOURCE_PATH)

	_menu_webview_node = webview
	return true


func _sync_web_menu_state() -> void:
	_post_web_payload({
		"type": "menu_state",
		"has_save": _has_any_save_slot(),
		"save_slots": _collect_web_save_slots(),
		"settings": _collect_web_settings_state(),
		"startup_debug": _collect_startup_debug_state(),
	})


func _on_menu_web_ipc_message(message: String) -> void:
	var parsed = JSON.parse_string(message)
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var data: Dictionary = parsed
	var msg_type := String(data.get("type", ""))

	match msg_type:
		"menu_ready":
			_sync_web_menu_state()
		"menu_request_state":
			_sync_web_menu_state()
		"menu_start":
			_start_game_action("web")
		"menu_continue":
			_load_game_action()
		"menu_load_slot":
			_load_game_slot_action(int(data.get("slot_id", -1)))
		"menu_settings":
			_open_settings_action()
		"menu_apply_settings":
			_apply_settings_from_web(data.get("settings", {}))
		"menu_reset_settings":
			_reset_settings_from_web()
		"menu_exit":
			_exit_game_action()


func _has_property(instance: Object, property_name: StringName) -> bool:
	for entry in instance.get_property_list():
		if StringName(entry.name) == property_name:
			return true
	return false


func _get_save_manager() -> Object:
	if SaveManager:
		return SaveManager
	return null


func _get_settings_manager() -> Object:
	if SettingsManager:
		return SettingsManager
	return null


func _collect_web_save_slots() -> Array:
	var result: Array = []
	var save_manager := _get_save_manager()
	for slot_id in range(1, 4):
		var info := {}
		if save_manager and save_manager.has_method("get_slot_info"):
			var raw_info = save_manager.call("get_slot_info", slot_id)
			if typeof(raw_info) == TYPE_DICTIONARY:
				info = raw_info

		result.append({
			"id": slot_id,
			"is_empty": info.is_empty(),
			"player_name": String(info.get("player_name", "")),
			"display_time": String(info.get("display_time", "")),
			"topology_mode": String(info.get("topology_mode", "legacy_infinite")),
			"world_size": String(info.get("world_size_preset", "legacy")),
			"progress": int(info.get("progress", 0)),
		})
	return result


func _settings_value(settings_manager: Object, section: String, key: String, fallback: Variant) -> Variant:
	if not settings_manager or not settings_manager.has_method("get_value"):
		return fallback
	var value = settings_manager.call("get_value", section, key)
	if value == null:
		return fallback
	return value


func _collect_web_settings_state() -> Dictionary:
	var settings_manager := _get_settings_manager()
	var language := String(_settings_value(settings_manager, "General", "language", "zh"))
	var window_mode := int(_settings_value(settings_manager, "Graphics", "window_mode", DisplayServer.WINDOW_MODE_WINDOWED))
	var vsync := bool(_settings_value(settings_manager, "Graphics", "vsync", true))
	var particles_quality := float(_settings_value(settings_manager, "Graphics", "particles_quality", 1.0))
	var brightness := float(_settings_value(settings_manager, "Graphics", "brightness", 1.0))
	var menu_visuals_quality := int(_settings_value(settings_manager, "Graphics", "menu_visuals_quality", 1))
	var master_vol := float(_settings_value(settings_manager, "Audio", "master_vol", 1.0))
	var music_vol := float(_settings_value(settings_manager, "Audio", "music_vol", 0.8))
	var sfx_vol := float(_settings_value(settings_manager, "Audio", "sfx_vol", 1.0))
	var ui_vol := float(_settings_value(settings_manager, "Audio", "ui_vol", 1.0))

	return {
		"general": {
			"language": language,
		},
		"graphics": {
			"fullscreen": window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or window_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
			"vsync": vsync,
			"particles_quality": particles_quality,
			"brightness": brightness,
			"menu_visuals_quality": menu_visuals_quality,
		},
		"audio": {
			"master_vol": master_vol,
			"music_vol": music_vol,
			"sfx_vol": sfx_vol,
			"ui_vol": ui_vol,
		},
		"input": _collect_web_input_bindings(),
	}


func _collect_startup_debug_state() -> Dictionary:
	if is_instance_valid(GameManager) and GameManager.has_method("get_startup_debug_snapshot"):
		var snapshot = GameManager.call("get_startup_debug_snapshot")
		if typeof(snapshot) == TYPE_DICTIONARY:
			return snapshot
	return {}


func _collect_web_input_bindings() -> Dictionary:
	var actions := ["left", "right", "up", "down", "interact", "jump", "attack", "inventory"]
	var bindings := {}
	for action_name in actions:
		if not InputMap.has_action(action_name):
			continue
		bindings[action_name] = _input_binding_text(action_name)
	return bindings


func _input_binding_text(action_name: String) -> String:
	var events := InputMap.action_get_events(action_name)
	if events.is_empty():
		return "无"
	var text := String(events[0].as_text())
	return text.split(" (")[0]


func _load_game_slot_action(slot_id: int) -> void:
	if _action_locked:
		return
	if slot_id < 1 or slot_id > 3:
		_post_web_payload({"type": "menu_notice", "level": "warn", "text": "无效存档槽位。"})
		return

	var save_manager := _get_save_manager()
	if not save_manager or not save_manager.has_method("get_slot_info"):
		_post_web_payload({"type": "menu_notice", "level": "error", "text": "存档服务不可用。"})
		return

	var slot_info = save_manager.call("get_slot_info", slot_id)
	if typeof(slot_info) != TYPE_DICTIONARY or (slot_info as Dictionary).is_empty():
		_post_web_payload({"type": "menu_notice", "level": "warn", "text": "该槽位为空，无法继续游戏。"})
		return

	_action_locked = true
	for button in [start_button, load_button, settings_button, exit_button]:
		button.disabled = true

	if is_instance_valid(GameManager):
		_post_web_payload({"type": "menu_transition", "active": true, "reason": "load"})
		await get_tree().create_timer(0.14).timeout
		_post_web_payload({"type": "menu_notice", "level": "info", "text": "正在读取存档并切换场景..."})
		GameManager.load_game(slot_id)
		call_deferred("_verify_load_feedback")
	else:
		_restore_web_menu_visibility()


func _apply_settings_from_web(payload_settings: Variant) -> void:
	if typeof(payload_settings) != TYPE_DICTIONARY:
		return

	var settings_manager := _get_settings_manager()
	if not settings_manager or not settings_manager.has_method("set_value"):
		_post_web_payload({"type": "menu_notice", "level": "error", "text": "设置服务不可用。"})
		return

	var settings_data: Dictionary = payload_settings

	if settings_data.has("general") and typeof(settings_data["general"]) == TYPE_DICTIONARY:
		var general_data: Dictionary = settings_data["general"]
		var language := String(general_data.get("language", "zh")).to_lower()
		if language.begins_with("en"):
			language = "en"
		else:
			language = "zh"
		settings_manager.call("set_value", "General", "language", language)

	if settings_data.has("graphics") and typeof(settings_data["graphics"]) == TYPE_DICTIONARY:
		var graphics_data: Dictionary = settings_data["graphics"]
		var fullscreen := bool(graphics_data.get("fullscreen", false))
		var window_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		settings_manager.call("set_value", "Graphics", "window_mode", window_mode)
		settings_manager.call("set_value", "Graphics", "vsync", bool(graphics_data.get("vsync", true)))
		settings_manager.call("set_value", "Graphics", "particles_quality", clampf(float(graphics_data.get("particles_quality", 1.0)), 0.0, 2.0))
		settings_manager.call("set_value", "Graphics", "brightness", clampf(float(graphics_data.get("brightness", 1.0)), 0.5, 1.5))
		settings_manager.call("set_value", "Graphics", "menu_visuals_quality", clampi(int(graphics_data.get("menu_visuals_quality", 1)), 0, 2))

	if settings_data.has("audio") and typeof(settings_data["audio"]) == TYPE_DICTIONARY:
		var audio_data: Dictionary = settings_data["audio"]
		settings_manager.call("set_value", "Audio", "master_vol", clampf(float(audio_data.get("master_vol", 1.0)), 0.0, 1.0))
		settings_manager.call("set_value", "Audio", "music_vol", clampf(float(audio_data.get("music_vol", 0.8)), 0.0, 1.0))
		settings_manager.call("set_value", "Audio", "sfx_vol", clampf(float(audio_data.get("sfx_vol", 1.0)), 0.0, 1.0))
		settings_manager.call("set_value", "Audio", "ui_vol", clampf(float(audio_data.get("ui_vol", 1.0)), 0.0, 1.0))

	if settings_manager.has_method("save_settings"):
		settings_manager.call("save_settings")

	_sync_web_menu_state()
	_post_web_payload({"type": "menu_notice", "level": "success", "text": "设置已应用。"})


func _reset_settings_from_web() -> void:
	var settings_manager := _get_settings_manager()
	if not settings_manager:
		_post_web_payload({"type": "menu_notice", "level": "error", "text": "设置服务不可用。"})
		return

	if settings_manager.has_method("reset_to_defaults"):
		settings_manager.call("reset_to_defaults")
	elif settings_manager.has_method("apply_all_settings"):
		settings_manager.call("apply_all_settings")

	if settings_manager.has_method("save_settings"):
		settings_manager.call("save_settings")

	_sync_web_menu_state()
	_post_web_payload({"type": "menu_notice", "level": "info", "text": "设置已重置为默认值。"})


func _post_web_payload(payload: Dictionary) -> void:
	if not is_instance_valid(_menu_webview_node):
		return
	if not _menu_webview_node.has_method("post_message"):
		return
	_menu_webview_node.call("post_message", JSON.stringify(payload))


func _game_manager_is_starting_transition() -> bool:
	if not is_instance_valid(GameManager):
		return false
	if _has_property(GameManager, &"_is_starting_new_game"):
		return bool(GameManager.get("_is_starting_new_game"))
	return false


func _play_entrance_animation() -> void:
	for node in [title_label, subtitle_label, button_column, left_decor, right_decor, bottom_left_label, bottom_right_line1, bottom_right_line2]:
		if node and node is CanvasItem:
			node.modulate.a = 0.0

	if title_label:
		title_label.scale = Vector2(0.94, 0.94)
		title_label.pivot_offset = title_label.size * 0.5

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_label, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.40).set_delay(0.10)
	tween.tween_property(button_column, "modulate:a", 1.0, 0.45).set_delay(0.18)
	tween.tween_property(left_decor, "modulate:a", 1.0, 0.45).set_delay(0.20)
	tween.tween_property(right_decor, "modulate:a", 1.0, 0.45).set_delay(0.20)
	tween.tween_property(bottom_left_label, "modulate:a", 1.0, 0.40).set_delay(0.28)
	tween.tween_property(bottom_right_line1, "modulate:a", 1.0, 0.40).set_delay(0.28)
	tween.tween_property(bottom_right_line2, "modulate:a", 1.0, 0.40).set_delay(0.32)


func _on_start_pressed() -> void:
	_start_game_action("native")


func _start_game_action(source: String) -> void:
	if _action_locked:
		return
	_action_locked = true

	for button in [start_button, load_button, settings_button, exit_button]:
		button.disabled = true

	if _web_menu_active and is_instance_valid(_menu_webview_node):
		if is_instance_valid(GameManager):
			_post_web_payload({"type": "menu_transition", "active": true, "reason": "start"})
			await get_tree().create_timer(0.14).timeout
			_post_web_payload({"type": "menu_notice", "level": "info", "text": "正在创建世界会话..."})
			GameManager.start_new_game()
			call_deferred("_verify_start_feedback")
		else:
			_restore_web_menu_visibility()
		return

	var tween := create_tween()
	if source == "native":
		tween.tween_property(center_group, "modulate:a", 0.0, 0.20)
		tween.parallel().tween_property(self, "modulate", Color(0, 0, 0, 1), 0.45)
	else:
		tween.tween_property(self, "modulate", Color(0, 0, 0, 1), 0.30)
	await tween.finished

	GameManager.start_new_game()


func _on_load_pressed() -> void:
	_load_game_action()


func _load_game_action() -> void:
	if _action_locked:
		return
	var window := UIManager.open_window("SaveSelection", "res://scenes/ui/SaveSelection.tscn")
	if window:
		_suspend_web_menu_for_subwindow()
	else:
		_restore_web_menu_visibility()


func _on_settings_pressed() -> void:
	_open_settings_action()


func _open_settings_action() -> void:
	if _action_locked:
		return
	var window := UIManager.open_window("SettingsWindow", "res://scenes/ui/settings/SettingsWindow.tscn")
	if window:
		_suspend_web_menu_for_subwindow()
	else:
		_restore_web_menu_visibility()


func _on_exit_pressed() -> void:
	_exit_game_action()


func _exit_game_action() -> void:
	if _action_locked:
		return
	_action_locked = true
	get_tree().quit()


func _on_visibility_changed() -> void:
	if is_instance_valid(_menu_webview_node):
		_menu_webview_node.visible = visible

	if visible:
		_show_external_backgrounds(false)
	else:
		_show_external_backgrounds(true)


func _hide_external_backgrounds() -> void:
	_hidden_backgrounds.clear()
	var root := get_tree().get_root()
	var self_path := str(get_path())
	_recurse_hide_background(root, self_path)


func _recurse_hide_background(node: Node, self_path: String) -> void:
	for child in node.get_children():
		var path := str(child.get_path())
		if path.begins_with(self_path):
			continue
		var name_l := str(child.name).to_lower()
		if child is CanvasItem and (child is ParallaxBackground or name_l.find("background") != -1):
			var canvas_child := child as CanvasItem
			if canvas_child.visible:
				canvas_child.visible = false
				_hidden_backgrounds.append(canvas_child)
		_recurse_hide_background(child, self_path)


func _show_external_backgrounds(make_visible: bool) -> void:
	for item in _hidden_backgrounds:
		if is_instance_valid(item) and item is CanvasItem:
			(item as CanvasItem).visible = make_visible
	if make_visible:
		_hidden_backgrounds.clear()


func _suspend_web_menu_for_subwindow() -> void:
	_set_native_menu_visible(true)
	if _web_menu_active and is_instance_valid(_menu_webview_node):
		_menu_webview_node.visible = false


func _restore_web_menu_visibility() -> void:
	_action_locked = false
	for button in [start_button, load_button, settings_button, exit_button]:
		button.disabled = false
	_post_web_payload({"type": "menu_transition", "active": false})
	if _web_menu_active and is_instance_valid(_menu_webview_node):
		_menu_webview_node.visible = true
		_set_native_menu_visible(false)
		_sync_web_menu_state()
	else:
		_set_native_menu_visible(true)


func _verify_start_feedback(attempts: int = 0) -> void:
	await get_tree().create_timer(0.9).timeout
	if not is_instance_valid(self):
		return
	if is_instance_valid(GameManager) and GameManager.current_state == GameManager.State.START_MENU:
		if _game_manager_is_starting_transition() and attempts < 8:
			await get_tree().create_timer(0.35).timeout
			if is_instance_valid(self):
				call_deferred("_verify_start_feedback", attempts + 1)
			return
		_restore_web_menu_visibility()


func _verify_load_feedback(attempts: int = 0) -> void:
	await get_tree().create_timer(1.1).timeout
	if not is_instance_valid(self):
		return
	if is_instance_valid(GameManager) and GameManager.current_state == GameManager.State.START_MENU:
		if _game_manager_is_starting_transition() and attempts < 8:
			await get_tree().create_timer(0.35).timeout
			if is_instance_valid(self):
				call_deferred("_verify_load_feedback", attempts + 1)
			return
		_restore_web_menu_visibility()