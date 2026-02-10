extends Control
class_name WandVisualGrid

signal cell_clicked(coords: Vector2i, button_index: int)
signal grid_changed

var cell_size = 24
var grid_width = 16
var grid_height = 48
var grid_data = {} # Vector2i -> BaseItem
var selected_material: BaseItem = null # Current brush
var is_painting = false # For mouse drag painting

@onready var grid_container = GridContainer.new()
@onready var background_rect = ColorRect.new()
@onready var center_container = CenterContainer.new()

var current_zoom = 1.0
var target_zoom = 1.0

var is_panning = false
var pan_start_pos = Vector2.ZERO
var grid_start_pos = Vector2.ZERO

func _ready():
	# Setup Blueprint Background
	background_rect.color = Color(0.05, 0.07, 0.1, 0.95) # Dark space blue
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_rect)
	
	# Center the grid
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)
	
	grid_container.pivot_offset = Vector2.ZERO
	center_container.add_child(grid_container)
	
	grid_container.add_theme_constant_override("h_separation", 2)
	grid_container.add_theme_constant_override("v_separation", 2)
	
	# Allow focus for mouse wheel
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	_rebuild_grid()

func _process(delta):
	if abs(current_zoom - target_zoom) > 0.0001:
		current_zoom = lerp(current_zoom, target_zoom, 15.0 * delta)
		set_zoom(current_zoom)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = min(target_zoom + 0.2, 4.0)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = max(target_zoom - 0.2, 0.2)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				pan_start_pos = get_global_mouse_position()
				grid_start_pos = grid_container.position
			else:
				is_panning = false
			accept_event()
			
	if event is InputEventMouseMotion and is_panning:
		var delta_pos = get_global_mouse_position() - pan_start_pos
		grid_container.position = grid_start_pos + delta_pos
		accept_event()

func setup(width: int, height: int):
	grid_width = width
	grid_height = height
	grid_container.columns = width
	_rebuild_grid()

func set_zoom(val: float):
	grid_container.scale = Vector2(val, val)
	# Update collision/visual size based on scale
	var base_w = grid_width * (cell_size + 2)
	var base_h = grid_height * (cell_size + 2)
	grid_container.custom_minimum_size = Vector2(base_w, base_h)

func set_cell(coords: Vector2i, item: BaseItem):
	if item == null:
		grid_data.erase(coords)
	else:
		grid_data[coords] = item
	
	_update_cell_visual(coords)
	grid_changed.emit()

func _rebuild_grid():
	for child in grid_container.get_children():
		child.queue_free()
		
	# Adjust cell size for larger grid
	if grid_height > 20:
		cell_size = 14
	else:
		cell_size = 24
		
	for y in range(grid_height):
		for x in range(grid_width):
			var coords = Vector2i(x, y)
			# Module Slot Style
			var cell = Panel.new()
			cell.custom_minimum_size = Vector2(cell_size, cell_size)
			cell.name = "Cell_%d_%d" % [x, y]
			
			# Base Style (Empty Slot)
			var style = StyleBoxFlat.new()
			# Initialize style based on existing data immediately
			var item = grid_data.get(coords)
			_update_cell_style(coords, style, item)
			
			cell.add_theme_stylebox_override("panel", style)
			
			# Icon holder
			var icon_rect = TextureRect.new()
			icon_rect.name = "Icon"
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(icon_rect)
			
			# Overlay Button for interaction
			var btn = TextureButton.new()
			btn.name = "Btn"
			btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			
			# Attach logic for Drag & Drop
			btn.set_script(load("res://src/ui/wand_editor/grid_cell.gd"))
			btn.grid_coords = coords
			
			# Connect signals
			btn.clicked.connect(func(c, b): _on_cell_clicked(c, b))
			btn.dropped_data.connect(func(item): set_cell(coords, item))
			btn.mouse_entered.connect(func(): _on_cell_mouse_entered(coords, style))
			btn.mouse_exited.connect(func(): _update_cell_style(coords, style))
			
			cell.add_child(btn)
			grid_container.add_child(cell)
	
	# Initial UI state is now set during loop, no need for redundant loops

func _on_cell_clicked(coords: Vector2i, button_index: int):
	# Left Click: Paint with selected material (if any)
	if button_index == MOUSE_BUTTON_LEFT:
		if selected_material:
			set_cell(coords, selected_material)
	# Right Click: Erase
	elif button_index == MOUSE_BUTTON_RIGHT:
		set_cell(coords, null)
		
	cell_clicked.emit(coords, button_index)

func _on_cell_mouse_entered(coords: Vector2i, style: StyleBoxFlat):
	# Highlight
	style.border_color = Color.CYAN
	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	
	# Drag Painting Check
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and selected_material:
		set_cell(coords, selected_material)
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		set_cell(coords, null)

func _update_cell_visual(coords: Vector2i):
	var idx = coords.y * grid_width + coords.x
	if idx >= grid_container.get_child_count():
		return
		
	var cell = grid_container.get_child(idx)
	var style = cell.get_theme_stylebox("panel")
	var icon_rect = cell.get_node("Icon")
	var item = grid_data.get(coords)
	
	_update_cell_style(coords, style, item)
	
	# Pixel art mode: Hide icon, show solid color in background
	icon_rect.texture = null
	
func _update_cell_style(coords: Vector2i, style: StyleBoxFlat, item = null):
	if item == null:
		item = grid_data.get(coords)
		
	if item:
		# Pixel Art Style
		style.bg_color = item.wand_visual_color
		# Use border to show selection/grid clearly?
		style.border_color = item.wand_visual_color.lightened(0.2)
		style.border_width_bottom = 0
		style.border_width_top = 0
		style.border_width_left = 0
		style.border_width_right = 0
		style.corner_radius_top_left = 0
		style.corner_radius_top_right = 0
		style.corner_radius_bottom_left = 0
		style.corner_radius_bottom_right = 0
	else:
		# "Empty Grid" Look - Sci-Fi
		style.bg_color = Color(0.05, 0.07, 0.1, 0.4) 
		style.border_color = Color(0.2, 0.8, 1.0, 0.15)
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_width_top = 1
		style.border_width_left = 1
		style.border_width_right = 1
		style.corner_radius_top_left = 0
		style.corner_radius_top_right = 0
		style.corner_radius_bottom_left = 0
		style.corner_radius_bottom_right = 0
