@tool
extends BTCondition
class_name BTCheckHappiness

## BTCheckHappiness
## 检查 NPC 的快乐度是否达到阈值。

@export var threshold: float = 0.7
@export var greater_than: bool = true

func _tick(_delta: float) -> Status:
	var happiness = blackboard.get_var("happiness", 1.0)
	
	if greater_than:
		return SUCCESS if happiness >= threshold else FAILURE
	else:
		return SUCCESS if happiness < threshold else FAILURE
