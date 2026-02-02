extends BaseNPC
class_name MerchantNPC

@export var merchant_inventory: Array[BaseItem] = []
@export var price_multiplier: float = 1.0

func _open_trade() -> void:
	# 覆盖基类方法以应用特定商人的逻辑
	if UIManager:
		var win = UIManager.open_window("TradeWindow", "res://scenes/ui/TradeWindow.tscn")
		if win and win.has_method("set_merchant"):
			win.set_merchant(self)
			# 这里可以同步 merchant_inventory 到交易窗口
	else:
		print("Merchant: UIManager 未初始化，无法打开交易界面")

func buy_item(item: BaseItem, amount: int) -> bool:
	var total_cost = int(item.value * price_multiplier * amount)
	# 检查玩家金钱（假设在 GameState 中）
	# if GameState.player_data.money >= total_cost: ...
	print("购买物品: ", item.display_name, " 消耗: ", total_cost)
	return true

func sell_item(item: BaseItem, amount: int) -> bool:
	var total_gain = int(item.value * 0.8 * amount)
	print("卖出物品: ", item.display_name, " 获得: ", total_gain)
	return true
