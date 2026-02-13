@tool
extends BTAction
class_name BTSelectDialogue

## BTSelectDialogue
## 根据黑板中的环境信息 (时间、天气、生物群落、心情) 选择合适的对话。

@export var dialogue_pool: Dictionary = {
	"Default": ["Hello!", "Nice weather today."],
	"Night": ["It's getting late...", "I should head home."],
	"Rainy": ["I don't like getting wet.", "Stay dry!"],
	"Forest": ["The trees are so peaceful here."],
	"Unhappy": ["I'm not feeling great...", "Leaving me alone might be best."]
}

func _tick(_delta: float) -> Status:
	var npc: BaseNPC = agent as BaseNPC
	if not npc: return FAILURE
	
	var chosen_pool = dialogue_pool["Default"]
	
	# 优先级逻辑
	if blackboard.get_var("is_night", false):
		chosen_pool = dialogue_pool.get("Night", chosen_pool)
	elif blackboard.get_var("weather", 0) == 1: # RAINY (WeatherManager.WeatherType.RAINY)
		chosen_pool = dialogue_pool.get("Rainy", chosen_pool)
	elif blackboard.get_var("happiness", 1.0) < 0.7:
		chosen_pool = dialogue_pool.get("Unhappy", chosen_pool)
	
	# 还可以根据 Biome 进一步细化...
	
	var message = chosen_pool[randi() % chosen_pool.size()]
	if npc.speech_bubble:
		npc.speech_bubble.say(message)
		
	return SUCCESS
