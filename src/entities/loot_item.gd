extends Area2D

# class_name LootItem # 移除全局类名以解决冲突，改用 has_method 检查

@onready var sprite = $Sprite2D

var item_resource: BaseItem
var attraction_range: float = 200.0
var move_speed: float = 400.0
var target_player: CharacterBody2D = null
var is_collecting: bool = false
var is_animating: bool = false
var amount: int = 1

func setup(res: BaseItem, qty: int = 1):
	item_resource = res
	amount = qty
	_update_visuals()
	# 确保在设置了 global_position 之后再播放动画
	_play_spawn_animation()

func _ready():
	_update_visuals()
	body_entered.connect(_on_body_entered)

func _play_spawn_animation():
	is_animating = true
	# 初始弹出动画
	var start_pos = global_position
	var target_pos = start_pos + Vector2(randf_range(-32, 32), randf_range(-40, -20))
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target_pos, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.25)
	
	# 串行部分：缩放回 1.0
	var scale_tween = create_tween()
	scale_tween.tween_interval(0.25)
	scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.25)
	
	tween.finished.connect(func(): is_animating = false)

func _update_visuals():
	if not sprite: return
	if item_resource and item_resource.icon:
		sprite.texture = item_resource.icon
		# 如果是泥土或石头，稍微调整颜色使其更像物块
		if item_resource.id == "dirt":
			sprite.modulate = Color(0.6, 0.4, 0.2)
		elif item_resource.id == "stone":
			sprite.modulate = Color(0.6, 0.6, 0.6)
	else:
		sprite.texture = preload("res://icon.svg")
		sprite.modulate = Color.GOLD

func _physics_process(delta: float) -> void:
	if is_collecting or is_animating: return
	
	# 动态获取玩家
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player")
	
	if target_player:
		var dist = global_position.distance_to(target_player.global_position)
		if dist < attraction_range:
			# 飞向玩家
			var dir = (target_player.global_position - global_position).normalized()
			global_position += dir * move_speed * delta
			
			# 如果非常接近，直接触发拾取
			if dist < 10.0:
				collect()

func _on_body_entered(body):
	if body.is_in_group("player"):
		collect()

func collect():
	if is_collecting:
		return
		
	if not item_resource:
		push_warning("LootItem: 尝试采集没有数据资源的掉落物，自动销毁")
		queue_free()
		return
		
	# Add to inventory via EventBus (Centralized approach)
	EventBus.item_collected.emit(item_resource, amount)
	
	is_collecting = true
	# Trigger floating text
	if UIManager:
		UIManager.show_floating_text("+" + str(amount) + " " + item_resource.display_name, global_position)
	
	queue_free()
