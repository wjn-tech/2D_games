extends Node

## 物理层隔离检测工具
## 使用方法：在运行游戏时，按 F8 (或其他绑定键) 触发检测 logic

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F8:
		run_isolation_test()

func run_isolation_test() -> void:
	print("\n--- 开始物理图层隔离检测 ---")
	
	var world_gen = get_tree().get_first_node_in_group("world_generator")
	if not world_gen:
		print("错误：未找到 WorldGenerator")
		return
		
	# 1. 检查 TileSet 唯一性
	var l0 = world_gen.get_node_or_null("Layer0")
	var l1 = world_gen.get_node_or_null("Layer1")
	if l0 and l1:
		if l0.tile_set == l1.tile_set:
			print("❌ 失败：图层 0 和图层 1 共享同一个 TileSet 资源，物理无法隔离！")
		else:
			print("✅ 成功：图层已拥有独立的 TileSet 副本。")
			
			# 2. 检查碰撞位
			var b0 = l0.tile_set.get_physics_layer_collision_layer(0)
			var b1 = l1.tile_set.get_physics_layer_collision_layer(0)
			print("图层 0 物理位: ", b0)
			print("图层 1 物理位: ", b1)
			if b0 != b1 and (b0 & b1) == 0:
				print("✅ 成功：物理碰撞位已正确分离。")
			else:
				print("❌ 失败：图层碰撞位冲突！")
	
	# 3. 实时实体检测
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var current_layer = player.get_meta("current_layer", 0)
		var expected_bit = LayerManager.get_world_bit(current_layer)
		print("玩家当前图层: ", current_layer, " (预期物理位: ", expected_bit, ")")
		if player.collision_mask & expected_bit:
			print("✅ 成功：玩家正在遮罩当前图层的物理。")
		else:
			print("❌ 失败：玩家碰撞遮罩未包含当前图层！")
			
		# 检查是否误撞了其他层
		for i in range(3):
			if i == current_layer: continue
			var other_bit = LayerManager.get_world_bit(i)
			if player.collision_mask & other_bit:
				print("❌ 严重错误：玩家会撞击到非活跃图层 %d 的物体！" % i)
				
	print("--- 检测结束 ---\n")
