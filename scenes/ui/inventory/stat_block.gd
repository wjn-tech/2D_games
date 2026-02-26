extends PanelContainer
class_name StatBlock

@onready var label: Label = %Label
@onready var value_label: Label = %Value
@onready var stat_bar: ProgressBar = %StatBar

func setup(stat_name: String, stat_value: String, progress: float = 0.0) -> void:
	if label:
		label.text = stat_name
	if value_label:
		value_label.text = stat_value
	if stat_bar:
		stat_bar.value = progress
		stat_bar.visible = progress > 0

