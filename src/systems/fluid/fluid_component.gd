extends Node
class_name FluidComponent

# Liquid constants
const LIQUID_NONE = 0
const LIQUID_WATER = 1
const LIQUID_LAVA = 2
const LIQUID_HONEY = 3

const MAX_LEVEL = 8.0

var liquid_data: Dictionary = {} # Key: Vector2i (local), Value: { type: int, level: float }
var active_cells: Array = [] # List of Vector2i cells that need processing

func _init():
	pass

func set_liquid(local_pos: Vector2i, type: int, level: float) -> void:
	if level <= 0.0 or type == LIQUID_NONE:
		liquid_data.erase(local_pos)
		return
	liquid_data[local_pos] = { "type": type, "level": clampf(level, 0.0, MAX_LEVEL) }
	if not active_cells.has(local_pos):
		active_cells.append(local_pos)

func get_liquid(local_pos: Vector2i) -> Dictionary:
	return liquid_data.get(local_pos, { "type": LIQUID_NONE, "level": 0.0 })

func serialize() -> Dictionary:
	return {
		"liquid_data": liquid_data.duplicate(),
		"active_cells": active_cells.duplicate()
	}

func deserialize(data: Dictionary) -> void:
	liquid_data = data.get("liquid_data", {})
	active_cells = data.get("active_cells", [])
