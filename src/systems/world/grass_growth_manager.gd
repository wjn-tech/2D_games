extends Node
class_name GrassGrowthManager

## GrassGrowthManager
## 处理泥土方块向草方块的自动转化。

@export var check_interval: float = 2.0 # 每2秒检查一次
@export var tiles_per_check: int = 10 # 每次检查随机选取的瓦片数量

var world_gen: WorldGenerator
var timer: float = 0.0

func _ready() -> void:
	world_gen = get_tree().get_first_node_in_group("world_generator")
	if not world_gen:
		push_warning("GrassGrowthManager: 未找到 WorldGenerator，脚本将失效。")

func _process(delta: float) -> void:
	if not world_gen: return
	
	timer += delta
	if timer >= check_interval:
		timer = 0.0
		_check_grass_growth()

func _check_grass_growth() -> void:
	var layer0 = world_gen.layer_0
	if not layer0: return
	
	for i in range(tiles_per_check):
		# 随机选取一个坐标
		var rx = randi_range(0, world_gen.world_width - 1)
		var ry = randi_range(0, world_gen.world_height - 1)
		var coords = Vector2i(rx, ry)
		
		# 检查是否是泥土
		var source_id = layer0.get_cell_source_id(coords)
		var atlas_coords = layer0.get_cell_atlas_coords(coords)
		
		if source_id == world_gen.tile_source_id and atlas_coords == world_gen.dirt_tile:
			# 检查上方是否是空气 (或者透明瓦片)
			var above_coords = coords + Vector2i(0, -1)
			if layer0.get_cell_source_id(above_coords) == -1:
				# 暴露在地表，转化为草方块
				layer0.set_cell(coords, world_gen.grass_dirt_source_id, world_gen.grass_tile)
				# print("GrassGrowthManager: 泥土已转化为草方块 @ ", coords)
