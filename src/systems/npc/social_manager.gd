extends Node

## SocialManager (Autoload)
## 处理婚姻、社交关系、声望阈值。

signal relationship_changed(npc: Node, new_level: int)
signal marriage_occurred(partner_a: CharacterData, partner_b: CharacterData)

enum Relation { STRANGER, ACQUAINTANCE, FRIEND, SOULMATE, SPOUSE }

func get_relation_level(player_data: CharacterData, target_data: CharacterData) -> Relation:
	if player_data.spouse_id != -1 and player_data.spouse_id == target_data.uuid:
		return Relation.SPOUSE
		
	var affinity = player_data.affinity_map.get(target_data.uuid, 0)
	
	if affinity > 800: return Relation.SOULMATE
	if affinity > 500: return Relation.FRIEND
	if affinity > 100: return Relation.ACQUAINTANCE
	return Relation.STRANGER

func try_propose(player: Node, npc: Node) -> bool:
	if not player or not npc: return false
	
	var p_data = player.attributes.data
	var n_data = npc.npc_data
	
	if p_data.spouse_id != -1:
		print("你已经结婚了！")
		return false
	
	# Check if relation is at least SOULMATE
	if get_relation_level(p_data, n_data) < Relation.SOULMATE:
		print("关系还没到结婚的程度。")
		return false
		
	# 成功结婚
	p_data.spouse_id = n_data.uuid
	n_data.spouse_id = p_data.uuid
	marriage_occurred.emit(p_data, n_data)
	print("求婚成功！你与 ", n_data.display_name, " 结为了伴侣。")
	return true
	
func change_affinity(player_data: CharacterData, target_data: CharacterData, amount: int) -> void:
	var current = player_data.affinity_map.get(target_data.uuid, 0)
	var new_val = clamp(current + amount, 0, 1000)
	player_data.affinity_map[target_data.uuid] = new_val
	# Ideally should be symmetric?
	target_data.affinity_map[player_data.uuid] = new_val
	# emit signal if needed
