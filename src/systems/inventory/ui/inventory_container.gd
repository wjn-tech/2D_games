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
		slot_ui.setup(inventory, i)
		slot_ui.slot_clicked.connect(_on_slot_clicked)

func _on_slot_clicked(_inv, index):
	item_clicked.emit(index)

