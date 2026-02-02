extends Area2D
class_name BaseFormation

## BaseFormation
## 阵法基类：提供区域性的 Buff 或防御效果。

@export var formation_type: String = "defense"
@export var buff_id: String = "damage_reduction"
@export var buff_value: float = 0.2 # 20% 减伤
@export var radius: float = 200.0

var is_active: bool = true

func _ready() -> void:
	if has_node("/root/FormationManager"):
		get_node("/root/FormationManager").register_formation(self)
	
	# 设置碰撞形状
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)

func _exit_tree() -> void:
	if has_node("/root/FormationManager"):
		get_node("/root/FormationManager").unregister_formation(self)

func is_position_inside(pos: Vector2) -> bool:
	if not is_active: return false
	return global_position.distance_to(pos) <= radius

## 消耗材料激活阵法
func activate_with_material(item_id: String, amount: int) -> bool:
	if GameState.inventory.remove_item(item_id, amount):
		is_active = true
		return true
	return false
