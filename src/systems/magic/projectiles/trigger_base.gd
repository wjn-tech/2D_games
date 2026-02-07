extends ProjectileBase
class_name TriggerBase

var child_tier: ExecutionTier

func setup_trigger(tier: ExecutionTier):
	child_tier = tier

func execute_children():
	if child_tier and not child_tier.instructions.is_empty():
		# Pass get_parent() as the world context (Arena or World)
		SpellProcessor.execute_tier(child_tier, global_position, velocity_vector.normalized(), get_parent())
