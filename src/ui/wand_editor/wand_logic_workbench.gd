extends Control
class_name WandLogicWorkbench

signal data_changed(logic_nodes: Array, logic_connections: Array)

const LogicSlotScene = preload("res://src/ui/wand_editor/components/logic_slot.tscn")

@onready var palette_grid = $HSplitContainer/LibraryPanel/VBoxContainer/ScrollContainer/GridContainer
@onready var workbench_list = $HSplitContainer/WorkbenchPanel/VBoxContainer/ScrollContainer/CenterContainer/SlotList
@onready var preview_label = $HSplitContainer/PreviewPanel/VBoxContainer/SummaryLabel

var slots: Array[WandLogicSlot] = []
var max_slots = 5

func _ready():
	_setup_library()
	_rebuild_workbench_slots()

func _setup_library():
	# Mock Library Items
	var items = [
		_create_mock_item("Trigger", "trigger", Color(1, 0.9, 0.7)),
		_create_mock_item("Ruby (Fire)", "modifier_element", Color(0.7, 0, 0), {"element": "fire"}),
		_create_mock_item("Sapphire (Ice)", "modifier_element", Color(0, 0, 0.7), {"element": "ice"}),
		_create_mock_item("Iron (Dmg)", "modifier_damage", Color(0.7, 0.7, 0.7), {"amount": 20}),
		_create_mock_item("Prism (Split)", "splitter", Color(0, 0.8, 1.0)),
		_create_mock_item("Launcher", "action_projectile", Color(1, 0.5, 0.5))
	]
	
	for item in items:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.text = item.display_name
		btn.icon = item.icon
		btn.expand_icon = true
		btn.script = load("res://src/ui/wand_editor/components/palette_item.gd")
		btn.item_data = item
		palette_grid.add_child(btn)

func _create_mock_item(name, type, color, val = {}):
	var item = BaseItem.new()
	item.display_name = name
	item.wand_logic_type = type
	item.wand_visual_color = color
	item.wand_logic_value = val
	item.icon = load("res://icon.svg") # Placeholder
	return item

func load_from_data(nodes: Array, connections: Array):
	# Decompile graph to linear list if possible
	# For now, we just clear and let user build new one, 
	# OR we try to parse a linear chain.
	# Simplification: Just clearing for this prototype as "New System" overrides
	_rebuild_workbench_slots()

func _rebuild_workbench_slots():
	for child in workbench_list.get_children():
		child.queue_free()
	slots.clear()
	
	for i in range(max_slots):
		var slot = LogicSlotScene.instantiate()
		slot.slot_index = i
		slot.item_dropped.connect(_on_slot_item_dropped)
		workbench_list.add_child(slot)
		slots.append(slot)
		
	# Add default Logic: Trigger at top?
	# User wanted explicit control.

func _on_slot_item_dropped(item, index):
	slots[index].set_item(item)
	_update_connections_visuals()
	_update_logic_data()
	_generate_summary()

func _update_connections_visuals():
	for i in range(slots.size()):
		var slot = slots[i]
		if i < slots.size() - 1:
			var next_slot = slots[i+1]
			if slot.current_item and next_slot.current_item:
				# Decide connection type
				if slot.current_item.wand_logic_type == "splitter":
					slot.set_connection_type("branch")
				else:
					slot.set_connection_type("enhance")
			else:
				slot.set_connection_type("none")
		else:
			slot.set_connection_type("none")

func _update_logic_data():
	# Compile Slots to Graph
	var nodes = []
	var connections = []
	
	# Linear compiler
	var previous_id = -1
	
	for i in range(slots.size()):
		var slot = slots[i]
		if not slot.current_item:
			continue
			
		var item = slot.current_item
		var node = {
			"id": i, # Use slot index as ID
			"type": item.wand_logic_type,
			"value": item.wand_logic_value,
			"position": Vector2(i * 150, 50) # Fake pos for graph compliance
		}
		nodes.append(node)
		
		if previous_id != -1:
			connections.append({
				"from_id": previous_id,
				"from_port": 0,
				"to_id": i,
				"to_port": 0
			})
			
		previous_id = i
		
	data_changed.emit(nodes, connections)

func _generate_summary():
	var text = "Sequence: "
	for slot in slots:
		if slot.current_item:
			text += "[" + slot.current_item.display_name + "] -> "
	preview_label.text = text
