extends StaticBody2D
class_name DestructibleBuilding

@export var max_health: float = 100.0
@export var hardness: float = 1.0
@export var drop_item_path: String = "res://data/items/wood.tres"
@export var drop_count: int = 5
@export var building_name: String = "建筑方块"

var current_health: float
var is_destroyed: bool = false

func _ready() -> void:
	current_health = max_health
	add_to_group("destructible")
	add_to_group("interactable")
	
	# 确保碰撞层正确
	# Bit 1 (Player), Bit 2 (NPC), Bit 4 (Interactions)
	collision_layer = (1 << 1) | (1 << 3) 
	
	# 如果没有碰撞形状，尝试根据子节点的视觉元素自动生成
	if get_child_count() > 0 and not _has_collision_shape():
		_auto_create_collision()

func _has_collision_shape() -> bool:
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			return true
	return false

func _auto_create_collision() -> void:
	# 支持从 ColorRect 或 Polygon2D 提取形状
	for child in get_children():
		if child is ColorRect:
			var shape = CollisionShape2D.new()
			var rect = RectangleShape2D.new()
			rect.size = child.size
			shape.shape = rect
			# ColorRect 的位置是左上角，而 CollisionShape2D 默认是中心
			shape.position = child.position + child.size / 2
			add_child(shape)
		elif child is Polygon2D:
			var poly = CollisionPolygon2D.new()
			poly.polygon = child.polygon
			poly.position = child.position
			poly.rotation = child.rotation
			poly.scale = child.scale
			add_child(poly)

func interact(_interactor: Node = null) -> void:
	print("Building: 这是一个 ", building_name, "。你可以通过挖掘来拆除它。")

func hit(damage: float, _hit_pos: Vector2 = Vector2.ZERO) -> void:
	take_damage(damage)

func take_damage(amount: float) -> void:
	if is_destroyed: return
	
	# 简单的硬度计算：伤害 = 原始伤害 / 硬度
	var actual_damage = amount / hardness
	current_health -= actual_damage
	
	# 视觉反馈：闪烁 (使用红色调)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 0.5, 0.5), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.05)
	
	if current_health <= 0:
		_destroy()

func _destroy() -> void:
	if is_destroyed: return
	is_destroyed = true
	_spawn_drops()
	queue_free()

func _spawn_drops() -> void:
	var loot_scene = preload("res://scenes/world/loot_item.tscn")
	var item_res = load(drop_item_path)
	
	if not item_res: return
	
	for i in range(drop_count):
		var loot = loot_scene.instantiate()
		# 放到父节点下
		get_parent().add_child(loot)
		loot.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		if loot.has_method("setup"):
			loot.setup(item_res)
