extends LimboState

## HomeState
## 让 NPC 移动回住所并在室内活动的 HSM 状态。

@export var day_transition_event: StringName = &"day_started"

func _enter() -> void:
	print("[HomeState] Entering HomeState for ", agent.name)
	if agent.bt_player:
		# 可以在这里设置专门的夜晚行为树，或者在统一 BT 中通过 is_night 判断
		agent.bt_player.set_active(true)

func _update(delta: float) -> void:
	# 如果是白天，触发离开家
	var chron = get_node_or_null("/root/Chronometer")
	if chron and not (chron.current_hour >= 20 or chron.current_hour < 6):
		dispatch(day_transition_event)

func _exit() -> void:
	print("[HomeState] Leaving HomeState")
