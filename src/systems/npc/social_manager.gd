extends Node

## SocialManager (Autoload)
## 处理婚姻、社交关系、声望阈值。

signal relationship_changed(npc: Node, new_level: int)
signal marriage_occurred(partner_a: CharacterData, partner_b: CharacterData)

enum Relation { STRANGER, ACQUAINTANCE, FRIEND, SOULMATE, SPOUSE }

func get_relation_level(player_data: CharacterData, target_data: CharacterData) -> Relation:
	if player_data.spouse == target_data:
		return Relation.SPOUSE
		
	var rep = player_data.attributes.get("reputation", 0)
	if rep > 1000: return Relation.SOULMATE
	if rep > 500: return Relation.FRIEND
	if rep > 100: return Relation.ACQUAINTANCE
	return Relation.STRANGER

func try_propose(player: Node, npc: Node) -> bool:
	if not player or not npc: return false
	
	var p_data = player.attributes.data
	var n_data = npc.npc_data
	
	if p_data.spouse:
		print("你已经结婚了！")
		return false
		
	if get_relation_level(p_data, n_data) < Relation.SOULMATE:
		print("关系还没到结婚的程度。")
		return false
		
	# 成功结婚
	p_data.spouse = n_data
	n_data.spouse = p_data
	marriage_occurred.emit(p_data, n_data)
	print("求婚成功！你与 ", n_data.display_name, " 结为了伴侣。")
	return true
