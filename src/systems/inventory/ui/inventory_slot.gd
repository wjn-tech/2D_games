extends PanelContainer
class_name InventorySlotUI

signal slot_clicked(inventory: Inventory, slot_index: int)

var inventory: Inventory
var slot_index: int = -1

@onready var icon = $MarginContainer/Icon
@onready var count_lbl = $MarginContainer/CountLabel

func _ready():
	gui_input.connect(_on_gui_input)

func setup(inv: Inventory, idx: int):
	inventory = inv
	slot_index = idx
	inventory.content_changed.connect(_on_inventory_changed)
	
	# Listen for visual update signal if InventoryManager exposes it, 
	# but tricky since we only have 'inventory' here (which is just data).
	# Simple hack: rely on player calling refresh or re-setting item.
	
	# However, we can listen to the item's `changed` signal if it's a Resource?
	# Or the User asked for Inventory Icon update.
	# We updated player.gd to emit `inventory.item_visual_updated`.
	# But InventoryContainer/Slot usually doesn't know about Manager.
	# Let's check parentage or global bus.
	# For now, Player.gd calls hotbar_ui.refresh() which rebuilds/updates.
	
	_update_visual()

func _on_inventory_changed(idx: int):
	if idx == slot_index:
		_update_visual()

func _update_visual():
	var slot = inventory.get_slot(slot_index)
	var item = slot.get("item")
	if item:
		icon.texture = item.icon
		icon.visible = true
		var count = slot.get("count", 0)
		if count > 1:
			count_lbl.text = str(count)
			count_lbl.visible = true
		else:
			count_lbl.visible = false
	else:
		icon.texture = null
		icon.visible = false
		count_lbl.visible = false

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Handle simple click if needed, but mainly Drag handled by _get_drag_data
			slot_clicked.emit(inventory, slot_index)

func _get_drag_data(at_position):
	var slot = inventory.get_slot(slot_index)
	var item = slot.get("item")
	if not item: return null
	
	var preview = TextureRect.new()
	preview.texture = item.icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(40, 40)
	set_drag_preview(preview)
	
	return { "inventory": inventory, "index": slot_index, "item": item }

func _can_drop_data(at_position, data):
	return data is Dictionary and data.has("inventory") and data.has("index")

func _drop_data(at_position, data):
	var from_inv = data.inventory
	var from_idx = data.index
	
	# Request swap via Manager (we assume a global or we traverse up to find it)
	# For now, let's signal up or call a static helper.
	# Or, since we have references to Inventory resources, we could do it directly,
	# but we want to stick to the Manager logic if possible.
	
	# Finding the manager is tricky without a global ref.
	# Let's assume the InventoryUI parent has a reference to Manager.
	var manager = get_tree().get_first_node_in_group("inventory_manager")
	if manager:
		manager.swap_items(from_inv, from_idx, inventory, slot_index)
