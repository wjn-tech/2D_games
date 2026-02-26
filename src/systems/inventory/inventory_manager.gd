extends Node
class_name InventoryManager

signal equipped_item_changed(item: Resource)
signal item_visual_updated(item: Resource) # New signal for texture updates
signal inventory_changed # Added for UI sync
signal inventory_created # Emitted when inventories are initialized

@export var backpack_capacity: int = 20
@export var hotbar_capacity: int = 9

var backpack: Inventory
var hotbar: Inventory
var active_hotbar_index: int = 0

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
	hotbar.content_changed.connect(func(_idx): inventory_changed.emit())
	
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
	
	# Check for stackable merge?
	if item1 and item2 and item1 == item2 and item1.get("stackable"):
		# Try to merge
		# ... (Simple merging logic could go here)
		pass

	# Perform Swap
	from_inv.set_item(from_idx, item2, count2)
	to_inv.set_item(to_idx, item1, count1)
	
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

func add_item(item: Resource, count: int = 1) -> bool:
	# Add to backpack first
	if _add_to_inventory(backpack, item, count):
		return true
	# If full, allow overflow? Or hotbar?
	if _add_to_inventory(hotbar, item, count):
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
			if slot.get("item") == item:
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

func remove_item(item: Resource, count: int = 1) -> bool:
	# Remove from backpack or hotbar
	if _remove_from_inventory(backpack, item, count): return true
	if _remove_from_inventory(hotbar, item, count): return true
	return false

func _remove_from_inventory(inv: Inventory, item: Resource, count: int) -> bool:
	# Find and remove
	for i in range(inv.capacity):
		var slot = inv.get_slot(i)
		if slot.get("item") == item:
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
	var item = get_equipped_item()
	equipped_item_changed.emit(item)
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
