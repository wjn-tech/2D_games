extends Node2D

var inventory_data: Dictionary = {}

func _ready() -> void:
    # Visuals
    # Minimalist box
    pass

func set_loot(items: Dictionary) -> void:
    inventory_data = items
    # TODO: Make interactable to pick up
    print("Loot dropped: ", items)

func interact(_player) -> void:
    # Give items back to player
    if GameState.inventory:
        # Merge logic needed
        pass
    queue_free()
