extends Resource
class_name MerchantProfile

## MerchantProfile
## 定义商人物品池和补货规则

@export_group("Inventory Rules")
## 补货的时间间隔（例如：游戏内小时，目前逻辑上预留）
@export var restock_interval: float = 24.0
## 基础价格倍率（1.0 为原价）
@export var base_price_multiplier: float = 1.0
## 最大槽位数量
@export var max_slots: int = 15

@export_group("Stock Pool")
## 该商人可能出售的所有物品列表
@export var stock_pool: Array[WeightedItemData] = []

## 随机生成一批库存数据
func generate_stock() -> Array[Dictionary]:
	var new_stock: Array[Dictionary] = []
	var pool = stock_pool.duplicate()
	pool.shuffle()
	
	# 选取最多 max_slots 个不重复的物品，或者根据权重随机
	var slot_count = randi_range(max_slots / 2, max_slots)
	
	for i in range(min(slot_count, pool.size())):
		var weighted_data = pool[i]
		if not weighted_data or not weighted_data.item_data: continue
		
		var count = randi_range(weighted_data.min_quantity, weighted_data.max_quantity)
		new_stock.append({
			"item": weighted_data.item_data,
			"count": count
		})
	
	return new_stock
