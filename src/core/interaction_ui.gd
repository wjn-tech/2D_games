extends Control

# --- 交互提示 UI ---
# 当玩家靠近可交互物体时显示提示。

@export var prompt_label: Label
@export var player_interaction_area: Area2D

func _ready() -> void:
	visible = false
	if not prompt_label:
		push_warning("InteractionUI: 未绑定 Label 节点")

func _process(_delta: float) -> void:
	if not player_interaction_area:
		return
		
	var targets = player_interaction_area.get_overlapping_areas()
	if targets.size() > 0:
		var target = targets[0]
		if target.has_method("interact"):
			_show_prompt("按 E 交互")
			return
			
	visible = false

func _show_prompt(text: String) -> void:
	prompt_label.text = text
	visible = true
	# 提示框跟随玩家或固定在屏幕下方
