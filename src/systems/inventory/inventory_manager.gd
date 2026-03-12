extends Node
class_name InventoryManager

signal equipped_item_changed(item: Resource)
signal item_visual_updated(item: Resource) # New signal for texture updates
signal inventory_changed # Added for UI sync
signal inventory_created # Emitted when inventories are initialized
signal active_hotbar_changed(index: int) # Support for Hotbar UI selection

@export var backpack_capacity: int = 20
@export var hotbar_capacity: int = 9

var backpack: Inventory
var hotbar: Inventory
var active_hotbar_index: int = 0 # Default to first slot

func _ready():
	_init_inventories()
	
	# Ensure this manager is in the group for lookups
	if not is_in_group("inventory_manager"):
		add_to_group("inventory_manager")

func _init_inventories():
	backpack = Inventory.new()
	backpack.capacity = backpack_capacity
	backpack.slots.resize(backpack_capacity)
	backpack.content_changed.connect(func(_idx): inventory_changed.emit())
	
	hotbar = Inventory.new()
	hotbar.capacity = hotbar_capacity
	hotbar.resize(hotbar_capacity)
	hotbar.content_changed.connect(func(_idx): 
		if _idx == active_hotbar_index:
			var item = get_equipped_item()
			equipped_item_changed.emit(item)
			EventBus.item_equipped.emit(item) # Re-broadcast for tutorial listeners
		inventory_changed.emit()
	)
	
	active_hotbar_changed.emit(active_hotbar_index)
	inventory_created.emit()

func swap_items(from_inv: Inventory, from_idx: int, to_inv: Inventory, to_idx: int):
	# Handle swapping between inventories
	if not from_inv or not to_inv: return
	if from_idx < 0 or to_idx < 0: return

	var from_slot = from_inv.get_slot(from_idx)
	var to_slot = to_inv.get_slot(to_idx)
	
	# Basic Swap Data
	var item1 = from_slot.get("item")
	var count1 = from_slot.get("count", 0)
	var item2 = to_slot.get("item")
	var count2 = to_slot.get("count", 0)
	
	# Perform Swap
	from_inv.set_item(from_idx, item2, count2)
	to_inv.set_item(to_idx, item1, count1)
	
	# IMPROVED: If swapping into or out of the hotbar, update equipped item
	if from_inv == hotbar or to_inv == hotbar:
		var current_item = get_equipped_item()
		equipped_item_changed.emit(current_item)
		EventBus.item_equipped.emit(current_item)
		item_visual_updated.emit(current_item)
	
	inventory_changed.emit()

func move_item(from_inv: Inventory, from_idx: int, to_inv: Inventory):
	# Move item to first empty slot in target inventory
	if not from_inv or not to_inv: return
	var from_slot = from_inv.get_slot(from_idx)
	if not from_slot.get("item"): return
	
	# Find empty slot
	for i in range(to_inv.capacity):
		var slot = to_inv.get_slot(i)
		if not slot.get("item"):
			# Move
			to_inv.set_item(i, from_slot.get("item"), from_slot.get("count"))
			from_inv.clear_slot(from_idx)
			inventory_changed.emit()
			return

func _get_item_id(item) -> String:
	if item == null:
		return ""
	if item is String:
		return String(item)
	if item is Object:
		var item_id = item.get("id")
		if item_id != null and not String(item_id).is_empty():
			return String(item_id)
	if item is Resource and not item.resource_path.is_empty():
		return item.resource_path
	return ""

func _items_match(left, right) -> bool:
	if left == null or right == null:
		return false
	if left == right:
		return true

	var left_id = _get_item_id(left)
	var right_id = _get_item_id(right)
	if not left_id.is_empty() and not right_id.is_empty():
		return left_id == right_id

	return false

func _resolve_item_resource(item_id: String, resource_path: String = "", fallback = null) -> Resource:
	if not item_id.is_empty() and GameState and GameState.item_db.has(item_id):
		return GameState.item_db[item_id]
	if not resource_path.is_empty() and ResourceLoader.exists(resource_path):
		var loaded = load(resource_path)
		if loaded is Resource:
			return loaded
	if fallback is Resource:
		return fallback
	return null

func _should_embed_item_data(item: Resource) -> bool:
	if item == null:
		return false
	if not item.resource_path.is_empty():
		return false
	var item_id = _get_item_id(item)
	if item_id.is_empty():
		return true
	if GameState and GameState.item_db.has(item_id):
		return false
	return true

func _serialize_slot(slot: Dictionary) -> Dictionary:
	var item = slot.get("item")
	var count = int(slot.get("count", 0))
	if item == null or count <= 0:
		return {"item_id": "", "resource_path": "", "count": 0, "item_data": null}

	var resource_path = item.resource_path if item is Resource else ""
	var serialized = {
		"item_id": _get_item_id(item),
		"resource_path": resource_path,
		"count": count
	}
	if item is Resource and _should_embed_item_data(item):
		serialized["item_data"] = item.duplicate(true)
	return serialized

func _deserialize_slot(saved_slot) -> Dictionary:
	if saved_slot == null:
		return {"item": null, "count": 0}

	if saved_slot is Dictionary:
		var legacy_item = saved_slot.get("item")
		var embedded_item = saved_slot.get("item_data")
		var item_id = String(saved_slot.get("item_id", _get_item_id(legacy_item)))
		if item_id.is_empty():
			item_id = _get_item_id(embedded_item)
		var resource_path = String(saved_slot.get("resource_path", legacy_item.resource_path if legacy_item is Resource else embedded_item.resource_path if embedded_item is Resource else ""))
		var fallback_item = embedded_item if embedded_item is Resource else legacy_item
		var resolved_item = _resolve_item_resource(item_id, resource_path, fallback_item)
		var count = max(int(saved_slot.get("count", 0)), 0)
		if resolved_item == null or count <= 0:
			return {"item": null, "count": 0}
		return {"item": resolved_item, "count": count}

	if saved_slot is Resource:
		var resolved_item = _resolve_item_resource(_get_item_id(saved_slot), saved_slot.resource_path, saved_slot)
		return {"item": resolved_item, "count": 1}

	return {"item": null, "count": 0}

func _normalize_inventory(inv: Inventory) -> void:
	if not inv:
		return

	inv.resize(inv.capacity)
	var first_index_by_item: Dictionary = {}
	for i in range(inv.capacity):
		var slot = inv.get_slot(i)
		var item = slot.get("item")
		var count = int(slot.get("count", 0))
		if item == null or count <= 0:
			inv.slots[i] = {"item": null, "count": 0}
			continue
		if not bool(item.get("stackable")):
			continue

		var item_key = _get_item_id(item)
		if item_key.is_empty():
			continue

		if first_index_by_item.has(item_key):
			var first_index = int(first_index_by_item[item_key])
			var first_slot = inv.get_slot(first_index)
			inv.slots[first_index] = {
				"item": first_slot.get("item", item),
				"count": int(first_slot.get("count", 0)) + count
			}
			inv.slots[i] = {"item": null, "count": 0}
		else:
			first_index_by_item[item_key] = i

func serialize_inventory() -> Dictionary:
	return {
		"backpack": _serialize_inventory_slots(backpack),
		"hotbar": _serialize_inventory_slots(hotbar)
	}

func _serialize_inventory_slots(inv: Inventory) -> Array:
	var serialized: Array = []
	if not inv:
		return serialized

	inv.resize(inv.capacity)
	for i in range(inv.capacity):
		serialized.append(_serialize_slot(inv.get_slot(i)))
	return serialized

func load_inventory_data(data: Dictionary) -> void:
	if backpack:
		_restore_inventory(backpack, data.get("backpack", []))
	if hotbar:
		_restore_inventory(hotbar, data.get("hotbar", []))
		if active_hotbar_index >= hotbar.capacity:
			active_hotbar_index = 0

	active_hotbar_changed.emit(active_hotbar_index)
	var equipped_item = get_equipped_item()
	equipped_item_changed.emit(equipped_item)
	EventBus.item_equipped.emit(equipped_item)
	item_visual_updated.emit(equipped_item)
	inventory_changed.emit()

func _restore_inventory(inv: Inventory, saved_slots: Array) -> void:
	if not inv:
		return

	inv.resize(inv.capacity)
	for i in range(inv.capacity):
		var restored_slot = _deserialize_slot(saved_slots[i]) if i < saved_slots.size() else {"item": null, "count": 0}
		inv.slots[i] = restored_slot

	_normalize_inventory(inv)
	inv.content_changed.emit(-1)

func add_item(item: Resource, count: int = 1) -> bool:
	# Add to hotbar first for immediate access
	if _add_to_inventory(hotbar, item, count):
		return true
	# If full, allow overflow to backpack
	if _add_to_inventory(backpack, item, count):
		return true
	return false

func add_item_or_drop(item: Resource, count: int = 1) -> void:
	if not add_item(item, count):
		drop_item(item, count)

func drop_item(item: Resource, count: int = 1) -> void:
	# Basic drop logic
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("InventoryManager: Cannot drop item, player not found.")
		return
		
	var world = player.get_parent()
	if not world: return
	
	# Load default loot scene (assumes one exists, e.g. src/entities/loot_item.tscn or scenes/world/loot_item.tscn)
	var loot_scene_path = "res://scenes/world/loot_item.tscn"
	if not ResourceLoader.exists(loot_scene_path):
		loot_scene_path = "res://src/entities/loot_item.tscn" # Fallback
	
	if ResourceLoader.exists(loot_scene_path):
		var loot_scene = load(loot_scene_path)
		var loot = loot_scene.instantiate()
		
		# Ensure we add to a valid 2D parent
		var target_parent = player.get_parent()
		if not target_parent: target_parent = get_tree().current_scene
		
		target_parent.add_child(loot)
		loot.global_position = player.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		
		# Set data after adding to tree or call setup
		if loot.has_method("setup"):
			loot.setup(item, count)
		else:
			loot.item_data = item
			if "stack_count" in loot:
				loot.stack_count = count
	else:
		print("InventoryManager: Loot scene not found.")

func _add_to_inventory(inv: Inventory, item: Resource, count: int) -> bool:
	if not inv: return false
	
	# 1. Try to stack
	if item.get("stackable"):
		for i in range(inv.capacity):
			var slot = inv.get_slot(i)
			if _items_match(slot.get("item"), item):
				# Add logic
				inv.set_item(i, item, slot.get("count") + count)
				inventory_changed.emit()
				return true
				
	# 2. Find empty
	for i in range(inv.capacity):
		var slot = inv.get_slot(i)
		if not slot.get("item"):
			inv.set_item(i, item, count)
			inventory_changed.emit()
			return true
			
	return false

func remove_item(item, count: int = 1) -> bool:
	# Remove from backpack or hotbar
	if _remove_from_inventory(backpack, item, count): return true
	if _remove_from_inventory(hotbar, item, count): return true
	return false

func _remove_from_inventory(inv: Inventory, item, count: int) -> bool:
	# Find and remove
	for i in range(inv.capacity):
		var slot = inv.get_slot(i)
		if _items_match(slot.get("item"), item):
			if slot.get("count") >= count:
				inv.remove_from_slot(i, count)
				inventory_changed.emit()
				return true
	return false

func has_item(item: Resource, count: int = 1) -> bool:
	# Check both
	# ... Simplified check
	return false

func select_hotbar_slot(index: int) -> void:
	if index < 0 or index >= hotbar_capacity: return
	
	active_hotbar_index = index
	active_hotbar_changed.emit(index) # Signal the UI to update selection
	var item = get_equipped_item()
	equipped_item_changed.emit(item)
	EventBus.item_equipped.emit(item)
	# 显式发出全局信号，确保教程系统能捕捉到任何位置切换后的装备变化
	if item:
		EventBus.item_equipped.emit(item)
	item_visual_updated.emit(item) # Ensure visual sync

func get_equipped_item() -> Resource:
	if not hotbar: return null
	if active_hotbar_index < 0 or active_hotbar_index >= hotbar.capacity: return null
	# Fixed accessing inventory directly, use get_slot if available or access slots array
	if hotbar.has_method("get_slot"):
		var slot = hotbar.get_slot(active_hotbar_index)
		return slot.get("item")
	elif "slots" in hotbar:
		var slot = hotbar.slots[active_hotbar_index] if active_hotbar_index < hotbar.slots.size() else {}
		return slot.get("item")
	return null

func get_item_count(item_id: String) -> int:
	var count = 0
	# Check Backpack
	if backpack:
		for i in range(backpack.capacity):
			var slot = backpack.get_slot(i)
			if slot.has("item") and slot.item and slot.item.get("id") == item_id:
				count += slot.get("count", 0)
				
	# Check Hotbar
	if hotbar:
		for i in range(hotbar.capacity):
			var slot = hotbar.get_slot(i)
			if slot.has("item") and slot.item and slot.item.get("id") == item_id:
				count += slot.get("count", 0)
				
	return count

func remove_item_by_id(item_id: String, count: int) -> bool:
	var remaining = count
	
	# Try Backpack
	if backpack:
		remaining = _process_remove(backpack, item_id, remaining)
		if remaining <= 0: return true
		
	# Try Hotbar
	if hotbar:
		remaining = _process_remove(hotbar, item_id, remaining)
		
	return remaining <= 0

func _process_remove(inv: Inventory, item_id: String, limit: int) -> int:
	var remaining = limit
	for i in range(inv.capacity):
		var slot = inv.get_slot(i)
		if slot.has("item") and slot.item and slot.item.get("id") == item_id:
			var current_count = slot.get("count", 0)
			if current_count >= remaining:
				inv.set_item(i, slot.item, current_count - remaining)
				if current_count - remaining == 0:
					inv.clear_slot(i)
				remaining = 0
				inventory_changed.emit()
				break
			else:
				remaining -= current_count
				inv.clear_slot(i)
				inventory_changed.emit()
	return remaining

func clear_all() -> void:
	if backpack:
		for i in range(backpack.capacity):
			backpack.clear_slot(i)
	if hotbar:
		for i in range(hotbar.capacity):
			hotbar.clear_slot(i)
	
	active_hotbar_index = 0
	active_hotbar_changed.emit(0)
	inventory_changed.emit()
