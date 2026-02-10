extends Node

## EconomyManager (Autoload)
## 处理全球市场价格价格波动与复杂的交易公式。

var market_fluctuation: Dictionary = {} # { "item_id": float (modifier) }

func _ready() -> void:
	# 初始波动
	_randomize_market()
	# 每天随机一次波动
	if EventBus:
		EventBus.time_passed.connect(_on_time_passed)

func _on_time_passed(total_seconds: float) -> void:
	# 每 24 小时（约 1440 秒，如果 1s=1min）重置一次
	if int(total_seconds) % 1440 == 0:
		_randomize_market()

func _randomize_market() -> void:
	for item_id in GameState.item_db.keys():
		market_fluctuation[item_id] = randf_range(0.8, 1.25)

func get_buy_price(item_data: BaseItem, merchant: Node) -> int:
	var base = item_data.value
	var fluctuation = market_fluctuation.get(item_data.id, 1.0)
	
	var merchant_modifier = 1.0
	
	# Relationship Modifier (New Spec)
	var rel_mod = 1.0
	if merchant and "relationship" in merchant:
		var rel = float(merchant.relationship)
		if rel > 80.0: rel_mod = 0.8
		elif rel < 20.0: rel_mod = 1.5
	
	if merchant and merchant.has_node("AttributeComponent"):
		var attr = merchant.get_node("AttributeComponent")
		# 越不快乐的人卖得越贵 (Legacy, combined with Relationship)
		merchant_modifier = 1.5 - (attr.data.happiness * 0.5)
	
	return int(base * fluctuation * merchant_modifier * rel_mod)

func get_sell_price(item_data: BaseItem, merchant: Node) -> int:
	var base = item_data.value * 0.5 # 基础回收价 50%
	var fluctuation = market_fluctuation.get(item_data.id, 1.0)
	
	var merchant_modifier = 1.0
	
	# Relationship Modifier (Better relationship = better sell prices)
	var rel_mod = 1.0
	if merchant and "relationship" in merchant:
		var rel = float(merchant.relationship)
		if rel > 80.0: rel_mod = 1.2
		elif rel < 20.0: rel_mod = 0.8
	
	if merchant and merchant.has_node("AttributeComponent"):
		var attr = merchant.get_node("AttributeComponent")
		# 越快乐的人回收价越高
		merchant_modifier = 0.5 + (attr.data.happiness * 0.5)
	
	return int(base * fluctuation * merchant_modifier * rel_mod)
