extends Node

## CombatManager (Autoload)
## 处理伤害计算、击退与全局战斗反馈。

signal damage_dealt(target: Node, amount: float, is_critical: bool)

# HitStop / Frame Freeze
var _hit_stop_duration: float = 0.0

func _physics_process(delta: float) -> void:
	pass # Logic moved to Timer



func trigger_hit_stop(_duration: float = 0.05, _timescale_min: float = 0.05) -> void:
	# 逻辑已彻底废弃，所有对该函数的调用已删除或空置
	pass

func deal_damage(attacker: Node, target: Node, base_damage: float, damage_type: String = "physical") -> void:
	if not target.has_method("take_damage"):
		return
		
	var final_damage = base_damage
	var is_critical = false
	
	if randf() < 0.1:
		final_damage *= 1.5 
		is_critical = true
		
	var hit_dir = Vector2.ZERO
	if attacker and "global_position" in attacker and "global_position" in target:
		hit_dir = (target.global_position - attacker.global_position).normalized()
		_apply_visual_embedding(attacker, target, hit_dir)
		
	target.take_damage(final_damage, damage_type)
	damage_dealt.emit(target, final_damage, is_critical)
	
	if target is CharacterBody2D and hit_dir != Vector2.ZERO:
		_apply_knockback(target, hit_dir, 300.0)

	# 移除了所有卡肉和攻击者嵌入逻辑，确保战斗流畅不中断
	if attacker and attacker.is_in_group("player"):
		_trigger_screen_shake(0.2, 12.0 + (final_damage * 0.5)) 

func _apply_visual_embedding(_attacker: Node, _target: Node, _direction: Vector2) -> void:
	# 逻辑已停用，保持空函数
	pass


func _apply_knockback(target: CharacterBody2D, direction: Vector2, force: float) -> void:
	# Prefer an 'apply_knockback' method if exists (Player/Enemy common interface)
	if target.has_method("apply_knockback"):
		target.apply_knockback(direction * force)
	else:
		# Fallback: Modify velocity directly (might be overwritten in their process)
		target.velocity += direction * force

func _trigger_screen_shake(duration: float, intensity: float) -> void:
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(duration, intensity)
