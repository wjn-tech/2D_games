extends Resource
class_name CraftingRecipe

@export var result_item: BaseItem
@export var result_amount: int = 1
@export var ingredients: Dictionary = {} # { "item_id": amount }
