extends Node

signal lineage_updated

var children: Array[Dictionary] = []

func marry(npc: BaseNPC) -> void:
	if npc.npc_data.can_marry:
		print("已与 ", npc.npc_data.display_name, " 结婚")
		# 记录配偶信息
		GameState.player_data["spouse"] = npc.npc_data.npc_id

func produce_offspring() -> void:
	if not GameState.player_data.has("spouse"):
		print("尚未结婚，无法繁育")
		return
		
	var child = {
		"name": "子嗣 " + str(children.size() + 1),
		"stats": {
			"strength": GameState.player_data.stats.strength + randi_range(-2, 5),
			"longevity": 100.0,
			"age": 0.0
		}
	}
	children.append(child)
	print("新子嗣出生: ", child.name)
	lineage_updated.emit()

func reincarnate(child_index: int) -> void:
	if child_index < 0 or child_index >= children.size():
		return
		
	var selected_child = children[child_index]
	print("转生为: ", selected_child.name)
	
	# 继承属性
	GameState.player_data.stats = selected_child.stats
	# 保留装备（假设 inventory 中包含装备）
	# 清空子嗣列表（或保留其他子嗣作为备选）
	children.remove_at(child_index)
	
	# 触发世界刷新或玩家重置
	SaveManager.save_game()
	get_tree().reload_current_scene()
