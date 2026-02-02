extends Node

## 角色属性引擎检测工具
## 使用方法：运行游戏时按 F9 键触发测试

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F9:
		run_attribute_influence_test()

func run_attribute_influence_test() -> void:
	print("\n--- 开始角色属性影响力检测 ---")
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("错误：未找到 Player")
		return
		
	var player_data = GameState.player_data
	print("初始属性: STR:%.1f, AGI:%.1f" % [player_data.strength, player_data.agility])
	print("当前物理值: Speed:%.1f, Jump:%.1f" % [player.SPEED, player.JUMP_VELOCITY])
	
	# 模拟属性变化
	print("\n>>> 模拟属性大幅提升 (Strength +50, Agility +50)...")
	# 修改 CharacterData 后，通过 Setter 触发信号，AttributeComponent 自动捕获
	player_data.strength += 50
	player_data.agility += 50
	
	# 等待一帧让信号处理（GDScript 信号通常同步，但为了保险等待）
	await get_tree().process_frame
	
	print("更新后物理值: Speed:%.1f, Jump:%.1f" % [player.SPEED, player.JUMP_VELOCITY])
	
	if player.SPEED > 375.0 and player.JUMP_VELOCITY < -1250.0:
		print("✅ 成功：属性已关联并实时影响物理参数。")
	else:
		print("❌ 失败：物理参数未发生预期偏移！")
		
	# 检查 UI
	var hud_stats = get_tree().get_first_node_in_group("hud_stats") # 假设 UI 在此组
	print("请检查屏幕左上方 HUD，确认数值是否同步更新。")
	
	print("--- 检测结束 ---\n")
