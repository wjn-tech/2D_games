extends Node

## MinimapManager (Autoload)
## 负责维护小地图的像素缓冲、战争迷雾以及坐标标记。

signal minimap_updated
signal chunk_explored(chunk_coord: Vector2i)

const MAP_RESOLUTION = 8 # 8x8 瓦片对应 1 像素
const CHUNK_SIZE = 64 # 与 InfiniteChunkManager 保持一致
const PIXELS_PER_CHUNK = CHUNK_SIZE / MAP_RESOLUTION # 每个区块在小地图上占 8x8 像素

# 存储小地图地形颜色的 Image
var map_image: Image
var map_texture: ImageTexture

# 存储战争迷雾的 Image (L8 格式)
var fog_image: Image
var fog_texture: ImageTexture

# 地形颜色映射（Atlas 坐标 -> 颜色）
var color_palette: Dictionary = {
	Vector2i(0, 0): Color.SADDLE_BROWN, # Dirt
	Vector2i(1, 0): Color.DARK_GREEN,   # Grass
	Vector2i(2, 0): Color.GRAY,         # Stone
	Vector2i(2, 1): Color.OLIVE_DRAB,   # Alt Grass / Surface
	Vector2i(1, 3): Color.DARK_SLATE_GRAY, # HardRock
	Vector2i(0, 4): Color.DIM_GRAY,     # Iron
	Vector2i(1, 4): Color.ORANGE,       # Copper
	Vector2i(4, 4): Color.GOLD,         # Gold
	Vector2i(5, 4): Color.AQUA,         # Diamond
	Vector2i(2, 4): Color.VIOLET,       # Magic Crystal
	Vector2i(3, 4): Color.DARK_RED,     # Staff Core
	Vector2i(0, 5): Color.CYAN,         # Speed Stone
	Vector2i(1, 2): Color.SADDLE_BROWN, # Wood/Trunk
}

# 记录已探索的区域矩形 (以像素为单位)
var explored_rect: Rect2i = Rect2i(0, 0, 0, 0)

func _ready() -> void:
	# 初始化一个合理大小的图像 (e.g. 2048x1024 像素覆盖 1.6w x 8k 像素世界)
	# 在无限世界中，我们可能需要根据动态扩展或使用偏移
	_init_images(1024, 512)

func _init_images(w: int, h: int) -> void:
	map_image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	map_image.fill(Color(0, 0, 0, 0))
	map_texture = ImageTexture.create_from_image(map_image)
	
	fog_image = Image.create(w, h, false, Image.FORMAT_L8)
	fog_image.fill(Color.BLACK) # 黑色代表未探索
	fog_texture = ImageTexture.create_from_image(fog_image)

## 重置小地图数据 (用于重新开始游戏)
func reset_map() -> void:
	if map_image:
		map_image.fill(Color(0, 0, 0, 0))
		map_texture.update(map_image)
	if fog_image:
		fog_image.fill(Color.BLACK)
		fog_texture.update(fog_image)
	print("MinimapManager: Map data reset.")

## 将世界坐标映射到小地图像素坐标
func world_to_map_pixel(world_pos: Vector2) -> Vector2i:
	var tile_pos = Vector2i((world_pos / 16.0).floor())
	var pixel_pos = tile_pos / MAP_RESOLUTION
	# 加上中心偏移（假设 0,0 在图像中心）
	return pixel_pos + Vector2i(map_image.get_width() / 2, map_image.get_height() / 2)

## 更新特定位置的地形颜色
func update_tile(world_pos: Vector2, atlas_coords: Vector2i) -> void:
	var pixel_pos = world_to_map_pixel(world_pos)
	if _is_pixel_valid(pixel_pos):
		# 从调色盘获取颜色，如果找不到则使用深灰色作为兜底（防止地图出现孔洞）
		var color = color_palette.get(atlas_coords, Color(0.2, 0.2, 0.2))
		map_image.set_pixelv(pixel_pos, color)

## 揭开战争迷雾
func reveal_area(world_pos: Vector2, radius_tiles: int) -> void:
	var center = world_to_map_pixel(world_pos)
	var radius_pix = maxi(1, radius_tiles / MAP_RESOLUTION)
	
	var changed = false
	for x in range(center.x - radius_pix, center.x + radius_pix + 1):
		for y in range(center.y - radius_pix, center.y + radius_pix + 1):
			var p = Vector2i(x, y)
			if _is_pixel_valid(p):
				if fog_image.get_pixelv(p).r < 1.0:
					fog_image.set_pixelv(p, Color.WHITE)
					changed = true
	
	if changed:
		fog_texture.update(fog_image)
		minimap_updated.emit()

## 更新或清除特定位置的瓦片
func update_tile_at_pos(world_pos: Vector2, source_id: int, atlas_coords: Vector2i) -> void:
	var pixel_pos = world_to_map_pixel(world_pos)
	if not _is_pixel_valid(pixel_pos): return
	
	if source_id == -1:
		map_image.set_pixelv(pixel_pos, Color(0, 0, 0, 0))
	else:
		var color = color_palette.get(atlas_coords, Color(0.2, 0.2, 0.2))
		map_image.set_pixelv(pixel_pos, color)
	
	map_texture.update(map_image)

func _is_pixel_valid(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < map_image.get_width() and p.y >= 0 and p.y < map_image.get_height()

func _get_cell_info(chunk: WorldChunk, cells: Dictionary, layer: int, pos: Vector2i) -> Dictionary:
	var source = -1
	var atlas = Vector2i(-1, -1)
	
	var delta = chunk.get_delta(layer, pos)
	if delta != null and delta is Dictionary:
		source = delta.get("source", -1)
		atlas = delta.get("atlas", Vector2i(-1, -1))
	elif cells.has(layer) and cells[layer] is Dictionary and cells[layer].has(pos):
		var data = cells[layer][pos]
		if data is Dictionary:
			source = data.get("source", -1)
			atlas = data.get("atlas", Vector2i(-1, -1))
	
	return {"source": source, "atlas": atlas}

## 批量更新区块数据 (由 InfiniteChunkManager 触发)
func update_from_chunk(chunk_coord: Vector2i, cells: Dictionary, chunk: WorldChunk) -> void:
	var origin_tile = chunk_coord * CHUNK_SIZE
	
	# 我们主要关注 Layer 0 (地表/核心地形) 和 Layer 1 (背景/墙壁)
	for local_x in range(0, CHUNK_SIZE, MAP_RESOLUTION):
		for local_y in range(0, CHUNK_SIZE, MAP_RESOLUTION):
			var local_pos = Vector2i(local_x, local_y)
			var world_tile = origin_tile + local_pos
			
			var final_atlas = Vector2i(-1, -1)
			
			# 1. 检查 Layer 0 (前景)
			var info0 = _get_cell_info(chunk, cells, 0, local_pos)
			if info0.source != -1:
				final_atlas = info0.atlas
			else:
				# 2. 检查 Layer 1 (背景)
				var info1 = _get_cell_info(chunk, cells, 1, local_pos)
				if info1.source != -1:
					final_atlas = info1.atlas
			
			if final_atlas != Vector2i(-1, -1):
				update_tile((Vector2(world_tile) * 16.0) + Vector2(8, 8), final_atlas)
			else:
				# 空气/无瓦片位置，根据需要可以清空像素（防止挖掉方块后地图不更新）
				var pixel_pos = world_to_map_pixel((Vector2(world_tile) * 16.0) + Vector2(8, 8))
				if _is_pixel_valid(pixel_pos):
					map_image.set_pixelv(pixel_pos, Color(0, 0, 0, 0))
	
	map_texture.update(map_image)

func get_map_texture() -> Texture2D:
	return map_texture

func get_fog_texture() -> Texture2D:
	return fog_texture
