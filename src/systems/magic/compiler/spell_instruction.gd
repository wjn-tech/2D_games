extends RefCounted
class_name SpellInstruction

# Types
const TYPE_PROJECTILE = "PROJECTILE"
const TYPE_TRIGGER_TIMER = "TRIGGER_TIMER"
const TYPE_TRIGGER_COLLISION = "TRIGGER_COLLISION"
const TYPE_TRIGGER_DISAPPEAR = "TRIGGER_DISAPPEAR"
const TYPE_MODIFIER = "MODIFIER"
const TYPE_LOGIC_BLOCK = "LOGIC_BLOCK"

var type: String = TYPE_PROJECTILE
var params: Dictionary = {} 
# Common params:
# - speed: float
# - damage: float
# - lifetime: float
# - element: String
# - timer_duration: float (if timer trigger)

var modifiers: Array = [] # Array of ModifierData (Dictionaries or Objects)
var child_tier # : ExecutionTier # Typed loosely to avoid cyclic dependency with ExecutionTier
var child_mode: String = "PARALLEL" # "PARALLEL" or "SEQUENTIAL"; how child_tier executes
var child_exec_immediate: bool = false # If true, execute child_tier at cast-time (not by projectile)

func duplicate() -> SpellInstruction:
	var copy = SpellInstruction.new()
	copy.type = type
	# Duplicate params and modifiers safely
	if params is Dictionary:
		copy.params = params.duplicate()
	else:
		copy.params = params

	if modifiers is Array:
		copy.modifiers = modifiers.duplicate()
	else:
		copy.modifiers = modifiers

	# Deep-copy child_tier (create a new ExecutionTier and duplicate contained instructions)
	if child_tier:
		var new_tier = ExecutionTier.new()
		new_tier.instructions.clear()
		for sub in child_tier.instructions:
			if sub and sub is SpellInstruction:
				new_tier.instructions.append(sub.duplicate())
			else:
				new_tier.instructions.append(sub)
		copy.child_tier = new_tier
		copy.child_exec_immediate = child_exec_immediate
	else:
		copy.child_tier = null
	return copy
