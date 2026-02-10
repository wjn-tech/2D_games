extends Resource
class_name CharacterData

## CharacterData
## 存储角色（玩家或 NPC）的属性、性格与血脉信息。

signal stat_changed(stat_name: String, new_value: float)

@export var display_name: String = ""
@export var gender: int = 0 # 0: Male, 1: Female
@export var personality: String = "Neutral" # Brave, Greedy, Gentle, etc.
@export var alignment: String = "Neutral"   # Friendly, Hostile, Neutral

# NPC 特定属性
@export var npc_type: String = "Animal"     # Hostile, Town, Animal
@export var happiness: float = 1.0          # 1.0 为标准, 越小越快乐(价格折扣)
@export var preferred_biome: String = "Forest"
@export var loved_neighbors: Array[String] = []  # 喜爱的 NPC 类别名
@export var hated_neighbors: Array[String] = []  # 讨厌的 NPC 类别名

# 基础数值配置 (Const/Resource)
const BASE_STATS = {
	"strength": 10.0,
	"agility": 10.0,
	"intelligence": 10.0,
	"constitution": 10.0,
	"max_health": 100.0
}
const INC_PER_WILD_LEVEL = 0.05 # 5% per wild level
const INC_PER_TAMED_LEVEL = 0.02 # 2% per tamed level

# Runtime Data
# { "strength": { "wild": 0, "tamed": 0, "mutation": 0 }, ... }
@export var stat_levels: Dictionary = {}

# Mutation Counters
@export var mutations: Dictionary = {
	"patrilineal": 0, # 父系
	"matrilineal": 0  # 母系
}

# 繁育相关
@export var spouse_id: int = -1
@export var generation: int = 1
@export var age: float = 0.0
@export var growth_stage: int = 0 # 0:BABY, 1:JUVENILE, 2:ADULT
@export var imprint_quality: float = 0.0 # 0.0 - 1.0

# 社交数据
@export var uuid: int = -1 # Unique Identifier
@export var affinity_map: Dictionary = {} # { target_uuid: affinity_value }

# 基础属性
var strength: float:
	get: return get_stat_value("strength")
	set(v): _set_stat_legacy("strength", v)

var agility: float:
	get: return get_stat_value("agility")
	set(v): _set_stat_legacy("agility", v)

var intelligence: float:
	get: return get_stat_value("intelligence")
	set(v): _set_stat_legacy("intelligence", v)

var constitution: float: # 体质：影响血量与抗性
	get: return get_stat_value("constitution")
	set(v): _set_stat_legacy("constitution", v)

var max_health: float:
	get: return get_stat_value("max_health")
	set(v): _set_stat_legacy("max_health", v)

var money: int:
	get: return attributes.get("money", 0)
	set(v): attributes["money"] = v

func _init() -> void:
	if uuid == -1:
		uuid = randi() # Simple random ID for prototype
	
	# Ensure stat_levels and attributes are initialized
	if attributes == null:
		attributes = { "money": 0 }
	
	for key in BASE_STATS.keys():
		if not stat_levels.has(key):
			stat_levels[key] = { "wild": 0, "tamed": 0, "mutation": 0 }

func get_stat_value(stat_name: String) -> float:
	var base = BASE_STATS.get(stat_name, 10.0)
	var levels = stat_levels.get(stat_name, { "wild": 0, "tamed": 0, "mutation": 0 })
	
	# 方舟逻辑：变异等级通常算作野生等级的一部分，这里我们将变异值加到野生系数中
	# 或者变异只是增加了 wild level 的“点数”，存储时直接存进 wild?
	# Design doc says "Add +2 to wild level". And "Mutation Check" counts total mutations.
	# So levels.mutation might just be for tracking, OR it's a separate multiplier?
	# Design doc code snippet:
	# var wild_mult = 1.0 + (levels.wild * INC_PER_WILD_LEVEL)
	# But in "Mutation Effect", specs say "Add +2 to wild level".
	# So `levels.wild` implies it includes mutation?
	# Let's support an explicit mutation field in stat structure for clarity if we want to separate "natural wild" vs "mutated wild",
	# BUT spec says: "Add +2 to wild level".
	# However, design code snippet used `levels.wild` and `levels.mutation` in `stat_levels`.
	# I'll treat `wild` as the base wild points. If mutation adds wild levels, we just increment `wild`.
	# BUT `stat_levels` structure in design has `mutation` key.
	# Maybe `mutation` count per stat track?
	# Spec: "Add +2 to wild level of that stat." 
	# So I will just increment wild.
	# The `mutation` key in stat_levels might be redundant OR used to track how many mutations applied to THIS stat specifically?
	# Let's keep the structure flexible: 
	var total_wild = levels.wild + (levels.get("mutation", 0) * 2) # Assuming mutation count * 2 levels?
	# Wait, Spec: "Add +2 to wild level". So I should just modify `wild`.
	# But if I modify `wild`, I can't easily tell what was mutation.
	# Let's assume `mutation` in `stat_levels` tracks number of mutation EVENTS on this stat.
	# Each event adds equivalent of 2 wild levels.
	
	var effective_wild = levels.wild + (levels.get("mutation", 0) * 2)
	
	var wild_mult = 1.0 + (effective_wild * INC_PER_WILD_LEVEL)
	var tamed_mult = 1.0 + (levels.tamed * INC_PER_TAMED_LEVEL)
	var imprint_mult = 1.0 + (imprint_quality * 0.2) # 20% max imprint bonus, for example. Design said "Bonus stats (Multiplicative)".
	
	return base * wild_mult * tamed_mult * imprint_mult

# Legacy setter to support loading old saves or direct assignment (converts to wild levels approx)
func _set_stat_legacy(stat_name: String, v: float) -> void:
	# This is a hacky reverse calculation or just direct setting for backward compat
	# Ideally we shouldn't use this, but for SaveManager...
	# Let's assuming setting it means setting it as if it's all Wild levels for simplicity
	# Base * (1 + x * 0.05) = v
	# 1 + x * 0.05 = v / Base
	# x * 0.05 = v/Base - 1
	# x = (v/Base - 1) / 0.05
	var base = BASE_STATS.get(stat_name, 10.0)
	if base == 0: return
	var needed_wild = max(0, int(((v / base) - 1.0) / INC_PER_WILD_LEVEL))
	
	if not stat_levels.has(stat_name):
		stat_levels[stat_name] = { "wild": 0, "tamed": 0, "mutation": 0 }
	
	stat_levels[stat_name]["wild"] = needed_wild
	stat_changed.emit(stat_name, get_stat_value(stat_name))

@export var health: float = 100.0:
	set(v):
		health = clamp(v, 0, max_health)
		stat_changed.emit("health", health)
@export var max_life_span: float = 100.0: # 最大寿命（年）
	set(v):
		max_life_span = v
		stat_changed.emit("max_life_span", v)

@export var life_span: float = 100.0: # 当前剩余寿命
	set(v):
		life_span = v
		stat_changed.emit("life_span", v)

@export var current_age: float = 20.0: # 当前年龄
	set(v):
		current_age = v
		stat_changed.emit("current_age", v)

# 等级与经验系统
@export var level: int = 1:
	set(v):
		level = v
		stat_changed.emit("level", v)

@export var experience: float = 0.0:
	set(v):
		experience = v
		stat_changed.emit("experience", v)
		_check_level_up()

@export var stat_points: int = 0:
	set(v):
		stat_points = v
		stat_changed.emit("stat_points", v)

func get_next_level_experience() -> float:
	return 100.0 * pow(level, 1.5)

## 增加经验值
func add_experience(amount: float) -> void:
	experience += amount
	# setter 逻辑会自动调用 _check_level_up()

func _check_level_up() -> void:
	var needed = get_next_level_experience()
	while experience >= needed:
		experience -= needed
		level += 1
		stat_points += 5 # 每级给 5 点属性点
		needed = get_next_level_experience()
		print("CharacterData: 等级提升! 当前等级: ", level)

# 扩展属性（金币、声望等）
@export var attributes: Dictionary = {
	"money": 0,
	# reputation is now legacy or global
}

## 增加/减少金币
func change_money(amount: int) -> bool:
	var current = attributes.get("money", 0)
	if current + amount < 0:
		return false
	attributes["money"] = current + amount
	stat_changed.emit("money", attributes["money"])
	return true

# 社交与阵营
@export var loyalty: float = 0.0 # 0-100, 达到一定值可招募
@export var role: String = "Villager" # Merchant, Farmer, Blacksmith, Guard, etc.

# Legacy fields cleaned up
# var spouse: CharacterData = null -> Use spouse_id
var children_ids: Array[int] = []


