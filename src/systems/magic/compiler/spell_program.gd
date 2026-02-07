extends RefCounted
class_name SpellProgram

var root_tier: ExecutionTier
var total_mana_cost: float = 0.0
var is_valid: bool = false
var compilation_errors: Array[String] = []

func _init():
	root_tier = ExecutionTier.new()
