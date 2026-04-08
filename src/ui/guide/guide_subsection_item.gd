extends VBoxContainer

## Displays a guide subsection with optional image and text content

@onready var title_label: Label = $TitleLabel
@onready var image_rect: TextureRect = $ImageRect
@onready var content_label: RichTextLabel = $ContentLabel

var subsection_data: GuideSubsectionData

func _ready() -> void:
	pass

func set_subsection_data(data: GuideSubsectionData) -> void:
	## Set the subsection data and populate UI elements
	subsection_data = data
	title_label.text = data.title
	content_label.text = data.content
	
	# Handle image display
	if data.image != null:
		image_rect.texture = data.image
		image_rect.show()
	else:
		image_rect.hide()
