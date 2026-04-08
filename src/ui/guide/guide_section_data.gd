class_name GuideSectionData extends Resource

## ID for this section (used for internal reference)
@export var section_id: String = "section_1"

## Title of this guide section
@export var title: String = "Guide Section Title"

## Description or subtitle
@export var description: String = "A brief description of this section"

## Optional icon for this section
@export var icon: Texture2D

## Array of subsections - stored as weakly typed, will be cast to proper type when needed
@export var subsections: Array = []

func get_subsections() -> Array[GuideSubsectionData]:
	## Returns subsections as properly typed array
	return subsections as Array[GuideSubsectionData]
