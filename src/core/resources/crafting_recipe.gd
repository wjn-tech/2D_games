extends Resource
class_name CraftingRecipe

@export var result_item: Resource
@export var result_amount: int = 1
@export var ingredients: Dictionary = {} # { "item_id": amount }
@export var required_station: String = "" # e.g. "workbench"
