extends Control

@onready var merchant_list = $Panel/HBoxContainer/MerchantSide/ScrollContainer/ItemList
@onready var player_list = $Panel/HBoxContainer/PlayerSide/ScrollContainer/ItemList
@onready var close_button = $Panel/CloseButton

var current_merchant: Node = null

func _ready() -> void:
	close_button.pressed.connect(func(): UIManager.close_window("TradeWindow"))
	_refresh_lists()

func set_merchant(merchant: Node) -> void:
	current_merchant = merchant
	_refresh_lists()

func _refresh_lists() -> void:
	_populate_merchant_list()
	_populate_player_list()

func _populate_merchant_list() -> void:
	for child in merchant_list.get_children():
		child.queue_free()
		
	if not current_merchant or not current_merchant.has_method("get_inventory"):
		return
		
	var items = current_merchant.get_inventory()
	for item_data in items:
		var price = EconomyManager.get_buy_price(item_data, current_merchant)
		var btn = Button.new()
		btn.text = "%s - 价格: %d" % [item_data.display_name, price]
		btn.pressed.connect(func(): _buy_item(item_data, price))
		merchant_list.add_child(btn)

func _populate_player_list() -> void:
	for child in player_list.get_children():
		child.queue_free()
		
	var slots = GameState.inventory.slots
	for slot in slots:
		var item_data = slot.item_data
		var price = EconomyManager.get_sell_price(item_data, current_merchant)
		var btn = Button.new()
		btn.text = "%s (x%d) - 售价: %d" % [item_data.display_name, slot.amount, price]
		btn.pressed.connect(func(): _sell_item(slot, price))
		player_list.add_child(btn)

func _buy_item(item_data: BaseItem, price: int) -> void:
	if GameState.player_data.change_money(-price):
		GameState.inventory.add_item(item_data, 1)
		_refresh_lists()
		print("购买成功: ", item_data.display_name, " 价格: ", price)
	else:
		print("金币不足！")

func _sell_item(slot: Dictionary, price: int) -> void:
	var item_data = slot.item_data
	
	if GameState.inventory.remove_item(item_data.id, 1):
		GameState.player_data.change_money(price)
		_refresh_lists()
		print("出售成功: ", item_data.display_name, " 售价: ", price)
