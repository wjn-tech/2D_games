extends ItemData
class_name TileItemData

## TileItemData
## 用于定义可以作为 TileMap 瓦片摆放在图层上的物品

@export_group("Placement Properties")
## 目标图层 (0: 世界实体, 2: 背景墙)
@export var target_layer: int = 0
## 在 TileSet 中的坐标
@export var tile_atlas_coords: Vector2i = Vector2i(0, 0)
## 瓦片源 ID (通常为 0)
@export var tile_source_id: int = 0

## 是否需要相邻物块才能摆放 (背景墙通常需要)
@export var requires_neighbors: bool = false
## 摆放时的视觉调制颜色
@export var placement_tint: Color = Color(1, 1, 1, 0.5)

func _init() -> void:
	stackable = true
	max_stack = 99
	item_type = "Tile"
	tile_source_id = 0
