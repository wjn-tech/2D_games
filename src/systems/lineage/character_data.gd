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

# 基础属性
@export var strength: float = 10.0:
	set(v):
		strength = v
		stat_changed.emit("strength", v)

@export var agility: float = 10.0:
	set(v):
		agility = v
		stat_changed.emit("agility", v)

@export var intelligence: float = 10.0:
	set(v):
		intelligence = v
		stat_changed.emit("intelligence", v)

@export var constitution: float = 10.0: # 体质：影响血量与抗性
	set(v):
		constitution = v
		stat_changed.emit("constitution", v)

@export var max_health: float = 100.0:
	set(v):
		max_health = v
		stat_changed.emit("max_health", v)
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
	"reputation": 0
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

# 状态
var is_married: bool = false
var spouse: CharacterData = null
var children: Array[CharacterData] = []

# 成长期相关
@export var is_adult: bool = true
@export var growth_progress: float = 1.0 # 0.0 到 1.0

## 生成后代数据
func create_offspring(partner: CharacterData) -> CharacterData:
	var child = CharacterData.new()
	child.display_name = "后代 of " + display_name
	child.is_adult = false
	child.growth_progress = 0.0
	child.current_age = 0.0
	
	# 遗传算法：(父*0.4 + 母*0.4) + (随机扰动*0.2)
	var avg_str = (strength + partner.strength) / 2.0
	var avg_agi = (agility + partner.agility) / 2.0
	var avg_int = (intelligence + partner.intelligence) / 2.0
	var avg_con = (constitution + partner.constitution) / 2.0
	
	child.strength = (strength * 0.4 + partner.strength * 0.4) + (avg_str * 0.2 * randf_range(0.5, 1.5))
	child.agility = (agility * 0.4 + partner.agility * 0.4) + (avg_agi * 0.2 * randf_range(0.5, 1.5))
	child.intelligence = (intelligence * 0.4 + partner.intelligence * 0.4) + (avg_int * 0.2 * randf_range(0.5, 1.5))
	child.constitution = (constitution * 0.4 + partner.constitution * 0.4) + (avg_con * 0.2 * randf_range(0.5, 1.5))
	
	# 随机继承性格
	child.personality = personality if randf() > 0.5 else partner.personality
	
	children.append(child)
	return child
