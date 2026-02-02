extends Control

@onready var slots = [
	$Panel/VBoxContainer/Slot1,
	$Panel/VBoxContainer/Slot2,
	$Panel/VBoxContainer/Slot3
]
@onready var back_button = $Panel/VBoxContainer/BackButton

func _ready() -> void:
	back_button.pressed.connect(func(): UIManager.close_window("SaveSelection"))
	
	for i in range(slots.size()):
		var slot_id = i + 1
		slots[i].pressed.connect(func(): _on_slot_pressed(slot_id))
		_update_slot_text(slot_id)

func _update_slot_text(slot_id: int) -> void:
	var path = "user://save_%d.save" % slot_id
	if FileAccess.file_exists(path):
		# 这里可以读取存档的简要信息，如玩家名、游戏时间
		slots[slot_id-1].text = "存档 %d - 已有数据" % slot_id
	else:
		slots[slot_id-1].text = "存档 %d - 空" % slot_id

func _on_slot_pressed(slot_id: int) -> void:
	# 假设 SaveManager 有 load_slot 方法
	# SaveManager.load_slot(slot_id)
	print("加载存档: ", slot_id)
	UIManager.close_window("SaveSelection")
	UIManager.close_window("MainMenu")
	GameManager.change_state(GameManager.State.PLAYING)
