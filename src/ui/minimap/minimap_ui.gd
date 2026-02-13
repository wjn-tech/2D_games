extends Control

@onready var texture_rect: TextureRect = $Panel/MapTexture
@onready var player_marker: ColorRect = $Panel/PlayerMarker

var zoom: float = 0.5

func _ready() -> void:
	if MinimapManager:
		texture_rect.texture = MinimapManager.get_map_texture()
		var mat = texture_rect.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("fog_texture", MinimapManager.get_fog_texture())
		
		MinimapManager.minimap_updated.connect(_on_minimap_updated)

func _process(_delta: float) -> void:
	_update_minimap_shader()

func _update_minimap_shader() -> void:
	if not MinimapManager: return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var mat = texture_rect.material as ShaderMaterial
	if mat:
		# 计算玩家在图像中的像素坐标，并归一化为 0.0 - 1.0 (相对于图像尺寸)
		var pixel_pos = MinimapManager.world_to_map_pixel(player.global_position)
		var img_size = MinimapManager.map_image.get_size()
		
		var offset = Vector2(
			float(pixel_pos.x) / img_size.x - 0.5,
			float(pixel_pos.y) / img_size.y - 0.5
		)
		
		mat.set_shader_parameter("map_center_offset", offset)
		mat.set_shader_parameter("zoom", zoom)

func _on_minimap_updated() -> void:
	# 强刷纹理显示
	pass
