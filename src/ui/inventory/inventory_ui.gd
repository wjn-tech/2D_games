extends Control
class_name InventoryUI

## InventoryUI
## Manages Inventory Window, Tabs, grid rendering and item details.

@export var slot_scene: PackedScene
@export var grid_container: GridContainer
@export var detail_panel: ItemDetailPanelUI
@export var crafting_view: Control
@export var inventory_view: Control
@export var hotbar_view: Control

@onready var tab_inv: Button = %TabInv
@onready var tab_craft: Button = %TabCraft

# New references for Polish V2
@export var equipment_grid: GridContainer
@export var stats_container: VBoxContainer
@export var trash_slot: TrashSlotUI

const HotbarPanelScene = preload("res://src/systems/inventory/ui/hotbar_panel.tscn")
const FX_CONVERGENCE = preload("res://scenes/ui/fx/ConvergenceParticles.tscn")
const WEB_SHELL_RESOURCE_PATH := "ui/web/inventory_shell/index.html"
const WEB_PROTOCOL_VERSION := "1.0"
const WEB_READY_WATCHDOG_SECONDS := 6.0

var _is_ready: bool = false
var current_filter: String = "All"
var selected_slot_index: int = -1
var _selected_inventory_name: String = "backpack"
var _web_shell_node: Node = null
var _using_web_shell: bool = false
var _web_bridge_ready: bool = false
var _web_active_tab: String = "inventory"
var _web_ready_watchdog_started: bool = false
var _web_selected_recipe_id: String = ""
var _web_icon_cache: Dictionary = {}

func _ready() -> void:
	_using_web_shell = _try_setup_web_inventory_shell()
	if _using_web_shell:
		_set_native_shell_visible(false)
		_set_web_shell_visible(true)
		_start_web_ready_watchdog()

	_setup_tabs()
	
	# Listen for Inventory updates
	if GameState.inventory:
		if not GameState.inventory.is_connected("inventory_changed", refresh_ui):
			GameState.inventory.inventory_changed.connect(refresh_ui)
	
	if EventBus:
		if not EventBus.is_connected("player_data_refreshed", refresh_ui):
			EventBus.player_data_refreshed.connect(refresh_ui)

	visibility_changed.connect(_on_visibility_changed)
		
	# Connect Trash Slot
	if trash_slot:
		trash_slot.item_trashed.connect(_on_item_trashed)
		
	# Initial UI Refresh including Hotbar
	refresh_ui()
	
	# Entrance Animation
	modulate.a = 0.0
	var glass_panel = get_node_or_null("GlassPanel")
	if glass_panel:
		# Ensure pivot is centered for scaling
		glass_panel.pivot_offset = glass_panel.size / 2
		glass_panel.scale = Vector2(0.1, 0.1)
		
		# Play Convergence Effect
		var fx = FX_CONVERGENCE.instantiate()
		glass_panel.add_child(fx)
		fx.position = glass_panel.size / 2 # Initially 0 if scaling from 0, maybe parent to self instead?
		
	# Start basic tween
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
	if glass_panel:
		tween.tween_property(glass_panel, "scale", Vector2.ONE, 0.6)
	
	await get_tree().process_frame
	_is_ready = true
	if _using_web_shell:
		call_deferred("_sync_web_inventory_state")

func _setup_tabs() -> void:
	if tab_inv:
		tab_inv.pressed.connect(func(): _switch_tab("inventory"))
	if tab_craft:
		tab_craft.pressed.connect(func(): _switch_tab("crafting"))
	
	_switch_tab("inventory")

func _switch_tab(tab: String) -> void:
	if tab_inv:
		tab_inv.set_pressed_no_signal(tab == "inventory")
	if tab_craft:
		tab_craft.set_pressed_no_signal(tab == "crafting")

	_web_active_tab = tab
		
	if inventory_view: inventory_view.visible = (tab == "inventory") and not _using_web_shell
	if crafting_view: crafting_view.visible = (tab == "crafting") and not _using_web_shell
	if detail_panel: detail_panel.visible = (tab == "inventory") and not _using_web_shell

	if _using_web_shell:
		# Shell mode keeps native hidden at all times unless fallback is triggered.
		_set_native_shell_visible(false)
		_set_web_shell_visible(true)
		if _web_bridge_ready:
			call_deferred("_sync_web_inventory_state")

func _on_player_refreshed() -> void:
	refresh_ui()

func refresh_ui() -> void:
	if not is_inside_tree(): return
	
	_update_hotbar()
	_update_backpack()
	_update_stats()
	# _update_equipment() # TODO: Connect to backend
	if _using_web_shell:
		_sync_web_inventory_state()

func _update_hotbar() -> void:
	if not hotbar_view: return
	for child in hotbar_view.get_children():
		child.queue_free()
		
	var inv_hotbar = GameState.inventory.hotbar
	if inv_hotbar:
		var hb_panel = HotbarPanelScene.instantiate()
		hb_panel.slot_scene = slot_scene
		hotbar_view.add_child(hb_panel)
		hb_panel.setup(inv_hotbar)
		
		for child in hb_panel.get_children():
			if child.has_signal("item_selected"):
				child.item_selected.connect(_on_item_selected)

func _update_backpack() -> void:
	if not grid_container: return
	
	# Clear old
	for child in grid_container.get_children():
		child.queue_free()
	
	var inv_manager = GameState.inventory
	if not inv_manager or not inv_manager.backpack: return
	
	var inv = inv_manager.backpack
	var slots_data = inv.slots
	
	for i in range(inv.capacity):
		var slot_ui = slot_scene.instantiate()
		grid_container.add_child(slot_ui)
		
		# Ensure data is a valid dictionary even if slot is null
		var slot_entry = slots_data[i] if i < slots_data.size() else null
		var data = slot_entry if slot_entry != null else {}
		
		if slot_ui.has_method("setup"):
			slot_ui.setup(i, data, inv)
			
		# Connect selection
		if slot_ui.has_signal("item_selected"):
			slot_ui.item_selected.connect(_on_item_selected)

func _update_stats() -> void:
	if not stats_container: return
	
	var pd = GameState.player_data
	if not pd: return
	
	# Map stats to display
	# Assuming StatBlock children are already in the scene (created in editor or instanced here)
	# In our Refactor step, we added StatBlockHealth, StatBlockMana etc to the scene manually.
	# So we just update them by name or index.
	
	var hp_block = stats_container.get_node_or_null("StatBlockHealth")
	var mp_block = stats_container.get_node_or_null("StatBlockMana")
	var atk_block = stats_container.get_node_or_null("StatBlockAttack")
	
	# Safely access stats
	var base_stats = pd.BASE_STATS if "BASE_STATS" in pd else {}
	if base_stats.is_empty() and pd.get("BASE_STATS"): 
		base_stats = pd.get("BASE_STATS")
		
	if hp_block: hp_block.setup("Health", str(base_stats.get("max_health", 100)))
	if mp_block: mp_block.setup("Mana", str(base_stats.get("max_mana", 100)))
	if atk_block: atk_block.setup("Attack", str(base_stats.get("damage", 10)))

func _on_item_selected(slot_ui: ItemSlotUI) -> void:
	if detail_panel:
		if slot_ui and slot_ui.current_item:
			_selected_inventory_name = "backpack"
			selected_slot_index = slot_ui.slot_index
			detail_panel.show_item(slot_ui.current_item, slot_ui.parent_inventory, slot_ui.slot_index)
			detail_panel.visible = true
		else:
			# Only hide if we want to clear. Maybe just show empty?
			# detail_panel.visible = false
			pass
	if _using_web_shell:
		_sync_web_inventory_state()

func _on_item_trashed(data: Variant) -> void:
	if not data is Dictionary: return
	var from_inv = data.get("inventory")
	var from_idx = data.get("index")
	
	if from_inv and from_idx != null:
		if from_inv.has_method("clear_slot"):
			from_inv.clear_slot(from_idx)
	if _using_web_shell:
		_sync_web_inventory_state()
			
func _input(event: InputEvent) -> void:
	if not _is_ready: return
	
	if event.is_action_pressed("ui_cancel"):
		# Close window with fade out
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.1)
		tween.finished.connect(func(): _close_inventory_window())
		get_viewport().set_input_as_handled()

func get_slot_global_position(index: int) -> Vector2:
	if not grid_container: return Vector2.ZERO
	if index < 0 or index >= grid_container.get_child_count(): return Vector2.ZERO
	
	var child = grid_container.get_child(index)
	if not child: return Vector2.ZERO
	
	# Return center of the slot
	return child.global_position + child.size / 2.0

func _close_inventory_window() -> void:
	if _using_web_shell:
		_set_web_shell_visible(false)
		_release_web_shell_focus()
		_web_bridge_ready = false
		_web_ready_watchdog_started = false
		if is_instance_valid(_web_shell_node):
			_web_shell_node.queue_free()
			_web_shell_node = null

	if UIManager:
		UIManager.close_window("InventoryWindow")
		UIManager.close_window("Inventory")
	else:
		queue_free()

func _try_setup_web_inventory_shell() -> bool:
	var webview_url := _resolve_webview_url(WEB_SHELL_RESOURCE_PATH, "InventoryWindow")
	if webview_url == "":
		return false

	if not ClassDB.class_exists("WebView"):
		push_warning("InventoryWindow: WebView class unavailable. Check godot-wry plugin enabled, exported addons/godot_wry runtime files, WebView2 runtime, and VC++ x64 redistributable; using native fallback.")
		return false

	var candidate: Object = ClassDB.instantiate("WebView")
	if candidate == null or not (candidate is Node):
		push_warning("InventoryWindow: Failed to instantiate WebView, using native fallback.")
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
		webview.connect("ipc_message", Callable(self, "_on_inventory_web_ipc_message"))

	add_child(webview)
	move_child(webview, get_child_count() - 1)

	if webview.has_method("load_url"):
		webview.call("load_url", webview_url)

	_web_shell_node = webview
	return true

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

	push_warning("%s: Web shell HTML missing at %s (check export include_filter includes ui/web/inventory_shell/index.html), using native fallback." % [owner_tag, res_path])
	return ""

func _set_native_shell_visible(make_visible: bool) -> void:
	var root = get_node_or_null("GlassPanel")
	if root and root is CanvasItem:
		(root as CanvasItem).visible = make_visible

func _set_web_shell_visible(make_visible: bool) -> void:
	if not is_instance_valid(_web_shell_node):
		return

	if _web_shell_node.has_method("set_forward_input_events"):
		_web_shell_node.call("set_forward_input_events", make_visible)

	if not make_visible and _web_shell_node.has_method("focus_parent"):
		_web_shell_node.call("focus_parent")

	if _web_shell_node.has_method("set_visible"):
		_web_shell_node.call("set_visible", make_visible)
		return

	if _web_shell_node is CanvasItem:
		(_web_shell_node as CanvasItem).visible = make_visible
		return

	if make_visible:
		if _web_shell_node.has_method("show"):
			_web_shell_node.call("show")
	else:
		if _web_shell_node.has_method("hide"):
			_web_shell_node.call("hide")

func _release_web_shell_focus() -> void:
	if is_instance_valid(_web_shell_node) and _web_shell_node.has_method("set_forward_input_events"):
		_web_shell_node.call("set_forward_input_events", false)

	if is_instance_valid(_web_shell_node) and _web_shell_node.has_method("focus_parent"):
		_web_shell_node.call("focus_parent")

	if is_instance_valid(_web_shell_node) and _web_shell_node is Control:
		var webview_control := _web_shell_node as Control
		if webview_control.has_focus():
			webview_control.release_focus()

	var viewport := get_viewport()
	if viewport:
		viewport.gui_release_focus()

func _on_inventory_web_ipc_message(message: String) -> void:
	var data := _normalize_web_payload(message)
	if data.is_empty():
		return

	var msg_type := String(data.get("type", ""))
	match msg_type:
		"inventory_ready":
			_web_bridge_ready = true
			_set_native_shell_visible(false)
			_set_web_shell_visible(true)
			_sync_web_inventory_state()
		"inventory_request_state":
			# Some export runtimes can drop the very first ready event during WebView bootstrap.
			# Treat request_state as proof that the bridge is alive so we avoid false fallback.
			if not _web_bridge_ready:
				_web_bridge_ready = true
				_set_native_shell_visible(false)
				_set_web_shell_visible(true)
			_sync_web_inventory_state()
		"inventory_close":
			_close_inventory_window()
		"inventory_set_tab":
			_handle_web_tab_request(String(data.get("tab", "inventory")))
		"inventory_select_slot":
			_handle_web_select_slot(String(data.get("inventory", "backpack")), int(data.get("index", -1)))
		"inventory_swap":
			_handle_web_swap(data)
		"inventory_drop":
			_handle_web_drop(data)
		"inventory_trash":
			_handle_web_trash(data)
		"inventory_use":
			_handle_web_use(data)
		"inventory_select_hotbar":
			_handle_web_select_hotbar(data)
		"inventory_select_recipe":
			_handle_web_select_recipe(String(data.get("recipe_id", "")))
		"inventory_craft_recipe":
			_handle_web_craft_recipe(data)
		"inventory_bridge_error":
			_activate_native_fallback("Shell reported a runtime bridge error.")

func _normalize_web_payload(raw_message: String) -> Dictionary:
	var payload: Variant = JSON.parse_string(raw_message)
	for _i in range(6):
		if typeof(payload) == TYPE_STRING:
			payload = JSON.parse_string(String(payload))
			continue
		break
	if payload is Dictionary:
		return payload
	return {}

func _handle_web_tab_request(tab: String) -> void:
	if tab != "inventory" and tab != "crafting":
		return
	_switch_tab(tab)
	_sync_web_inventory_state()

func _handle_web_select_slot(inv_name: String, index: int) -> void:
	var inv := _resolve_inventory_by_name(inv_name)
	if inv == null:
		return
	if index < 0 or index >= inv.capacity:
		return

	_selected_inventory_name = inv_name
	selected_slot_index = index
	var slot := inv.get_slot(index)
	var item = slot.get("item")
	if detail_panel and item:
		detail_panel.show_item(item, inv, index)
		detail_panel.visible = true
	elif detail_panel:
		detail_panel.visible = false
	_sync_web_inventory_state()

func _handle_web_swap(data: Dictionary) -> void:
	if not GameState.inventory or not GameState.inventory.has_method("swap_items"):
		return

	var from_inv := _resolve_inventory_by_name(String(data.get("from_inventory", "")))
	var to_inv := _resolve_inventory_by_name(String(data.get("to_inventory", "")))
	var from_idx := int(data.get("from_index", -1))
	var to_idx := int(data.get("to_index", -1))

	if from_inv == null or to_inv == null:
		return
	if from_idx < 0 or to_idx < 0:
		return
	if from_idx >= from_inv.capacity or to_idx >= to_inv.capacity:
		return

	GameState.inventory.swap_items(from_inv, from_idx, to_inv, to_idx)
	refresh_ui()

func _handle_web_drop(data: Dictionary) -> void:
	var inv := _resolve_inventory_by_name(String(data.get("inventory", "")))
	var index := int(data.get("index", -1))
	if inv == null or index < 0 or index >= inv.capacity:
		return

	var slot := inv.get_slot(index)
	var item = slot.get("item")
	var count := int(slot.get("count", 0))
	if item == null or count <= 0:
		return

	var drop_count := mini(maxi(int(data.get("count", 1)), 1), count)
	if GameState.inventory and GameState.inventory.has_method("drop_item"):
		GameState.inventory.drop_item(item, drop_count)
	if inv.has_method("remove_from_slot"):
		inv.remove_from_slot(index, drop_count)
	refresh_ui()

func _handle_web_trash(data: Dictionary) -> void:
	var inv := _resolve_inventory_by_name(String(data.get("inventory", "")))
	var index := int(data.get("index", -1))
	if inv == null or index < 0 or index >= inv.capacity:
		return

	if inv.has_method("clear_slot"):
		inv.clear_slot(index)
	refresh_ui()

func _handle_web_use(data: Dictionary) -> void:
	# Keep behavior parity: native use button is currently non-functional.
	_handle_web_select_slot(String(data.get("inventory", "backpack")), int(data.get("index", -1)))

func _handle_web_select_hotbar(data: Dictionary) -> void:
	if not GameState.inventory:
		return
	var index := int(data.get("index", -1))
	if index < 0:
		return
	if GameState.inventory.has_method("select_hotbar_slot"):
		GameState.inventory.select_hotbar_slot(index)
	refresh_ui()

func _handle_web_select_recipe(recipe_id: String) -> void:
	_web_selected_recipe_id = recipe_id
	_sync_web_inventory_state()

func _handle_web_craft_recipe(data: Dictionary) -> void:
	var recipe_id := String(data.get("recipe_id", _web_selected_recipe_id))
	var recipe := _resolve_crafting_recipe_by_id(recipe_id)
	if recipe == null:
		return

	var manager := _get_crafting_manager()
	if manager == null or not manager.has_method("craft"):
		return

	var times := mini(maxi(int(data.get("times", 1)), 1), 99)
	var crafted_any := false
	for _i in range(times):
		if not bool(manager.call("craft", recipe)):
			break
		crafted_any = true

	_web_selected_recipe_id = recipe_id
	if crafted_any:
		refresh_ui()
	else:
		_sync_web_inventory_state()

func _resolve_inventory_by_name(inv_name: String) -> Inventory:
	if not GameState.inventory:
		return null
	if inv_name == "hotbar":
		return GameState.inventory.hotbar
	if inv_name == "backpack":
		return GameState.inventory.backpack
	return null

func _sync_web_inventory_state() -> void:
	if not _using_web_shell:
		return
	if not is_instance_valid(_web_shell_node):
		return
	if not _web_bridge_ready:
		return
	if not _web_shell_node.has_method("post_message"):
		_activate_native_fallback("Web shell post_message is unavailable.")
		return

	_web_shell_node.call("post_message", JSON.stringify(_build_web_inventory_payload()))

func _build_web_inventory_payload() -> Dictionary:
	var manager = GameState.inventory
	var backpack_payload: Array = []
	var hotbar_payload: Array = []
	if manager:
		backpack_payload = _serialize_inventory_for_web(manager.backpack, "backpack")
		hotbar_payload = _serialize_inventory_for_web(manager.hotbar, "hotbar")

	return {
		"type": "inventory_state",
		"protocol": WEB_PROTOCOL_VERSION,
		"active_tab": _web_active_tab,
		"backpack": backpack_payload,
		"hotbar": hotbar_payload,
		"crafting": _build_web_crafting_payload(),
		"selected": _build_selected_payload(),
		"stats": _collect_stats_payload(),
		"texts": _collect_text_bundle()
	}

func _serialize_inventory_for_web(inv: Inventory, inv_name: String) -> Array:
	var result: Array = []
	if inv == null:
		return result

	for i in range(inv.capacity):
		var slot := inv.get_slot(i)
		var item = slot.get("item")
		var count := int(slot.get("count", 0))
		var has_item := item != null and count > 0
		result.append({
			"inventory": inv_name,
			"index": i,
			"count": count,
			"has_item": has_item,
			"item": _serialize_item_for_web(item, count) if has_item else null
		})
	return result

func _serialize_item_for_web(item: Resource, count: int) -> Dictionary:
	if item == null:
		return {}
	var display_name := _item_display_name(item)
	var rarity_value = item.get("quality_grade")
	var rarity := String(rarity_value if rarity_value != null else "common")
	var item_id_value = item.get("id")
	var item_id := String(item_id_value if item_id_value != null else "")
	var icon_texture := _item_icon_texture(item)
	if item_id.is_empty() and not item.resource_path.is_empty():
		item_id = item.resource_path

	return {
		"id": item_id,
		"display_name": display_name,
		"description": String(item.get("description") if item.get("description") != null else ""),
		"rarity": rarity,
		"count": count,
		"icon_data_url": _texture_to_data_url(icon_texture),
		"icon_text": _item_icon_glyph(item, display_name),
		"icon_path": icon_texture.resource_path if icon_texture != null and not icon_texture.resource_path.is_empty() else ""
	}

func _item_icon_texture(item: Resource) -> Texture2D:
	if item == null:
		return null
	var icon_value = item.get("icon")
	if icon_value is Texture2D:
		return icon_value
	return null

func _item_display_name(item: Resource) -> String:
	var display_name_value = item.get("display_name")
	var display_name := String(display_name_value if display_name_value != null else "")
	if not display_name.is_empty():
		return display_name
	if not item.resource_name.is_empty():
		return item.resource_name
	return "Item"

func _item_icon_glyph(item: Resource, fallback_name: String) -> String:
	var item_type_value = item.get("item_type")
	var item_type := String(item_type_value if item_type_value != null else "")
	if item_type == "Weapon":
		return "⚔"
	if item_type == "Consumable":
		return "✦"
	if item_type == "Resource":
		return "◈"
	if fallback_name.length() > 0:
		return fallback_name.substr(0, 1)
	return "?"

func _build_web_crafting_payload() -> Dictionary:
	var recipes := _get_available_crafting_recipes()
	var payload_recipes: Array = []
	for recipe in recipes:
		if recipe is CraftingRecipe:
			var serialized := _serialize_crafting_recipe_for_web(recipe)
			if not serialized.is_empty():
				payload_recipes.append(serialized)

	var selected_id := _web_selected_recipe_id
	if selected_id.is_empty() and payload_recipes.size() > 0:
		selected_id = String(payload_recipes[0].get("id", ""))

	var has_selected := false
	for entry in payload_recipes:
		if String(entry.get("id", "")) == selected_id:
			has_selected = true
			break

	if not has_selected and payload_recipes.size() > 0:
		selected_id = String(payload_recipes[0].get("id", ""))
	elif not has_selected:
		selected_id = ""

	_web_selected_recipe_id = selected_id

	return {
		"recipes": payload_recipes,
		"selected_recipe_id": selected_id
	}

func _get_available_crafting_recipes() -> Array:
	var manager := _get_crafting_manager()
	if manager and manager.has_method("get_handcrafting_recipes"):
		var result: Variant = manager.call("get_handcrafting_recipes")
		if result is Array:
			return result

	var fallback: Array = []
	var recipe_db_variant: Variant = GameState.get("recipe_db") if GameState else null
	if recipe_db_variant is Dictionary:
		var recipe_db: Dictionary = recipe_db_variant
		for recipe in recipe_db.values():
			if recipe is CraftingRecipe:
				fallback.append(recipe)
	return fallback

func _get_crafting_manager() -> Node:
	if GameState:
		var singleton = GameState.get("crafting_manager")
		if singleton != null and singleton is Node:
			return singleton
	var group_node = get_tree().get_first_node_in_group("crafting_manager")
	return group_node if group_node is Node else null

func _resolve_crafting_recipe_by_id(recipe_id: String) -> CraftingRecipe:
	if recipe_id.is_empty():
		return null

	for recipe in _get_available_crafting_recipes():
		if recipe is CraftingRecipe:
			var typed_recipe := recipe as CraftingRecipe
			if _crafting_recipe_id(typed_recipe) == recipe_id:
				return typed_recipe

	var recipe_db_variant: Variant = GameState.get("recipe_db") if GameState else null
	if recipe_db_variant is Dictionary:
		var recipe_db: Dictionary = recipe_db_variant
		if recipe_db.has(recipe_id) and recipe_db[recipe_id] is CraftingRecipe:
			return recipe_db[recipe_id]
	return null

func _crafting_recipe_id(recipe: CraftingRecipe) -> String:
	if recipe == null or recipe.result_item == null:
		return ""
	var recipe_id_value = recipe.result_item.get("id")
	var recipe_id := String(recipe_id_value if recipe_id_value != null else "")
	if recipe_id.is_empty() and not recipe.result_item.resource_path.is_empty():
		recipe_id = recipe.result_item.resource_path
	if recipe_id.is_empty():
		recipe_id = str(recipe.get_instance_id())
	return recipe_id

func _serialize_crafting_recipe_for_web(recipe: CraftingRecipe) -> Dictionary:
	if recipe == null or recipe.result_item == null:
		return {}

	var ingredients_payload: Array = []
	var can_craft := true
	for ingredient_id_variant in recipe.ingredients.keys():
		var ingredient_id := String(ingredient_id_variant)
		var required_amount := int(recipe.ingredients.get(ingredient_id_variant, 0))
		var owned_amount := 0
		if GameState.inventory and GameState.inventory.has_method("get_item_count"):
			owned_amount = int(GameState.inventory.get_item_count(ingredient_id))

		var ingredient_item := _resolve_item_resource_for_web(ingredient_id)
		var ingredient_name := _item_display_name(ingredient_item) if ingredient_item else ingredient_id
		var ingredient_icon := _texture_to_data_url(_item_icon_texture(ingredient_item)) if ingredient_item else ""
		var enough := owned_amount >= required_amount
		if not enough:
			can_craft = false

		ingredients_payload.append({
			"id": ingredient_id,
			"name": ingredient_name,
			"required": required_amount,
			"owned": owned_amount,
			"satisfied": enough,
			"icon_data_url": ingredient_icon
		})

	return {
		"id": _crafting_recipe_id(recipe),
		"name": _item_display_name(recipe.result_item),
		"description": String(recipe.result_item.get("description") if recipe.result_item.get("description") != null else ""),
		"result_amount": maxi(int(recipe.result_amount), 1),
		"required_station": String(recipe.required_station),
		"can_craft": can_craft,
		"result_item": _serialize_item_for_web(recipe.result_item, maxi(int(recipe.result_amount), 1)),
		"ingredients": ingredients_payload
	}

func _resolve_item_resource_for_web(item_id: String) -> Resource:
	if item_id.is_empty():
		return null

	var item_db_variant: Variant = GameState.get("item_db") if GameState else null
	if item_db_variant is Dictionary:
		var item_db: Dictionary = item_db_variant
		if item_db.has(item_id) and item_db[item_id] is Resource:
			return item_db[item_id]

	var recipe_db_variant: Variant = GameState.get("recipe_db") if GameState else null
	if recipe_db_variant is Dictionary:
		var recipe_db: Dictionary = recipe_db_variant
		if recipe_db.has(item_id):
			var recipe = recipe_db[item_id]
			if recipe is CraftingRecipe and recipe.result_item is Resource:
				return recipe.result_item

	return null

func _texture_to_data_url(texture: Texture2D) -> String:
	if texture == null:
		return ""

	var cache_key := texture.resource_path
	if cache_key.is_empty():
		cache_key = str(texture.get_instance_id())

	if _web_icon_cache.has(cache_key):
		return String(_web_icon_cache[cache_key])

	var image := _extract_texture_image(texture)
	if image == null or image.is_empty():
		return ""

	var png_bytes := image.save_png_to_buffer()
	if png_bytes.is_empty():
		return ""

	var data_url := "data:image/png;base64,%s" % Marshalls.raw_to_base64(png_bytes)
	_web_icon_cache[cache_key] = data_url
	return data_url

func _extract_texture_image(texture: Texture2D) -> Image:
	if texture is AtlasTexture:
		var atlas_texture := texture as AtlasTexture
		if atlas_texture.atlas == null:
			return null
		var atlas_image := atlas_texture.atlas.get_image()
		if atlas_image == null or atlas_image.is_empty():
			return null

		var region := atlas_texture.region
		var region_rect := Rect2i(
			maxi(int(region.position.x), 0),
			maxi(int(region.position.y), 0),
			maxi(int(region.size.x), 0),
			maxi(int(region.size.y), 0)
		)

		if region_rect.size.x <= 0 or region_rect.size.y <= 0:
			return atlas_image

		region_rect.size.x = mini(region_rect.size.x, atlas_image.get_width() - region_rect.position.x)
		region_rect.size.y = mini(region_rect.size.y, atlas_image.get_height() - region_rect.position.y)
		if region_rect.size.x <= 0 or region_rect.size.y <= 0:
			return null

		return atlas_image.get_region(region_rect)

	return texture.get_image()

func _build_selected_payload() -> Dictionary:
	var inv := _resolve_inventory_by_name(_selected_inventory_name)
	if inv == null:
		return {}
	if selected_slot_index < 0 or selected_slot_index >= inv.capacity:
		return {}

	var slot := inv.get_slot(selected_slot_index)
	var item = slot.get("item")
	if item == null:
		return {
			"inventory": _selected_inventory_name,
			"index": selected_slot_index,
			"item": null
		}

	return {
		"inventory": _selected_inventory_name,
		"index": selected_slot_index,
		"item": _serialize_item_for_web(item, int(slot.get("count", 0)))
	}

func _collect_stats_payload() -> Dictionary:
	var payload := {
		"max_health": 100,
		"max_mana": 100,
		"damage": 10
	}
	var pd = GameState.player_data
	if pd == null:
		return payload

	var base_stats = pd.BASE_STATS if "BASE_STATS" in pd else {}
	if base_stats.is_empty() and pd.get("BASE_STATS"):
		base_stats = pd.get("BASE_STATS")

	payload["max_health"] = int(base_stats.get("max_health", payload["max_health"]))
	payload["max_mana"] = int(base_stats.get("max_mana", payload["max_mana"]))
	payload["damage"] = int(base_stats.get("damage", payload["damage"]))
	return payload

func _collect_text_bundle() -> Dictionary:
	var title_text := "背包"
	var title_label = get_node_or_null("GlassPanel/MainLayout/Header/TitleLabel")
	if title_label and title_label is Label:
		title_text = String((title_label as Label).text)

	var use_text := "使用"
	var drop_text := "丢弃"
	if detail_panel and detail_panel.use_button:
		use_text = String(detail_panel.use_button.text)
	if detail_panel and detail_panel.drop_button:
		drop_text = String(detail_panel.drop_button.text)

	return {
		"title": title_text,
		"tab_inventory": String(tab_inv.text) if tab_inv else "Inventory",
		"tab_crafting": String(tab_craft.text) if tab_craft else "Crafting",
		"label_hotbar": "快捷栏",
		"label_backpack": "背包",
		"label_details": "详情",
		"btn_use": use_text,
		"btn_drop": drop_text,
		"btn_trash": "销毁",
		"btn_close": "关闭",
		"crafting_hint": "选择配方并直接制作",
		"crafting_list": "配方列表",
		"crafting_materials": "所需材料",
		"crafting_action": "制作",
		"crafting_empty": "请选择一个配方"
	}

func _on_visibility_changed() -> void:
	if not _using_web_shell:
		return
	if not visible:
		_set_web_shell_visible(false)
		_release_web_shell_focus()
		return
	_set_native_shell_visible(false)
	_set_web_shell_visible(true)
	if _web_bridge_ready:
		call_deferred("_sync_web_inventory_state")

func _start_web_ready_watchdog() -> void:
	if _web_ready_watchdog_started:
		return
	_web_ready_watchdog_started = true
	var timer := get_tree().create_timer(WEB_READY_WATCHDOG_SECONDS)
	timer.timeout.connect(func() -> void:
		_web_ready_watchdog_started = false
		if _using_web_shell and not _web_bridge_ready:
			_activate_native_fallback("Web shell bridge did not become ready in %.1fs." % WEB_READY_WATCHDOG_SECONDS)
	)

func _activate_native_fallback(reason: String) -> void:
	push_warning("InventoryWindow: %s Falling back to native UI." % reason)
	_web_bridge_ready = false
	_using_web_shell = false
	_web_ready_watchdog_started = false
	_release_web_shell_focus()
	if is_instance_valid(_web_shell_node):
		_web_shell_node.queue_free()
		_web_shell_node = null
	_set_native_shell_visible(true)
	_switch_tab("inventory")

func _exit_tree() -> void:
	_release_web_shell_focus()
	if is_instance_valid(_web_shell_node):
		_web_shell_node.queue_free()
		_web_shell_node = null
