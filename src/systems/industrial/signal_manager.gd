extends Node

## SignalManager (Autoload)
## 处理工业、逻辑电路的信号传递。

# 信号连接: { "source_node_id": [target_node, target_input_id] }
var connections: Dictionary = {}

func connect_nodes(source: Node, target: Node, input_id: int = 0) -> void:
	var sid = source.get_instance_id()
	if not connections.has(sid):
		connections[sid] = []
	connections[sid].append([target, input_id])
	
	# 如果 source 有当前状态，立即同步
	if "output" in source:
		transmit_signal(source, source.output)

func transmit_signal(source: Node, value: bool) -> void:
	var sid = source.get_instance_id()
	if not connections.has(sid): return
	
	for connection in connections[sid]:
		var target = connection[0]
		var input_id = connection[1]
		if is_instance_valid(target) and target.has_method("receive_signal"):
			target.receive_signal(input_id, value)
