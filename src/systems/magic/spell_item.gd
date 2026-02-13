extends BaseItem
class_name SpellItem

@export var spell_unlock_id: String = ""

# Virtual hook called by InventoryManager or Pickup
func on_pickup() -> void:
	if spell_unlock_id != "":
		var tree = Engine.get_main_loop() as SceneTree
		if tree:
			var gs = tree.root.get_node_or_null("GameState")
			if gs and gs.has_method("unlock_spell"):
				gs.unlock_spell(spell_unlock_id)
