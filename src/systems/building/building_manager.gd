extends Node2D
class_name BuildingManager

# --- 建造系统 ---
# 处理建筑的预览、放置与资源扣除。

const TILE_SIZE = 16

@export var building_parent: Node2D # 建筑生成的父节点
@export var tile_map: TileMapLayer # 用于放置单块瓦片

var current_resource: BuildingResource
var preview_instance: Node2D
var is_tile_mode: bool = false

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
	if world_gen and "tile_source_id" in world_gen:
		return world_gen.tile_source_id
	return 1 # 默认值

func _process(_delta: float) -> void:
	if preview_instance:
		# 每次处理前重新获取当前活跃图层，确保预览在正确的层
		if has_node("/root/LayerManager"):
			tile_map = get_node("/root/LayerManager").get_current_layer()

		# 预览跟随鼠标并对齐网格
		var mouse_pos = get_global_mouse_position()
		
		if tile_map:
			var local_pos = tile_map.to_local(mouse_pos)
			var map_pos = tile_map.local_to_map(local_pos)
			var snapped_local = tile_map.map_to_local(map_pos)
			var snapped_global = tile_map.to_global(snapped_local)
			
			if is_tile_mode:
				# 瓦片模式：Sprite2D centered=false，所以需要偏移到左上角
				preview_instance.global_position = snapped_global - Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0)
			else:
				# 场景模式：通常中心对齐
				preview_instance.global_position = snapped_global
		else:
			# 兜底方案
			var grid_pos = (mouse_pos / float(TILE_SIZE)).floor() * TILE_SIZE
			if not is_tile_mode:
				grid_pos += Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
			preview_instance.global_position = grid_pos
		
		# 实时验证并更新视觉反馈
		_update_preview_visuals()
		
		# 左键放置，右键取消
		if Input.is_action_just_pressed("mouse_left"):
			# 标记本帧已处理建造，防止挖掘逻辑触发
			get_viewport().set_input_as_handled()
			place_building()
		elif Input.is_action_just_pressed("mouse_right"):
			get_viewport().set_input_as_handled()
			cancel_building()

func is_building() -> bool:
	return preview_instance != null and is_instance_valid(preview_instance)

func start_building(resource: BuildingResource) -> void:
	cancel_building()
	current_resource = resource
	
	if resource.scene:
		is_tile_mode = false
		preview_instance = resource.scene.instantiate()
		preview_instance.modulate = Color(1, 1, 1, 0.5) # 半透明预览
		# 禁用预览实例的脚本处理，防止其产生副作用
		preview_instance.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(preview_instance)
	elif resource.atlas_coords != Vector2i(-1, -1):
		is_tile_mode = true
		# 创建一个简单的预览节点
		preview_instance = Sprite2D.new()
		
		# 尝试从 TileSet 获取贴图
		if tile_map and tile_map.tile_set:
			var source_id = resource.source_id if resource.source_id != -1 else _get_tile_source_id()
			var atlas_source = tile_map.tile_set.get_source(source_id)
			if atlas_source is TileSetAtlasSource:
				var atlas_tex = atlas_source.texture
				var region = atlas_source.get_tile_texture_region(resource.atlas_coords)
				
				var atlas_tex_sub = AtlasTexture.new()
				atlas_tex_sub.atlas = atlas_tex
				atlas_tex_sub.region = region
				preview_instance.texture = atlas_tex_sub
		
		if not preview_instance.texture:
			# 兜底：如果没找到贴图，使用半透明色块
			var tex = PlaceholderTexture2D.new()
			tex.size = Vector2(TILE_SIZE, TILE_SIZE)
			preview_instance.texture = tex
			preview_instance.modulate = Color(0.5, 0.3, 0.1, 0.5) # 褐色代表土
			if resource.id == "stone_tile":
				preview_instance.modulate = Color(0.5, 0.5, 0.5, 0.5) # 灰色代表石
		
		preview_instance.centered = false # 瓦片模式左上角对齐
		preview_instance.modulate.a = 0.5
		add_child(preview_instance)

func cancel_building() -> void:
	if preview_instance:
		preview_instance.queue_free()
		preview_instance = null
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
	if preview_instance and get_node_or_null("/root/SettlementManager"):
		var sm = get_node("/root/SettlementManager")
		var player = get_tree().get_first_node_in_group("player")
		
		# 绘制当前城邦的领土范围
		var radius = sm.stats.territory_radius
		var center = to_local(sm.get_settlement_center())
		
		draw_arc(center, radius, 0, TAU, 64, Color(0, 0.5, 1, 0.3), 2.0)
		
		# 绘制新建筑的影响范围
		if current_resource:
			var local_pos = to_local(preview_instance.global_position)
			draw_arc(local_pos, current_resource.influence_radius, 0, TAU, 32, Color(1, 1, 0, 0.3), 1.0)
			
		# 绘制建造范围（玩家周围 150 像素）
		if player:
			var player_local = to_local(player.global_position)
			draw_arc(player_local, 150, 0, TAU, 64, Color(1, 1, 1, 0.1), 1.0)

func _can_place() -> bool:
	if not current_resource: return false
	
	# 0. 确保 TileMap 有效
	if not tile_map:
		if has_node("/root/LayerManager"):
			tile_map = get_node("/root/LayerManager").get_current_layer()
		if not tile_map:
			print("BuildingManager: 找不到 TileMapLayer")
			return false
	
	# 1. 检查资源是否足够
	for item_id in current_resource.cost:
		var count = GameState.inventory.get_item_count(item_id)
		if count < current_resource.cost[item_id]:
			# print("BuildingManager: 资源不足: ", item_id, " 需要 ", current_resource.cost[item_id], " 持有 ", count)
			return false
			
	# 2. 检查地形要求
	var map_pos = tile_map.local_to_map(tile_map.to_local(preview_instance.global_position))
	if current_resource.requires_flat_ground:
		# 检查下方是否有实体瓦片
		if tile_map.get_cell_source_id(map_pos + Vector2i(0, 1)) == -1:
			return false
		# 检查当前位置是否已被占用
		if tile_map.get_cell_source_id(map_pos) != -1:
			return false
	elif is_tile_mode:
		# 瓦片模式下，不能在已有瓦片的位置放置
		if tile_map.get_cell_source_id(map_pos) != -1:
			return false
			
	# 3. 检查领土限制
	if current_resource.category == "Production" or current_resource.category == "Housing":
		var sm = get_node_or_null("/root/SettlementManager")
		if sm:
			# 如果还没有任何建筑，允许放置第一个建筑（只要在玩家范围内）
			if sm.buildings.is_empty():
				return true
				
			# 检查是否在现有领土内
			var center = sm.get_settlement_center()
			var dist = preview_instance.global_position.distance_to(center)
			if dist > sm.stats.territory_radius:
				return false
				
	# 4. 检查距离玩家是否太远
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.global_position.distance_to(preview_instance.global_position) > 150:
			return false
				
	return true

func place_building() -> void:
	# 每次放置前重新获取当前活跃图层，确保在正确的层建造
	if has_node("/root/LayerManager"):
		tile_map = get_node("/root/LayerManager").get_current_layer()

	if not _can_place():
		# print("无法放置建筑: 资源不足、位置无效或距离太远")
		return
		
	if is_tile_mode:
		if tile_map:
			var local_pos = tile_map.to_local(preview_instance.global_position)
			var map_pos = tile_map.local_to_map(local_pos)
			
			# 检查该位置是否已有方块
			if tile_map.get_cell_source_id(map_pos) == -1:
				# 使用动态获取的 source_id
				var source_id = current_resource.source_id if current_resource.source_id != -1 else _get_tile_source_id()
				tile_map.set_cell(map_pos, source_id, current_resource.atlas_coords)
				
				# 扣除资源
				for item_id in current_resource.cost:
					GameState.inventory.remove_item(item_id, current_resource.cost[item_id])
				print("方块已放置于 ", map_pos, ": ", current_resource.display_name)
			else:
				print("该位置已有方块: ", map_pos)
	else:
		# 扣除资源
		for item_id in current_resource.cost:
			GameState.inventory.remove_item(item_id, current_resource.cost[item_id])
			
		var new_building = current_resource.scene.instantiate()
		if building_parent:
			building_parent.add_child(new_building)
		else:
			get_tree().current_scene.add_child(new_building)
			
		new_building.global_position = preview_instance.global_position
		
		if new_building.has_method("setup"):
			new_building.setup(current_resource)
		
		# 注册到城邦系统
		if get_node_or_null("/root/SettlementManager"):
			get_node("/root/SettlementManager").register_building(new_building, current_resource)
	
	print("建筑已放置: ", current_resource.display_name)
	# 放置后不自动取消，方便连续建造
