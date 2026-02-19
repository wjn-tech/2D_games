extends Control

@onready var texture_rect: TextureRect = $Panel/MapTexture
@onready var player_marker: ColorRect = $Panel/PlayerMarker

var zoom: float = 0.5
var is_expanded: bool = false
var original_rect_settings: Dictionary = {}

func _ready() -> void:
	# Ensure the control can receive input and has a clear cursor
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	if MinimapManager:
		texture_rect.texture = MinimapManager.get_map_texture()
		var mat = texture_rect.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("fog_texture", MinimapManager.get_fog_texture())
		
		MinimapManager.minimap_updated.connect(_on_minimap_updated)

func _process(_delta: float) -> void:
	_update_minimap_shader()

func _input(event: InputEvent) -> void:
	# If any UI window has input focus (e.g. WandEditor open), do not capture minimap clicks
	if UIManager and UIManager.is_ui_focused:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Calculate if the mouse is within our boundaries
		var global_rect = get_global_rect()
		if global_rect.has_point(get_global_mouse_position()):
			toggle_expand()
			get_viewport().set_input_as_handled()

func toggle_expand() -> void:
	is_expanded = !is_expanded
	
	if is_expanded:
		# Put on top of everything and ignore parents
		top_level = true
		
		# Center on screen
		anchor_left = 0.5
		anchor_top = 0.5
		anchor_right = 0.5
		anchor_bottom = 0.5
		
		var vp_size = get_viewport_rect().size
		var s = min(vp_size.x, vp_size.y) * 0.85
		custom_minimum_size = Vector2(s, s)
		
		# Set offsets to center precisely
		offset_left = -s/2.0
		offset_top = -s/2.0
		offset_right = s/2.0
		offset_bottom = s/2.0
		
		zoom = 0.1
		z_index = 100
	else:
		top_level = false
		custom_minimum_size = Vector2(200, 200)
		
		# Reset offsets to let container take over
		offset_left = 0
		offset_top = 0
		offset_right = 0
		offset_bottom = 0
		
		zoom = 0.5
		z_index = 0

	_update_minimap_shader()

func _update_minimap_shader() -> void:
	if not MinimapManager: return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	# Explicitly update zoom in shader before position calc
	var mat = texture_rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("zoom", zoom)
		
		# Calculate normalized offset
		var pixel_pos = MinimapManager.world_to_map_pixel(player.global_position)
		var img_size = MinimapManager.map_image.get_size()
		var offset = Vector2(
			float(pixel_pos.x) / img_size.x - 0.5,
			float(pixel_pos.y) / img_size.y - 0.5
		)
		mat.set_shader_parameter("map_center_offset", offset)

func _on_minimap_updated() -> void:
	pass
