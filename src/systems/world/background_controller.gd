extends ParallaxBackground
class_name BackgroundController

@export var surface_height: float = 0.0
@export var underground_color: Color = Color(0.05, 0.02, 0.02) # 更暗的地底

# 昼夜背景颜色
var sky_night = Color(0.05, 0.05, 0.1)
var sky_day = Color(0.7, 0.8, 1.0) # 标准天蓝色背景

@onready var layers: Array[ParallaxLayer] = []
@onready var sky_layer: ParallaxLayer = get_node_or_null("SkyLayer")

func _ready() -> void:
	for child in get_children():
		if child is ParallaxLayer:
			layers.append(child)
	
	var world_gen = get_tree().get_first_node_in_group("world_generator")
	if world_gen:
		surface_height = world_gen.world_height * 0.6 * 16

func _process(_delta: float) -> void:
	# 获取地表高度
	if surface_height == 0.0:
		var world_gen = get_tree().get_first_node_in_group("world_generator")
		if world_gen:
			surface_height = world_gen.world_height * 0.6 * 16
	
	var camera = get_viewport().get_camera_2d()
	if not camera: return
	
	var cam_y = camera.global_position.y
	var progress = Chronometer.get_day_progress()
	
	# 1. 计算基于时间的表面颜色（天际线颜色）
	var time_weight = 0.5 + 0.5 * cos((progress * 2.0 - 1.0) * PI)
	var time_color = sky_night.lerp(sky_day, time_weight)
	
	# 2. 计算基于生态的颜色修正
	var biome_mod = Color.WHITE
	var world_gen = get_tree().get_first_node_in_group("world_generator")
	if world_gen:
		var weights = world_gen.get_biome_weights_at_pos(camera.global_position)
		var target_biome_color = Color(0,0,0,0)
		for b_type in weights:
			var b_color = world_gen.biome_params[b_type].get("color", Color.WHITE)
			target_biome_color += b_color * weights[b_type]
		biome_mod = target_biome_color
	
	# 3. 垂直深度过渡 (地表 vs 地底)
	var depth_factor = clamp((cam_y - surface_height) / 500.0, 0.0, 1.0)
	var final_surface_color = (time_color * biome_mod).lerp(underground_color, depth_factor)
	
	# 更新所有层
	for p_layer in layers:
		if p_layer == sky_layer:
			# 天空层受时间和生态影响，地底变黑
			p_layer.modulate = p_layer.modulate.lerp(time_color * biome_mod * (1.0 - depth_factor), 0.1)
		else:
			p_layer.modulate = p_layer.modulate.lerp(final_surface_color, 0.1)
