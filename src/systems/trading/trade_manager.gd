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
		GameState.inventory.add_item(item, qty)
		
		# Remove from Merchant (Logic only, assuming Merchant Inventory is Array of BaseItems)
		# Note: In a real system we'd find the specific slot in merchant inventory
		if current_merchant.has_method("remove_item"):
			current_merchant.remove_item(item, qty)
	
	cart.clear()
	cart_updated.emit()
	transaction_completed.emit()
	return true
