extends PanelContainer

signal wand_selected(wand_item: WandItem)
signal selector_closed

@onready var item_list: ItemList = find_child("ItemList", true, false) as ItemList
@onready var title_label: Label = find_child("TitleLabel", true, false) as Label
@onready var subtitle_label: Label = find_child("SubtitleLabel", true, false) as Label
@onready var hint_label: Label = find_child("HintLabel", true, false) as Label
@onready var close_button: Button = find_child("CloseButton", true, false) as Button
@onready var dialog_panel: PanelContainer = find_child("DialogPanel", true, false) as PanelContainer

var wands: Array[WandItem] = []

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_theme()

	if item_list:
		item_list.item_selected.connect(_on_item_selected)
		if item_list.has_signal("item_activated"):
			item_list.item_activated.connect(_on_item_selected)

	if close_button:
		close_button.pressed.connect(_close_selector)

	if subtitle_label:
		subtitle_label.text = "从快捷栏或背包中选择需要编辑的法杖"

func refresh(inventory_manager: InventoryManager):
	if not item_list:
		return

	item_list.clear()
	wands.clear()
	
	if not inventory_manager:
		if subtitle_label:
			subtitle_label.text = "库存管理器不可用"
		return
	
	# Scan Hotbar
	var hotbar_count := _scan_inventory(inventory_manager.hotbar, "快捷栏")
	# Scan Backpack
	var backpack_count := _scan_inventory(inventory_manager.backpack, "背包")

	if subtitle_label:
		subtitle_label.text = "快捷栏 %d 把 | 背包 %d 把" % [hotbar_count, backpack_count]

	if wands.is_empty():
		item_list.add_item("未找到可编辑法杖", null)

func _scan_inventory(inv: Inventory, prefix: String) -> int:
	if inv == null:
		return 0

	var count := 0
	for i in range(inv.capacity):
		var slot = inv.get_slot(i)
		var item = slot.get("item")
		if item and item is WandItem:
			wands.append(item)
			count += 1
			var label = "%s%d: %s" % [prefix, i + 1, item.display_name]
			item_list.add_item(label, item.icon)

	return count

func _on_item_selected(index: int):
	if index >= 0 and index < wands.size():
		wand_selected.emit(wands[index])

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_selector()
		get_viewport().set_input_as_handled()

func _close_selector() -> void:
	visible = false
	selector_closed.emit()

func _apply_theme() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#08142a")
	panel_style.border_color = Color("#2aa7ff")
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 2
	panel_style.corner_radius_top_right = 2
	panel_style.corner_radius_bottom_left = 2
	panel_style.corner_radius_bottom_right = 2
	add_theme_stylebox_override("panel", panel_style)

	if dialog_panel:
		dialog_panel.add_theme_stylebox_override("panel", panel_style)

	if title_label:
		title_label.add_theme_color_override("font_color", Color("#d9ecff"))

	if subtitle_label:
		subtitle_label.add_theme_color_override("font_color", Color("#7ecaff"))

	if hint_label:
		hint_label.add_theme_color_override("font_color", Color("#6ea6d8"))

	if item_list:
		var list_style := StyleBoxFlat.new()
		list_style.bg_color = Color("#061126")
		list_style.border_color = Color("#2a4b7a")
		list_style.border_width_left = 1
		list_style.border_width_top = 1
		list_style.border_width_right = 1
		list_style.border_width_bottom = 1
		item_list.add_theme_stylebox_override("panel", list_style)
		item_list.add_theme_color_override("font_color", Color("#d9ecff"))
		item_list.add_theme_color_override("font_selected_color", Color("#0b1020"))
		item_list.add_theme_color_override("guide_color", Color("#2f5f93"))
		item_list.add_theme_color_override("font_hovered_color", Color("#ffffff"))

	if close_button:
		var btn_normal := StyleBoxFlat.new()
		btn_normal.bg_color = Color("#0d1d3a")
		btn_normal.border_color = Color("#2aa7ff")
		btn_normal.border_width_left = 1
		btn_normal.border_width_top = 1
		btn_normal.border_width_right = 1
		btn_normal.border_width_bottom = 1

		var btn_hover := btn_normal.duplicate() as StyleBoxFlat
		btn_hover.bg_color = Color("#17325f")
		btn_hover.border_color = Color("#6fd1ff")

		var btn_pressed := btn_normal.duplicate() as StyleBoxFlat
		btn_pressed.bg_color = Color("#0a1730")
		btn_pressed.border_color = Color("#ffd569")

		close_button.add_theme_stylebox_override("normal", btn_normal)
		close_button.add_theme_stylebox_override("hover", btn_hover)
		close_button.add_theme_stylebox_override("pressed", btn_pressed)
		close_button.add_theme_color_override("font_color", Color("#d9ecff"))
		close_button.add_theme_color_override("font_hover_color", Color("#ffffff"))
