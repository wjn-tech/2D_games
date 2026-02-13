extends StaticBody2D

var is_open: bool = false
@onready var animation_player = $AnimationPlayer
@onready var collision_shape = $CollisionShape2D

var health: float = 2.0 # 挖掘强度需求

func _ready():
	add_to_group("doors")
	# 默认关闭
	is_open = false
	collision_shape.disabled = false

func interact():
	toggle_door()

func toggle_door():
	is_open = !is_open
	if is_open:
		animation_player.play("open")
		collision_shape.disabled = true
	else:
		animation_player.play("close")
		collision_shape.disabled = false

func handle_mining(_damage: float):
	# 获取对应的物品资源并生成掉落物
	var item_res = GameState.crafting_manager.get_item_by_id("door")
	if item_res:
		var loot_item = preload("res://scenes/world/loot_item.tscn").instantiate()
		get_tree().current_scene.add_child(loot_item)
		loot_item.global_position = global_position
		loot_item.setup(item_res, 1)
	queue_free()
