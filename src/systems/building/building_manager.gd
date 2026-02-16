extends Node2D
class_name BuildingManager

# --- 建造系统 ---
# 处理建筑的预览、放置与资源扣除。

const TILE_SIZE = 16
const PLACEMENT_REACH = 160.0 # 玩家放置距离限制

# 使用可变变量存储，并在 _ready 或使用时按需加载，避免 Preload 路径解析失败
var building_base_scene: PackedScene

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
	
	# 动态加载基础场景，处理路径不存在的情况
	building_base_scene = load("res://scenes/world/Building.tscn")
	if not building_base_scene:
		print("BuildingManager Warning: res://scenes/world/Building.tscn not found, checking alternatives...")
	
	# 自动查找 TileMapLayer
	_refresh_tile_map()
	
	# 自动查找建筑父节点
	if not building_parent:
		building_parent = get_tree().get_first_node_in_group("buildings_container")

func _refresh_tile_map() -> void:
	if has_node("/root/LayerManager"):
		var lm = get_node("/root/LayerManager")
		if is_instance_valid(lm):
			tile_map = lm.get_current_layer()
	
	if not tile_map:
		tile_map = get_tree().get_first_node_in_group("world_tiles")
		
	# 最后的保底：尝试从 WorldGenerator 获取图层0
	if not tile_map:
		var wg = get_tree().get_first_node_in_group("world_generator")
		if wg and wg.has_node("Layer0"):
			tile_map = wg.get_node("Layer0")

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
			var local_pos = TransformHelper.safe_to_local(tile_map, mouse_pos)
			var map_pos = tile_map.local_to_map(local_pos)
			var snapped_local = tile_map.map_to_local(map_pos)
			var snapped_global = tile_map.to_global(snapped_local)
			
			# UNIFIED GRID SNAPPING
			var tile_top_left = snapped_global - Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0)
			
			if is_tile_mode:
				# 瓦片模式：锚点在左上角
				preview_instance.global_position = tile_top_left
			else:
				# 场景建筑模式：基于底边对齐的多格摆放逻辑
				# 以当前鼠标指向的瓦片作为底格的左侧锚点
				var bottom_y = tile_top_left.y + TILE_SIZE
				var top_y = bottom_y - (gs.y * TILE_SIZE)
				
				var final_pos = Vector2(tile_top_left.x, top_y)
				
				# 应用资源定义的垂直微调
				if current_resource is BuildingResource:
					final_pos.y += current_resource.vertical_pixel_offset
				
				preview_instance.global_position = final_pos
				
				# 家具朝向逻辑 (由于锚点在左上角，水平翻转会导致位置偏移)
				# 如果家具需要带朝向，建议场景内部有一个 Pivot 节点处理翻转，或者在这里补偿偏移
				if current_resource is BuildingResource and current_resource.should_face_player:
					var player = get_tree().get_first_node_in_group("player")
					if player:
						# 这里使用玩家的当前视向 (通常可以通过 mouse_pos 判断)
						var p_face_left = (get_global_mouse_position().x < player.global_position.x)
						var target_scale_x = -1.0 if p_face_left else 1.0
						
						# 如果比例发生变化，且又是向左翻转，需要平移以保持在格子里
						# 假设场景是以 (0,0) 为左上角，翻转会导致它渲染到 (-W, 0) 区域
						preview_instance.scale.x = target_scale_x
						if target_scale_x < 0:
							preview_instance.global_position.x += gs.x * TILE_SIZE
						# Standard sprite faces Right. Left is Scale X -1.
						# Check player face direction or calculate from mouse.
						
						# Logic: If preview is Left of Player, Player faces Left. Chair faces Left (Scale -1).
						# If preview is Right of Player, Player faces Right. Chair faces Right (Scale 1).
						if final_pos.x < player.global_position.x:
							preview_instance.scale.x = -1
						else:
							preview_instance.scale.x = 1
				else:
					preview_instance.scale.x = 1 # Reset
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
				current_map_pos = tile_map.local_to_map(TransformHelper.safe_to_local(tile_map, preview_instance.global_position))
			
			# 如果进入了新的方块格子，或者刚点击瞬间
			# 使用鼠标状态而不是未定义的 Action "mouse_left"
			if _started_this_frame or current_map_pos != _last_placed_map_pos:
				get_viewport().set_input_as_handled()
				place_building()
				
				# 关键修复：放置后通知玩家脚本进入冷却，防止瞬间挖掉
				var player = get_tree().get_first_node_in_group("player")
				if player and "action_cooldown" in player:
					player.action_cooldown = 0.3 # 0.3秒安全期
				
				_last_placed_map_pos = current_map_pos
				_started_this_frame = false # 确保点击第一帧处理后不再重复触发 _started
				
		elif Input.is_action_just_pressed("mouse_right") and not _started_this_frame:
			get_viewport().set_input_as_handled()
			cancel_building()
		
		_started_this_frame = false

func is_building() -> bool:
	return preview_instance != null and is_instance_valid(preview_instance)

func start_building(resource: Resource, cost_override = null) -> void:
	_refresh_tile_map()
	
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
	
	# NEW UNIFIED LOGIC: Treat multi-tile Atlas builds as "Building" mode but using Tiles
	var is_atlas_building = (current_resource is BuildingResource and current_resource.atlas_coords != Vector2i(-1, -1))
	
	if current_resource is BuildingResource and "scene" in current_resource and current_resource.scene:
		is_tile_mode = false
		preview_instance = current_resource.scene.instantiate()
		# 强制设为半透明
		preview_instance.modulate = Color(1, 1, 1, 0.5) 
		preview_instance.z_index = -1 
		preview_instance.z_as_relative = true
		preview_instance.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(preview_instance)
	elif resource is TileItemData or is_atlas_building:
		is_tile_mode = true
		preview_instance = Sprite2D.new()
		preview_instance.z_index = 2000 
		
		# 加载贴图参数
		var atlas_coords = Vector2i(-1, -1)
		var s_id = -1
		var gs = Vector2i(1, 1)
		
		if resource is TileItemData:
			atlas_coords = resource.tile_atlas_coords
			s_id = resource.tile_source_id
			preview_instance.modulate = resource.placement_tint
		else:
			atlas_coords = resource.atlas_coords
			s_id = resource.source_id if resource.source_id != -1 else _get_tile_source_id()
			
			# IMPORTANT: Use .grid_size directly if possible, or get() as fallback
			if "grid_size" in resource:
				gs = resource.grid_size
			elif resource.has_method("get"):
				var res_gs = resource.get("grid_size")
				if res_gs != null: gs = res_gs
			
			# Multi-tile tile preview adjustment
			if gs.x > 1 or gs.y > 1:
				is_tile_mode = false # Switch to building-style snap logic but using sprites
		
		# 尝试获取区域贴图 (优先使用自定义家具贴图集)
		var texture_set = false
		
		var custom_tex = load("res://assets/world/custom_furniture.png")
		if custom_tex and resource.get("id") and ("workbench" in resource.id or resource.id in ["door", "table", "chair", "torch"]):
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = custom_tex
			var region = Rect2(0,0,0,0)
			match resource.id:
				"workbench", "workbench_item": region = Rect2(0, 0, 32, 16)
				"door": region = Rect2(0, 16, 16, 32)
				"table": region = Rect2(16, 16, 32, 32)
				"chair": region = Rect2(48, 16, 16, 32)
				"torch": region = Rect2(64, 16, 16, 16)
			
			if region.size != Vector2.ZERO:
				atlas_tex.region = region
				preview_instance.texture = atlas_tex
				preview_instance.scale = Vector2(1,1)
				texture_set = true
				
				# 修复：确保预览图正确可见，不受层级或透明度影响
				preview_instance.modulate = Color(1, 1, 1, 0.5) 
		
		# Fallback to TileSet
		if not texture_set and tile_map and tile_map.tile_set:
			var source_id = s_id if s_id != -1 else _get_tile_source_id()
			var atlas_source = tile_map.tile_set.get_source(source_id)
			if atlas_source is TileSetAtlasSource:
				var atlas_tex = atlas_source.texture
				var region = atlas_source.get_tile_texture_region(atlas_coords)
				
				# For multi-tile atlas builds, we want to show the full region
				# Ensure we use the gs from resource
				region.size = Vector2i(gs.x * TILE_SIZE, gs.y * TILE_SIZE)
				
				var atlas_tex_sub = AtlasTexture.new()
				atlas_tex_sub.atlas = atlas_tex
				atlas_tex_sub.region = region
				preview_instance.texture = atlas_tex_sub
				preview_instance.scale = Vector2(1, 1) # 重置缩放
				texture_set = true
		
		# Fallback to Icon if tile fetch failed
		if not texture_set and resource.get("icon"):
			preview_instance.texture = resource.icon
			preview_instance.scale = Vector2((gs.x * TILE_SIZE) / resource.icon.get_size().x, (gs.y * TILE_SIZE) / resource.icon.get_size().y)
			texture_set = true

		if not texture_set:
			var tex = PlaceholderTexture2D.new()
			tex.size = Vector2(gs.x * TILE_SIZE, gs.y * TILE_SIZE)
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
		var player_local = TransformHelper.safe_to_local(self, player.global_position)
		draw_arc(player_local, PLACEMENT_REACH, 0, TAU, 64, Color(1, 1, 1, 0.2), 2.0)
	
	# 2. 绘制城邦领土圈 (蓝色)
	# 这是玩家已建立的城邦中心，不会随鼠标移动
	var sm = get_node_or_null("/root/SettlementManager")
	if sm and sm.has_method("get_settlement_center") and not sm.buildings.is_empty():
		var radius = sm.stats.territory_radius
		var center = TransformHelper.safe_to_local(self, sm.get_settlement_center())
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
	var local_pos = TransformHelper.safe_to_local(self, preview_instance.global_position)
	
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
	var mouse_map_pos = tile_map.local_to_map(TransformHelper.safe_to_local(tile_map, get_global_mouse_position()))
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
		
	if is_tile_mode and not (current_resource is BuildingResource and current_resource.atlas_coords != Vector2i(-1, -1)):
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
			var local_pos = TransformHelper.safe_to_local(actual_map, preview_instance.global_position)
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
		# 场景建筑逻辑 或 多格瓦片建筑逻辑
		var resource_data = current_resource
		if not resource_data: return
		
		var cost_map = resource_data.cost
		if current_cost_override != null:
			cost_map = current_cost_override
			
		var spawn_pos = preview_instance.global_position
		
		# 修正：只有在没有提供 scene 且提供了 atlas_coords 时，才使用通用瓦片建筑逻辑
		var has_scene = ("scene" in resource_data and resource_data.scene != null)
		var is_atlas_build = (resource_data is BuildingResource and resource_data.atlas_coords != Vector2i(-1, -1) and not has_scene)
		
		# 1. 扣除资源
		for item_id in cost_map:
			GameState.inventory.remove_item_by_id(item_id, cost_map[item_id])
		
		# 2. 实例化建筑
		var new_building: Node2D
		
		if is_atlas_build:
			var gs = resource_data.grid_size
			# 使用统用的 Building.tscn 承载瓦片视觉与逻辑
			if not building_base_scene:
				building_base_scene = load("res://scenes/world/Building.tscn")
				
			if building_base_scene:
				new_building = building_base_scene.instantiate()
				# 确保 Z-Index 合适，并强制显示在上方
				new_building.visible = true
				if tile_map:
					# 提高 Z 轴深度，确保高于地块和大多数实体
					new_building.z_index = tile_map.z_index + 10
				else:
					new_building.z_index = 100 
				new_building.z_as_relative = true
				
				# 强制刷新物理层
				if tile_map:
					var layer_idx = tile_map.get_meta("layer_index", 0)
					var bit_val = 1 << layer_idx
					# 家具属于物理地表层 bit_val，同时属于交互层 (8)
					new_building.collision_layer = bit_val | 8
					new_building.collision_mask = 0 # 静态物体不主动碰撞
				else:
					new_building.collision_layer = 1 | 8
					
			else:
				# 致命错误：如果场景加载失败，手动创建一个，防止隐身
				new_building = StaticBody2D.new()
				new_building.set_script(load("res://src/systems/building/building_node.gd"))
				new_building.collision_layer = 1 | 8
				new_building.z_index = 100

			if not building_parent:
				building_parent = get_tree().get_first_node_in_group("buildings_container")
				if not building_parent:
					building_parent = get_tree().current_scene

			building_parent.add_child(new_building)
			new_building.global_position = spawn_pos
			new_building.modulate = Color.WHITE
			
			# 设置瓦片贴图
			var sprite = new_building.get_node_or_null("Sprite2D")
			if not sprite:
				sprite = Sprite2D.new()
				sprite.name = "Sprite2D"
				new_building.add_child(sprite)
				
			if sprite:
				sprite.position = Vector2.ZERO
				sprite.scale = Vector2(1, 1)
				sprite.centered = false
				sprite.visible = true
				sprite.modulate = Color.WHITE
				
				var tex_found = false
				
				# 1. 优先尝试自定义家具贴图集 (确保放置后视觉一致)
				var custom_path = "res://assets/world/custom_furniture.png"
				if FileAccess.file_exists(custom_path):
					var custom_tex = load(custom_path)
					if custom_tex and resource_data.id:
						var region = Rect2(0,0,0,0)
						match resource_data.id:
							"workbench", "workbench_item": region = Rect2(0, 0, 32, 16)
							"door": region = Rect2(0, 16, 16, 32)
							"table": region = Rect2(16, 16, 32, 32)
							"chair": region = Rect2(48, 16, 16, 32)
							"torch": region = Rect2(64, 16, 16, 16)
						
						if region.size != Vector2.ZERO:
							var atlas_tex = AtlasTexture.new()
							atlas_tex.atlas = custom_tex
							atlas_tex.region = region
							sprite.texture = atlas_tex
							tex_found = true

				# 2. 如果不是自定义家具，尝试从 TileSet 获取
				if not tex_found and tile_map and tile_map.tile_set:
					var s_id = resource_data.source_id if resource_data.source_id != -1 else _get_tile_source_id()
					var atlas_source = tile_map.tile_set.get_source(s_id)
					if atlas_source is TileSetAtlasSource:
						var region = atlas_source.get_tile_texture_region(resource_data.atlas_coords)
						var rect = Rect2(Vector2(region.position), Vector2(gs.x * TILE_SIZE, gs.y * TILE_SIZE))
						
						var atlas_tex = AtlasTexture.new()
						atlas_tex.atlas = atlas_source.texture
						atlas_tex.region = rect
						sprite.texture = atlas_tex
						tex_found = true
				
				if not tex_found and resource_data.icon:
					sprite.texture = resource_data.icon
					sprite.centered = true
					sprite.position = Vector2(gs.x * TILE_SIZE / 2.0, gs.y * TILE_SIZE / 2.0)
				elif not tex_found:
					# 纯色块，确保“能看见”
					var placeholder = PlaceholderTexture2D.new()
					placeholder.size = Vector2(gs.x * TILE_SIZE, gs.y * TILE_SIZE)
					sprite.texture = placeholder
					sprite.modulate = Color(1, 0, 1, 0.8) # 亮粉色

			# 设置物理碰撞 (关键修复)
			var collider = new_building.get_node_or_null("CollisionShape2D")
			if not collider:
				collider = CollisionShape2D.new()
				collider.name = "CollisionShape2D"
				new_building.add_child(collider)
				
			if collider:
				var rect_shape = RectangleShape2D.new()
				rect_shape.size = Vector2(gs.x * TILE_SIZE, gs.y * TILE_SIZE)
				collider.shape = rect_shape
				collider.position = Vector2(gs.x * TILE_SIZE / 2.0, gs.y * TILE_SIZE / 2.0)
				collider.disabled = false
				
		else:
			if not resource_data.scene: return
			new_building = resource_data.scene.instantiate()
			
			# 确保 Z-Index 与地图匹配，并处理碰撞层
			if tile_map:
				new_building.z_index = tile_map.z_index + 5
				if new_building is StaticBody2D:
					var layer_idx = tile_map.get_meta("layer_index", 0)
					new_building.collision_layer |= (1 << layer_idx)
					# 门这种互动物体还需要额外的交互层 Bit 3 (Value 8)
					new_building.collision_layer |= 8
			else:
				new_building.z_index = 5
				
			if building_parent:
				building_parent.add_child(new_building)
			else:
				get_tree().current_scene.add_child(new_building)
			new_building.global_position = spawn_pos
			
			# 强制为场景建筑应用自定义贴图 (如果适用)
			var scene_sprite = new_building.get_node_or_null("Sprite2D")
			if scene_sprite and resource_data.id:
				var custom_path = "res://assets/world/custom_furniture.png"
				if FileAccess.file_exists(custom_path):
					var custom_tex = load(custom_path)
					var region = Rect2(0,0,0,0)
					match resource_data.id:
						"workbench", "workbench_item": region = Rect2(0, 0, 32, 16)
						"door": region = Rect2(0, 16, 16, 32)
						"torch": region = Rect2(64, 16, 16, 16)
					if region.size != Vector2.ZERO:
						var atlas_tex = AtlasTexture.new()
						atlas_tex.atlas = custom_tex
						atlas_tex.region = region
						scene_sprite.texture = atlas_tex
						scene_sprite.centered = false
		
		# Apply Direction/Scale from preview
		if preview_instance:
			new_building.scale = preview_instance.scale
			if preview_instance.scale.x < 0:
				# 补偿翻转偏移
				pass 
		
		if new_building.has_method("setup"):
			new_building.setup(resource_data)
		
		# 3. 注册到城邦系统
		if get_node_or_null("/root/SettlementManager"):
			get_node("/root/SettlementManager").register_building(new_building, resource_data)
	
	print("建筑已放置")
