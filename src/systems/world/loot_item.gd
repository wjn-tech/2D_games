extends Area2D

## LootItem
## 掉落物实体，支持自动吸附飞向玩家。

@export var item_data: BaseItem
@export var amount: int = 1
@export var attraction_range: float = 200.0
@export var move_speed: float = 400.0

var target_player: CharacterBody2D = null
var is_collecting: bool = false

func setup(data: BaseItem, qty: int = 1) -> void:
	item_data = data
	amount = qty
	# 更新贴图 (假设有 Sprite2D 子节点)
	var sprite = find_child("Sprite2D", true, false)
	if sprite and item_data and item_data.icon:
		sprite.texture = item_data.icon

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# 初始弹出动画
	var random_dir = Vector2(randf_range(-1, 1), randf_range(-1, -0.5)).normalized()
	var tween = create_tween()
	tween.tween_property(self, "position", position + random_dir * 40.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	if is_collecting: return
	
	# 动态获取玩家，防止转生后引用失效
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player")
	
	if target_player:
		var dist = global_position.distance_to(target_player.global_position)
		if dist < attraction_range:
			# 飞向玩家
			var dir = (target_player.global_position - global_position).normalized()
			global_position += dir * move_speed * delta
			
			# 如果非常接近，直接触发拾取
			if dist < 20.0:
				_collect()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	if is_collecting: return
	is_collecting = true
	
	# 加入背包
	EventBus.item_collected.emit(item_data, amount)
	
	# 播放音效或动画后销毁
	queue_free()
