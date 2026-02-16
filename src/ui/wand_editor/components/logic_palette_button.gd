extends PanelContainer

var item_data: BaseItem
var _drag_start_pos: Vector2 = Vector2.ZERO

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drag_start_pos = event.position
				accept_event()
			else:
				_drag_start_pos = Vector2.ZERO

	if event is InputEventMouseMotion and _drag_start_pos != Vector2.ZERO:
		if event.position.distance_to(_drag_start_pos) > 5:
			_drag_start_pos = Vector2.ZERO
			_trigger_drag()

func _trigger_drag():
	var preview = Control.new()
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.color = item_data.wand_visual_color
	preview.add_child(icon)
	force_drag(item_data, preview)

func setup(item):
	item_data = item
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(110, 80)

	# --- Tooltip System (Stat Display) ---
	var tt = "[ " + item.display_name + " ]"
	var l_type = item.wand_logic_type
	var val = item.wand_logic_value

	# Mana Cost
	var mana = val.get("mana_cost", 10)
	tt += "\n吸取法力: " + str(mana)

	# 1. Damage (Projectiles only)
	if l_type == "action_projectile":
		var dmg = val.get("damage", 0)
		tt += "\n伤害: " + str(dmg)
	elif l_type == "modifier_damage":
		var dmg = val.get("amount", val.get("damage_add", 0))
		if dmg != 0:
			tt += "\n伤害修正: " + ("+" if dmg >= 0 else "") + str(dmg)

	# 2. Speed (Projectiles or Speed Modifiers)
	if l_type == "action_projectile":
		var spd = val.get("speed", 0)
		tt += "\n速度: " + str(spd)
	elif l_type == "modifier_speed":
		if val.has("speed_add"):
			var spd = val["speed_add"]
			tt += "\n速度修正: " + ("+" if spd >= 0 else "") + str(spd)
		elif val.has("multiplier"):
			tt += "\n速度倍率: x" + str(val["multiplier"])

	# 3. Delay & Recharge (Noita Style)
	var delay = val.get("delay", 0.0)
	if delay != 0:
		tt += "\n施法延迟: " + ("+" if delay >= 0 else "") + str(delay) + "s"
	
	var recharge = val.get("recharge", 0.0)
	if recharge != 0:
		tt += "\n充能时间: " + ("+" if recharge >= 0 else "") + str(recharge) + "s"

	# 4. Description
	if not item.description.is_empty():
		tt += "\n\n" + item.description

	tooltip_text = tt
	
	# UI Layout (Visual Tile)
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 5)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)

	var center_container = CenterContainer.new()
	center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(center_container)

	var icon_box = Panel.new()
	icon_box.custom_minimum_size = Vector2(32, 32)
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box_style = StyleBoxFlat.new()
	box_style.bg_color = Color.TRANSPARENT
	box_style.border_color = item.wand_visual_color
	box_style.border_width_left = 2
	box_style.border_width_top = 2
	box_style.border_width_right = 2
	box_style.border_width_bottom = 2
	box_style.corner_radius_top_left = 4
	box_style.corner_radius_top_right = 4
	box_style.corner_radius_bottom_left = 4
	box_style.corner_radius_bottom_right = 4
	icon_box.add_theme_stylebox_override("panel", box_style)
	center_container.add_child(icon_box)

	var symbol = Label.new()
	symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	symbol.text = item.wand_logic_type.left(1).to_upper()
	if item.wand_logic_type == "trigger": symbol.text = "T"
	elif item.wand_logic_type == "modifier_damage": symbol.text = "%"
	elif item.wand_logic_type == "action_projectile": symbol.text = "!"

	symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	symbol.set_anchors_preset(Control.PRESET_FULL_RECT)
	symbol.add_theme_color_override("font_color", item.wand_visual_color)
	icon_box.add_child(symbol)

	var lbl = Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.text = item.display_name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size.x = 80
	vbox.add_child(lbl)

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.12, 0.12, 0.14)
	btn_style.border_color = Color(0.3, 0.3, 0.3)
	btn_style.border_width_left = 1
	btn_style.border_width_top = 1
	btn_style.border_width_right = 1
	btn_style.border_width_bottom = 1
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", btn_style)
