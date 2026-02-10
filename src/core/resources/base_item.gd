extends Resource
class_name BaseItem

@export var id: String = ""
@export var display_name: String = ""
var building_name: String: get = _get_building_name
func _get_building_name(): return display_name
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

# 魔杖合成属性
@export_group("Wand Crafting")
@export var is_wand_material: bool = false
@export var wand_visual_color: Color = Color.WHITE
@export var wand_logic_type: String = "" # "trigger", "modifier_damage", "splitter", "action_projectile"
@export var wand_logic_value: Dictionary = {} # { "amount": 10 }

# Crafting & Quality
@export_group("Quality")
@export var quality_grade: String = "Common" # Common, Rare, Epic, Legendary, Masterwork
@export var quality_score: float = 0.0 # 0.0 - 100.0
@export var crafted_by: String = ""
@export var crafted_properties: Dictionary = {} # Dynamic stats added during crafting
