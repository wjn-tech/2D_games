extends Resource
class_name WorldChunk

## WorldChunk
## 存储单个区块 (64x64) 的数据及其玩家修改 (Delta)。

@export var coord: Vector2i
# 存储三层图层的瓦片 Delta: { layer_idx: { local_pos: { "source": int, "atlas": Vector2i } } }
@export var deltas: Dictionary = {
	0: {},
	1: {},
	2: {}
}

# 存储区块内的实体数据 (机器、容器等): [ { "scene_path": string, "pos": Vector2, "data": dict } ]
@export var entities: Array = []

# 标记该区块是否已被玩家探索/发现
@export var is_discovered: bool = false

func add_delta(layer: int, local_pos: Vector2i, source_id: int, atlas_coords: Vector2i = Vector2i.ZERO) -> void:
	if not deltas.has(layer):
		deltas[layer] = {}
	deltas[layer][local_pos] = { "source": source_id, "atlas": atlas_coords }

func get_delta(layer: int, local_pos: Vector2i) -> Variant:
	return deltas.get(layer, {}).get(local_pos, null) # null 表示无 Delta
