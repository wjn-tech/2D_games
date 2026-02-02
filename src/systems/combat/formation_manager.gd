extends Node

## FormationManager (Autoload)
## 管理阵法（移动 Buff 区域或固定防御设施）。

signal formation_activated(formation_id: String)
signal formation_deactivated(formation_id: String)

# 存储当前活跃的阵法节点
var active_formations: Array[Node] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func register_formation(node: Node) -> void:
	if not node in active_formations:
		active_formations.append(node)
		formation_activated.emit(node.name)

func unregister_formation(node: Node) -> void:
	if node in active_formations:
		active_formations.erase(node)
		formation_deactivated.emit(node.name)

## 检查某个位置是否在特定阵法范围内
func is_in_formation(pos: Vector2, formation_type: String = "") -> bool:
	for f in active_formations:
		if is_instance_valid(f) and f.has_method("is_position_inside"):
			if formation_type == "" or f.formation_type == formation_type:
				if f.is_position_inside(pos):
					return true
	return false
