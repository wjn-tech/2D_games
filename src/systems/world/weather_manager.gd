extends Node

## WeatherManager (Autoload)
## 管理天气状态及其对世界的影响。

enum WeatherType { SUNNY, RAINY, SNOWY, THUNDERSTORM }

# 昼夜周期颜色配置
var night_color = Color(0.15, 0.15, 0.25, 1.0)
var day_color = Color(1.3, 1.3, 1.35, 1.0)

var current_weather: WeatherType = WeatherType.SUNNY
var weather_timer: float = 300.0 # 初始晴天持续 5 分钟
var thunder_cooldown: float = 0.0

signal weather_changed(new_weather: WeatherType)

func _ready() -> void:
	# 确保启动时应用一次晴天效果
	call_deferred("_apply_weather_effects")

func _process(delta: float) -> void:
	weather_timer -= delta
	if weather_timer <= 0:
		_change_random_weather()
		
	if current_weather == WeatherType.THUNDERSTORM:
		_handle_thunder(delta)
	
	_update_lighting()

func _update_lighting() -> void:
	var canvas_modulate = get_tree().get_first_node_in_group("global_light")
	if not canvas_modulate: return
	
	var progress = Chronometer.get_day_progress()
	var base_light: Color
	
	# 简单的亮度渐变：中午(0.5)最亮，深夜(0.0/1.0)最暗
	# 使用 cos 函数平滑过渡
	var weight = 0.5 + 0.5 * cos((progress * 2.0 - 1.0) * PI)
	base_light = night_color.lerp(day_color, weight)

	# 应用天气修正
	var weather_mod = Color.WHITE
	match current_weather:
		WeatherType.RAINY: weather_mod = Color(0.7, 0.7, 0.8, 1.0)
		WeatherType.SNOWY: weather_mod = Color(0.9, 0.9, 1.0, 1.0)
		WeatherType.THUNDERSTORM: weather_mod = Color(0.5, 0.5, 0.6, 1.0)
	
	canvas_modulate.color = base_light * weather_mod

func _handle_thunder(delta: float) -> void:
	thunder_cooldown -= delta
	if thunder_cooldown <= 0:
		_trigger_thunder()
		thunder_cooldown = randf_range(10.0, 30.0)

func _trigger_thunder() -> void:
	print("WeatherManager: 触发打雷 SFX")
	# 闪电视觉反馈
	var canvas_modulate = get_tree().get_first_node_in_group("global_light")
	if canvas_modulate:
		var original_color = canvas_modulate.color
		var flash_color = Color(3.0, 3.0, 3.5, 1.0) # 强光闪电
		
		var tween = create_tween()
		tween.tween_property(canvas_modulate, "color", flash_color, 0.05)
		tween.tween_property(canvas_modulate, "color", original_color, 0.2).set_delay(0.05)

func _change_random_weather() -> void:
	var types = WeatherType.values()
	current_weather = types[randi() % types.size()]
	weather_timer = randf_range(60.0, 180.0) # 持续 1-3 分钟
	
	weather_changed.emit(current_weather)
	_apply_weather_effects()
	if EventBus:
		EventBus.weather_changed.emit(WeatherType.keys()[current_weather])

func _apply_weather_effects() -> void:
	print("天气切换为: ", WeatherType.keys()[current_weather])
	
	# 视觉反馈：确保 CanvasModulate 启用
	var canvas_modulate = get_tree().get_first_node_in_group("global_light")
	if canvas_modulate:
		canvas_modulate.visible = true
				
	# 粒子特效反馈
	_update_particles()
				
	# 影响玩家属性
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# 使用动态属性系统的基础速度 (200.0)
		var base_s = player.get("BASE_SPEED") if player.get("BASE_SPEED") != null else 200.0
		var weather_mult = 1.0
		
		if current_weather == WeatherType.RAINY:
			weather_mult = 0.9
		elif current_weather == WeatherType.SNOWY:
			weather_mult = 0.7
		elif current_weather == WeatherType.THUNDERSTORM:
			weather_mult = 0.8
		
		# 如果玩家有属性组件，建议通过信号触发重新计算，或者手动更新并应用天气乘数
		if player.get("attributes") and player.attributes.has_method("get_move_speed"):
			player.SPEED = player.attributes.get_move_speed(base_s) * weather_mult
		else:
			player.SPEED = base_s * weather_mult

## 获取天气对特定属性的修正系数
func get_weather_modifier(modifier_id: String) -> float:
	match modifier_id:
		"fire_damage":
			if current_weather == WeatherType.RAINY or current_weather == WeatherType.THUNDERSTORM:
				return 0.5 # 雨天火属性伤害减半
		"ice_damage":
			if current_weather == WeatherType.SNOWY:
				return 1.5 # 雪天冰属性伤害增加
		"visibility":
			if current_weather == WeatherType.THUNDERSTORM:
				return 0.4 # 雷暴天视野极低
	return 1.0

func _update_particles() -> void:
	# 获取雨滴特效（建议用户在编辑器中将 GPUParticles2D 加入 "weather_rain_vfx" 组）
	var rain_nodes = get_tree().get_nodes_in_group("weather_rain_vfx")
	for node in rain_nodes:
		if node.has_method("set_emitting"):
			node.emitting = (current_weather == WeatherType.RAINY or current_weather == WeatherType.THUNDERSTORM)
	
	# 获取雪花特效（建议用户在编辑器中将 GPUParticles2D 加入 "weather_snow_vfx" 组）
	var snow_nodes = get_tree().get_nodes_in_group("weather_snow_vfx")
	for node in snow_nodes:
		if node.has_method("set_emitting"):
			node.emitting = (current_weather == WeatherType.SNOWY)
