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

var _is_ready: bool = false
var current_filter: String = "All"
var selected_slot_index: int = -1

func _ready() -> void:
	_setup_tabs()
	
	# Listen for Inventory updates
	if GameState.inventory:
		GameState.inventory.inventory_changed.connect(refresh_ui)
	
	if EventBus:
		EventBus.player_data_refreshed.connect(refresh_ui)
		
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
		
	if inventory_view: inventory_view.visible = (tab == "inventory")
	if crafting_view: crafting_view.visible = (tab == "crafting")
	if detail_panel: detail_panel.visible = (tab == "inventory")

func _on_player_refreshed() -> void:
	refresh_ui()

func refresh_ui() -> void:
	if not is_inside_tree(): return
	
	_update_hotbar()
	_update_backpack()
	_update_stats()
	# _update_equipment() # TODO: Connect to backend

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
			detail_panel.show_item(slot_ui.current_item, slot_ui.parent_inventory, slot_ui.slot_index)
			detail_panel.visible = true
		else:
			# Only hide if we want to clear. Maybe just show empty?
			# detail_panel.visible = false
			pass

func _on_item_trashed(data: Variant) -> void:
	if not data is Dictionary: return
	var from_inv = data.get("inventory")
	var from_idx = data.get("index")
	
	if from_inv and from_idx != null:
		if from_inv.has_method("clear_slot"):
			from_inv.clear_slot(from_idx)
			
func _input(event: InputEvent) -> void:
	if not _is_ready: return
	
	if event.is_action_pressed("ui_cancel"):
		# Close window with fade out
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.1)
		tween.finished.connect(func(): UIManager.close_window("Inventory"))
		get_viewport().set_input_as_handled()
