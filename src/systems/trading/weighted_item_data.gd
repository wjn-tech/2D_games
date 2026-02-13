extends Resource
class_name WeightedItemData

## WeightedItemData
## 用于商人物品生成的权重配置

@export var item_data: BaseItem # 指定为 BaseItem
@export var weight: float = 1.0
@export var min_quantity: int = 1
@export var max_quantity: int = 99
@export var price_multiplier: float = 1.0 # 个体价格修正
