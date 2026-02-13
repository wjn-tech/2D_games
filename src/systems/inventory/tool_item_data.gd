extends ItemData
class_name ToolItemData

enum ToolType { HAMMER, PICKAXE, AXE, HOUSING_QUERY }

@export var tool_type: ToolType = ToolType.HAMMER
@export var power: int = 1
@export var range_pixels: float = 160.0

func _on_use(user: Node):
	if tool_type == ToolType.HAMMER:
		_process_hammer(user)
	elif tool_type == ToolType.HOUSING_QUERY:
		_process_housing_query(user)

func _process_housing_query(user: Node):
	var mouse_pos = user.get_global_mouse_position()
	var sm = user.get_node_or_null("/root/SettlementManager")
	if sm:
		var msg = sm.inspect_housing(mouse_pos)
		
		var ui_mgr = user.get_node_or_null("/root/UIManager")
		if ui_mgr:
			ui_mgr.show_notification(msg)
		else:
			print("Housing Query: ", msg)

func _process_hammer(user: Node):
	var lm = user.get_node_or_null("/root/LayerManager")
	if not lm or not lm.layer_nodes.has(2): return
	
	var mouse_pos = user.get_global_mouse_position()
	if user.global_position.distance_to(mouse_pos) > range_pixels:
		return # Out of reach
		
	var layer2 = lm.layer_nodes[2]
	var map_pos = layer2.local_to_map(layer2.to_local(mouse_pos))
	
	# Hammer primarily removes Layer 2 (Background walls)
	if layer2.get_cell_source_id(map_pos) != -1:
		# Save old tile info before removal for dropping
		var source_id = layer2.get_cell_source_id(map_pos)
		var atlas_coords = layer2.get_cell_atlas_coords(map_pos)
		
		layer2.set_cell(map_pos, -1)
		
		# Drop item logic
		_spawn_wall_loot(user, source_id, atlas_coords)
		
		# Trigger settlement update if needed
		var sm = user.get_node_or_null("/root/SettlementManager")
		if sm: sm.mark_housing_dirty(mouse_pos)

func _spawn_wall_loot(user: Node, source_id: int, atlas_coords: Vector2i):
	var loot_scene = load("res://scenes/world/loot_item.tscn")
	if not loot_scene: return
	
	var loot = loot_scene.instantiate()
	user.get_parent().add_child(loot)
	var mouse_pos = user.get_global_mouse_position()
	loot.global_position = mouse_pos
	
	# Try to find matching ItemData for this tile
	# Simplified: Just create a generic item if not found
	var item = ItemData.new()
	item.display_name = "Wall Fragment"
	item.id = "wall_fragment"
	if loot.has_method("setup"):
		loot.setup(item, 1)
