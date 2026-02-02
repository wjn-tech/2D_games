extends Area2D
class_name LayerGate

@export var target_layer: int = 1 # 目标碰撞层 (1-32)
@export var gate_name: String = "传送门"

func _ready() -> void:
	# 门本身在交互层 (Bit 4)
	collision_layer = 8
	collision_mask = 0

func interact() -> void:
	if get_node_or_null("/root/LayerManager"):
		get_node("/root/LayerManager").switch_to_layer(target_layer)
		print("玩家切换到图层: ", target_layer)
	else:
		# 回退逻辑
		var player = get_tree().get_first_node_in_group("player")
		if player:
			_switch_player_layer(player, target_layer)

func _switch_player_layer(player: CharacterBody2D, layer_num: int) -> void:
	# 物理层切换
	player.collision_layer = (1 << (layer_num - 1))
	# 玩家通常需要检测环境碰撞（假设环境在第 1 层）
	player.collision_mask = 1 | (1 << (layer_num - 1))
	
	# 交互层切换（假设交互 Area2D 在玩家子节点）
	var interaction_area = player.get("interaction_area")
	if interaction_area:
		# 玩家交互 Area2D 的 mask 决定了它能看到哪一层的交互对象
		interaction_area.collision_mask = (1 << (layer_num - 1))
	
	# 视觉反馈（可选：改变透明度或颜色）
	if layer_num == 1:
		player.modulate = Color.WHITE
	else:
		player.modulate = Color(0.7, 0.7, 1.0, 0.8) # 变蓝变透表示在另一层
