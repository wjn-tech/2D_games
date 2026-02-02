extends Camera2D

var shake_duration: float = 0.0
var shake_intensity: float = 0.0
var default_offset: Vector2 = Vector2.ZERO

var player: Node2D

func _ready() -> void:
	default_offset = offset
	player = get_tree().get_first_node_in_group("player")
	if player:
		# 初始时直接对齐玩家位置，避免开局镜头从 (0,0) 滑动到生成点
		global_position = player.global_position

func _process(delta: float) -> void:
	if player:
		# 平滑跟随玩家
		global_position = global_position.lerp(player.global_position, 10.0 * delta)
	
	if shake_duration > 0:
		shake_duration -= delta
		offset = default_offset + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		offset = default_offset

func shake(duration: float, intensity: float) -> void:
	shake_duration = duration
	shake_intensity = intensity
