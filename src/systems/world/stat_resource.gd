extends Resource
class_name StatResource

## StatResource
## 定义单个属性的成长曲线与修正系数。

@export var stat_name: String = "Strength"
@export var base_value: float = 10.0
@export var growth_curve: Curve # 允许在编辑器中定义非线性成长

## 计算在该等级/进度下的实际值
func get_value_at_progress(progress: float) -> float:
	if growth_curve:
		return base_value + growth_curve.sample(progress)
	return base_value
