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
var mode_tabs: TabContainer # 新增：切换 买/卖 模式
var _current_merchant_ref: Node # 新增引用

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
	print("TradeWindow: Initializing trade for merchant: ", merchant.name if merchant else "NULL")
	_current_merchant_ref = merchant
	if _trade_mgr:
		_trade_mgr.start_session(merchant)
	
	# 等待一帧确保 UI 节点完全挂载并准备就绪
	if not is_inside_tree():
		await ready
	await get_tree().process_frame
	
	# 强制更新布局
	_populate_merchant_stock(merchant)
	_refresh_sell_list()
	_update_ui_state()
	
	# 调试：检查内容节点是否有子节点
	var merchant_content = find_child("MerchantContent", true, false)
	if merchant_content:
		print("TradeWindow: Merchant items count: ", merchant_content.get_child_count())

func _setup_dynamic_layout() -> void:
	for c in main_container.get_children():
		c.queue_free()
	
	# 使用 TabContainer 来分离“商店”和“出售”
	mode_tabs = TabContainer.new()
	mode_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(mode_tabs)
	
	# 1. Buy Tab (Merchant Stock)
	var buy_vbox = VBoxContainer.new()
	buy_vbox.name = "Buy Items"
	buy_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# 添加一个重置按钮方便测试
	var refresh_btn = Button.new()
	refresh_btn.text = "Refresh Merchant Stock"
	refresh_btn.pressed.connect(func(): 
		if _current_merchant_ref:
			if _current_merchant_ref.has_method("restock"):
				_current_merchant_ref.restock()
			_populate_merchant_stock(_current_merchant_ref)
	)
	buy_vbox.add_child(refresh_btn)
	
	merchant_list_container = ScrollContainer.new()
	merchant_list_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var m_content = VBoxContainer.new()
	m_content.name = "MerchantContent"
	m_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	merchant_list_container.add_child(m_content)
	buy_vbox.add_child(merchant_list_container)
	mode_tabs.add_child(buy_vbox)
	
	# 2. Sell Tab (Player Inventory)
	var sell_vbox = VBoxContainer.new()
	sell_vbox.name = "Sell Items"
	sell_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var p_scroll = ScrollContainer.new()
	p_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var p_content = VBoxContainer.new()
	p_content.name = "PlayerContent"
	p_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_scroll.add_child(p_content)
	sell_vbox.add_child(p_scroll)
	mode_tabs.add_child(sell_vbox)
	
	# 3. Summary Column (Right Side)
	summary_col = _create_column("Checkout")
	summary_col.custom_minimum_size.x = 200
	
	# Cart Display inside Summary
	var cart_lbl = Label.new()
	cart_lbl.text = "Cart items:"
	summary_col.add_child(cart_lbl)
	
	cart_list_container = ScrollContainer.new()
	cart_list_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c_vbox = VBoxContainer.new()
	c_vbox.name = "CartContent" # 唯一命名
	cart_list_container.add_child(c_vbox)
	summary_col.add_child(cart_list_container)
	
	summary_col.add_child(HSeparator.new())
	
	money_label = Label.new()
	summary_col.add_child(money_label)
	
	total_label = Label.new()
	summary_col.add_child(total_label)
	
	checkout_btn = Button.new()
	checkout_btn.text = "Checkout"
	checkout_btn.custom_minimum_size = Vector2(0, 40)
	checkout_btn.pressed.connect(func(): 
		if _trade_mgr: _trade_mgr.execute_checkout()
	)
	summary_col.add_child(checkout_btn)
	
	main_container.add_child(summary_col)
	
	# 初始刷新玩家背包显示（用于出售）
	mode_tabs.tab_changed.connect(func(_idx): _refresh_sell_list())

func _refresh_sell_list():
	var container = find_child("PlayerContent", true, false)
	if not container: 
		# 尝试直接通过引用获取
		return
	
	for c in container.get_children(): c.queue_free()
	
	var inv = GameState.inventory.backpack
	if not inv: return
	
	var has_items = false
	for i in range(inv.capacity):
		var slot = inv.get_slot(i)
		var item = slot.get("item")
		if not item: continue
		
		has_items = true
		var sell_price = int(item.value * 0.5)
		var btn = Button.new()
		btn.text = "%s x%d (Sell for $%d)" % [item.display_name, slot.count, sell_price]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size.y = 35
		btn.pressed.connect(func():
			if _trade_mgr: 
				_trade_mgr.sell_to_merchant(inv, i, 1)
				_refresh_sell_list() # 刷新当前列表
		)
		container.add_child(btn)
	
	if not has_items:
		_add_empty_label(container, "Your backpack is empty.")

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
	# 强力查找，无视层级
	var content_node = find_child("MerchantContent", true, false)
	if not content_node: 
		print("TradeWindow: 严重错误 - 找不到 MerchantContent 节点")
		return
	
	for c in content_node.get_children(): c.queue_free()
	
	if merchant == null:
		_add_empty_label(content_node, "Merchant node is null")
		return

	if not merchant.has_method("get_inventory"): 
		_add_empty_label(content_node, "No inventory method on " + merchant.name)
		return
	
	var merchant_inv = merchant.get_inventory()
	if not merchant_inv: 
		_add_empty_label(content_node, "Merchant inventory is currently empty.")
		return
	
	var items_added = 0
	for slot in merchant_inv.slots:
		var item = slot.get("item")
		if not item: continue
		
		items_added += 1
		var count = slot.get("count", 0)
		var price = EconomyManager.get_buy_price(item, merchant)
		
		var btn = Button.new()
		btn.text = " %s (x%d) - $%d" % [item.display_name, count, price]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size.y = 40
		# 设置白色文字，防止主题颜色导致的不可见
		btn.add_theme_color_override("font_color", Color.WHITE)
		
		btn.pressed.connect(func(): 
			if _trade_mgr: 
				_trade_mgr.add_to_cart(item, price)
				_update_ui_state()
		)
		content_node.add_child(btn)
	
	if items_added == 0:
		_add_empty_label(content_node, "Merchant has nothing to sell right now.")
		# 尝试触发一次手动补货 (如果商人支持)
		if merchant.has_method("restock"):
			print("TradeWindow: Merchant stock empty, triggering auto-restock...")
			merchant.restock()
			# 补货后再次尝试填充 (避免无限递归)
			_populate_after_restock(merchant, content_node)

func _populate_after_restock(merchant: Node, content_node: Node) -> void:
	var merchant_inv = merchant.get_inventory()
	if not merchant_inv: return
	
	for slot in merchant_inv.slots:
		var item = slot.get("item")
		if not item: continue
		
		# 如果之前没加过（现在有了），就清理空标签并添加
		if content_node.get_child_count() > 0 and content_node.get_child(0) is Label:
			for c in content_node.get_children(): c.queue_free()
		
		_add_item_button(item, slot.get("count", 0), merchant, content_node)

func _add_item_button(item: BaseItem, count: int, merchant: Node, container: Node) -> void:
	var price = EconomyManager.get_buy_price(item, merchant)
	var btn = Button.new()
	btn.text = " %s (x%d) - $%d" % [item.display_name, count, price]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size.y = 40
	btn.add_theme_color_override("font_color", Color.WHITE)
	
	btn.pressed.connect(func(): 
		if _trade_mgr: 
			_trade_mgr.add_to_cart(item, price)
			_update_ui_state()
	)
	container.add_child(btn)

func _add_empty_label(parent: Node, text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.modulate.a = 0.5
	parent.add_child(lbl)

func _update_ui_state() -> void:
	if not cart_list_container: return
	var cart_container = cart_list_container.get_node_or_null("CartContent")
	if not cart_container: return
	
	for c in cart_container.get_children(): c.queue_free()
	
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
		
		cart_container.add_child(row)
	
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
