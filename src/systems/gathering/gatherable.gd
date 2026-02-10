extends Area2D
class_name Gatherable

@export var item_data: BaseItem
@export var amount_min: int = 1
@export var amount_max: int = 3
@export var loot_scene: PackedScene = preload("res://scenes/world/loot_item.tscn")
@export var respawn_time: float = 60.0 # 60 秒后再生

var is_gathered: bool = false
var _respawn_timer: float = 0.0

func _ready() -> void:
	# 确保碰撞层正确（Bit 4 为交互层）
	collision_layer = LayerManager.LAYER_INTERACTION
	collision_mask = 0 # 仅被玩家检测

func _process(delta: float) -> void:
	if is_gathered:
		_respawn_timer -= delta
		if _respawn_timer <= 0:
			_respawn()

func _respawn() -> void:
	is_gathered = false
	visible = true
	# 开启交互
	set_deferred("monitorable", true)
	print("资源点已再生: ", item_data.display_name if item_data else "未知物品")

func interact(_interactor: Node = null) -> void:
	if is_gathered:
		return
		
	var amount = randi_range(amount_min, amount_max)
	
	# 城邦加成：如果附近有工坊等建筑，采集量增加
	if SettlementManager:
		var bonus = SettlementManager.get_efficiency_bonus(global_position)
		if bonus > 0:
			var bonus_amount = int(amount * bonus)
			amount += bonus_amount
			print("城邦加成效果！额外获得: ", bonus_amount)
	
	is_gathered = true
	_respawn_timer = respawn_time
	
	print("采集了: ", item_data.display_name, " x", amount)
	
	# 生成物理掉落物，而不是直接塞进背包
	if loot_scene:
		var loot = loot_scene.instantiate()
		# 挂载到 Entities 节点或场景根节点
		var entities = get_tree().current_scene.find_child("Entities", true, false)
		if entities:
			entities.add_child(loot)
		else:
			get_parent().add_child(loot)
			
		loot.global_position = global_position
		if loot.has_method("setup"):
			loot.setup(item_data, amount)
		else:
			loot.item_data = item_data
			loot.amount = amount
	else:
		# 退化方案：如果没配置掉落物场景，直接发放
		EventBus.item_collected.emit(item_data, amount)
	
	# 简单的视觉反馈：隐藏并暂时禁用监视
	visible = false
	set_deferred("monitorable", false)
	
	# 可以在这里播放音效或粒子效果
	# queue_free() # 或者直接销毁
