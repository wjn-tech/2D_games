extends PanelContainer
class_name ResourceDisplay

@onready var icon_rect: TextureRect = %Icon
@onready var count_label: Label = %Count

@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		if is_inside_tree() and icon_rect:
			icon_rect.texture = value

func _ready() -> void:
	if icon_texture and icon_rect:
		icon_rect.texture = icon_texture

func setup(texture: Texture2D, count: int) -> void:
	if icon_rect:
		icon_rect.texture = texture
	if count_label:
		count_label.text = str(count)

func update_count(count: int) -> void:
	if count_label:
		count_label.text = str(count)
