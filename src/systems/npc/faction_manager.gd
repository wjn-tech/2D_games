extends Node

# 阵营声望: { "FactionName": reputation_value }
var reputations: Dictionary = {
	"Villagers": 0,
	"Bandits": -100,
	"Guardians": 50
}

func change_reputation(faction: String, amount: int):
	reputations[faction] = reputations.get(faction, 0) + amount
	print("Faction: ", faction, " 声望变化: ", amount, " 当前: ", reputations[faction])
	
	# 触发全局事件
	EventBus.emit_signal("reputation_changed", faction, reputations[faction])

func get_alignment(faction: String) -> String:
	var rep = reputations.get(faction, 0)
	if rep <= -50: return "Hostile"
	if rep >= 50: return "Friendly"
	return "Neutral"

# 群体仇恨：当一个 NPC 被攻击时，通知周围同阵营 NPC
func notify_attack(attacker: Node2D, victim: Node2D):
	if not victim.has_method("get_faction"): return
	
	var faction = victim.get_faction()
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc != victim and npc.has_method("get_faction") and npc.get_faction() == faction:
			if npc.global_position.distance_to(victim.global_position) < 500:
				npc.on_ally_attacked(attacker)
