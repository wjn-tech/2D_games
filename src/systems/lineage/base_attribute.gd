extends Resource
class_name BaseAttribute

## BaseAttribute
## 定义属性的基础信息，可用于扩展更复杂的属性系统（如带修饰符的属性）。

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var base_value: float = 0.0

var current_value: float = 0.0:
	get:
		return base_value + bonus_value

var bonus_value: float = 0.0
