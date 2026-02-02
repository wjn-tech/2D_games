extends Resource
class_name BaseItem

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var stackable: bool = true
@export var max_stack: int = 99
@export var value: int = 10

# 弹药/装备属性
@export var item_type: String = "General" # General, Weapon, Ammo, Consumable
@export var ammo_type: String = "" # 如果是武器，需要的弹药 ID；如果是弹药，其自身的 ID
@export var damage_modifier: float = 0.0
@export var element_type: String = "None" # Fire, Ice, Lightning
@export var durability: float = 100.0
