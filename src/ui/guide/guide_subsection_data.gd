class_name GuideSubsectionData extends Resource

## ID for this subsection (used for internal reference)
@export var subsection_id: String = "subsection_1"

## Title of this subsection
@export var title: String = "Subsection Title"

## Content text (supports BBCode formatting)
@export var content: String = "This is the content text. You can use [b]bold[/b], [color=yellow]colors[/color], and more."

## Optional image to display alongside text
@export var image: Texture2D
