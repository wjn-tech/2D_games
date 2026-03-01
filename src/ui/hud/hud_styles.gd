class_name HUDStyles
extends RefCounted

# Palette Definitions - Revised for "Pixel Cosmic Magic"
const COLOR_BG_PRIMARY = Color("#1A1A2E") # Deep Purple/Cosmic Blue
const COLOR_BG_SECONDARY = Color("#16213E") # Slightly Lighter Blue
const COLOR_BORDER_MAGIC = Color("#4361EE") # Neon Magical Blue
const COLOR_BORDER_GOLD = Color("#FFD700") # Highlighting Gold
const COLOR_HP = Color("#E63946") # Vibrant Red
const COLOR_MANA = Color("#4361EE") # Matches Magic Border
const COLOR_STAMINA = Color("#2ECC71") # Stamina Green
const COLOR_TEXT_PRIMARY = Color("#E0FFFF") # Light Cyan / White
const COLOR_TEXT_SHADOW = Color("#0F172A") # Deep Shadow

# programmatic style generators
static func get_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BG_PRIMARY
	style.bg_color.a = 0.9 # Mild Transparency
	
	# Pixel Art Border Logic
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = COLOR_BORDER_MAGIC
	
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	
	style.anti_aliasing = false
	
	return style

static func get_button_style_normal() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BG_SECONDARY
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = COLOR_BORDER_MAGIC
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	style.anti_aliasing = false
	return style

static func get_button_style_hover() -> StyleBoxFlat:
	var style = get_button_style_normal()
	style.border_color = COLOR_BORDER_GOLD
	style.bg_color = COLOR_BG_SECONDARY.lightened(0.1)
	return style

static func get_button_style_pressed() -> StyleBoxFlat:
	var style = get_button_style_normal()
	style.bg_color = COLOR_BG_SECONDARY.darkened(0.2)
	style.border_color = COLOR_BORDER_GOLD
	return style

static func get_slot_style_normal() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BG_SECONDARY
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = COLOR_BG_SECONDARY.lightened(0.2) # Subtle border
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	style.anti_aliasing = false
	return style

static func get_slot_style_active() -> StyleBoxFlat:
	var style = get_slot_style_normal()
	style.border_color = COLOR_BORDER_GOLD # Gold highlight for active slot
	style.bg_color = COLOR_BG_SECONDARY.lightened(0.1)
	return style

static func get_bar_bg_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#0F172A") # Dark background
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = COLOR_BG_SECONDARY
	style.anti_aliasing = false
	return style

static func get_bar_fg_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.anti_aliasing = false
	return style

static func get_minimap_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BG_PRIMARY # Deep Blue
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = COLOR_BORDER_MAGIC
	style.anti_aliasing = false
	return style

static func get_info_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BG_PRIMARY
	style.bg_color.a = 0.85
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = COLOR_BG_SECONDARY # Less intrusive border for info
	style.anti_aliasing = false
	return style

static func get_progress_bar_bg() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.5)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.0, 0.0, 0.0, 0.8)
	style.anti_aliasing = false
	return style

static func get_progress_bar_fill(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = color.lightened(0.2) # Inner highlight
	style.anti_aliasing = false
	return style
