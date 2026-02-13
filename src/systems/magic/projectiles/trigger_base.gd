extends ProjectileBase
class_name TriggerBase

var child_tier: ExecutionTier

func setup_trigger(tier: ExecutionTier):
	child_tier = tier

func execute_children():
	if child_tier and not child_tier.instructions.is_empty():
		# 使用此触发器的原始施法者 (caster) 作为后续指令的施法者
		# get_parent() 仅作为场景树中的挂载点（世界节点）
		SpellProcessor.execute_tier(child_tier, global_position, velocity_vector.normalized(), caster, get_parent())
