extends Control

@export var webview_resource_path: String = "ui/web/main_menu_starfield/index.html"
@export var prefer_webview: bool = true

@onready var fallback_starfield: Control = $FallbackStarfield

var _webview_node: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	if prefer_webview and _try_setup_webview():
		fallback_starfield.visible = false
		return

	_activate_fallback()


func _activate_fallback() -> void:
	_release_webview_focus()
	if is_instance_valid(_webview_node):
		_webview_node.queue_free()
		_webview_node = null
	fallback_starfield.visible = true


func _try_setup_webview() -> bool:
	var webview_url := _resolve_webview_url(webview_resource_path, "MenuEffects")
	if webview_url == "":
		return false

	if not ClassDB.class_exists("WebView"):
		push_warning("MenuEffects: WebView class unavailable. Check godot-wry plugin enabled, exported addons/godot_wry runtime files, WebView2 runtime, and VC++ x64 redistributable; using fallback starfield.")
		return false

	var candidate: Object = ClassDB.instantiate("WebView")
	if candidate == null or not (candidate is Node):
		push_warning("MenuEffects: Failed to instantiate WebView, using fallback starfield.")
		return false

	var webview := candidate as Node
	if webview is Control:
		var webview_control := webview as Control
		webview_control.set_anchors_preset(Control.PRESET_FULL_RECT)
		webview_control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if _has_property(candidate, &"transparent"):
		candidate.set(&"transparent", true)
	if _has_property(candidate, &"full_window_size"):
		candidate.set(&"full_window_size", false)
	if _has_property(candidate, &"url"):
		candidate.set(&"url", webview_url)
	if webview.has_method("set_focused_when_created"):
		webview.call("set_focused_when_created", false)
	if webview.has_method("set_forward_input_events"):
		webview.call("set_forward_input_events", false)

	add_child(webview)
	move_child(webview, 0)

	if webview.has_method("load_url"):
		webview.call("load_url", webview_url)

	_webview_node = webview
	_release_webview_focus()
	return true


func _release_webview_focus() -> void:
	if is_instance_valid(_webview_node) and _webview_node.has_method("set_forward_input_events"):
		_webview_node.call("set_forward_input_events", false)

	if is_instance_valid(_webview_node) and _webview_node.has_method("focus_parent"):
		_webview_node.call("focus_parent")

	if is_instance_valid(_webview_node) and _webview_node is Control:
		var webview_control := _webview_node as Control
		if webview_control.has_focus():
			webview_control.release_focus()

	var viewport := get_viewport()
	if viewport:
		viewport.gui_release_focus()


func _exit_tree() -> void:
	_release_webview_focus()
	if is_instance_valid(_webview_node):
		_webview_node.queue_free()
		_webview_node = null


func _has_property(instance: Object, property_name: StringName) -> bool:
	for entry in instance.get_property_list():
		if StringName(entry.name) == property_name:
			return true
	return false


func _resolve_webview_url(resource_path: String, owner_tag: String) -> String:
	var relative_path := resource_path
	if relative_path.begins_with("res://"):
		relative_path = relative_path.substr(6, relative_path.length() - 6)

	var res_path := "res://" + relative_path
	if FileAccess.file_exists(res_path):
		return res_path

	if FileAccess.file_exists(relative_path):
		return relative_path

	push_warning("%s: WebView HTML resource missing (check export include_filter for ui/web/*), using fallback starfield." % owner_tag)
	return ""
