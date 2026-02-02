extends Node
class_name CircuitNode

## CircuitNode
## 工业电路的基础节点，支持信号输入与输出。

enum NodeType { POWER, WIRE, AND_GATE, OR_GATE, NOT_GATE, ACTUATOR, AUTO_MINER }

@export var type: NodeType = NodeType.WIRE
@export var inputs: Array[CircuitNode] = []

var is_powered: bool = false
var mining_timer: float = 0.0
const MINING_INTERVAL: float = 2.0

func _process(_delta: float) -> void:
	update_logic()

func update_logic() -> void:
	match type:
		NodeType.POWER:
			is_powered = true
		
		NodeType.WIRE:
			is_powered = _any_input_powered()
			
		NodeType.AND_GATE:
			is_powered = _all_inputs_powered() and inputs.size() >= 2
			
		NodeType.OR_GATE:
			is_powered = _any_input_powered()
			
		NodeType.NOT_GATE:
			is_powered = not _any_input_powered() if inputs.size() > 0 else false
			
		NodeType.ACTUATOR:
			is_powered = _any_input_powered()
			_on_actuator_state_changed(is_powered)
			
		NodeType.AUTO_MINER:
			is_powered = _any_input_powered()
			if is_powered:
				_handle_auto_mining(get_process_delta_time())

func _handle_auto_mining(delta: float) -> void:
	mining_timer += delta
	if mining_timer >= MINING_INTERVAL:
		mining_timer = 0.0
		_try_mine_nearby()

func _try_mine_nearby() -> void:
	if GameState.digging:
		# 自动挖掘下方的 Tile
		var parent = get_parent()
		if parent is Node2D:
			var world_pos = parent.global_position + Vector2(0, 32)
			var tile_map = GameState.digging.tile_map
			if tile_map:
				var map_pos = tile_map.local_to_map(tile_map.to_local(world_pos))
				GameState.digging.try_mine_tile(map_pos, 10) # 自动采矿机默认稿力 10

func _any_input_powered() -> bool:
	for input in inputs:
		if input.is_powered: return true
	return false

func _all_inputs_powered() -> bool:
	for input in inputs:
		if not input.is_powered: return false
	return true

func _on_actuator_state_changed(state: bool) -> void:
	# 由子类实现具体行为（如开门、亮灯）
	pass
