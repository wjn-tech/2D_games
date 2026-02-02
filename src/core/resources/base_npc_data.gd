extends Resource
class_name BaseNPCData

@export var npc_id: String = ""
@export var display_name: String = ""
@export var portrait: Texture2D
@export var base_health: float = 100.0
@export var base_speed: float = 100.0
@export var faction: String = "neutral" # neutral, hostile, friendly
@export var can_trade: bool = false
@export var can_marry: bool = false
