extends VBoxContainer

## Displays a collapsible guide section with multiple subsections

@onready var header_button: Button = %HeaderButton
@onready var content_container: VBoxContainer = %ContentContainer

var section_data: GuideSectionData
var is_expanded: bool = false

func _ready() -> void:
	header_button.pressed.connect(_on_header_pressed)

func set_section_data(data: GuideSectionData) -> void:
	## Set the section data and populate content
	section_data = data
	header_button.text = "▶ " + data.title
	_populate_content()

func _populate_content() -> void:
	## Clear existing subsections and create new ones
	for child in content_container.get_children():
		child.queue_free()
	
	for subsection in section_data.get_subsections():
		var subsection_item = preload("res://scenes/ui/guide_subsection_item.tscn").instantiate()
		subsection_item.set_subsection_data(subsection)
		content_container.add_child(subsection_item)

func _on_header_pressed() -> void:
	toggle_expand()

func toggle_expand() -> void:
	## Toggle between expanded and collapsed states
	is_expanded = !is_expanded
	header_button.text = ("▼ " if is_expanded else "▶ ") + section_data.title
	content_container.visible = is_expanded
