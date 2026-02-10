extends Node
class_name AttributeComponent

## AttributeComponent
## 角色属性管理组件，将 CharacterData 的原始数值转化为实体的物理表现。

signal attribute_changed(attr_name: String, new_value: float)

# 规范化修正系数定义 (1.0 = 100%)
const STR_DAMAGE_STEP = 0.05      # 每点力量 +5% 伤害
const STR_JUMP_STEP = 0.01        # 每点力量 +1% 跳跃力
const AGI_SPEED_STEP = 0.03       # 每点敏捷 +3% 速度
const CON_HEALTH_STEP = 10.0      # 每点体质 +10 生命值
const BASE_STAT_THRESHOLD = 10.0  # 基础属性阈值 (高于此值产生正修正)

@export var data: CharacterData

# 缓存的物理修正系数
var move_speed_mult: float = 1.0
var jump_force_mult: float = 1.0
var damage_mult: float = 1.0

func _ready() -> void:
	if not data:
		# 如果是玩家，尝试从 GameState 获取
		var parent = get_parent()
		if parent and parent.is_in_group("player"):
			data = GameState.player_data
		else:
			data = CharacterData.new()
	
	if data:
		if not data.stat_changed.is_connected(update_modifiers_from_signal):
			data.stat_changed.connect(update_modifiers_from_signal)
	
	update_modifiers()

func update_modifiers_from_signal(_name: String, _val: float) -> void:
	# Ignore health/max_health changes to prevent recursive loops
	if _name == "health" or _name == "max_health":
		attribute_changed.emit(_name, _val)
		return
		
	update_modifiers()
	attribute_changed.emit(_name, _val)

## 更新所有修正系数
func update_modifiers() -> void:
	if not data: return
	
	var str_diff = data.strength - BASE_STAT_THRESHOLD
	var agi_diff = data.agility - BASE_STAT_THRESHOLD
	# var con_diff = data.constitution - BASE_STAT_THRESHOLD
	
	# 计算乘数
	damage_mult = 1.0 + (str_diff * STR_DAMAGE_STEP)
	jump_force_mult = 1.0 + (str_diff * STR_JUMP_STEP)
	move_speed_mult = 1.0 + (agi_diff * AGI_SPEED_STEP)
	
	# 从 AttributeComponent 移除对 max_health 的强制覆写
	# CharacterData 内部已有基于野性等级(stat_levels)的 max_health 计算逻辑 (Ark风格)
	# 这里只负责根据当前 max_health 调整 health 比例 (如果需要)
	# 但由于 CharacterData 自身处理属性变更，这里不再干预 max_health
	
	# 旧逻辑 (造成递归且覆盖了等级系统的效果):
	# var new_max_hp = 100.0 + (con_diff * CON_HEALTH_STEP)
	# ...


## 获取当前移动速度
func get_move_speed(base_speed: float) -> float:
	return base_speed * move_speed_mult

## 获取当前跳跃力
func get_jump_force(base_jump: float) -> float:
	return base_jump * jump_force_mult

## 获取伤害修正后的数值
func get_damage_multiplier(base_damage: float) -> float:
	return base_damage * damage_mult

## 获取最大生命值
func get_max_hp(base_hp: float = 100.0) -> float:
	if data: return data.max_health
	return base_hp

## 获取生命值百分比
func get_health_percent() -> float:
	if data.max_health <= 0: return 0.0
	return data.health / data.max_health
