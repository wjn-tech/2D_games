extends Control

@onready var child_list = $Panel/VBoxContainer/ScrollContainer/ChildList
@onready var game_over_button = $Panel/VBoxContainer/GameOverButton

func _ready() -> void:
	_populate_children()
	game_over_button.pressed.connect(func(): GameManager.change_state(GameManager.State.START_MENU))

func _populate_children() -> void:
	# 清空列表
	for child in child_list.get_children():
		child.queue_free()
		
	# Update to use LineageManager for finding candidates
	var all_descendants = LineageManager.descendants if LineageManager else []
	var candidates: Array[CharacterData] = []
	candidates.assign(all_descendants.filter(func(c): return c.growth_stage >= 2)) # ADULT
	
	var candidate_count = candidates.size()
	print("Reincarnation: Found %d total descendants, %d adults." % [all_descendants.size(), candidate_count])
	
	for child_data in candidates:
		var btn = Button.new()
		# Add mutation count display
		var mutations = child_data.mutations.get("patrilineal", 0) + child_data.mutations.get("matrilineal", 0)
		var mut_text = " [M:%d]" % mutations if mutations > 0 else ""
		
		btn.text = "%s (力:%.0f 敏:%.0f 智:%.0f 体:%.0f)%s" % [
			child_data.display_name, 
			child_data.strength, 
			child_data.agility, 
			child_data.intelligence,
			child_data.constitution,
			mut_text
		]
		btn.custom_minimum_size.y = 50
		btn.pressed.connect(func(): _on_child_selected(child_data))
		child_list.add_child(btn)
			
	if candidate_count == 0:
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
	
	# 从后代列表中移除该子嗣，因为它现在变成了玩家角色
	if LineageManager.descendants.has(child_data):
		LineageManager.descendants.erase(child_data)
	
	if old_data.attributes.has("money"):
		GameState.player_data.attributes["money"] = old_data.attributes["money"]
	
	# Find heir entity position before removing old player
	var spawn_pos = Vector2.ZERO
	var heir_found = false
	# 修正：NPC 组名为 "npcs" (复数)，此前写成单数导致未找到子嗣实体，引发双重存在和位置错误
	var npcs = get_tree().get_nodes_in_group("npcs")
	print("Reincarnation: 正在寻找 ID 为 %d 的子嗣实体，当前场景共有 %d 个NPC。" % [child_data.uuid, npcs.size()])
	
	for npc in npcs:
		var target_uuid = -1
		if npc.has_method("get_uuid"):
			target_uuid = npc.get_uuid()
		elif "npc_data" in npc and npc.npc_data:
			target_uuid = npc.npc_data.uuid
			
		print("  - 检查 NPC: ", npc.name, " (UUID: ", target_uuid, ")")
		
		if target_uuid != -1 and target_uuid == child_data.uuid:
			spawn_pos = npc.global_position
			print("Reincarnation: 找到继承人实体，位置: ", spawn_pos)
			
			# 确保生成位置在地面上，避免物理误差导致的位移
			if npc is CharacterBody2D:
				npc.velocity = Vector2.ZERO # 停止任何残留速度
			
			# 立即隐藏并停止处理，确保在 queue_free 生效前就在视觉上消失
			npc.visible = false
			npc.process_mode = Node.PROCESS_MODE_DISABLED
			
			heir_found = true
			npc.queue_free() # Remove NPC instance as it becomes Player
			break
			
	if not heir_found:
		# Fallback to current camera pos or player death pos
		spawn_pos = GameState.get_meta("last_player_pos", Vector2.ZERO)
		
	# Store position Meta for GameManager to pick up
	# 关键：我们设置 meta 并在 GameManager 中立即应用
	GameState.set_meta("load_spawn_pos", spawn_pos)
	
	# Reset state
	GameState.player_data.life_span = child_data.max_life_span
	# 确保属性完整性，新角色以满状态开始
	GameState.player_data.health = GameState.player_data.max_health
	
	UIManager.close_window("Reincarnation")
	
	# 3. 切换状态 (GameManager 现在会处理从 REINCARNATING 到 PLAYING 的玩家重置逻辑)
	GameManager.change_state(GameManager.State.PLAYING)
	
	# 4. 淡入回游戏
	await UIManager.play_fade(false, 0.6)
