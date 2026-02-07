extends Node

## LifespanManager (Autoload)
## 负责管理角色的寿命流逝，包括自然衰老和高强度动作导致的加速消耗。

signal lifespan_depleted(character_data: CharacterData)

# 游戏内一天的秒数
# 根据需求：一昼夜 (24h) = 10分钟 (600s)
@export var seconds_per_day: float = 600.0 
# 每年多少天 (应与 Chronometer.DAYS_PER_YEAR 一致)
@export var days_per_year: int = 30

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 也可以连接 Chronometer 信号来保持绝对同步
	if Chronometer:
		Chronometer.day_passed.connect(_on_calendar_day_passed)

func _process(delta: float) -> void:
	if not GameState.player_data: return
	if Chronometer and Chronometer.is_paused: return
	
	# 这里依然保留 _process 以支持平滑增长和可能的加速消耗逻辑
	# 1秒经过的人生比例 = (1/seconds_per_day) 天 = 1/(seconds_per_day * days_per_year) 年
	var years_passed = delta / (seconds_per_day * days_per_year)
	
	# 注意：如果 Chronometer 有 time_scale，这里也应该乘上
	if Chronometer:
		years_passed *= Chronometer.time_scale
		
	consume_lifespan(GameState.player_data, years_passed)
	
	# 子嗣成长逻辑 (假设 10 分钟成年，即 1 个游戏日)
	for child in GameState.player_data.children:
		if not child.is_adult:
			child.growth_progress += delta / 600.0 
			if child.growth_progress >= 1.0:
				child.growth_progress = 1.0
				child.is_adult = true
				child.current_age = 18.0 
				print("LifespanManager: 子嗣已成年: ", child.display_name)

func _on_calendar_day_passed(day: int, year: int) -> void:
	# 仅用于日志或触发每日结算
	print("LifespanManager: 历法更新, 第 %d 天, 当前玩家年龄: %.2f" % [day, GameState.player_data.current_age])

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
			if EventBus and EventBus.has_signal("player_health_changed"):
				EventBus.player_health_changed.emit(0, data.max_health)
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
