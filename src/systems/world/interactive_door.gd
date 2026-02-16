extends StaticBody2D
class_name InteractiveDoor

@onready var visual = $MinimalistEntity
@onready var sprite = get_node_or_null("Sprite2D")
@onready var collision = get_node_or_null("CollisionShape2D")
@onready var detection_area = get_node_or_null("DetectionArea")

var is_open: bool = false
var hp: float = 2.0 # 门比石头脆弱

func _ready() -> void:
	add_to_group("destructible")
	add_to_group("interactable")
	add_to_group("doors")
	
	# 物理层：位于 Layer 1 (环境)，阻挡所有人
	collision_layer = 1
	collision_mask = 0
	
	# 确保 Area2D 正确
	if detection_area:
		# 强制设置范围，防止编辑器设置不生效
		var circle = CircleShape2D.new()
		circle.radius = 48.0 # 扩大感应半径
		var shape_node = detection_area.get_node_or_null("CollisionShape2D")
		if shape_node:
			shape_node.shape = circle
			shape_node.position = Vector2(8, 16)
		
		detection_area.collision_layer = 0
		detection_area.collision_mask = 16 | 32
		detection_area.monitoring = true

	_update_state()

func _physics_process(_delta: float) -> void:
	if not detection_area: return
	
	# 主动扫描感应区内的所有人
	var bodies = detection_area.get_overlapping_bodies()
	var any_friendly = false
	
	for body in bodies:
		if _is_friendly(body):
			any_friendly = true
			# 始终维持物理穿透
			add_collision_exception_with(body)
	
	# 根据感应结果切换门的状态
	if any_friendly:
		if not is_open:
			open_door()
	else:
		if is_open:
			close_door()

func _is_friendly(body: Node) -> bool:
	if not body: return false
	if body.is_in_group("player"): return true
	if body.is_in_group("hostile_npcs"): return false
	if body is BaseNPC:
		return body.npc_data.alignment != "Hostile"
	return false

func _on_body_entered(body: Node2D) -> void:
	if _is_friendly(body):
		add_collision_exception_with(body)

func _on_body_exited(body: Node2D) -> void:
	if _is_friendly(body):
		remove_collision_exception_with(body)

func _has_friendlies_in_area() -> bool:
	if not detection_area: return false
	for b in detection_area.get_overlapping_bodies():
		if _is_friendly(b): return true
	return false

func open_door():
	if is_open: return
	is_open = true
	_update_state()

func close_door():
	if not is_open: return
	is_open = false
	_update_state()

func _update_state():
	if not is_inside_tree(): return # 确保在节点树中
	
	# 设置基本状态逻辑
	if is_open:
		# 打开为虚化
		if visual: visual.modulate.a = 0.3
		if sprite: sprite.modulate.a = 0.3
	else:
		# 关闭为实心
		if visual: visual.modulate.a = 1.0
		if sprite: sprite.modulate.a = 1.0
	
	# 物理特性：敌对始终有碰撞，友方例外已在 _physics_process 处理
	# 这里确保物理体本身是开启的
	if collision: 
		collision.set_deferred("disabled", false)
		
	if visual and visual.has_method("queue_redraw"):
		visual.queue_redraw()
		
	# 调试打印状态
	print("Door state updated: ", "OPEN" if is_open else "CLOSED")

# 被挖掘/攻击时的逻辑
func hit(damage: float, _damage_source: Variant = null) -> void:
	hp -= damage
	# 简单的抖动视觉效果
	var base_x = visual.position.x
	var tween = create_tween()
	tween.tween_property(visual, "position:x", base_x + 2.0, 0.05)
	tween.tween_property(visual, "position:x", base_x - 2.0, 0.05)
	tween.tween_property(visual, "position:x", base_x, 0.05)
	
	if hp <= 0:
		_destroy()

func _destroy():
	# 掉落物品逻辑
	_spawn_drop()
	queue_free()

func _spawn_drop():
	var loot_scene = load("res://scenes/world/loot_item.tscn")
	if loot_scene:
		var loot = loot_scene.instantiate()
		get_parent().add_child(loot)
		loot.global_position = global_position + Vector2(8, -16)
		
		# 加载门的数据资源
		var door_item = load("res://data/items/door.tres")
		if door_item:
			# 关键修复：将对应的建筑资源重新绑回物品元数据，确保捡起来后能再次放置
			var build_res = load("res://src/core/resources/build_door.tres")
			if build_res:
				door_item.set_meta("building_resource", build_res)
			
			loot.setup(door_item, 1)
		
		print("Door: 门已被挖掘，掉落物品: 门 (含建筑元数据)")
