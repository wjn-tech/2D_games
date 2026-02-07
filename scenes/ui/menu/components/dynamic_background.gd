extends Control
class_name MenuDynamicBackground

## Dynamic Background Component
##根据系统时间或游戏进度显示不同的背景氛围

# 颜色配置
const COLOR_DAY = Color("87CEEB") # Sky Blue
const COLOR_NIGHT = Color("1a1a2e") # Dark Blue/Purple
const COLOR_DUSK = Color("fd7e14") # Orange
const COLOR_DAWN = Color("ff9f43") # Lighter Orange

@export var sky_rect: ColorRect
@export var particles: GPUParticles2D

func _ready() -> void:
	update_based_on_time()

func update_based_on_time() -> void:
	var system_time = Time.get_time_dict_from_system()
	var hour = system_time.hour
	
	print("DynamicBackground: Current system hour is ", hour)
	
	var target_color = COLOR_DAY
	var particle_amount = 5
	
	if hour >= 5 and hour < 8:
		# Dawn
		target_color = COLOR_DAWN
	elif hour >= 8 and hour < 17:
		# Day
		target_color = COLOR_DAY
	elif hour >= 17 and hour < 20:
		# Dusk
		target_color = COLOR_DUSK
	else:
		# Night (20 - 5)
		target_color = COLOR_NIGHT
		particle_amount = 20 # More stars/fireflies
	
	if sky_rect:
		# 如果是第一次加载，直接设置；如果是运行时变化，可以 tween
		sky_rect.color = target_color
		
	if particles:
		particles.amount_ratio = float(particle_amount) / 20.0
