extends Node

## LayerManager (Autoload)
## 处理多层地图的切换与视觉反馈。

const LAYER_WORLD_0 = 1 # Bit 0
const LAYER_WORLD_1 = 2 # Bit 1
const LAYER_WORLD_2 = 4 # Bit 2
const LAYER_WORLD_3 = 64 # Bit 6
const LAYER_WORLD_4 = 128 # Bit 7

const LAYER_INTERACTION = 8 # Bit 3
const LAYER_PLAYER = 16 # Bit 4
const LAYER_NPC = 32 # Bit 5

@export var active_layer: int = 0
@export var layer_dim_color: Color = Color(1.0, 1.0, 1.0, 0.4) # 修改：不再使用暗色，而是使用透明度

var layer_nodes: Dictionary = {} # { index: Node }

func register_layer(index: int, node: Node) -> void:
	# 清理旧节点的组和标记（如果存在）
	if layer_nodes.has(index) and is_instance_valid(layer_nodes[index]):
		layer_nodes[index].remove_from_group("map_layers")
	
	layer_nodes[index] = node
	node.set_meta("layer_index", index)
	node.add_to_group("map_layers")
	
	# 物理隔离核心逻辑：
	# 为每个图层唯一化 TileSet 并设置其碰撞层位
	if node is TileMapLayer:
		if node.tile_set:
			# 复制一份 TileSet 资源以实现独立配置
			node.tile_set = node.tile_set.duplicate()
			var world_bit = get_world_bit(index)
			
			# 设置该图层瓦片的物理所属层（Bit X）
			# 第 0 个物理层（通常是默认添加的那个）
			if node.tile_set.get_physics_layers_count() > 0:
				node.tile_set.set_physics_layer_collision_layer(0, world_bit)
				node.tile_set.set_physics_layer_collision_mask(0, 0) # 瓦片本身不主动撞物体
				print("LayerManager: 图层 %d 物理隔离已就绪 (Bit:%d)" % [index, world_bit])

func get_world_bit(index: int) -> int:
	if index < 3:
		return 1 << index
	return 1 << (index + 3)

func get_current_layer() -> TileMapLayer:
	return layer_nodes.get(active_layer) as TileMapLayer

func get_layer(index: int) -> Node:
	return layer_nodes.get(index)

func switch_to_layer(layer_index: int) -> void:
	active_layer = layer_index
	print("LayerManager: 切换主视角到图层: ", layer_index)
	
	var tree = get_tree()
	var layers = tree.get_nodes_in_group("map_layers")
	for layer in layers:
		var idx = layer.get_meta("layer_index", -1)
		var is_active = (idx == active_layer)
		
		# 视觉反馈：非活跃层半透明
		if layer.has_method("set_modulate"):
			layer.modulate = Color.WHITE if is_active else layer_dim_color
		
		# Z-Index 渲染排序
		if layer is CanvasItem:
			layer.z_index = (active_layer - idx) * 20
				
	# 仅更新玩家及其视野内的实体
	var player = tree.get_first_node_in_group("player")
	if player:
		_update_entity_collision(player, layer_index)

func _update_entity_collision(entity: Node2D, layer_index: int) -> void:
	var world_bit = get_world_bit(layer_index)
	
	# 设置实体的图层（它是被撞体，例如 NPC 被玩家撞）
	if entity.is_in_group("player"):
		entity.collision_layer = LAYER_PLAYER
	elif entity.is_in_group("npc"):
		entity.collision_layer = LAYER_NPC
	
	# 设置实体的遮罩（它是主动撞击体，例如 撞地表）
	# 实体现在的 Mask 包含：当前地表层位 + 交互层 + 角色/NPC 层
	var mask = world_bit | LAYER_INTERACTION
	if entity.is_in_group("player"):
		mask |= LAYER_NPC # 玩家能撞 NPC
	else:
		mask |= LAYER_PLAYER # NPC 能撞玩家
		
	entity.collision_mask = mask
	
	# 发出信号
	if entity.is_in_group("player"):
		EventBus.player_layer_changed.emit(layer_index)
	
	# 同步元数据
	entity.set_meta("current_layer", layer_index)

func move_entity_to_layer(entity: Node2D, new_index: int) -> void:
	# 用于 NPC 或 玩家实际发生位面移动时调用
	_update_entity_collision(entity, new_index)
