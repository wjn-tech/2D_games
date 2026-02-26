extends PanelContainer
class_name ItemSlotUI

## ItemSlotUI
## Handles display, interaction, and drag-and-drop for inventory slots.
## Implements "Precision Magitech" visual feedback using Tweens.

signal item_selected(slot: ItemSlotUI)
signal item_dropped(from_inv, from_idx, to_inv, to_idx)
signal item_activated(slot: ItemSlotUI)

@export var icon_rect_path: NodePath
@export var count_label_path: NodePath

@onready var icon_rect: TextureRect = get_node(icon_rect_path)
@onready var count_label: Label = get_node(count_label_path)
@onready var rarity_glow: ColorRect = get_node_or_null("RarityGlow")
@onready var border: ReferenceRect = get_node_or_null("Border")

# State & Data
var slot_index: int = -1
var parent_inventory: Resource = null
var current_item: Resource = null
var _tween: Tween

# Constants for Magitech Feel
const HOVER_SCALE = Vector2(1.05, 1.05)
const PRESS_SCALE = Vector2(0.95, 0.95)
const NORMAL_SCALE = Vector2(1.0, 1.0)
const GLOW_COLOR_HOVER = Color(0.0, 1.0, 1.0, 0.4) # Cyan Glow
const GLOW_COLOR_NORMAL = Color(0.0, 0.0, 0.0, 0.0)
const BORDER_COLOR_HOVER = Color(0.0, 0.8, 1.0, 0.8)
const BORDER_COLOR_NORMAL = Color(0.3, 0.3, 0.4, 0.0)
const FX_DUST = preload("res://scenes/ui/fx/digital_dust.tscn")

var is_hovered: bool = false
var is_selected: bool = false

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	pivot_offset = size / 2
	
	# Initialize visuals
	if rarity_glow:
		rarity_glow.modulate.a = 0.0 # Start invisible
	if border:
		border.border_color = BORDER_COLOR_NORMAL
		border.editor_only = false # Ensure it shows in game

func setup(index: int, slot_data: Dictionary, inventory_ref: Resource) -> void:
	slot_index = index
	parent_inventory = inventory_ref
	
	current_item = slot_data.get("item")
	var count = slot_data.get("count", 0)
	
	# Reset State
	is_hovered = false
	is_selected = false
	scale = NORMAL_SCALE
	modulate = Color.WHITE
	
	if not current_item:
		_clear_visuals()
		return
		
	# Update Icon
	if current_item.get("icon") and icon_rect:
		icon_rect.texture = current_item.icon
		icon_rect.visible = true
	elif icon_rect:
		icon_rect.visible = false
		
	# Update Count
	if count_label:
		count_label.text = str(count) if count > 1 else ""
		count_label.visible = count > 1
		
	# Update Tooltip
	var d_name = current_item.get("display_name")
	var d_desc = current_item.get("description")
	tooltip_text = "%s\n%s" % [d_name if d_name else "Item", d_desc if d_desc else ""]
	
	# Rarity Visuals (Magitech Style)
	var rarity = current_item.get("quality_grade")
	if not rarity: rarity = "common" 
	_apply_rarity_style(rarity)

func _start_magitech_tween(property: String, target_val: Variant, duration: float = 0.15) -> void:
	if _tween: _tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, property, target_val, duration)

# --- Visual Logic ---
func _apply_rarity_style(rarity: String) -> void:
	# In Magitech style, rarity is a subtle colored underglow + border tint
	var base_color = Color(0.5, 0.5, 0.5)
	match rarity:
		"uncommon": base_color = Color(0.2, 1.0, 0.2) # Green
		"rare": base_color = Color(0.0, 0.4, 1.0) # Blue
		"epic": base_color = Color(0.8, 0.0, 1.0) # Purple
		"legendary": base_color = Color(1.0, 0.6, 0.0) # Orange
	
	if rarity_glow:
		# Pulse animation for high rarity?
		if rarity in ["epic", "legendary"]:
			var pulse = create_tween().set_loops()
			pulse.tween_property(rarity_glow, "modulate:a", 0.3, 1.0)
			pulse.tween_property(rarity_glow, "modulate:a", 0.1, 1.0)
		else:
			rarity_glow.modulate = base_color
			rarity_glow.modulate.a = 0.0 # Only show on hover mostly? Or faint?
			
	if border:
		border.border_color = base_color
		border.border_color.a = 0.3 # Dim by default

func _clear_visuals() -> void:
	tooltip_text = ""
	if icon_rect:
		icon_rect.texture = null
		icon_rect.visible = false
	if count_label: 
		count_label.text = ""
	if rarity_glow:
		rarity_glow.visible = false
	if border:
		border.border_color = BORDER_COLOR_NORMAL

# --- Interaction ---
func _on_mouse_entered() -> void:
	if not current_item: return
	is_hovered = true
	
	# Magitech: "Lock On" effect
	# 1. Quick scale snap
	if _tween: _tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", HOVER_SCALE, 0.15)
	
	# 2. Border glow on
	if border:
		_tween.tween_property(border, "border_color:a", 1.0, 0.1)
	
	# 3. Background/Glow flare
	if rarity_glow:
		rarity_glow.visible = true
		_tween.tween_property(rarity_glow, "modulate:a", 0.5, 0.2)
		
	# Audio feedback (placeholder)
	# SoundManager.play_ui_hover()

func _on_mouse_exited() -> void:
	is_hovered = false
	if not is_selected:
		if _tween: _tween.kill()
		_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "scale", NORMAL_SCALE, 0.2)
		
		if border:
			_tween.tween_property(border, "border_color:a", 0.3, 0.2)
			
		if rarity_glow:
			_tween.tween_property(rarity_glow, "modulate:a", 0.0, 0.2)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_press()
			else:
				_on_release()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			pass # Context menu?

func _on_press() -> void:
	# Mechanical "Click" - scale down
	var click_tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	click_tween.tween_property(self, "scale", PRESS_SCALE, 0.05)
	
	_spawn_particles()

func _spawn_particles() -> void:
	if current_item:
		var fx = FX_DUST.instantiate()
		add_child(fx)
		fx.position = size / 2
		fx.color = border.border_color if border else Color.CYAN

func _on_release() -> void:
	# Spring back
	var release_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	release_tween.tween_property(self, "scale", HOVER_SCALE if is_hovered else NORMAL_SCALE, 0.3)
	
	if current_item:
		item_selected.emit(self)

# --- Drag & Drop ---
func _get_drag_data(_at_position: Vector2):
	if not current_item: return null
	
	var data = {
		"inventory": parent_inventory,
		"index": slot_index,
		"item": current_item
	}
	
	# Magitech Holographic Preview
	var preview = Control.new()
	var icon = TextureRect.new()
	if current_item.get("icon"):
		icon.texture = current_item.icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.size = Vector2(48, 48)
		icon.modulate = Color(0.8, 0.9, 1.0, 0.8) # Hologram blue tint
		icon.position = -icon.size / 2
		
		# Add a scanline shader or effect? For now, just opacity.
		
		preview.add_child(icon)
		set_drag_preview(preview)
	
	return data

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("inventory") and data.has("index")):
		return false
	if data.inventory == parent_inventory and data.index == slot_index:
		return false
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var from_inv = data.inventory
	var from_idx = data.index
	
	# Manager Call
	if GameState.inventory.has_method("swap_items"):
		GameState.inventory.swap_items(from_inv, from_idx, parent_inventory, slot_index)
	
	item_dropped.emit(from_inv, from_idx, parent_inventory, slot_index)
	item_dropped.emit(from_inv, from_idx, parent_inventory, slot_index)
