extends Node

## CombatManager (Autoload)
## 处理伤害计算、击退与全局战斗反馈。

signal damage_dealt(target: Node, amount: float, is_critical: bool)

func deal_damage(attacker: Node, target: Node, base_damage: float) -> void:
	if not target.has_method("take_damage"):
		return
		
	var final_damage = base_damage
	var is_critical = false
	
	# 简单的暴击逻辑
	if randf() < 0.1:
		final_damage *= 2.0
		is_critical = true
		
	target.take_damage(final_damage)
	damage_dealt.emit(target, final_damage, is_critical)
	
	# 击退逻辑
	if target is CharacterBody2D:
		var knockback_dir = (target.global_position - attacker.global_position).normalized()
		_apply_knockback(target, knockback_dir, 300.0)
		
	# 视觉反馈：屏幕抖动
	if target.is_in_group("player") or attacker.is_in_group("player"):
		_trigger_screen_shake(0.2, 15.0)

func _apply_knockback(target: CharacterBody2D, direction: Vector2, force: float) -> void:
	target.velocity = direction * force
	# 假设目标有处理击退的状态，或者直接在 move_and_slide 中被应用

func _trigger_screen_shake(duration: float, intensity: float) -> void:
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(duration, intensity)
