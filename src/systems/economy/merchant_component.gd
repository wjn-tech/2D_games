extends Node
class_name MerchantComponent

## MerchantComponent
## 挂载在 NPC 上的组件，使其具备交易能力。

# 商店库存: { "item_data": BaseItem, "amount": int, "price_override": int }
@export var shop_inventory: Array[Dictionary] = []
# 买入价格倍率（玩家卖给商人的价格 = 物品价值 * buy_back_multiplier）
@export var buy_back_multiplier: float = 0.5

func _ready() -> void:
	# 确保父节点是 NPC 且可交互
	var parent = get_parent()
	if parent.has_method("add_to_group"):
		parent.add_to_group("merchants")

## 打开交易界面
func open_trade() -> void:
	var window = UIManager.open_window("Trade", "res://scenes/ui/TradeWindow.tscn")
	if window and window.has_method("setup"):
		window.setup(self)
	print("打开商店界面")

## 购买物品逻辑
func buy_item(item_data: BaseItem, amount: int) -> bool:
	var price = item_data.value
	# 检查玩家金币
	if GameState.player_data.attributes.get("money", 0) >= price * amount:
		GameState.player_data.attributes["money"] -= price * amount
		GameState.inventory.add_item(item_data, amount)
		return true
	return false

## 卖出物品逻辑
func sell_item(item_data: BaseItem, amount: int) -> void:
	var price = int(item_data.value * buy_back_multiplier)
	GameState.player_data.attributes["money"] += price * amount
	GameState.inventory.remove_item(item_data.id, amount)
