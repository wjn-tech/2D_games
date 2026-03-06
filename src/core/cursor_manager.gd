extends Node

## CursorManager (Autoload)
## Manages custom mouse cursors and context-aware switching.

enum CursorType {
	DEFAULT,
	HOVER,
	GRAB,
	TARGET,
	PICKUP,
	TALK,
	WAIT
}

# Configuration for cursors: Texture path and Hotspot offset
const CURSOR_CONFIG = {
	CursorType.DEFAULT: {
		"path": "res://assets/ui/icons/cursor_magic_default.svg", # Magical Mana Shard
		"hotspot": Vector2(10, 10) # Tips of the shard
	},
	CursorType.HOVER: {
		"path": "res://assets/ui/icons/cursor_magic_hover.svg", # Emerald Interaction
		"hotspot": Vector2(32, 32) # Center of the icon
	},
	CursorType.TALK: {
		"path": "res://assets/ui/icons/cursor_magic_hover.svg", # Same Emerald icon for talk for now
		"hotspot": Vector2(32, 32)
	},
	CursorType.TARGET: {
		"path": "res://assets/ui/icons/cursor_magic_target.svg", # Red Targeting Sigil
		"hotspot": Vector2(32, 32) # Dead center
	},
	CursorType.PICKUP: {
		"path": "res://assets/ui/icons/cursor_magic_hover.svg", # Fallback to hover 
		"hotspot": Vector2(32, 32)
	}
}

var current_cursor: int = -1 # Initialize to -1 to force update on first set_cursor call

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Defer setting cursor to ensure Input system is ready
	call_deferred("set_cursor", CursorType.DEFAULT)
	print("CursorManager: Initialized with default cursor.")

func set_cursor(type: CursorType) -> void:
	if current_cursor == type:
		return
		
	# Update state
	current_cursor = type
	
	if CURSOR_CONFIG.has(type):
		var config = CURSOR_CONFIG[type]
		var tex = load(config.path)
		if tex:
			# Important: Use Input.CURSOR_ARROW as the base shape, 
			# but ensure the image is valid.
			Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, config.hotspot)
			# Only print if debug is needed, to avoid spam
			# print("CursorManager: Success setting cursor to type index: ", type)
		else:
			push_error("CursorManager: Failed to load texture at: " + config.path)
			# Fallback to system cursor if texture fails
			Input.set_custom_mouse_cursor(null)
	else:
		Input.set_custom_mouse_cursor(null)
		print("CursorManager: Resetting cursor to system default (CONFIG missing).")

# Debug feature: Press F9 to toggle cursor for testing
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F9:
		var next = (current_cursor + 1) % CursorType.size()
		# Check if enums are just ints starting at 0
		if next >= CursorType.size(): next = 0
		set_cursor(next as CursorType)
		print("CursorManager: Debug switch to cursor type: ", next)
