extends CharacterBody2D

## LootItem
## 掉落物实体，支持自动吸附飞向玩家，并具有重力物理。

@export var item_data: BaseItem
@export var amount: int = 1
@export var attraction_range: float = 80.0
@export var move_speed: float = 600.0

@onready var sprite = $Sprite2D

var target_player: CharacterBody2D = null
var is_collecting: bool = false
var pickup_delay: float = 0.8

# Physics
var fall_gravity: float = 980.0

func setup(data: BaseItem, qty: int = 1, delay: float = 0.8) -> void:
	item_data = data
	amount = qty
	pickup_delay = delay
	_update_visuals()
	
	# Initial toss velocity - Increased to throw further
	velocity = Vector2(randf_range(-250, 250), -400)

func _ready() -> void:
	add_to_group("loot")
	
	# CharacterBody2D doesn't use body_entered directly for its main collision.
	# We'll use a child Area2D for easier pickup detection if needed, 
	# or just check player proximity in _physics_process.
	
	_update_visuals()

func _update_visuals():
	if not sprite: 
		sprite = get_node_or_null("Sprite2D")
	if not sprite: return
	
	if item_data:
		# 优先使用 icon 属性
		if item_data.icon:
			sprite.texture = item_data.icon
		# 如果没有 icon 但有 building_resource 元数据，从资源中获取图标
		elif item_data.has_meta("building_resource"):
			var res = item_data.get_meta("building_resource")
			if res and res.icon:
				sprite.texture = res.icon
		
		if sprite.texture:
			sprite.scale = Vector2(1, 1)
			sprite.modulate = Color.WHITE
			return

	# 回退方案
	sprite.texture = preload("res://icon.svg")
	sprite.modulate = Color.GOLD

func _physics_process(delta: float) -> void:
	if pickup_delay > 0:
		pickup_delay -= delta

	if is_collecting: return

	# 1. Player Attraction Check
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player")
	
	var being_attracted = false
	if target_player:
		var dist = global_position.distance_to(target_player.global_position)
		if dist < attraction_range and pickup_delay <= 0:
			being_attracted = true
			var dir = (target_player.global_position - global_position).normalized()
			# 磁铁般吸附
			velocity = velocity.move_toward(dir * move_speed, 2000 * delta)
			
			if dist < 30.0:
				_collect()
	
	# 2. Gravity & Contextual Physics
	if being_attracted:
		# 被吸引时：禁用重力，穿透墙壁
		collision_mask = 0 
		global_position += velocity * delta
	else:
		# 未被吸引时：受重力影响，受地形阻挡
		if not is_on_floor() or velocity.y < 0:
			velocity.y += fall_gravity * delta
		
		# 地面摩擦力
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, 500 * delta)
			if abs(velocity.x) < 10: velocity.x = 0
			
		collision_mask = 1 
		move_and_slide()

func _collect() -> void:
	if is_collecting: return
	is_collecting = true

	var remaining = amount

	# 优先通过 InventoryManager 直接添加，以处理背包满逻辑
	if target_player and (target_player.has_method("get_inventory") or "inventory" in target_player):
		var inv = target_player.inventory
		if inv and inv.has_method("add_item_partial"):
			remaining = inv.add_item_partial(item_data, amount)
		else:
			# Fallback to general event
			EventBus.item_collected.emit(item_data, amount)
			remaining = 0
	else:
		EventBus.item_collected.emit(item_data, amount)
		remaining = 0

	if remaining <= 0:
		# 成功全部拾取
		if UIManager:
			UIManager.show_floating_text("+" + str(amount) + " " + item_data.display_name, global_position)
		queue_free()
	else:
		# 背包满了，只拾取了部分或没拾取
		var picked = amount - remaining
		if picked > 0 and UIManager:
			UIManager.show_floating_text("+" + str(picked) + " " + item_data.display_name, global_position)
		
		amount = remaining
		is_collecting = false
		pickup_delay = 1.0 # 1秒后再尝试吸取
		
		# 满容视觉反馈 (轻微缩放)
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
