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

var creation_time: float = 0.0
var merge_timer: float = randf_range(0.0, 1.0) # Staggered merge checks
const MAX_GLOBAL_LOOT = 200

func setup(data: BaseItem, qty: int = 1, delay: float = 0.8) -> void:
	item_data = data
	amount = qty
	pickup_delay = delay
	_update_visuals()
	
	# Initial toss velocity - Increased to throw further
	velocity = Vector2(randf_range(-250, 250), -400)

func _ready() -> void:
	add_to_group("loot")
	add_to_group("pickups")
	creation_time = Time.get_ticks_msec() / 1000.0
	
	_check_global_limit()
	
	_update_visuals()

func _check_global_limit():
	var loot_items = get_tree().get_nodes_in_group("loot")
	if loot_items.size() > MAX_GLOBAL_LOOT:
		# Sort by creation time to remove oldest
		loot_items.sort_custom(func(a, b): return a.creation_time < b.creation_time)
		
		# Remove excess items (remove multiple to quickly get under limit)
		var to_remove = loot_items.size() - MAX_GLOBAL_LOOT
		for i in range(to_remove):
			var item = loot_items[i]
			if is_instance_valid(item) and item != self:
				item.queue_free()

func _update_visuals():
	if not sprite: 
		sprite = get_node_or_null("Sprite2D")
	if not sprite: return
	
	if item_data:
		# 优先使用 icon 属性
		if item_data.get("icon"):
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

func _try_merge():
	if is_collecting or pickup_delay > 0: return
	
	var others = get_tree().get_nodes_in_group("loot")
	var merge_radius = 80.0 # Increased from 48.0
	
	for other in others:
		if other == self or not is_instance_valid(other): continue
		if other.is_collecting: continue
		
		# Check distance
		if global_position.distance_to(other.global_position) < merge_radius:
			# Check compatibility
			# IMPORTANT: Use resource path comparison for reliability
			var my_id = item_data.resource_path if item_data else ""
			var other_id = other.item_data.resource_path if other.item_data else ""
			
			if my_id == other_id and my_id != "":
				# Decide who stays: the one with more or the older one
				if other.amount >= self.amount or other.creation_time < self.creation_time:
					# Merge into 'other'
					other.amount += self.amount
					# If other has been quiet, reset its merge timer to trigger cascade
					other.merge_timer = 0.1 
					queue_free()
					return
				else:
					# Merge 'other' into me
					self.amount += other.amount
					other.queue_free()
					# Don't break, see if we can merge with more in this cycle
					# but use a small yield or just break to prevent deep recursions
					break 

func _physics_process(delta: float) -> void:
	if pickup_delay > 0:
		pickup_delay -= delta
		
	merge_timer -= delta
	if merge_timer <= 0:
		merge_timer = 1.0 + randf_range(-0.2, 0.2)
		_try_merge()

	if is_collecting: return

	# 1. Player Attraction Check
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player")
	
	var being_attracted = false
	if target_player:
		var dist = global_position.distance_to(target_player.global_position)
		# Greatly increased attraction range for better pickup feel and cleaning
		var effective_range = attraction_range
		if is_in_group("loot"): effective_range = 250.0 
		
		if dist < effective_range and pickup_delay <= 0:
			being_attracted = true
			var dir = (target_player.global_position - global_position).normalized()
			# Magnet-like attraction - faster as it gets closer
			var pull_speed = move_speed * (1.0 + (1.0 - dist/effective_range) * 2.0)
			velocity = velocity.move_toward(dir * pull_speed, 3000 * delta)
			
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
		elif inv and inv.has_method("add_item"):
			if inv.add_item(item_data, amount):
				remaining = 0
				EventBus.item_collected.emit(item_data, amount)
			else:
				remaining = amount # Full inventory
		else:
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

# --- Persistence
func get_save_data() -> Dictionary:
	return {
		'file': scene_file_path,
		'pos': global_position,
		'amount': amount,
		'item_res': item_data.resource_path if item_data else ''
	}
