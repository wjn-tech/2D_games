extends Node2D
class_name IndustrialEntity

## IndustrialEntity
## 工业设备基类（传送带、机械臂、逻辑门）。

@export var entity_id: String = ""
@export var power_requirement: float = 0.0 # 每秒消耗的电量

var current_power_ratio: float = 0.0 # 0.0 到 1.0，由 PowerGridManager 设置

func _ready() -> void:
	if power_requirement > 0:
		if has_node("/root/PowerGridManager"):
			get_node("/root/PowerGridManager").register_consumer(self)
	_setup_entity()

func _setup_entity() -> void:
	# 子类初始化
	pass

func get_power_requirement() -> float:
	return power_requirement

func set_power_supply_ratio(ratio: float) -> void:
	current_power_ratio = ratio
	_on_power_changed()

func _on_power_changed() -> void:
	# 子类实现具体逻辑（如停止动画、降低速度）
	pass

## 逻辑信号处理（用于逻辑门）
func receive_signal(input_id: int, value: bool) -> void:
	pass
