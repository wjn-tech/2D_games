extends Node

## Chronometer (Autoload)
## 负责管理全球时间流逝、历法（天、月、年）以及与此相关的周期性信号。

# 常量定义
const SECONDS_PER_MINUTE = 60.0
const MINUTES_PER_HOUR = 60
const HOURS_PER_DAY = 24
const DAYS_PER_YEAR = 30 # 每个季度/年设为 30 天，简化模拟

# 时间比例设置
# 要求：一昼夜 (24h) = 10分钟 (600s)
# 1440 游戏分钟 / 600 真实秒 = 2.4 游戏分钟/秒
const GAME_MINUTES_PER_REAL_SECOND = 2.4

# 状态变量
@export var is_paused: bool = false
@export var time_scale: float = 1.0 # 时间加速倍率

var total_seconds: float = 0.0
var fractional_minutes: float = 0.0
var current_minute: int = 0
var current_hour: int = 8 # 默认早上 8 点开始
var current_day: int = 1
var current_year: int = 1

# 信号
signal minute_passed(m: int, h: int)
signal hour_passed(h: int, d: int)
signal day_passed(d: int, y: int)
signal year_passed(y: int)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func reset() -> void:
	print("Chronometer: Resetting calendar to Day 1 Hour 8...")
	total_seconds = 0.0
	fractional_minutes = 0.0
	current_minute = 0
	current_hour = 8
	current_day = 1
	current_year = 1
	is_paused = false

func _process(delta: float) -> void:
	if is_paused:
		return
	
	var frame_seconds = delta * time_scale
	total_seconds += frame_seconds
	
	# 通过 EventBus 通知全局时间流逝
	if EventBus:
		EventBus.time_passed.emit(total_seconds)
	
	_update_calendar(frame_seconds)

func _update_calendar(delta: float) -> void:
	# 计算本帧增加的游戏分钟
	var minutes_to_add = delta * GAME_MINUTES_PER_REAL_SECOND
	fractional_minutes += minutes_to_add
	
	# 提取整数分钟
	var passed_minutes = floori(fractional_minutes)
	if passed_minutes > 0:
		fractional_minutes -= passed_minutes
		
		for i in range(passed_minutes):
			current_minute += 1
			if current_minute >= MINUTES_PER_HOUR:
				current_minute = 0
				_on_hour_passed(1)
			
			minute_passed.emit(current_minute, current_hour)

func _on_hour_passed(hours: int) -> void:
	current_hour += hours
	if current_hour >= HOURS_PER_DAY:
		var extra_days = floori(current_hour / float(HOURS_PER_DAY))
		current_hour %= HOURS_PER_DAY
		_on_day_passed(extra_days)
	
	hour_passed.emit(current_hour, current_day)

func _on_day_passed(days: int) -> void:
	current_day += days
	if current_day >= DAYS_PER_YEAR:
		var extra_years = floori(current_day / float(DAYS_PER_YEAR))
		current_day %= DAYS_PER_YEAR
		_on_year_passed(extra_years)
	
	day_passed.emit(current_day, current_year)

func _on_year_passed(years: int) -> void:
	current_year += years
	year_passed.emit(current_year)
	print("!!! Happy New Year !!! Year: ", current_year)

## 获取当日进度的归一化值 (0.0 - 1.0)
## 0.0 代表午夜 00:00，0.5 代表正午 12:00
func get_day_progress() -> float:
	var total_minutes_in_day = HOURS_PER_DAY * MINUTES_PER_HOUR
	var current_total_minutes = current_hour * MINUTES_PER_HOUR + current_minute
	return float(current_total_minutes) / float(total_minutes_in_day)

## 获取当日阶段
func get_time_phase() -> String:
	var h = current_hour
	if h >= 5 and h < 7: return "Dawn"
	if h >= 7 and h < 18: return "Day"
	if h >= 18 and h < 20: return "Dusk"
	return "Night"

## 获取格式化的时间字符串 (例如: "Year 1, Day 12 - 08:30")
func get_time_string() -> String:
	return "Year %d, Day %d - %02d:%02d" % [current_year, current_day, current_hour, current_minute]
