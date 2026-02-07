extends Control

var mode: String = "load" # "load" or "save"

@onready var slots = [
	$Panel/VBoxContainer/Slot1,
	$Panel/VBoxContainer/Slot2,
	$Panel/VBoxContainer/Slot3
]
@onready var back_button = $Panel/VBoxContainer/BackButton

var confirmation_dialog: ConfirmationDialog
var pending_slot_id: int = -1

func _ready() -> void:
	# 动态创建确认对话框
	confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.title = "确认覆盖"
	confirmation_dialog.dialog_text = "该栏位已有存档，是否覆盖？"
	confirmation_dialog.ok_button_text = "覆盖"
	confirmation_dialog.cancel_button_text = "取消"
	confirmation_dialog.confirmed.connect(_on_confirm_overwrite)
	add_child(confirmation_dialog)

	back_button.pressed.connect(func(): UIManager.close_window("SaveSelection"))
	
	for i in range(slots.size()):
		var slot_id = i + 1
		slots[i].pressed.connect(func(): _on_slot_pressed(slot_id))
	
	refresh_ui()

func set_mode(m: String) -> void:
	mode = m
	refresh_ui()

func refresh_ui() -> void:
	if not is_inside_tree(): return
	
	# 尝试更新标题（如果存在）
	var title_node = find_child("Label", true, false)
	if title_node and title_node is Label:
		if mode == "save":
			title_node.text = "保存游戏 - 选择栏位"
		else:
			title_node.text = "读取游戏 - 选择栏位"
			
	for i in range(slots.size()):
		_update_slot_text(i + 1)

func _update_slot_text(slot_id: int) -> void:
	var info = SaveManager.get_slot_info(slot_id)
	var btn = slots[slot_id-1]
	
	if info.is_empty():
		btn.text = "存档 %d\n[ 空 ]" % slot_id
	else:
		btn.text = "存档 %d\n%s  |  %s" % [
			slot_id, 
			info.get("player_name", "未知"), 
			info.get("display_time", "")
		]

func _on_slot_pressed(slot_id: int) -> void:
	if mode == "save":
		var info = SaveManager.get_slot_info(slot_id)
		if not info.is_empty():
			pending_slot_id = slot_id
			confirmation_dialog.popup_centered()
			return
		
		_perform_save(slot_id)
	else:
		var info = SaveManager.get_slot_info(slot_id)
		if info.is_empty():
			# 空存档无法加载
			UIManager.show_floating_text("空存档无法加载", get_global_mouse_position(), Color.RED)
			return
		
		_perform_load(slot_id)

func _on_confirm_overwrite() -> void:
	if pending_slot_id != -1:
		_perform_save(pending_slot_id)
		pending_slot_id = -1

func _perform_save(slot_id: int) -> void:
	SaveManager.save_game(slot_id)
	UIManager.show_floating_text("存档成功！", Vector2(100, 100), Color.GREEN)
	
	# 关闭所有相关窗口并返回主菜单
	UIManager.close_window("SaveSelection")
	UIManager.close_window("PauseMenu") 
	GameManager.change_state(GameManager.State.START_MENU)
	
func _perform_load(slot_id: int) -> void:
	if SaveManager.load_game(slot_id):
		UIManager.close_window("SaveSelection")
		UIManager.close_window("MainMenu")
		GameManager.change_state(GameManager.State.PLAYING)
		
		# 强制刷新状态
		GameManager.current_state = GameManager.State.PAUSED 
		GameManager.change_state(GameManager.State.PLAYING)
