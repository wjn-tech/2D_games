extends ProjectileBase
class_name TriggerBase

var child_tier: ExecutionTier
var _incoming_modifiers: Array = []
var _child_mode: String = ""

func setup_trigger(tier: ExecutionTier, incoming_mods: Array = [], incoming_mode: String = ""):
	child_tier = tier
	_incoming_modifiers = incoming_mods.duplicate()
	_child_mode = incoming_mode

func execute_children():
	if child_tier and not child_tier.instructions.is_empty():
		# 使用此触发器的原始施法者 (caster) 作为后续指令的施法者
		# get_parent() 仅作为场景树中的挂载点（世界节点）
		SpellProcessor.execute_tier(child_tier, global_position, velocity_vector.normalized(), caster, get_parent(), _incoming_modifiers, _child_mode == "PARALLEL")
