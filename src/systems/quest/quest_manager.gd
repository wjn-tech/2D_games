extends Node

## QuestManager (Autoload)
## 管理任务的接受、追踪与奖励。

signal quest_accepted(quest: QuestResource)
signal quest_completed(quest: QuestResource)
signal quest_updated(quest: QuestResource)

var active_quests: Array[QuestResource] = []
var completed_quests: Array[String] = [] # 存储已完成任务的 ID

func _ready() -> void:
	if EventBus:
		EventBus.item_collected.connect(_on_item_collected)
		EventBus.enemy_killed.connect(_on_enemy_killed)
		EventBus.poi_discovered.connect(_on_poi_discovered)

func _on_item_collected(item_data: Resource, amount: int) -> void:
	if item_data is BaseItem:
		update_quest_progress(QuestResource.QuestType.FETCH, item_data.id, amount)

func _on_enemy_killed(enemy_id: String, _faction: String) -> void:
	# 优先匹配具体的 ID，如果没有则匹配阵营（可选逻辑）
	update_quest_progress(QuestResource.QuestType.KILL, enemy_id, 1)

func _on_poi_discovered(poi_name: String) -> void:
	update_quest_progress(QuestResource.QuestType.DISCOVER, poi_name, 1)

func accept_quest(quest: QuestResource) -> void:
	if quest.quest_id in completed_quests:
		return
		
	for active in active_quests:
		if active.quest_id == quest.quest_id:
			return
			
	quest.is_active = true
	active_quests.append(quest)
	quest_accepted.emit(quest)
	print("QuestManager: 接受任务: ", quest.title)

func update_quest_progress(type: QuestResource.QuestType, target_id: String, amount: int = 1) -> void:
	for quest in active_quests:
		if quest.type == type and quest.target_id == target_id:
			quest.current_amount += amount
			quest_updated.emit(quest)
			print("QuestManager: 任务进度更新: ", quest.title, " ", quest.current_amount, "/", quest.required_amount)
			
			if quest.check_completion():
				print("QuestManager: 任务目标已达成: ", quest.title)

func complete_quest(quest_id: String) -> bool:
	var found_quest: QuestResource = null
	for i in range(active_quests.size()):
		if active_quests[i].quest_id == quest_id:
			found_quest = active_quests[i]
			if found_quest.is_completed:
				active_quests.remove_at(i)
				completed_quests.append(quest_id)
				_give_rewards(found_quest)
				quest_completed.emit(found_quest)
				print("QuestManager: 任务已交付: ", found_quest.title)
				return true
			break
	return false

func _give_rewards(quest: QuestResource) -> void:
	# 发放金钱奖励
	if GameState.player_data:
		GameState.player_data.attributes["money"] = GameState.player_data.attributes.get("money", 0) + quest.reward_money
		
	# 发放物品奖励 (需接入 Inventory 系统)
	for item_id in quest.reward_items:
		var item_data = GameState.item_db.get(item_id)
		if item_data:
			GameState.inventory.add_item(item_data, 1)
	
	print("QuestManager: 已发放奖励: ", quest.reward_money, " 金币")

func is_quest_active(quest_id: String) -> bool:
	for quest in active_quests:
		if quest.quest_id == quest_id:
			return true
	return false

func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests

## 生成一个随机任务
func create_random_quest() -> QuestResource:
	var quest = QuestResource.new()
	var types = [QuestResource.QuestType.FETCH, QuestResource.QuestType.KILL, QuestResource.QuestType.DISCOVER]
	quest.type = types.pick_random()
	
	match quest.type:
		QuestResource.QuestType.FETCH:
			var items = ["wood", "stone", "iron"]
			quest.target_id = items.pick_random()
			quest.required_amount = randi_range(3, 10)
			quest.quest_id = "fetch_" + quest.target_id + "_" + str(Time.get_ticks_msec())
			quest.title = "收集" + quest.target_id
			quest.description = "我需要一些" + quest.target_id + "，你能帮我找 " + str(quest.required_amount) + " 个吗？"
		
		QuestResource.QuestType.KILL:
			quest.target_id = "Enemy" # 假设所有敌人的 ID 都是 Enemy
			quest.required_amount = randi_range(1, 3)
			quest.quest_id = "kill_enemy_" + str(Time.get_ticks_msec())
			quest.title = "消灭威胁"
			quest.description = "附近有一些危险的生物，请帮我消灭 " + str(quest.required_amount) + " 个。"
			
		QuestResource.QuestType.DISCOVER:
			quest.target_id = "营地"
			quest.required_amount = 1
			quest.quest_id = "discover_camp_" + str(Time.get_ticks_msec())
			quest.title = "探索荒野"
			quest.description = "我听说附近有一个营地，你能帮我确认它的位置吗？"
	
	quest.reward_money = randi_range(50, 200)
	return quest
