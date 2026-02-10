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
		
	# Listen for global collection events
	if EventBus:
		EventBus.item_collected.connect(add_item)
	
func _init_inventories():
	backpack = Inventory.new(backpack_capacity)
	hotbar = Inventory.new(hotbar_capacity)
	
	# Connect signals if needed, or UI listens to resources directly
	hotbar.content_changed.connect(_on_hotbar_changed)
	
	backpack.content_changed.connect(func(_idx): inventory_changed.emit())
	hotbar.content_changed.connect(func(_idx): inventory_changed.emit())
	
	inventory_created.emit()

func _on_hotbar_changed(slot_index: int):
	if slot_index == active_hotbar_index:
		emit_signal("equipped_item_changed", get_equipped_item())

func clear_all():
	if backpack:
		for i in range(backpack.slots.size()):
			backpack.slots[i] = { "item": null, "count": 0 }
	if hotbar:
		for i in range(hotbar.slots.size()):
			hotbar.slots[i] = { "item": null, "count": 0 }

# Core Operations
func add_item(item: Resource, count: int = 1) -> bool:
	# 1. Adapt BaseItem to ItemData if necessary (Hack for legacy support)
	# Ideally we should unify, but for now we accept Resource and duck-type
	
	if not item: return false
	
	# 2. Try stacking in Hotbar
	var remaining = _try_add_to_inventory(hotbar, item, count)
	if remaining == 0: return true
	
	# 2. Try stacking in Backpack
	remaining = _try_add_to_inventory(backpack, item, remaining)
	if remaining == 0: return true
	
	# If failed to add all, return false (inventory full)
	# (In a real game, you might drop the excess)
	return false

func remove_item(from_inv: Inventory, slot_index: int, count: int) -> int:
	var slot = from_inv.get_slot(slot_index)
	var item = slot.get("item")
	if item == null: return 0
	
	var current_count = slot.get("count", 0)
	var removed = min(current_count, count)
	current_count -= removed
	if current_count <= 0:
		from_inv.clear_slot(slot_index)
	else:
		from_inv.set_item(slot_index, item, current_count) # Trigger update
		
	return removed

func swap_items(inv_a: Inventory, idx_a: int, inv_b: Inventory, idx_b: int):
	var slot_a = inv_a.get_slot(idx_a)
	var slot_b = inv_b.get_slot(idx_b)
	
	# Swap distinct values
	inv_a.set_item(idx_a, slot_b.get("item"), slot_b.get("count", 0))
	inv_b.set_item(idx_b, slot_a.get("item"), slot_a.get("count", 0))

func select_hotbar_slot(index: int):
	if index < 0 or index >= hotbar_capacity: return
	if active_hotbar_index != index:
		active_hotbar_index = index
		emit_signal("equipped_item_changed", get_equipped_item())

func get_equipped_item() -> Resource:
	var slot = hotbar.get_slot(active_hotbar_index)
	return slot.get("item")

# Helper for Crafting
func get_item_count(item_id: String) -> int:
	var total = 0
	# Check both inventories
	for inv in [backpack, hotbar]:
		if not inv: continue
		for i in range(inv.slots.size()):
			var slot = inv.get_slot(i)
			var item = slot.get("item")
			# Check item.id if item is BaseItem/Resource with id property
			if item and "id" in item and item.id == item_id:
				total += slot.get("count", 0)
	return total

func remove_item_by_id(item_id: String, count: int) -> bool:
	if get_item_count(item_id) < count: return false
	
	var remaining = count
	for inv in [backpack, hotbar]:
		if not inv: continue
		# Reverse iteration avoids index issues if we were removing items from list, but slots are fixed size array usually
		for i in range(inv.slots.size()):
			var slot = inv.get_slot(i)
			var item = slot.get("item")
			if item and "id" in item and item.id == item_id:
				var current = slot.get("count", 0)
				var to_take = min(remaining, current)
				
				remove_item(inv, i, to_take)
				
				remaining -= to_take
				if remaining == 0: 
					inventory_changed.emit() # Signal final update
					return true
	return remaining == 0

func get_item_at(index: int) -> Resource:
	if backpack:
		var slot = backpack.get_slot(index)
		return slot.get("item")
	return null

# Internal Helper
func _try_add_to_inventory(inv: Inventory, item: Resource, count: int) -> int:
	# Check stackability (Check property existence safely)
	var can_stack = item.get("stackable") if "stackable" in item else true
	var max_stack = item.get("max_stack") if "max_stack" in item else 99
	# ItemData might behave differently? ItemData usually implies scenes.
	# Let's hope fields match or we update them.
	
	var remaining = count
	
	# 1. Add to existing stacks
	for i in range(inv.capacity):
		var slot = inv.get_slot(i)
		var slot_item = slot.get("item")
		var slot_count = slot.get("count", 0)
		if slot_item and slot_item.id == item.id and slot_count < slot_item.max_stack:
			var space = slot_item.max_stack - slot_count
			var to_add = min(remaining, space)
			slot_count += to_add
			inv.set_item(i, slot_item, slot_count)
			remaining -= to_add
			if remaining == 0: return 0
			
	# 2. Add to empty slots
	for i in range(inv.capacity):
		var slot = inv.get_slot(i)
		if slot.get("item") == null:
			var to_add = min(remaining, item.max_stack)
			# Clone item logic? Usually Resources are shared references. 
			# For WandItem (unique state), we might need to be careful if we are splitting stacks.
			# But Wands usually don't stack.
			inv.set_item(i, item, to_add)
			remaining -= to_add
			if remaining == 0: return 0
			
	return remaining
