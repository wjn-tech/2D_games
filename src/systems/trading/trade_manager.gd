extends Node

## TradeManager (Autoload)
## Manages the state of active trading sessions (Cart, Validation, Checkout).

signal cart_updated
signal transaction_completed
signal transaction_failed(reason: String)

var current_merchant: Node
var cart: Array[Dictionary] = [] # [{ "item": BaseItem, "price": int, "quantity": int, "source_index": int }]

func start_session(merchant: Node) -> void:
	current_merchant = merchant
	cart.clear()
	cart_updated.emit()

func add_to_cart(item: BaseItem, price: int, quantity: int = 1) -> void:
	# Check if item already in cart (stacking)
	for entry in cart:
		if entry.item.id == item.id:
			entry.quantity += quantity
			cart_updated.emit()
			return
			
	cart.append({
		"item": item,
		"price": price,
		"quantity": quantity
	})
	cart_updated.emit()

func remove_from_cart(index: int) -> void:
	if index >= 0 and index < cart.size():
		cart.remove_at(index)
		cart_updated.emit()

func get_cart_total() -> int:
	var total = 0
	for entry in cart:
		total += entry.price * entry.quantity
	return total

func validate_transaction(player_money: int) -> bool:
	return player_money >= get_cart_total()

func execute_checkout() -> bool:
	var total = get_cart_total()
	
	if not GameState.player_data.change_money(-total):
		transaction_failed.emit("Not enough money!")
		return false
	
	# Transfer items
	for entry in cart:
		var item = entry.item
		var qty = entry.quantity
		
		# Add to Player
		GameState.inventory.add_item_or_drop(item, qty)
		
		# 从商人库存中扣除 (如果商人有 Inventory 并且提供了接口)
		if current_merchant.has_method("get_inventory"):
			var merchant_inv = current_merchant.get_inventory()
			if merchant_inv:
				# 查找对应的槽位进行扣除
				for i in range(merchant_inv.capacity):
					var slot = merchant_inv.get_slot(i)
					if slot.item == item:
						merchant_inv.remove_from_slot(i, qty)
						break
	
	cart.clear()
	cart_updated.emit()
	transaction_completed.emit()
	return true

## 玩家向商人出售
func sell_to_merchant(inventory_obj: Inventory, slot_index: int, quantity: int = 1) -> bool:
	if not current_merchant: return false
	
	var slot = inventory_obj.get_slot(slot_index)
	var item = slot.item
	if not item: return false
	
	var sell_value = int(item.value * 0.5) # 默认 50% 回收价
	
	# 支付给玩家
	if GameState.player_data.change_money(sell_value * quantity):
		# 从来源库存移除
		inventory_obj.remove_from_slot(slot_index, quantity)
		
		# 将物品加入商人库存（回收）
		if current_merchant.has_method("get_inventory"):
			var m_inv = current_merchant.get_inventory()
			if m_inv:
				_add_item_to_inventory(m_inv, item, quantity)
		
		transaction_completed.emit()
		return true
	
	return false

## 内部方法：向库存添加物品
func _add_item_to_inventory(inv: Inventory, item: Resource, count: int) -> void:
	# 先尝试堆叠
	for i in range(inv.capacity):
		var slot = inv.get_slot(i)
		if slot.item == item:
			inv.set_item(i, item, slot.count + count)
			return
	
	# 再找空位
	for i in range(inv.capacity):
		var slot = inv.get_slot(i)
		if not slot.item:
			inv.set_item(i, item, count)
			return
