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
	if merchant and merchant.has_node("AttributeComponent"):
		var attr = merchant.get_node("AttributeComponent")
		# 越不快乐的人卖得越贵
		merchant_modifier = 1.5 - (attr.data.happiness * 0.5)
	
	return int(base * fluctuation * merchant_modifier)

func get_sell_price(item_data: BaseItem, merchant: Node) -> int:
	var base = item_data.value * 0.5 # 基础回收价 50%
	var fluctuation = market_fluctuation.get(item_data.id, 1.0)
	
	var merchant_modifier = 1.0
	if merchant and merchant.has_node("AttributeComponent"):
		var attr = merchant.get_node("AttributeComponent")
		# 越快乐的人回收价越高
		merchant_modifier = 0.5 + (attr.data.happiness * 0.5)
	
	return int(base * fluctuation * merchant_modifier)
