extends StaticBody2D
class_name LootChest

@export var loot_table: Array[String] = [
	"res://data/items/wood.tres",
	"res://data/items/stone.tres",
	"res://data/items/dirt.tres",
	"res://data/items/iron.tres",
	"res://data/items/pickaxe.tres"
]
@export var min_items: int = 1
@export var max_items: int = 3

var is_opened: bool = false

func _ready() -> void:
	add_to_group("interactable")

func load_custom_data(data: Dictionary) -> void:
	if data.has("size"):
		var size = data["size"] # Vector2i(match_w, match_h)
		# 如果是由蓝图生成的装饰性宝箱，隐藏原始精灵图
		var v = get_node_or_null("MinimalistEntity")
		if not v: v = get_node_or_null("Sprite2D") # Fallback
		if v: v.visible = false
		
		# 调整碰撞区域以覆盖对应的瓦片区域 (宽度 match_w * 16, 高度 match_h * 16)
		if has_node("CollisionShape2D"):
			var shape = $CollisionShape2D.shape
			if shape is RectangleShape2D:
				var px_w = size.x * 16
				var px_h = size.y * 16
				shape.size = Vector2(px_w, px_h)
				# 蓝图传入的坐标是底部瓦片的左上角，我们将形状中心移到区域中心
				# X: 宽度的一半, Y: 高度的一半（负值向上）
				$CollisionShape2D.position = Vector2(px_w / 2.0, -px_h / 2.0)

func interact() -> void:
	if is_opened: return
	
	is_opened = true
	
	var visual = get_node_or_null("MinimalistEntity")
	if visual:
		# Open visual state (e.g. darker or alpha change)
		if "color" in visual: visual.color = visual.color.darkened(0.5)
		if visual.has_method("queue_redraw"): visual.queue_redraw()
	elif has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.5, 0.5, 0.5) 
		
	_spawn_loot()
	print("Chest: 宝箱已打开！")

func _spawn_loot() -> void:
	var count = randi_range(min_items, max_items)
	var loot_scene = preload("res://scenes/world/loot_item.tscn")
	
	for i in range(count):
		var item_path = loot_table.pick_random()
		var item_res = load(item_path)
		if item_res:
			var loot = loot_scene.instantiate()
			get_parent().add_child(loot)
			# 在宝箱位置稍微偏移生成
			loot.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
			loot.setup(item_res)
