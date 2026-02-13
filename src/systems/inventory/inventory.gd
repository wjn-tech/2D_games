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

## 从指定槽位移除指定数量的物品
func remove_from_slot(index: int, amount: int) -> bool:
	if index < 0 or index >= capacity: return false
	var slot = get_slot(index)
	if not slot.item or slot.count < amount: return false
	
	slot.count -= amount
	if slot.count <= 0:
		slots[index] = { "item": null, "count": 0 }
	
	content_changed.emit(index)
	return true
