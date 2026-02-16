extends StaticBody2D

func _ready():
    add_to_group("chairs")
    add_to_group("housing_comfort")
    add_to_group("destructible") # 允许被挖掘

func hit(damage: float, _pos: Vector2 = Vector2.ZERO):
    handle_mining(damage)

func handle_mining(_damage: float):
    var item_res = GameState.crafting_manager.get_item_by_id("chair")
    if item_res:
        var loot_item = preload("res://scenes/world/loot_item.tscn").instantiate()
        get_tree().current_scene.add_child(loot_item)
        loot_item.global_position = global_position
        loot_item.setup(item_res, 1)
    queue_free()
