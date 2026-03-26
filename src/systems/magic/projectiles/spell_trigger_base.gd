extends ProjectileBase
class_name SpellTriggerBase

var _continuation: Dictionary = {}
var _wand_data: WandData

func setup_trigger(continuation: Dictionary = {}, wand_data: WandData = null):
	_continuation = continuation
	_wand_data = wand_data

func execute_children():
	var emissions = _continuation.get("emissions", []) if _continuation is Dictionary else []
	if not emissions.is_empty():
		SpellProcessor.execute_continuation(_continuation, global_position, velocity_vector.normalized(), caster, get_parent(), _wand_data)
