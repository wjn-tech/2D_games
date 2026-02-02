extends IndustrialEntity

## LogicGate
## 逻辑门：处理简单的布尔逻辑信号。

enum GateType { AND, OR, NOT, XOR }
@export var gate_type: GateType = GateType.AND

var inputs: Dictionary = {0: false, 1: false}
var output: bool = false

signal output_changed(value: bool)

func receive_signal(input_id: int, value: bool) -> void:
	inputs[input_id] = value
	_update_logic()

func _update_logic() -> void:
	var old_output = output
	
	match gate_type:
		GateType.AND:
			output = inputs[0] and inputs[1]
		GateType.OR:
			output = inputs[0] or inputs[1]
		GateType.NOT:
			output = not inputs[0]
		GateType.XOR:
			output = inputs[0] != inputs[1]
			
	if old_output != output:
		output_changed.emit(output)
		_propagate_signal()

func _propagate_signal() -> void:
	if SignalManager:
		SignalManager.transmit_signal(self, output)
