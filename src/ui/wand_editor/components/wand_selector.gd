extends PanelContainer

signal wand_selected(wand_item: WandItem)

@onready var item_list = $VBoxContainer/ItemList

var wands: Array[WandItem] = []

func _ready():
	item_list.item_selected.connect(_on_item_selected)

func refresh(inventory_manager: InventoryManager):
	item_list.clear()
	wands.clear()
	
	if not inventory_manager: return
	
	# Scan Hotbar
	_scan_inventory(inventory_manager.hotbar, "快捷栏")
	# Scan Backpack
	_scan_inventory(inventory_manager.backpack, "背包")

func _scan_inventory(inv: Inventory, prefix: String):
	for i in range(inv.capacity):
		var slot = inv.get_slot(i)
		var item = slot.get("item")
		if item and item is WandItem:
			wands.append(item)
			var label = "%s: %s" % [prefix, item.display_name]
			item_list.add_item(label, item.icon)

func _on_item_selected(index: int):
	if index >= 0 and index < wands.size():
		wand_selected.emit(wands[index])
