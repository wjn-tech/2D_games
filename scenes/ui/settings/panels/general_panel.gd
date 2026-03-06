extends VBoxContainer

@onready var language_option: OptionButton = %LanguageOption

func _ready() -> void:
	# Initialize UI
	if not language_option: return
	
	language_option.clear()
	# Add items with translation keys for display if desired, 
	# but usually language names are native.
	language_option.add_item("简体中文", 0)
	language_option.set_item_metadata(0, "zh")
	language_option.add_item("English", 1)
	language_option.set_item_metadata(1, "en")
	
	# Set current selection
	var current_lang = SettingsManager.get_value("General", "language")
	var found = false
	for i in language_option.item_count:
		if language_option.get_item_metadata(i) == current_lang:
			language_option.selected = i
			found = true
			break
	if not found:
		language_option.selected = 0 # Default to zh if unknown
			
	language_option.item_selected.connect(_on_language_selected)

func _on_language_selected(index: int) -> void:
	var lang_code = language_option.get_item_metadata(index)
	SettingsManager.set_value("General", "language", lang_code)
