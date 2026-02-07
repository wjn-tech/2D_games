extends Resource
class_name WandEmbryo

@export var level: int = 1
@export var grid_resolution: int = 4 # 4x4, 8x8, 16x16 etc
@export var stat_capacity: int = 2 # Number of passive slots
@export var logic_capacity: int = 5 # Number of logic nodes allowed
@export var base_mana_cost: float = 10.0
@export var recharge_rate: float = 0.5 # Seconds between casts
@export var mana_capacity: float = 100.0 # Max mana for logic cost check
