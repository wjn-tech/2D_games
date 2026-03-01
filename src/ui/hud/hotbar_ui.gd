extends "res://src/systems/inventory/ui/inventory_container.gd"
class_name HotbarUI

# Tracks active slot from GameState
func _ready() -> void:
	# InventoryManager is a singleton instance via GameState usually, 
	# or an Autoload depending on project structure.
	# The user says "InventoryManager" is a class, not an instance.
	# We should check GameState.inventory which is likely the Manager instance.
	
	if GameState.inventory:
		# Listen for active slot changes
		if GameState.inventory.has_signal("active_hotbar_changed"):
			if not GameState.inventory.active_hotbar_changed.is_connected(_on_active_slot_changed):
				GameState.inventory.active_hotbar_changed.connect(_on_active_slot_changed)
				
		# Listen for visual updates (e.g. wand texture generation)
		if GameState.inventory.has_signal("item_visual_updated"):
			if not GameState.inventory.item_visual_updated.is_connected(_on_visual_update):
				GameState.inventory.item_visual_updated.connect(_on_visual_update)
	
	# Connect click interactions
	if not item_clicked.is_connected(_on_slot_clicked_action):
		item_clicked.connect(_on_slot_clicked_action)
	
	_refresh_selection()

func _on_slot_clicked_action(index: int) -> void:
	if GameState.inventory:
		GameState.inventory.select_hotbar_slot(index)

func _on_visual_update(_item: Resource) -> void:
	# Efficiently only update the relevant slot? Or just refresh all.
	# For now, safe refresh.
	refresh()

func _on_active_slot_changed(index: int) -> void:
	_refresh_selection()

func _refresh_selection() -> void:
	var active_idx = -1 # Default to none if not found
	
	if GameState.inventory:
		if "active_hotbar_index" in GameState.inventory:
			active_idx = GameState.inventory.active_hotbar_index
		
	var children = get_children()
	for i in range(children.size()):
		var slot = children[i]
		# Only update if it has the method
		if slot.has_method("set_active"):
			# If we have a valid index, select it
			if active_idx != -1:
				slot.set_active(i == active_idx)
			else:
				slot.set_active(false)

# Override refresh to also update selection
func refresh() -> void:
	super.refresh()
	_refresh_selection()
