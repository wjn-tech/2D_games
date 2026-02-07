extends Control
class_name InventoryContainerUI

signal item_clicked(index: int)

@export var inventory_path: NodePath # Path to a node holding Inventory or just set via code
@export var slot_scene: PackedScene = preload("res://src/systems/inventory/ui/inventory_slot.tscn")

var inventory: Inventory

func setup(inv: Inventory):
	inventory = inv
	_rebuild_slots()
	
func refresh():
	# Force update of all slots without rebuilding
	for child in get_children():
		if child is InventorySlotUI:
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

