extends ParallaxBackground
class_name BackgroundController

@export var surface_height: float = 0.0
@export var underground_color: Color = Color(0.1, 0.1, 0.1) # Dark Grey Underground
@export var void_color: Color = Color(0.0, 0.0, 0.0) # Black Void

# Minimalist Style: Soft Sky Blue
var sky_night = Color(0.05, 0.05, 0.1)
var sky_day = Color(0.7, 0.85, 1.0) # Light Sky Blue for contrast

@onready var bg_rect: ColorRect = ColorRect.new()

func _ready() -> void:
	# Clean up existing texture layers for minimalist style
	for child in get_children():
		child.visible = false
		# Optional: child.queue_free() if we want to aggressively remove them
	
	# Create solid color background
	add_child(bg_rect)
	bg_rect.anchor_right = 1.0
	bg_rect.anchor_bottom = 1.0
	bg_rect.color = sky_day
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Ensure it covers the viewport even if camera moves (ParallaxBackground handles this partially, 
	# but ColorRect inside ParallaxBackground needs to be handled or simplified)
	# Actually, putting ColorRect inside a CanvasLayer (which ParallaxBackground is) works if we set the layer index.
	# But ParallaxBackground expects scroll.
	# Better to set the bg_rect size to a very large value or fix it relative to screen.
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	
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
	
	# --- 1. Day/Night Cycle ---
	var progress = Chronometer.get_day_progress()
	var time_weight = 0.5 + 0.5 * cos((progress * 2.0 - 1.0) * PI)
	var time_color = sky_night.lerp(sky_day, time_weight)
	
	# --- 2. Depth Interpolation (Underground) ---
	# Surface at surface_height.
	# Deep underground (e.g. +1000 pixels) is dark.
	var final_color = time_color
	
	if cam_y > surface_height:
		var depth = cam_y - surface_height
		var depth_weight = clamp(depth / 2000.0, 0.0, 1.0)
		final_color = time_color.lerp(underground_color, depth_weight)
		
		if depth > 3000.0:
			var void_weight = clamp((depth - 3000.0) / 1000.0, 0.0, 1.0)
			final_color = final_color.lerp(void_color, void_weight)
			
	# Apply
	bg_rect.color = final_color
	
	# No Biome tint for now - keep it clean/minimalist white/grey
