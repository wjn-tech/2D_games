extends Node

# Grid-Based Cellular Automata Liquid System
# Based on Terraria liquid mechanics (0-1 levels, rapid settling)

signal liquid_updated(global_pos: Vector2i, type: int, level: float)

const LIQUID_TYPE_NONE = 0
const LIQUID_TYPE_WATER = 1
const LIQUID_TYPE_LAVA = 2
const LIQUID_TYPE_HONEY = 3
const LIQUID_TYPE_ACID = 4 # Extended type

const MAX_LEVEL = 1.0
const MIN_LEVEL = 0.005 # Evaporation threshold
const FLOW_SPEED = 0.25 # Level transfer per tick

# Chunk-based active set for optimization
var _active_chunks: Dictionary = {} # {Vector2i: true}
var _liquid_chunks: Dictionary = {} # {Vector2i: PackedByteArray} 
# 1 byte per tile? Maybe 2 bytes (Type + Level * 255)
# Or Dictionary {local_pos: {type, level}} for sparse? 
# PackedByteArray is better for memory. 
# Size: 64x64 = 4096 tiles. 
# 2 Arrays: types (PackedByteArray), levels (PackedFloat32Array or Byte).

const CHUNK_SIZE = 64

func _ready() -> void:
	if InfiniteChunkManager:
		InfiniteChunkManager.chunk_loaded.connect(_on_chunk_loaded)
		InfiniteChunkManager.chunk_unloaded.connect(_on_chunk_unloaded)

func _on_chunk_loaded(coord: Vector2i) -> void:
	# Load liquid data from disk or generate it
	# For now, just mark active if near player?
	# Actual loading logic goes here
	pass

func _on_chunk_unloaded(coord: Vector2i) -> void:
	# Save liquid data
	pass

func _physics_process(delta: float) -> void:
	# Ticking logic
	pass
