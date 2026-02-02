extends Area2D
class_name CraftingStation

## CraftingStation
## 制造设施基类（如铁砧、炼丹炉）。

@export var station_id: String = "anvil"
@export var station_name: String = "铁砧"
# 该设施支持的配方分类
@export var supported_categories: Array[String] = ["weapon", "armor"]

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("crafting_stations")

## 被玩家交互时调用
func interact() -> void:
	# 打开制造界面
	var window = UIManager.open_window("Crafting", "res://scenes/ui/CraftingWindow.tscn")
	if window and window.has_method("setup"):
		window.setup(self)
	print("使用设施: ", station_name)
