extends RefCounted
class_name SpellInstruction

# Types
const TYPE_PROJECTILE = "PROJECTILE"
const TYPE_TRIGGER_TIMER = "TRIGGER_TIMER"
const TYPE_TRIGGER_COLLISION = "TRIGGER_COLLISION"
const TYPE_TRIGGER_DISAPPEAR = "TRIGGER_DISAPPEAR"

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

func duplicate() -> SpellInstruction:
	var copy = SpellInstruction.new()
	copy.type = type
	copy.params = params.duplicate()
	copy.modifiers = modifiers.duplicate()
	# child_tier is shared ref or deep copy? 
	# For compiled logic, shared ref is usually fine as it's read-only at runtime.
	copy.child_tier = child_tier 
	return copy
