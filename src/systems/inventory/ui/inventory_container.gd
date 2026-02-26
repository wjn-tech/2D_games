extends Control
class_name InventoryContainerUI

signal item_clicked(index: int)

@export var inventory_path: NodePath # Path to a node holding Inventory or just set via code
@export var slot_scene: PackedScene = preload("res://src/systems/inventory/ui/inventory_slot.tscn")

var inventory: Inventory

func setup(inv: Inventory):
	if inventory and inventory.content_changed.is_connected(_on_content_changed):
		inventory.content_changed.disconnect(_on_content_changed)
		
	inventory = inv
	if inventory:
		inventory.content_changed.connect(_on_content_changed)
	_rebuild_slots()

func _on_content_changed(_slot_index: int):
	# Simple MVP: full rebuild or just refresh
	# Rebuilding slots might be heavy if done every frame, but fine for discrete changes
	# Or we can just call refresh() if slots exist
	refresh()
	
func refresh():
	# Force update of all slots without rebuilding
	for child in get_children():
		# Using duck-typing or checking if it has a method is safer if InventorySlotUI is not global
		if child.has_method("_update_visual"):
			child._update_visual()

func _rebuild_slots():
	# remove children
	for child in get_children():
		child.queue_free()
		
	if not inventory: return
	
	for i in range(inventory.capacity):
		var slot_ui = slot_scene.instantiate()
		add_child(slot_ui)
		
		# Polished ItemSlotUI uses `setup(index, data, inv)`, old uses `setup(inventory, index)`
		if slot_ui.has_method("setup_container"):
			slot_ui.setup_container(inventory, i)
		elif slot_ui.has_method("setup"):
			# Try old way
			# Check setup signature via trial or explicit check if possible (GDScript hard)
			# Assume if no setup_container, it expects (inv, id) OR (id, data, inv)
			# Our ItemSlotUI has (id, data, inv). 
			# InventorySlotUI (old) has (inv, id).
			
			# HACK: Detect by class_name or method arg count if possible, or just try-catch (not in GDScript)
			# Let's rely on `setup_container` being the bridge for new UI.
			# If it's the old slot script:
			if slot_ui.get_script().get_global_name() == "InventorySlotUI":
				slot_ui.setup(inventory, i)
			else:
				# It might be ItemSlotUI expecting 3 args
				var data = {}
				if inventory.slots.size() > i:
					data = inventory.slots[i]
				slot_ui.setup(i, data, inventory)

		# Forward signals if needed
		if slot_ui.has_signal("item_selected"):
			pass # Usually we want to connect this up the chain
		if slot_ui.has_signal("slot_clicked"):
			slot_ui.slot_clicked.connect(_on_slot_clicked)

func _on_slot_clicked(_inv, index):
	item_clicked.emit(index)
