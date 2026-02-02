extends Control

@onready var building_list = $Panel/ScrollContainer/VBoxContainer
@onready var category_tabs = $Panel/CategoryTabs

var buildings: Array[BuildingResource] = []

func _ready() -> void:
	_load_buildings()
	_display_buildings("All")
	
	if category_tabs:
		category_tabs.tab_changed.connect(_on_category_changed)
		
	if GameState.inventory:
		GameState.inventory.inventory_changed.connect(func(): _display_buildings(category_tabs.get_tab_title(category_tabs.current_tab) if category_tabs else "All"))

func _load_buildings() -> void:
	var dir = DirAccess.open("res://data/buildings/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
				var path = "res://data/buildings/" + file_name.replace(".remap", "")
				var res = load(path)
				if res is BuildingResource:
					buildings.append(res)
			file_name = dir.get_next()

func _display_buildings(category: String) -> void:
	# 清空列表
	for child in building_list.get_children():
		child.queue_free()
		
	var sm = get_node_or_null("/root/SettlementManager")
	var current_level = sm.stats.level if sm else 1
		
	for res in buildings:
		if category == "All" or res.category == category:
			var btn = Button.new()
			
			# 获取背包中的数量 (取第一个消耗品作为主要参考)
			var inv_count = 0
			if res.cost.size() > 0:
				var first_item = res.cost.keys()[0]
				inv_count = GameState.inventory.get_item_count(first_item)
			
			# 构建成本字符串
			var cost_str = ""
			for item_id in res.cost:
				var count = res.cost[item_id]
				var chinese_name = _get_item_chinese_name(item_id)
				cost_str += " %s:%d" % [chinese_name, count]
			
			btn.text = "%s [持有:%d] (%s)" % [res.display_name, inv_count, cost_str.strip_edges()]
			btn.tooltip_text = res.description
			
			# 设置图标
			if res.icon:
				btn.icon = res.icon
			elif res.cost.size() > 0:
				var first_item_id = res.cost.keys()[0]
				if GameState.item_db.has(first_item_id):
					btn.icon = GameState.item_db[first_item_id].icon
			
			btn.expand_icon = true
			btn.custom_minimum_size = Vector2(0, 40)
			
			# 检查等级要求
			if res.required_level > current_level:
				btn.disabled = true
				btn.text += " [等级 %d 解锁]" % res.required_level
			
			btn.pressed.connect(_on_building_selected.bind(res))
			building_list.add_child(btn)

func _get_item_chinese_name(id: String) -> String:
	match id:
		"wood": return "木"
		"stone": return "石"
		"dirt": return "土"
		"food": return "粮"
		_: return id

func _on_category_changed(tab: int) -> void:
	var category = category_tabs.get_tab_title(tab)
	_display_buildings(category)

func _on_building_selected(res: BuildingResource) -> void:
	var building_mgr = get_tree().get_first_node_in_group("building_manager")
	if building_mgr:
		building_mgr.start_building(res)
		# UIManager.close_window("BuildingMenu") # 不再自动关闭，方便连续选择

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		UIManager.close_window("BuildingMenu")
