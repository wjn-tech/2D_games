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
@export var layer_dim_color: Color = Color(0.7, 0.7, 0.7, 0.6) # 修改：提高可见度 (0.4 -> 0.6) 并略微调暗但不透明

var layer_nodes: Dictionary = {} # { index: Node }

func _ready() -> void:
	# 初始同步世界层级状态
	call_deferred("switch_to_layer", 0)

func reset() -> void:
	print("LayerManager: Resetting layer cache...")
	layer_nodes.clear()
	active_layer = 0

func register_layer(index: int, node: Node) -> void:
	if not is_instance_valid(node):
		return
		
	# 清理旧节点的组和标记
	if layer_nodes.has(index):
		var old_node = layer_nodes[index]
		if is_instance_valid(old_node) and old_node != node:
			old_node.remove_from_group("map_layers")
	
	layer_nodes[index] = node
	node.set_meta("layer_index", index)
	node.add_to_group("map_layers")
	
	# 同步当前活跃状态的视觉效果
	var idx = index
	var is_active = (idx == active_layer)
	if node is CanvasItem:
		node.modulate = Color.WHITE if is_active else layer_dim_color
		node.z_index = (active_layer - idx) * 20
	
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

func get_current_layer() -> Node:
	if not layer_nodes.has(active_layer):
		return null
		
	var node = layer_nodes[active_layer]
	# 核心安全巡查：排除已彻底删减或标记删除的对象，防止 Caller 端的类型转换崩溃
	if is_instance_valid(node) and not node.is_queued_for_deletion():
		return node
		
	# 自动修复无效引用
	layer_nodes.erase(active_layer)
	return null

func get_layer(index: int) -> Node:
	if not layer_nodes.has(index):
		return null
		
	var node = layer_nodes[index]
	if is_instance_valid(node) and not node.is_queued_for_deletion():
		return node
		
	layer_nodes.erase(index)
	return null

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
			# 如果是背景层 (Layer 1/2)，在活跃层为 Layer 0 时，保持一定可见度
			if not is_active and idx > 0 and active_layer == 0:
				layer.modulate = Color(0.8, 0.8, 0.8, 0.7)
			else:
				layer.modulate = Color.WHITE if is_active else layer_dim_color
		
		# Z-Index 渲染排序
		# 核心逻辑：背景图层 (idx > 0) 必须使用负的 Z-Index 确保在角色后方
		# 前景图层 (idx = 0) 使用 0 或正值
		if layer is CanvasItem:
			if idx == 0:
				layer.z_index = 0 if is_active else -5
			else:
				# idx 为 1, 2... 的层作为背景，Z-Index 为负
				layer.z_index = -idx * 50 + (0 if is_active else -10)
				
	# 仅更新玩家及其视野内的实体
	var player = tree.get_first_node_in_group("player")
	if player:
		player.z_index = 10 # 确保玩家始终在背景墙 (-10, -50等) 和当前地块 (0) 之上
		_update_entity_collision(player, layer_index)

func _update_entity_collision(entity: Node2D, layer_index: int) -> void:
	var world_bit = get_world_bit(layer_index)
	
	# 设置实体的图层（它是被撞体，例如 NPC 被玩家撞）
	if entity.is_in_group("player"):
		entity.collision_layer = LAYER_PLAYER
	elif entity.is_in_group("npcs"):
		entity.collision_layer = LAYER_NPC
	
	# 设置实体的遮罩（它是主动撞击体，例如 撞地表）
	# 实体现在的 Mask 包含：当前地表层位 + 交互层 + 角色/NPC 层
	var mask = world_bit | LAYER_INTERACTION
	if entity.is_in_group("player"):
		mask |= LAYER_NPC # 玩家能撞 NPC
	elif entity.is_in_group("npcs"):
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
