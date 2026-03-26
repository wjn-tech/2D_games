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
			
		if target_uuid != -1 and target_uuid == child_data.uuid:
			spawn_pos = npc.global_position
			print("Reincarnation: 找到继承人实体，位置: ", spawn_pos)
			
			# 确保生成位置在地面上，避免物理误差导致的位移
			if npc is CharacterBody2D:
				npc.velocity = Vector2.ZERO # 停止任何残留速度
			
			# 立即彻底移除子嗣实体，防止继承后世间还存在一个一模一样的自己
			npc.visible = false
			npc.process_mode = Node.PROCESS_MODE_DISABLED
			npc.remove_from_group("npcs") # 立即移出组，防止被后续逻辑误判
			
			heir_found = true
			npc.free() # 使用 free() 强制立即释放，而不是 wait queue_free
			break
			
	if not heir_found:
		# Fallback to current camera pos or player death pos
		spawn_pos = GameState.get_meta("last_player_pos", Vector2.ZERO)
		print("Reincarnation: 未找到继承人实体，使用保底位置: ", spawn_pos)
		
	# Store position Meta for GameManager to pick up
	# 关键：设置位置元数据
	GameState.set_meta("load_spawn_pos", spawn_pos)
	
	# 显式重置新角色的生命状态，防止继承了死亡状态的数据
	child_data.health = child_data.max_health
	child_data.life_span = child_data.max_life_span
	child_data.current_age = 20.0 # 继承后统一设为成年起始年龄（或根据需求保持 child_data.age）
	
	UIManager.close_window("Reincarnation")
	
	# 3. 切换状态 (GameManager 现在会处理从 REINCARNATING 到 PLAYING 的玩家重置逻辑)
	GameManager.change_state(GameManager.State.PLAYING)
	
	# 4. 强制在本帧刷新玩家位置（双重保险）
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = spawn_pos
		if player.has_method("refresh_data"):
			player.refresh_data()
			
	# 5. 延迟恢复淡入，确保新场景/角色已就绪
	await get_tree().create_timer(0.2).timeout
	UIManager.play_fade(false, 0.6)
