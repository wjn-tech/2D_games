extends Node

# --- 全局游戏状态管理 ---
# 建议在 Godot 编辑器中将其设置为 Autoload (名称: GameState)

var current_time: float = 0.0
var player_data: CharacterData = CharacterData.new()

var item_db: Dictionary = {}
var recipe_db: Dictionary = {}

@onready var inventory: Node = _create_inventory_manager()
@onready var digging: Node = _create_digging_manager()

func _ready() -> void:
	_load_databases()

func _load_databases() -> void:
	# 加载物品数据库
	var item_dir = DirAccess.open("res://data/items/")
	if item_dir:
		item_dir.list_dir_begin()
		var file_name = item_dir.get_next()
		while file_name != "":
			if not item_dir.current_is_dir() and file_name.ends_with(".tres"):
				var item = load("res://data/items/" + file_name)
				if item is BaseItem:
					item_db[item.id] = item
			file_name = item_dir.get_next()
	
	# 加载配方数据库
	var recipe_dir = DirAccess.open("res://data/recipes/")
	if recipe_dir:
		recipe_dir.list_dir_begin()
		var file_name = recipe_dir.get_next()
		while file_name != "":
			if not recipe_dir.current_is_dir() and file_name.ends_with(".tres"):
				var recipe = load("res://data/recipes/" + file_name)
				if recipe is CraftingRecipe:
					recipe_db[file_name.get_basename()] = recipe
			file_name = recipe_dir.get_next()
	
	print("GameState: 已加载 ", item_db.size(), " 个物品和 ", recipe_db.size(), " 个配方")

func _create_inventory_manager() -> Node:
	var mgr = load("res://src/systems/crafting/inventory_manager.gd").new()
	mgr.name = "InventoryManager"
	add_child(mgr)
	return mgr

func _create_digging_manager() -> Node:
	var mgr = load("res://src/systems/world/digging_manager.gd").new()
	mgr.name = "DiggingManager"
	add_child(mgr)
	return mgr

func _process(delta: float) -> void:
	current_time += delta
	
	# 植物生长与生态逻辑
	_handle_ecology(delta)

	# 每隔一段时间发出时间流逝信号
	if Engine.get_frames_drawn() % 60 == 0:
		EventBus.time_passed.emit(current_time)

func _handle_ecology(delta: float) -> void:
	# 简单的植物生长逻辑：随机在 TileMap 上生成资源
	if randf() < 0.01 * delta: # 极低概率
		if digging and digging.tile_map:
			# 随机找个位置生成植物
			pass

func _on_player_death() -> void:
	print("GameState: 玩家寿命耗尽！")
	if GameManager:
		GameManager.change_state(GameManager.State.REINCARNATING)

## 重置背包（用于转生时清空或继承处理）
func reset_inventory() -> void:
	if inventory:
		inventory.slots.clear()
		inventory.inventory_changed.emit()
