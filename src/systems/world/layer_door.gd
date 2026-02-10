extends Area2D
class_name LayerDoor

## LayerDoor
## 允许玩家在不同物理图层之间切换的交互对象。

@export var target_layer: int = 0
@export var door_name: String = "图层传送门"

func _ready() -> void:
	# 确保门有正确的碰撞层，以便玩家能检测到它
	# 门通常应该在它所在的层可见
	add_to_group("interactable")

## 被玩家交互时调用
func interact(_interactor: Node = null) -> void:
	if LayerManager:
		var current = LayerManager.active_layer
		if current == target_layer:
			# 如果已经在目标层，可能需要一个“返回”逻辑，或者门是单向的
			# 这里简单处理：如果已经在目标层，则不做动作
			return
			
		LayerManager.switch_to_layer(target_layer)
		
		# 脱战逻辑：当玩家通过传送门时，让玩家附近的敌对 NPC 强制丢失目标
		_reset_nearby_npc_aggro()
		
		# 播放简单的视觉反馈
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func _reset_nearby_npc_aggro() -> void:
	# 找到所有正在追逐玩家的 NPC
	var npcs = get_tree().get_nodes_in_group("npcs")
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	for npc in npcs:
		if npc is BaseNPC:
			var bb = npc.bt_player.blackboard if npc.bt_player else null
			if bb and bb.get_var("target") == player:
				# 只要玩家跨越了层级，NPC 即使视野内也会因为逻辑检测而丢失目标
				bb.set_var("target", null)
				# 触发 HSM 事件回到和平状态
				if npc.hsm:
					npc.hsm.dispatch("threat_cleared")
