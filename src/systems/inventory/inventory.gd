extends Resource
class_name Inventory

signal content_changed(slot_index: int)

# Array of Dictionary { "item": ItemData, "count": int }
# Empty slots are null or { "item": null, "count": 0 }
@export var slots: Array[Dictionary] = []
@export var capacity: int = 20

func _init(cap: int = 20):
	capacity = cap
	resize(capacity)

func resize(cap: int):
	capacity = cap
	slots.resize(capacity)
	for i in range(capacity):
		if slots[i] == null:
			slots[i] = { "item": null, "count": 0 }

func set_item(index: int, item: Resource, count: int = 1):
	if index < 0 or index >= capacity: return
	
	slots[index] = { "item": item, "count": count }
	content_changed.emit(index)

func get_slot(index: int) -> Dictionary:
	if index < 0 or index >= capacity: return { "item": null, "count": 0 }
	if slots[index] == null: slots[index] = { "item": null, "count": 0 }
	return slots[index]
	
func clear_slot(index: int):
	if index < 0 or index >= capacity: return
	slots[index] = { "item": null, "count": 0 }
	content_changed.emit(index)
