extends LimboState

## 战斗/逃跑状态 (CombatState)
## 处理：面对威胁时的反应

@export var state_behavior_tree: BehaviorTree

var npc: BaseNPC
var attack_cooldown: float = 0.0

func _setup() -> void:
	npc = agent as BaseNPC

func _enter() -> void:
	# npc.say("有敌袭！")
	blackboard.set_var("behavior_mode", "combat")
	
	if npc.bt_player and state_behavior_tree:
		npc.bt_player.behavior_tree = state_behavior_tree
		npc.bt_player.active = true
	elif npc.bt_player and npc.bt_player.behavior_tree:
		npc.bt_player.active = true

func _exit() -> void:
	blackboard.set_var("behavior_mode", "peaceful")

func _update(delta: float) -> void:
	var target = blackboard.get_var("target")
	
	# 如果目标消失或死亡
	if not is_instance_valid(target):
		dispatch("threat_cleared")
		return
		
	# 距离过远脱战
	var dist = npc.global_position.distance_to(target.global_position)
	if dist > npc.detection_range * 1.5:
		blackboard.set_var("target", null)
		dispatch("threat_cleared")
		return
		
	# BehaviorTree 处理优先
	if npc.bt_player and npc.bt_player.behavior_tree:
		return
		
	# Fallback Combat Logic
	_fallback_combat(target, dist, delta)

func _fallback_combat(target: Node2D, dist: float, delta: float) -> void:
	if attack_cooldown > 0:
		attack_cooldown -= delta
		
	# Action: Move to target
	if dist > npc.attack_range:
		npc.move_along_path(target.global_position)
	else:
		npc.stop_movement()
		if attack_cooldown <= 0:
			_perform_attack(target)

func _perform_attack(target: Node2D) -> void:
	# Simple direct damage for now
	attack_cooldown = 1.0
	if npc.animator:
		# Try play attack anim?
		# npc.animator.play("attack")
		pass
		
	if target.has_method("take_damage"):
		target.take_damage(10.0) # Base damage

