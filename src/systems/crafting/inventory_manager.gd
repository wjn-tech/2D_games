extends Node

# --- 背包管理系统 ---
# 处理物品的添加、移除、堆叠与查询。

signal inventory_changed

# 物品槽位结构: { "item_data": BaseItem, "amount": int }
var slots: Array[Dictionary] = []
@export var max_slots: int = 20

func _ready() -> void:
	# 监听全局采集信号
	EventBus.item_collected.connect(add_item)

func add_item(item_data: BaseItem, amount: int) -> int:
	if not item_data:
		push_warning("InventoryManager: 尝试添加空物品")
		return amount
		
	var remaining = amount
	
	# 1. 尝试堆叠到现有槽位
	if item_data.stackable:
		for slot in slots:
			if slot.item_data.id == item_data.id:
				var space = slot.item_data.max_stack - slot.amount
				var to_add = min(space, remaining)
				slot.amount += to_add
				remaining -= to_add
				if remaining <= 0:
					break
	
	# 2. 尝试放入新槽位
	while remaining > 0 and slots.size() < max_slots:
		var to_add = min(item_data.max_stack, remaining)
		slots.append({
			"item_data": item_data,
			"amount": to_add
		})
		remaining -= to_add
		
	inventory_changed.emit()
	return remaining # 返回未能放入背包的数量

func remove_item(item_id: String, amount: int) -> bool:
	if get_item_count(item_id) < amount:
		return false
		
	var to_remove = amount
	var i = slots.size() - 1
	while i >= 0 and to_remove > 0:
		if slots[i].item_data.id == item_id:
			if slots[i].amount > to_remove:
				slots[i].amount -= to_remove
				to_remove = 0
			else:
				to_remove -= slots[i].amount
				slots.remove_at(i)
		i -= 1
		
	inventory_changed.emit()
	return true

func get_item_at(index: int) -> BaseItem:
	if index >= 0 and index < slots.size():
		return slots[index].item_data
	return null

func get_item_count(item_id: String) -> int:
	var count = 0
	for slot in slots:
		if slot.item_data.id == item_id:
			count += slot.amount
	return count

## 检查是否有足够弹药
func has_ammo(ammo_id: String, amount: int = 1) -> bool:
	if ammo_id == "": return true # 无需弹药
	return get_item_count(ammo_id) >= amount

## 消耗弹药
func consume_ammo(ammo_id: String, amount: int = 1) -> bool:
	if ammo_id == "": return true
	return remove_item(ammo_id, amount)

func use_item(index: int) -> void:
	if index < 0 or index >= slots.size():
		return
		
	var slot = slots[index]
	var item: BaseItem = slot.item_data
	
	# 这里可以根据物品类型触发不同效果
	print("使用了物品: ", item.display_name)
	
	# 如果是消耗品，减少数量
	slot.amount -= 1
	if slot.amount <= 0:
		slots.remove_at(index)
	
	inventory_changed.emit()
