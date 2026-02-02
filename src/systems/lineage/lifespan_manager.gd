extends Node

## LifespanManager (Autoload)
## 负责管理角色的寿命流逝，包括自然衰老和高强度动作导致的加速消耗。

signal lifespan_depleted(character_data: CharacterData)

# 游戏内一天的秒数（默认 60 秒一天）
@export var seconds_per_day: float = 60.0 
# 每年多少天（默认 30 天一年）
@export var days_per_year: int = 30

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if not GameState.player_data: return
	
	# 自然衰老：每秒流逝的时间转换为年
	# 1秒 = 1/seconds_per_day 天 = 1/(seconds_per_day * days_per_year) 年
	var years_passed = delta / (seconds_per_day * days_per_year)
	consume_lifespan(GameState.player_data, years_passed)
	
	# 子嗣成长逻辑
	for child in GameState.player_data.children:
		if not child.is_adult:
			# 子嗣成长速度可以比寿命流逝快，这里假设 10 分钟成年
			child.growth_progress += delta / 600.0 
			if child.growth_progress >= 1.0:
				child.growth_progress = 1.0
				child.is_adult = true
				child.current_age = 18.0 # 成年后设定为 18 岁
				print("LifespanManager: 子嗣已成年: ", child.display_name)

## 消耗寿命
func consume_lifespan(data: CharacterData, amount_years: float) -> void:
	if data.life_span <= 0: return
	
	data.life_span -= amount_years
	data.current_age += amount_years
	
	if data.life_span <= 0:
		data.life_span = 0
		lifespan_depleted.emit(data)
		# 触发全局死亡事件
		if data == GameState.player_data:
			# 发出全局死亡警报信号 (EventBus)
			if EventBus:
				EventBus.emit_signal("player_health_changed", 0, data.max_health)
			GameManager.change_state(GameManager.State.REINCARNATING)

## 环境触发的意外死亡（如掉落虚空、极寒天气）
func trigger_instant_death(data: CharacterData, reason: String = "意外") -> void:
	print("LifespanManager: 角色死亡原因: ", reason)
	data.life_span = 0
	lifespan_depleted.emit(data)
	if data == GameState.player_data:
		GameManager.change_state(GameManager.State.REINCARNATING)

## 高强度动作导致的额外消耗（加速老化）
func record_action_strain(data: CharacterData, strain_days: float = 1.0) -> void:
	# 将天数转换为年数
	var amount_years = strain_days / days_per_year
	consume_lifespan(data, amount_years)
