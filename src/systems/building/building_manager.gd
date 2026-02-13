extends Node2D
class_name BuildingManager

# --- 建造系统 ---
# 处理建筑的预览、放置与资源扣除。

const TILE_SIZE = 16
const PLACEMENT_REACH = 160.0 # 玩家放置距离限制

@export var building_parent: Node2D # 建筑生成的父节点
@export var tile_map: TileMapLayer # 用于放置单块瓦片

var current_resource: Resource # 可以是 BuildingResource 或 TileItemData
var current_cost_override = null # 专门用于存放如手里拿着东西时的覆盖成本
var preview_instance: Node2D
var is_tile_mode: bool = false
var _started_this_frame: bool = false
var _last_placed_map_pos: Vector2i = Vector2i(-9999, -9999) # 用于连续摆放去重

func _ready() -> void:
	add_to_group("building_manager")
	
	# 自动查找 TileMapLayer
	if not tile_map:
		if has_node("/root/LayerManager"):
			tile_map = get_node("/root/LayerManager").get_current_layer()
		
		if not tile_map:
			tile_map = get_tree().get_first_node_in_group("world_tiles")
	
	# 自动查找建筑父节点
	if not building_parent:
		building_parent = get_tree().get_first_node_in_group("buildings_container")

func _get_tile_source_id() -> int:
	var world_gen = get_tree().get_first_node_in_group("world_generator")
	if world_gen:
		if "tile_source_id" in world_gen:
			return world_gen.tile_source_id
	return 0 # 修改默认值为 0，与现实项目一致

func _process(_delta: float) -> void:
	if preview_instance:
		# 1. 自动图层切换逻辑 (基于 TileItemData)
		if current_resource is TileItemData:
			var target_layer = current_resource.target_layer
			
			# 支持 SHIFT 键强制把方块放入背景层 (Layer 2)
			if Input.is_key_pressed(KEY_SHIFT):
				target_layer = 2
				if preview_instance:
					preview_instance.modulate = Color(0.6, 0.6, 0.6, 0.5) # 稍微变暗
			else:
				if preview_instance:
					preview_instance.modulate = current_resource.placement_tint

			if has_node("/root/LayerManager"):
				tile_map = get_node("/root/LayerManager").layer_nodes.get(target_layer)
		
		# 如果不是 TileItemData，默认使用 LayerManager 的当前图层
		if not tile_map and has_node("/root/LayerManager"):
			tile_map = get_node("/root/LayerManager").get_current_layer()

		# 2. 预览跟随鼠标并对齐网格
		var mouse_pos = get_global_mouse_position()
		
		# 获取当前建筑的格数大小 (默认 1x1)
		var gs = Vector2i(1, 1)
		if current_resource:
			if "grid_size" in current_resource:
				gs = current_resource.grid_size
			elif current_resource.get("grid_size") != null:
				gs = current_resource.get("grid_size")

		if tile_map:
			var local_pos = tile_map.to_local(mouse_pos)
			var map_pos = tile_map.local_to_map(local_pos)
			var snapped_local = tile_map.map_to_local(map_pos)
			var snapped_global = tile_map.to_global(snapped_local)
			
			if is_tile_mode:
				# 瓦片模式：Sprite2D centered=false，锚点在左上角
				preview_instance.global_position = snapped_global - Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0)
			else:
				# 场景建筑模式：假定物体 Origin 在中心
				# X 轴居中：基于当前瓦片中心，向右偏移 (W-1)/2 个瓦片宽
				var offset_x = (gs.x - 1) * TILE_SIZE / 2.0
				# Y 轴对齐：建筑底部必须对齐当前瓦片底部
				# 当前瓦片底部 = snapped_global.y + 8. 建筑中心 = 底部 - 高度/2
				var target_bottom = snapped_global.y + TILE_SIZE / 2.0
				var center_y = target_bottom - (gs.y * TILE_SIZE / 2.0)
				
				preview_instance.global_position = Vector2(snapped_global.x + offset_x, center_y)
		else:
			# Fallback if tile_map is missing
			var grid_pos = (mouse_pos / float(TILE_SIZE)).floor() * TILE_SIZE
			if not is_tile_mode:
				grid_pos += Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
				var center_offset = (Vector2(gs) - Vector2.ONE) * (TILE_SIZE / 2.0)
				grid_pos += center_offset
			preview_instance.global_position = grid_pos
		
		_update_preview_visuals()
		
		# 3. 连续摆放逻辑
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var current_map_pos = Vector2i.ZERO
			if tile_map:
				current_map_pos = tile_map.local_to_map(tile_map.to_local(preview_instance.global_position))
			
			# 如果进入了新的方块格子，或者刚点击瞬间
			# 使用鼠标状态而不是未定义的 Action "mouse_left"
			if _started_this_frame or current_map_pos != _last_placed_map_pos:
				get_viewport().set_input_as_handled()
				place_building()
				_last_placed_map_pos = current_map_pos
				_started_this_frame = false # 确保点击第一帧处理后不再重复触发 _started
				
		elif Input.is_action_just_pressed("mouse_right") and not _started_this_frame:
			get_viewport().set_input_as_handled()
			cancel_building()
		
		_started_this_frame = false

func is_building() -> bool:
	return preview_instance != null and is_instance_valid(preview_instance)

func start_building(resource: Resource, cost_override = null) -> void:
	# 如果已经在建造同一个东西且预览实例有效，则不执行任何操作，防止闪烁
	if current_resource == resource and is_instance_valid(preview_instance):
		if cost_override != null:
			current_cost_override = cost_override
		return
		
	cancel_building()
	current_cost_override = cost_override
	
	# 提升层级，确保绘制的圈在最顶层
	z_index = 3000
	
	# 处理封装在 BaseItem 中的建筑资源
	if resource.has_meta("building_resource"):
		resource = resource.get_meta("building_resource")
		
	current_resource = resource
	if not current_resource: return
	
	_started_this_frame = true
	_last_placed_map_pos = Vector2i(-9999, -9999) # 重置连续摆放缓存
	
	if current_resource is BuildingResource and "scene" in current_resource and current_resource.scene:
		is_tile_mode = false
		preview_instance = current_resource.scene.instantiate()
		# 强制设为半透明
		preview_instance.modulate = Color(1, 1, 1, 0.5) 
		# 重要修复：将预览物体的 Z 轴设为相对于父节点 (BuildingManager) 较低，
		# 这样 BuildingManager 的 _draw (3000) 实际上会绘制在预览物体之上。
		preview_instance.z_index = -1 
		preview_instance.z_as_relative = true
		preview_instance.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(preview_instance)
	elif resource is TileItemData or (resource is BuildingResource and resource.atlas_coords != Vector2i(-1, -1)):
		is_tile_mode = true
		preview_instance = Sprite2D.new()
		preview_instance.z_index = 2000 
		
		# 加载贴图
		var atlas_coords = Vector2i(-1, -1)
		var s_id = -1
		
		if resource is TileItemData:
			atlas_coords = resource.tile_atlas_coords
			s_id = resource.tile_source_id
			preview_instance.modulate = resource.placement_tint
			# 优先使用图标作为预览 fallback
			if resource.icon:
				preview_instance.texture = resource.icon
				preview_instance.scale = Vector2(TILE_SIZE / resource.icon.get_size().x, TILE_SIZE / resource.icon.get_size().y)
		else:
			atlas_coords = resource.atlas_coords
			s_id = resource.source_id if resource.source_id != -1 else _get_tile_source_id()
		
		# 尝试获取精确的 Tile 集区域贴图
		if tile_map and tile_map.tile_set:
			var source_id = s_id if s_id != -1 else _get_tile_source_id()
			var atlas_source = tile_map.tile_set.get_source(source_id)
			if atlas_source is TileSetAtlasSource:
				var atlas_tex = atlas_source.texture
				var region = atlas_source.get_tile_texture_region(atlas_coords)
				
				var atlas_tex_sub = AtlasTexture.new()
				atlas_tex_sub.atlas = atlas_tex
				atlas_tex_sub.region = region
				preview_instance.texture = atlas_tex_sub
				preview_instance.scale = Vector2(1, 1) # 重置缩放
		
		if not preview_instance.texture:
			var tex = PlaceholderTexture2D.new()
			tex.size = Vector2(TILE_SIZE, TILE_SIZE)
			preview_instance.texture = tex
			preview_instance.modulate = Color(0.5, 0.5, 0.5, 0.5)
		
		preview_instance.centered = false
		add_child(preview_instance)

func cancel_building() -> void:
	if preview_instance:
		preview_instance.queue_free()
		preview_instance = null
	
	# 重置层级，不再遮挡 UI
	z_index = 0
	
	current_resource = null
	queue_redraw()

func _update_preview_visuals() -> void:
	if not preview_instance: return
	
	if _can_place():
		preview_instance.modulate = Color(0, 1, 0, 0.5) # 绿色表示合法
	else:
		preview_instance.modulate = Color(1, 0, 0, 0.5) # 红色表示非法
	
	# 绘制领土范围预览
	queue_redraw()

func _draw() -> void:
	if not preview_instance: return
	
	var player = get_tree().get_first_node_in_group("player")
	
	# 1. 绘制建造距离限制圈 (白色，以玩家为中心)
	if player:
		var player_local = to_local(player.global_position)
		draw_arc(player_local, PLACEMENT_REACH, 0, TAU, 64, Color(1, 1, 1, 0.2), 2.0)
	
	# 2. 绘制城邦领土圈 (蓝色)
	# 这是玩家已建立的城邦中心，不会随鼠标移动
	var sm = get_node_or_null("/root/SettlementManager")
	if sm and sm.has_method("get_settlement_center") and not sm.buildings.is_empty():
		var radius = sm.stats.territory_radius
		var center = to_local(sm.get_settlement_center())
		draw_arc(center, radius, 0, TAU, 128, Color(0, 0.6, 1, 0.2), 1.5)
		
	# === 绘制预览物品的影响/选中圈 (黄色) ===
	# 确保即便 current_resource 属性暂时获取失败，也有默认 fallback 值
	var inf_radius = 160.0 
	
	if current_resource:
		if current_resource is BuildingResource:
			# 如果资源没有 define radius，给一个较大的默认值 (160)
			inf_radius = current_resource.get("influence_radius")
			if inf_radius == null or inf_radius <= 0: inf_radius = 160.0
		elif current_resource is TileItemData:
			inf_radius = 48.0 # 普通方块小一点
			
	# 计算预览实例的中心点
	# 因为我们已经在 _process 中根据 grid_size 修正了 global_position 到几何中心
	# 所以这里直接使用 global_position 即可，无需再次进行 gs 补偿
	var local_pos = to_local(preview_instance.global_position)
	
	if is_tile_mode:
		# Tile 模式的 global_position 是左上角，所以绘图中心需要往右下偏移半格
		local_pos += Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
		
	# 绘制亮色选中中心点反馈 (强制置顶渲染)
	draw_circle(local_pos, 4.0, Color(1, 1, 1, 0.8))
	# 绘制黄色影响范围圈 (跟着鼠标走)
	draw_arc(local_pos, inf_radius, 0, TAU, 64, Color(1, 1, 0, 0.45), 1.5)

func _can_place() -> bool:
	if not current_resource or not preview_instance: return false
	
	# 0. 确保 TileMap 有效
	if not tile_map:
		# 尝试即时重新获取
		if has_node("/root/LayerManager"):
			tile_map = get_node("/root/LayerManager").get_current_layer()
	
	if not tile_map:
		# print("BuildingManager: 无法放置，找不到有效图层Node")
		return false
	
	# 1. 检查距离玩家是否太远
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var dist = player.global_position.distance_to(preview_instance.global_position)
		if dist > PLACEMENT_REACH:
			return false

	# 2. 检查资源是否足够
	if not GameState or not GameState.inventory:
		return false
		
	var cost_map = {}
	if current_cost_override != null:
		cost_map = current_cost_override
	elif current_resource is BuildingResource:
		cost_map = current_resource.cost
	elif current_resource is TileItemData:
		cost_map = { current_resource.id: 1 }

	if cost_map == null: return false

	for item_id in cost_map:
		var count = GameState.inventory.get_item_count(item_id)
		if count < cost_map[item_id]:
			return false
			
	# 3. 检查地形与相邻规则
	# 修正：对于多格建筑，我们需要基于“起始格子”进行循环检测
	var mouse_map_pos = tile_map.local_to_map(tile_map.to_local(get_global_mouse_position()))
	var map_pos = mouse_map_pos
	
	# 确定实际目标层级（考虑 Shift 键）
	var actual_target_layer = 0
	if current_resource is TileItemData:
		actual_target_layer = current_resource.target_layer
		if Input.is_key_pressed(KEY_SHIFT): 
			actual_target_layer = 1
	
	# 背景墙相邻规则 (Layer 1 为主背景层)
	if actual_target_layer == 1:
		var lm = get_node_or_null("/root/LayerManager")
		if lm:
			var l0_node = lm.layer_nodes.get(0)
			var l1_node = lm.layer_nodes.get(1)
			
			var has_neighbor = false
			# 检查中心位置是否有 L0 方块 (允许墙壁放在实体地块的正后方)
			if l0_node and l0_node.get_cell_source_id(map_pos) != -1:
				has_neighbor = true
			
			if not has_neighbor:
				# 检查上下左右是否有 L1 墙或 L0 块 (允许背景墙依附于地形或已有墙面)
				for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					if l1_node and l1_node.get_cell_source_id(map_pos + offset) != -1:
						has_neighbor = true
						break
					if l0_node and l0_node.get_cell_source_id(map_pos + offset) != -1:
						has_neighbor = true
						break
			if not has_neighbor: return false

	# 3.1 检查场景建筑的多格子占用情况
	if current_resource is BuildingResource:
		var gs = current_resource.grid_size
		
		for dx in range(gs.x):
			for dy in range(gs.y):
				var check_pos = map_pos + Vector2i(dx, -dy) # 向上延展
				
				# A. 检查自身是否被占用
				if tile_map.get_cell_source_id(check_pos) != -1:
					return false
				
				# B. 如果需要平整地面，检查最底层格子的下方是否有支撑
				if current_resource.requires_flat_ground and dy == 0:
					if tile_map.get_cell_source_id(check_pos + Vector2i(0, 1)) == -1:
						return false
		
		# 3.2 检查特定的放置类型
		if current_resource.placement_type == "Wall":
			# 检查背景墙 (Layer 1)
			var lm = get_node_or_null("/root/LayerManager")
			if lm:
				var l1 = lm.layer_nodes.get(1)
				if l1 and l1.get_cell_source_id(map_pos) != -1:
					pass # 有背景墙，可以挂
				else:
					# 检查左右是否有实心方块
					var l0 = lm.layer_nodes.get(0)
					var has_side_wall = false
					for offset in [Vector2i.LEFT, Vector2i.RIGHT]:
						if l0 and l0.get_cell_source_id(map_pos + offset) != -1:
							has_side_wall = true
							break
					if not has_side_wall: return false
	
	elif is_tile_mode:
		# 修改：如果是在放置背景墙 (Layer 1)，允许覆盖 Layer 1 的位置 (即替换背景墙)
		var lm = get_node_or_null("/root/LayerManager")
		var target_map = tile_map
		if lm:
			target_map = lm.layer_nodes.get(actual_target_layer, tile_map)
		
		var s_id = current_resource.tile_source_id if current_resource is TileItemData else current_resource.source_id
		var a_coords = current_resource.tile_atlas_coords if current_resource is TileItemData else current_resource.atlas_coords

		# 如果是背景层，我们允许“替换”现有瓦片 (只要不是同一个)
		if actual_target_layer == 1:
			if target_map.get_cell_source_id(map_pos) == s_id and target_map.get_cell_atlas_coords(map_pos) == a_coords:
				return false
			return true 
		else:
			# 前景层 (Layer 0)：仍然禁止在非空位放置
			if target_map.get_cell_source_id(map_pos) != -1:
				return false
			
	# 4. 检查城邦领土限制
	if current_resource is BuildingResource and (current_resource.category == "Production" or current_resource.category == "Housing"):
		var sm = get_node_or_null("/root/SettlementManager")
		if sm:
			if sm.buildings.is_empty(): return true
			var center = sm.get_settlement_center()
			var dist = preview_instance.global_position.distance_to(center)
			if dist > sm.stats.territory_radius:
				return false
				
	return true

func place_building() -> void:
	if not _can_place():
		return
		
	if is_tile_mode:
		# 确保层级即时匹配（支持放置瞬间的 Shift 状态）
		var target_layer = 0
		if current_resource is TileItemData:
			target_layer = current_resource.target_layer
			if Input.is_key_pressed(KEY_SHIFT): target_layer = 1 # 统一背景层为 Layer 1
		
		var actual_map = tile_map
		if has_node("/root/LayerManager"):
			var lm_map = get_node("/root/LayerManager").layer_nodes.get(target_layer)
			if lm_map: actual_map = lm_map

		if actual_map:
			var local_pos = actual_map.to_local(preview_instance.global_position)
			var map_pos = actual_map.local_to_map(local_pos)
			
			var s_id = -1
			var a_coords = Vector2i.ZERO
			var cost_map = {}

			if current_cost_override != null:
				cost_map = current_cost_override
			elif current_resource is TileItemData:
				s_id = current_resource.tile_source_id
				a_coords = current_resource.tile_atlas_coords
				cost_map = { current_resource.id: 1 }
			else:
				s_id = current_resource.source_id if current_resource.source_id != -1 else _get_tile_source_id()
				a_coords = current_resource.atlas_coords
				cost_map = current_resource.cost
			
			# 执行放置
			actual_map.set_cell(map_pos, s_id, a_coords)
			if actual_map is TileMapLayer:
				actual_map.update_internals()
			
			# 记录 Delta (InfiniteChunkManager)
			if get_node_or_null("/root/InfiniteChunkManager"):
				get_node("/root/InfiniteChunkManager").record_delta(preview_instance.global_position, target_layer, s_id, a_coords)
			
			# 扣除资源
			for item_id in cost_map:
				GameState.inventory.remove_item_by_id(item_id, cost_map[item_id])
	else:
		# 场景建筑逻辑
		if not current_resource or not ("scene" in current_resource) or not current_resource.scene:
			print("BuildingManager: Error - 无法放置建筑，场景资源为空")
			return

		# 先捕获必要的资源引用
		var scene_to_instantiate = current_resource.scene
		var resource_data = current_resource
		var cost_map = current_resource.cost
		if current_cost_override != null:
			cost_map = current_cost_override
			
		var spawn_pos = preview_instance.global_position
		
		# 1. 扣除资源 (可能会触发 player.gd 的信号)
		for item_id in cost_map:
			GameState.inventory.remove_item_by_id(item_id, cost_map[item_id])
		
		# 2. 实例化建筑 (使用局部变量，即便 current_resource 在上一步被杀掉也能继续)
		var new_building = scene_to_instantiate.instantiate()
		if building_parent:
			building_parent.add_child(new_building)
		else:
			get_tree().current_scene.add_child(new_building)
			
		new_building.global_position = spawn_pos
		
		if new_building.has_method("setup"):
			new_building.setup(resource_data)
		
		# 3. 注册到城邦系统
		if get_node_or_null("/root/SettlementManager"):
			get_node("/root/SettlementManager").register_building(new_building, resource_data)
	
	print("建筑已放置")
