extends BaseNPC
class_name MerchantNPC

@export var profile: MerchantProfile
@export var price_multiplier: float = 1.0

var merchant_inventory: Inventory # 核心：使用 Inventory 资源类

func _ready() -> void:
	super._ready() # 确保父类逻辑执行
	
	# 自动加载默认配置（如果编辑器中未手动分配）
	if not profile:
		var default_path = "res://assets/merchants/general_trader.tres"
		if ResourceLoader.exists(default_path):
			profile = load(default_path)
			print("Merchant: 自动加载默认 Profile: ", default_path)
	
	# 初始化库存
	var capacity = 15
	if profile:
		capacity = profile.max_slots
		price_multiplier = profile.base_price_multiplier
	
	merchant_inventory = Inventory.new(capacity)
	
	# 执行初始补货
	restock()

## 补货逻辑：根据 Profile 生成随机库存
func restock() -> void:
	print("Merchant: 开始尝试补货...")
	if not profile:
		print("Merchant: 没有配置 Profile，尝试补货失败")
		return
	
	var items = profile.generate_stock()
	print("Merchant: Profile 生成了 ", items.size(), " 种物品")
	
	# 清空当前库存并填充新生成的
	for i in range(merchant_inventory.capacity):
		merchant_inventory.clear_slot(i)
	
	for i in range(min(items.size(), merchant_inventory.capacity)):
		var entry = items[i]
		if entry.item:
			merchant_inventory.set_item(i, entry.item, entry.count)
			print("Merchant: 上架物品 - ", entry.item.display_name, " x", entry.count)
	
	print("Merchant: 补货完成，当前货架物品数量: ", items.size())

func _open_trade() -> void:
	if UIManager:
		var win = UIManager.open_window("TradeWindow", "res://scenes/ui/TradeWindow.tscn")
		if win and win.has_method("set_merchant"):
			win.set_merchant(self)
	else:
		print("Merchant: UIManager 未初始化")

func get_inventory():
	if not merchant_inventory:
		var capacity = 15
		if profile: capacity = profile.max_slots
		merchant_inventory = Inventory.new(capacity)
		restock()
		
	# 关键修复：检查库存是否实际上是空的（每个槽位都是 null）
	var has_items = false
	for slot in merchant_inventory.slots:
		if slot.get("item") != null:
			has_items = true
			break
			
	if not has_items:
		print("Merchant: 检测到空货架，强制补货")
		restock()
		
	return merchant_inventory

## 购买接口 (玩家从商人处购买)
func buy_item(item: BaseItem, amount: int) -> bool:
	var total_cost = int(item.value * price_multiplier * amount)
	# 实际金额扣除在 TradeManager 执行，这里仅负责确认交易可能发生的逻辑
	return true

## 卖出接口 (玩家卖给商人)
func sell_item(item: BaseItem, amount: int) -> bool:
	# 回收价通常是原价的 40% - 60%
	var base_value = item.value if item else 0
	var total_gain = int(base_value * 0.5 * amount)
	return true
