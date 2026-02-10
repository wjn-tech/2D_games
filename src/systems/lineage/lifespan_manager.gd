extends Node

## LifespanManager (Autoload)
## 负责管理角色的寿命流逝，包括自然衰老和高强度动作导致的加速消耗。

signal lifespan_depleted(character_data: CharacterData)

# 游戏内一天的秒数
# 根据需求：一昼夜 (24h) = 10分钟 (600s)
@export var seconds_per_day: float = 600.0 
# 每年多少天 (应与 Chronometer.DAYS_PER_YEAR 一致)
@export var days_per_year: int = 30

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 也可以连接 Chronometer 信号来保持绝对同步
	if Chronometer:
		Chronometer.day_passed.connect(_on_calendar_day_passed)

func _process(delta: float) -> void:
	if not GameState.player_data: return
	if Chronometer and Chronometer.is_paused: return
	
	# 这里依然保留 _process 以支持平滑增长和可能的加速消耗逻辑
	# 1秒经过的人生比例 = (1/seconds_per_day) 天 = 1/(seconds_per_day * days_per_year) 年
	var years_passed = delta / (seconds_per_day * days_per_year)
	
	# 注意：如果 Chronometer 有 time_scale，这里也应该乘上
	if Chronometer:
		years_passed *= Chronometer.time_scale
		
	consume_lifespan(GameState.player_data, years_passed)
	
	# 子嗣成长逻辑 (delegated to LineageManager for tracking active descendants)
	if LineageManager:
		LineageManager.process_growth(delta)

func _on_calendar_day_passed(day: int, year: int) -> void:
	# 仅用于日志或触发每日结算
	print("LifespanManager: 历法更新, 第 %d 天, 当前玩家年龄: %.2f" % [day, GameState.player_data.current_age])

## 消耗寿命
func consume_lifespan(data: CharacterData, amount_years: float) -> void:
	if data.life_span <= 0: return
	
	data.life_span -= amount_years
	data.current_age += amount_years
	
	if data.life_span <= 0:
		data.life_span = 0
		lifespan_depleted.emit(data)
		# 触发全局死亡事件
		if data == GameState.player_data:
			_on_player_death()

func _drop_player_loot() -> void:
	if not GameState.inventory: return
	
	# Pack inventory similar to SaveManager
	var inv_data = SaveManager._pack_inventory()
	
	# Spawn Loot Bag
	var loot_script = load("res://src/systems/inventory/loot_container.gd")
	if loot_script:
		var loot = Node2D.new() # Ideally instantiate scene
		loot.set_script(loot_script)
		loot.name = "DeathLoot"
		
		var player = GameState.get_tree().get_first_node_in_group("player")
		if player:
			loot.global_position = player.global_position
			GameState.get_tree().current_scene.call_deferred("add_child", loot)
			loot.call_deferred("set_loot", inv_data)
			
			# Clear current inventory
			if GameState.inventory.has_method("clear_all"):
				GameState.inventory.clear_all()
			else:
				# Fallback if clear_all not available
				for i in range(GameState.inventory.backpack.slots.size()):
					GameState.inventory.backpack.slots[i] = { "item": null, "count": 0 }
				for i in range(GameState.inventory.hotbar.slots.size()):
					GameState.inventory.hotbar.slots[i] = { "item": null, "count": 0 }

## 环境触发的意外死亡（如掉落虚空、极寒天气）
func trigger_instant_death(data: CharacterData, reason: String = "意外") -> void:
	print("LifespanManager: 角色死亡原因: ", reason)
	data.life_span = 0
	lifespan_depleted.emit(data)
	if data == GameState.player_data:
		_on_player_death()

func _on_player_death() -> void:
	# 记录死亡时的位置，作为转生失败后的保底坐标
	var player = get_tree().get_first_node_in_group("player")
	if player:
		GameState.set_meta("last_player_pos", player.global_position)
	
	_drop_player_loot()
	if EventBus and EventBus.has_signal("player_health_changed"):
		EventBus.player_health_changed.emit(0, GameState.player_data.max_health)
	GameManager.change_state(GameManager.State.REINCARNATING)

## 高强度动作导致的额外消耗（加速老化）
func record_action_strain(data: CharacterData, strain_days: float = 1.0) -> void:
	# 将天数转换为年数
	var amount_years = strain_days / days_per_year
	consume_lifespan(data, amount_years)
