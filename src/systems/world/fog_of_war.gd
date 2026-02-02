extends TileMapLayer
class_name FogOfWar

signal poi_discovered(poi_name: String)

@export var fog_enabled: bool = true
@export var reveal_radius: int = 8
@onready var player = get_tree().get_first_node_in_group("player")

var discovered_pois: Array = []

func _ready():
	if not fog_enabled:
		visible = false
		return
		
	# 填充整个地图为迷雾
	var world_gen = get_tree().get_first_node_in_group("world_generator")
	if world_gen:
		# 稍微扩大一点范围确保覆盖
		for x in range(-10, world_gen.world_width + 10):
			for y in range(-10, world_gen.world_height + 10):
				set_cell(Vector2i(x, y), 0, Vector2i(0, 0)) 

func _process(_delta):
	if not fog_enabled:
		return
		
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	var pos = local_to_map(to_local(player.global_position))
	_reveal_area(pos)

func _reveal_area(center: Vector2i):
	for x in range(center.x - reveal_radius, center.x + reveal_radius + 1):
		for y in range(center.y - reveal_radius, center.y + reveal_radius + 1):
			var dist = Vector2(x, y).distance_to(Vector2(center))
			if dist <= reveal_radius:
				if get_cell_source_id(Vector2i(x, y)) != -1:
					erase_cell(Vector2i(x, y))
					_check_poi_discovery(Vector2i(x, y))

func _check_poi_discovery(pos: Vector2i):
	# 检查该位置是否有 POI
	# 这里可以与 WorldGenerator 的 POI 列表对比
	var world_gen = get_tree().get_first_node_in_group("world_generator")
	if world_gen and world_gen.has_method("get_poi_at"):
		var poi = world_gen.get_poi_at(pos)
		if poi != "" and not poi in discovered_pois:
			discovered_pois.append(poi)
			poi_discovered.emit(poi)
			if EventBus:
				EventBus.poi_discovered.emit(poi)
			print("发现新地点: ", poi)
