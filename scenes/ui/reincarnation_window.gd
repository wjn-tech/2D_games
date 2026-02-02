extends Control

@onready var child_list = $Panel/VBoxContainer/ScrollContainer/ChildList
@onready var game_over_button = $Panel/VBoxContainer/GameOverButton

func _ready() -> void:
	_populate_children()
	game_over_button.pressed.connect(func(): GameManager.change_state(GameManager.State.GAME_OVER))

func _populate_children() -> void:
	# 清空列表
	for child in child_list.get_children():
		child.queue_free()
		
	var children = GameState.player_data.children
	var adult_count = 0
	
	for child_data in children:
		if child_data.is_adult:
			adult_count += 1
			var btn = Button.new()
			btn.text = "%s (力:%.1f 敏:%.1f 智:%.1f 体:%.1f)" % [
				child_data.display_name, 
				child_data.strength, 
				child_data.agility, 
				child_data.intelligence,
				child_data.constitution
			]
			btn.custom_minimum_size.y = 50
			btn.pressed.connect(func(): _on_child_selected(child_data))
			child_list.add_child(btn)
			
	if adult_count == 0:
		game_over_button.visible = true
		game_over_button.text = "接受终结"
		$Panel/VBoxContainer/Description.text = "你没有成年的子嗣可以继承。家族的血脉就此断绝..."
	else:
		game_over_button.visible = false
		$Panel/VBoxContainer/Description.text = "请选择一位成年的后裔，继承你的意志和事业。"

func _on_child_selected(child_data: CharacterData) -> void:
	print("选择继承人: ", child_data.display_name)
	
	# 执行异步转场
	_perform_succession_async(child_data)

func _perform_succession_async(child_data: CharacterData) -> void:
	# 1. 淡出到黑屏
	await UIManager.play_fade(true, 0.4)
	
	# 2. 核心继承逻辑
	var old_data = GameState.player_data
	GameState.player_data = child_data
	
	if old_data.attributes.has("money"):
		GameState.player_data.attributes["money"] = old_data.attributes["money"]
	
	GameState.player_data.life_span = child_data.max_life_span
	
	UIManager.close_window("Reincarnation")
	
	# 3. 刷新世界与玩家
	if EventBus:
		EventBus.player_data_refreshed.emit()
	
	GameManager.change_state(GameManager.State.PLAYING)
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("refresh_data"):
		player.refresh_data()
	
	# 4. 淡入回游戏
	await UIManager.play_fade(false, 0.6)
