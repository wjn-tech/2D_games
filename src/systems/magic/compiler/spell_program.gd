extends RefCounted
class_name SpellProgram

var root_tier: ExecutionTier
var total_mana_cost: float = 0.0
var total_cast_delay: float = 0.0
var total_recharge_time: float = 0.0
var is_valid: bool = false
var compilation_errors: Array[String] = []
var compile_version: int = 0

func _init():
	root_tier = ExecutionTier.new()
