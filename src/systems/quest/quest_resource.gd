extends Resource
class_name QuestResource

@export var quest_id: String = ""
@export var title: String = ""
@export var description: String = ""

enum QuestType { FETCH, KILL, TALK, DISCOVER }
@export var type: QuestType = QuestType.FETCH

@export var target_id: String = "" # Item ID or NPC ID or Enemy ID
@export var required_amount: int = 1
var current_amount: int = 0

@export var reward_money: int = 0
@export var reward_items: Array[String] = [] # Array of item IDs

var is_completed: bool = false
var is_active: bool = false

func check_completion() -> bool:
	if current_amount >= required_amount:
		is_completed = true
	return is_completed
