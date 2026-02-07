extends LimboState

## 闲置/和平状态 (IdleState)
## 处理：日常游荡、寻找房屋、避雨、夜晚归家等逻辑

@export var state_behavior_tree: BehaviorTree

var npc: BaseNPC
var wander_timer: float = 0.0
var current_wander_target: Vector2 = Vector2.ZERO

func _setup() -> void:
	npc = agent as BaseNPC

func _enter() -> void:
	print("[IdleState] _enter called for ", npc.name if npc else "Unknown")
	# 动态切换行为树
	if npc and npc.bt_player:
		if state_behavior_tree:
			print("[IdleState] Assigning and starting Behavior Tree: ", state_behavior_tree.resource_path)
			npc.bt_player.behavior_tree = state_behavior_tree
			npc.bt_player.active = true
		elif npc.bt_player.behavior_tree:
			print("[IdleState] Resuming existing Behavior Tree.")
			npc.bt_player.active = true
		else:
			print("[IdleState] No Behavior Tree available, using fallback logic.")
			_pick_new_wander_target()
	else:
		push_error("[IdleState] Error: NPC or BTPlayer is missing!")

func _update(delta: float) -> void:
	# 1. 发现敌人判定 (如果是敌对单位找玩家，如果是友方找怪物)
	var target = _scan_for_targets()
	if target:
		# 修改：如果 NPC 是被动型 (Passive)，则不进入战斗追逐状态，除非被攻击（目前暂不实现反击）
		if npc.ai_type != BaseNPC.AIType.PASSIVE:
			# 修改：同时在 HSM 的黑板和 BTPlayer 的黑板设置目标
			blackboard.set_var("target", target)
			if npc.bt_player and npc.bt_player.blackboard:
				npc.bt_player.blackboard.set_var("target", target)
			
			dispatch("enemy_detected")
			return

	# 2. 如果有 BehaviorTree，交给 BT 处理
	if npc.bt_player and npc.bt_player.behavior_tree:
		return

	# 3. Fallback 简易游荡逻辑
	wander_timer -= delta
	if wander_timer <= 0:
		_pick_new_wander_target()
	
	if current_wander_target != Vector2.ZERO:
		npc.move_along_path(current_wander_target)
		
		if npc.global_position.distance_to(current_wander_target) < 20.0:
			npc.stop_movement()
			current_wander_target = Vector2.ZERO # Wait a bit

func _scan_for_targets() -> Node2D:
	if not npc.npc_data: return null
	
	if npc.npc_data.alignment == "Hostile":
		# 获取所有玩家
		var players = get_tree().get_nodes_in_group("player")
		if players.size() == 0:
			# 如果找不到 group，尝试直接按类查找作为兜底
			var fallback_player = get_tree().root.find_child("Player", true, false)
			if fallback_player: players = [fallback_player]

		for player in players:
			var dist = npc.global_position.distance_to(player.global_position)
			if dist < npc.detection_range:
				print("[IdleState] DETECTED TARGET: ", player.name, " (Group: player) Dist: ", dist)
				return player
	return null

func _pick_new_wander_target() -> void:
	wander_timer = randf_range(3.0, 8.0)
	# Random point around home or current pos
	var center = npc.home_position if npc.home_position != Vector2.ZERO else npc.global_position
	var range = npc.wander_radius
	
	var drift = Vector2(randf_range(-range, range), 0) # Mostly horizontal for 2D platformer?
	# Or keep it 2D grounded logic
	current_wander_target = center + drift
