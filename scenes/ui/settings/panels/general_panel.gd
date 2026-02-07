extends VBoxContainer

func _ready() -> void:
	refresh_ui()

func refresh_ui() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()
	
	# Rebuild (Simple VBox for now)
	var label = Label.new()
	label.text = "语言 (Language): " + str(SettingsManager.get_value("General", "language"))
	add_child(label)
	
	# Add more general settings here...
