extends Node
class_name EnvironmentalSensor

## EnvironmentalSensor
## 用于感知外部环境 (时间、天气、地形、邻居) 并同步到 AI 黑板。

@onready var npc = get_parent()
@onready var bt_player = npc.get_node_or_null("BTPlayer")

func _ready() -> void:
	# 每隔一秒进行一次环境感知，避免每帧执行
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_tick)
	add_child(timer)

func _on_tick() -> void:
	if not bt_player or not bt_player.blackboard: return
	var bb = bt_player.blackboard
	
	# 1. 同步时间与天气
	var chron = get_node_or_null("/root/Chronometer")
	if chron:
		bb.set_var("hour", chron.current_hour)
		bb.set_var("is_night", chron.current_hour >= 20 or chron.current_hour < 6)
	
	var weather_mgr = get_node_or_null("/root/WeatherManager")
	if weather_mgr:
		bb.set_var("weather", weather_mgr.current_weather)

	# 2. 感知生物环境与地形 (Biome)
	var world_gen = get_tree().get_first_node_in_group("world_generator")
	if world_gen and world_gen.has_method("get_biome_at"):
		var biome = world_gen.get_biome_at(int(npc.global_position.x), int(npc.global_position.y))
		bb.set_var("biome", biome)
	
	# 3. 感知附近 NPC (用于社交逻辑)
	var neighbors = []
	var alignment = npc.npc_data.alignment if npc.npc_data else "Neutral"
	for other in get_tree().get_nodes_in_group("npcs"):
		if other == npc: continue
		var dist = npc.global_position.distance_to(other.global_position)
		if dist < 200: # 社交/感知半径
			neighbors.append(other)
	
	bb.set_var("neighbors_count", neighbors.size())
	bb.set_var("nearest_neighbor", neighbors[0] if neighbors.size() > 0 else null)
	
	# 3. 性格与情绪状态
	if npc.npc_data:
		bb.set_var("happiness", npc.npc_data.happiness)
		bb.set_var("is_settled", npc.npc_data.is_settled)
