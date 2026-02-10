extends Control

@onready var main_container = $Panel/HBoxContainer
@onready var close_button = $Panel/CloseButton

var merchant_col: VBoxContainer
var cart_col: VBoxContainer
var summary_col: VBoxContainer

var merchant_list_container: ScrollContainer
var cart_list_container: ScrollContainer

var total_label: Label
var money_label: Label
var checkout_btn: Button

# Resilient references for Autoloads
@onready var _trade_mgr = get_node_or_null("/root/TradeManager")
@onready var _feedback_mgr = get_node_or_null("/root/FeedbackManager")

func _ready() -> void:
	if has_node("Panel/CloseButton"):
		$Panel/CloseButton.pressed.connect(func(): UIManager.close_window("TradeWindow"))
	
	_setup_dynamic_layout()
	
	if _trade_mgr:
		_trade_mgr.cart_updated.connect(_update_ui_state)
		_trade_mgr.transaction_completed.connect(_on_transaction_success)
		_trade_mgr.transaction_failed.connect(_on_transaction_fail)

func set_merchant(merchant: Node) -> void:
	if _trade_mgr:
		_trade_mgr.start_session(merchant)
	_populate_merchant_stock(merchant)
	_update_ui_state()

func _setup_dynamic_layout() -> void:
	# Keep the Panel as background but wipe the container to enforce our 3-column layout
	for c in main_container.get_children():
		c.queue_free()
	
	# 1. Merchant Column
	merchant_col = _create_column("Merchant Stock")
	merchant_list_container = ScrollContainer.new()
	merchant_list_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	merchant_col.add_child(merchant_list_container)
	var m_vbox = VBoxContainer.new()
	m_vbox.name = "Content"
	merchant_list_container.add_child(m_vbox)
	main_container.add_child(merchant_col)
	
	# 2. Cart Column
	cart_col = _create_column("Buying Cart")
	cart_list_container = ScrollContainer.new()
	cart_list_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cart_col.add_child(cart_list_container)
	var c_vbox = VBoxContainer.new()
	c_vbox.name = "Content"
	cart_list_container.add_child(c_vbox)
	main_container.add_child(cart_col)
	
	# 3. Summary Column
	summary_col = _create_column("Transaction")
	
	money_label = Label.new()
	money_label.text = "Money: 0"
	summary_col.add_child(money_label)
	
	total_label = Label.new()
	total_label.text = "Total: 0"
	total_label.add_theme_font_size_override("font_size", 20)
	summary_col.add_child(total_label)
	
	checkout_btn = Button.new()
	checkout_btn.text = "Checkout"
	checkout_btn.custom_minimum_size = Vector2(0, 50)
	checkout_btn.pressed.connect(func(): 
		if _trade_mgr: _trade_mgr.execute_checkout()
	)
	summary_col.add_child(checkout_btn)
	
	main_container.add_child(summary_col)

func _create_column(title: String) -> VBoxContainer:
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl = Label.new()
	lbl.text = title
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	col.add_child(lbl)
	col.add_child(HSeparator.new())
	return col

func _populate_merchant_stock(merchant: Node) -> void:
	var container = merchant_list_container.get_node("Content")
	for c in container.get_children(): c.queue_free()
	
	if not merchant.has_method("get_inventory"): return
	
	var items = merchant.get_inventory()
	for item in items:
		var price = EconomyManager.get_buy_price(item, merchant)
		var btn = Button.new()
		btn.text = "%s ($%d)" % [item.display_name, price]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func(): 
			if _trade_mgr: _trade_mgr.add_to_cart(item, price)
		)
		container.add_child(btn)

func _update_ui_state() -> void:
	# Update Cart List
	var container = cart_list_container.get_node("Content")
	for c in container.get_children(): c.queue_free()
	
	if not _trade_mgr: return
	
	var cart = _trade_mgr.cart
	for i in range(cart.size()):
		var entry = cart[i]
		var item = entry.item
		var price = entry.price
		var qty = entry.quantity
		
		var row = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = "%s x%d ($%d)" % [item.display_name, qty, price * qty]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		
		var del_btn = Button.new()
		del_btn.text = "X"
		del_btn.pressed.connect(func(): 
			if _trade_mgr: _trade_mgr.remove_from_cart(i)
		)
		row.add_child(del_btn)
		
		container.add_child(row)
	
	# Update Summary
	var total = _trade_mgr.get_cart_total()
	var money = GameState.player_data.money
	
	money_label.text = "Player Money: $%d" % money
	total_label.text = "Total Cost: $%d" % total
	
	if total > money:
		total_label.add_theme_color_override("font_color", Color.RED)
		checkout_btn.disabled = true
		checkout_btn.text = "Not Enough Money"
	else:
		total_label.add_theme_color_override("font_color", Color.WHITE)
		checkout_btn.disabled = false
		checkout_btn.text = "Checkout"
		
	if cart.is_empty():
		checkout_btn.disabled = true
		checkout_btn.text = "Cart Empty"

func _on_transaction_success() -> void:
	# Just update, maybe sound effect later
	_update_ui_state()
	print("Trade successful!")
	if _feedback_mgr:
		_feedback_mgr.spawn_floating_text(global_position + size/2, "Transaction Complete!", Color.GREEN)

func _on_transaction_fail(reason: String) -> void:
	print("Trade failed: ", reason)
	if _feedback_mgr:
		_feedback_mgr.play_shake(self)
		_feedback_mgr.spawn_floating_text(global_position + size/2, reason, Color.RED)
