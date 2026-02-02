extends Node

## PowerGridManager (Autoload)
## 管理工业设备的电力生产与消耗。

signal power_updated(total_production: float, total_consumption: float)

# 存储发电机和用电器
var generators: Array[Node] = []
var consumers: Array[Node] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func register_generator(node: Node) -> void:
	if not node in generators:
		generators.append(node)

func register_consumer(node: Node) -> void:
	if not node in consumers:
		consumers.append(node)

func _process(_delta: float) -> void:
	# 每秒更新一次电力平衡（原型阶段可每帧更新，但建议降频）
	if Engine.get_frames_drawn() % 10 != 0: return
	
	var total_prod = 0.0
	var total_cons = 0.0
	
	# 清理无效引用并计算总产出
	var i = generators.size() - 1
	while i >= 0:
		var g = generators[i]
		if is_instance_valid(g):
			if g.has_method("get_power_output"):
				total_prod += g.get_power_output()
		else:
			generators.remove_at(i)
		i -= 1
			
	# 清理无效引用并计算总需求
	i = consumers.size() - 1
	while i >= 0:
		var c = consumers[i]
		if is_instance_valid(c):
			if c.has_method("get_power_requirement"):
				total_cons += c.get_power_requirement()
		else:
			consumers.remove_at(i)
		i -= 1
			
	# 电力分配逻辑：计算供需比
	var power_ratio = 1.0
	if total_cons > 0:
		power_ratio = clamp(total_prod / total_cons, 0.0, 1.0)
		
	# 通知所有用电器当前的供电比例
	for c in consumers:
		if is_instance_valid(c) and c.has_method("set_power_supply_ratio"):
			c.set_power_supply_ratio(power_ratio)
			
	power_updated.emit(total_prod, total_cons)
