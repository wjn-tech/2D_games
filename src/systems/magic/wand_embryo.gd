extends Resource
class_name WandEmbryo

@export var level: int = 1
@export var grid_resolution: int = 4 # 4x4, 8x8, 16x16 etc
@export var stat_capacity: int = 2 # Number of passive slots
@export var logic_capacity: int = 5 # Number of logic nodes allowed
@export var base_mana_cost: float = 0.0 # Noita doesn't have this, usually 0
@export var cast_delay: float = 0.2 # Base Cast Delay (seconds)
@export var recharge_time: float = 0.5 # Base Recharge Time (seconds)
@export var mana_capacity: float = 200.0 # Max mana
@export var mana_recharge_speed: float = 50.0 # Mana regained per second
@export var mana_recharge_burst: float = 40.0 # Flat mana given upon hitting recharge
