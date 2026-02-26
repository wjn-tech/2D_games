extends PanelContainer
class_name ItemDetailPanelUI


@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var type_label: Label = %TypeLabel
@onready var desc_label: RichTextLabel = %DescLabel
@onready var stats_container: VBoxContainer = %StatsContainer
@onready var use_button: Button = %UseButton
@onready var drop_button: Button = %DropButton

var current_inventory: Inventory = null
var current_index: int = -1

func _ready() -> void:
	visible = false
	if use_button: use_button.pressed.connect(_on_use_pressed)
	if drop_button: drop_button.pressed.connect(_on_drop_pressed)

func show_item(item: Resource, inv: Inventory = null, index: int = -1) -> void:
	if not item:
		visible = false
		return
	
	current_inventory = inv
	current_index = index
	visible = true
	
	# Validate buttons based on item
	if use_button: use_button.disabled = (index == -1)
	if drop_button: drop_button.disabled = (index == -1)
	
	# Icon
	if item.icon:
		icon_rect.texture = item.icon
	
	# Name & Rarity Color
	name_label.text = item.display_name
	var rarity = item.get("quality_grade")
	if not rarity: rarity = ItemRarity.COMMON
	name_label.add_theme_color_override("font_color", ItemRarity.get_color(rarity))
	
	# Type
	type_label.text = item.get("item_type") if item.get("item_type") else "Item"
	
	# Description
	desc_label.text = item.description
	
	# Stats (Mockup logic based on available fields)
	for child in stats_container.get_children():
		child.queue_free()
		
	# Add some stats rows
	if item.get("damage_modifier") and item.damage_modifier > 0:
		_add_stat_row("Damage", str(item.damage_modifier))
	
	if item.get("durability"):
		_add_stat_row("Durability", str(item.durability))
		
	if item.get("value"):
		_add_stat_row("Value", str(item.value) + " Gold")

func _on_use_pressed() -> void:
	# TODO: Implement Use Item Logic (e.g., equip or consume)
	print("Use pressed for slot: ", current_index)
	pass

func _on_drop_pressed() -> void:
	if not current_inventory or current_index < 0: return

	var slot = current_inventory.get_slot(current_index)
	var item = slot.get("item")
	if not item: return

	# 1. Spawn in world
	if GameState.inventory.has_method("drop_item"):
		GameState.inventory.drop_item(item, 1)

	# 2. Remove from inventory (must verify method exists)
	if current_inventory.has_method("remove_from_slot"):
		current_inventory.remove_from_slot(current_index, 1)
	
	# 3. Refresh UI (close panel or update count)
	var new_slot = current_inventory.get_slot(current_index)
	if not new_slot.get("item"):
		visible = false
	else:
		# Refresh current display if count changed
		show_item(new_slot.get("item"), current_inventory, current_index)

func _add_stat_row(label: String, value: String) -> void:
	var row = HBoxContainer.new()
	var l = Label.new()
	l.text = label + ":"
	l.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	var v = Label.new()
	v.text = value
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	row.add_child(l)
	row.add_child(v)
	stats_container.add_child(row)
