extends Node

## Autoload singleton for managing gameplay guide content

var sections: Dictionary = {} # { section_id: GuideSectionData }

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_all_guide_resources()
	print("GuideDataManager: Loaded ", sections.size(), " guide sections")

func _load_all_guide_resources() -> void:
	## Load all .tres files from res://data/guide/ directory
	var dir = DirAccess.open("res://data/guide/")
	if dir:
		dir.list_dir_begin()
		while true:
			var file = dir.get_next()
			if file.is_empty():
				break
			if not dir.current_is_dir() and file.ends_with(".tres"):
				var resource = load("res://data/guide/" + file)
				if resource is GuideSectionData:
					sections[resource.section_id] = resource
					print("GuideDataManager: Loaded section '", resource.section_id, "': ", resource.title)

func get_all_sections() -> Array[GuideSectionData]:
	## Returns all loaded guide sections
	var result: Array[GuideSectionData] = []
	for value in sections.values():
		if value is GuideSectionData:
			result.append(value)
	return result

func get_section(section_id: String) -> GuideSectionData:
	## Get a specific section by ID
	var value = sections.get(section_id)
	if value is GuideSectionData:
		return value
	return null
