@tool
extends BTAction
class_name BTPerformAttack
## BTPerformAttack
## 执行攻击动作并造成伤害。

@export var damage: float = 10.0
@export var animation_name: String = "attack"
@export var cooldown: float = 1.0

var _cooldown_timer: float = 0.0

func _tick(delta: float) -> Status:
	if _cooldown_timer > 0:
		_cooldown_timer -= delta
		return RUNNING # 正在冷却或动作中
	
	var npc: BaseNPC = agent as BaseNPC
	var target = blackboard.get_var("target", null)
	
	if not is_instance_valid(target):
		return FAILURE
	
	# 执行攻击逻辑
	# Minimalist Visual (Bump)
	var min_vis = npc.get_node_or_null("MinimalistEntity")
	if min_vis:
		var dir = (target.global_position - npc.global_position).normalized()
		var tw = npc.create_tween()
		var start_pos = min_vis.position
		tw.tween_property(min_vis, "position", start_pos + dir * 8.0, 0.1)
		tw.tween_property(min_vis, "position", start_pos, 0.1)

	# if npc.animator and npc.animator.sprite_frames.has_animation(animation_name):
	# 	npc.animator.play(animation_name)
	
	if target.has_method("take_damage"):
		target.take_damage(damage)
	
	# 重置并返回成功
	_cooldown_timer = cooldown
	return SUCCESS

func _enter() -> void:
	_cooldown_timer = 0.0
