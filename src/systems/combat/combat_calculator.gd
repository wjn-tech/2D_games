extends Node
class_name CombatCalculator

## CombatCalculator (Static)
## 负责计算攻击伤害的基础公式。

## 计算基础伤害
## attacker_attr: 攻击者的 AttributeComponent
## target_attr: 防御者的 AttributeComponent
static func calculate_damage(attacker_attr: AttributeComponent, target_attr: AttributeComponent) -> float:
	var base_dmg = 10.0 # 基础固定伤害
	var str_mult = attacker_attr.damage_mult if attacker_attr else 1.0
	
	# 防御：体质减少伤害 (每 1 点体质减少 0.5 固定点，每 10 点提供 5% 减伤)
	var con_def = 0.0
	var def_mult = 1.0
	if target_attr and target_attr.data:
		con_def = (target_attr.data.constitution - 10.0) * 0.5
		def_mult = 1.0 / (1.0 + (target_attr.data.constitution - 10.0) * 0.01)
	
	var final_dmg = (base_dmg * str_mult - con_def) * def_mult
	return max(1.0, final_dmg) # 至少造成 1 点伤害

## 计算暴击率
static func calculate_crit_chance(agility: float) -> float:
	# 敏捷增加暴击，基础 10 点提供 5%，每 10 点多 5%
	return 0.05 + (agility - 10.0) * 0.005
