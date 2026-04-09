class_name GameplayGuideWindow extends CanvasLayer

## Main gameplay guide window - hierarchical catalog + book-like page navigation

@onready var close_button: Button = %CloseButton
@onready var catalog_tree: Tree = %CatalogTree
@onready var page_path_label: Label = %PagePathLabel
@onready var page_title_label: Label = %PageTitleLabel
@onready var page_image: TextureRect = %PageImage
@onready var page_content_label: RichTextLabel = %PageContentLabel
@onready var prev_button: Button = %PrevButton
@onready var next_button: Button = %NextButton
@onready var page_indicator: Label = %PageIndicator
@onready var window_container: CenterContainer = $WindowContainer
@onready var background_overlay: ColorRect = $BackgroundOverlay

const MAGIC_WAND_PROGRAMMING_PATH := "res://data/guide/magic.tres"
const MAGIC_BUILD_GUIDE_PATH := "res://data/guide/magic_building_guide.tres"
const WORLD_GUIDE_PATH := "res://data/guide/world.tres"
const NPC_GUIDE_PATH := "res://data/guide/npc_interaction.tres"
const INHERITANCE_GUIDE_PATH := "res://data/guide/inheritance.tres"
const WEB_SHELL_RESOURCE_PATH := "ui/web/gameplay_guide_shell/index.html"
const WEB_PROTOCOL_VERSION := "1.0"
const WEB_READY_WATCHDOG_SECONDS := 6.0

const BASE_SPELL_IDS: Array[String] = [
	"generator",
	"trigger_cast", "trigger_collision", "trigger_timer",
	"action_projectile",
	"projectile_slime", "projectile_tnt", "projectile_blackhole", "projectile_teleport",
	"projectile_spark_bolt", "projectile_magic_bolt", "projectile_bouncing_burst",
	"projectile_tri_bolt", "projectile_chainsaw",
	"modifier_damage", "modifier_damage_plus", "modifier_pierce",
	"modifier_speed", "modifier_speed_plus", "modifier_delay", "modifier_add_mana",
	"modifier_element_fire", "modifier_element_ice", "modifier_element_slime",
	"modifier_orbit", "modifier_mana_to_damage",
	"element_fire", "element_ice",
	"logic_splitter", "logic_sequence",
	"projectile_vampire_bolt", "projectile_healing_circle"
]

var _pages: Array[Dictionary] = []
var is_open: bool = false
var _current_page_index: int = -1
var _syncing_tree_selection: bool = false
var _web_shell_node: Node = null
var _using_web_shell: bool = false
var _web_bridge_ready: bool = false
var _web_ready_watchdog_started: bool = false
var _web_icon_cache: Dictionary = {}

func _safe_get_string(target: Variant, key: String, fallback: String = "") -> String:
	if target == null or not target.has_method("get"):
		return fallback
	var value = target.get(key)
	if value == null:
		return fallback
	var text := str(value)
	if text == "<null>":
		return fallback
	return text

func _safe_get_array(target: Variant, key: String) -> Array:
	if target == null or not target.has_method("get"):
		return []
	var value = target.get(key)
	if value is Array:
		return value
	return []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(_on_close_pressed)
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	catalog_tree.item_selected.connect(_on_catalog_item_selected)
	visibility_changed.connect(_on_visibility_changed)
	page_image.show()
	_using_web_shell = ClassDB.class_exists("WebView")
	_set_native_shell_visible(true)
	_build_catalog_and_pages()

func _build_catalog_and_pages() -> void:
	_pages.clear()
	catalog_tree.clear()
	catalog_tree.columns = 1
	catalog_tree.hide_root = true

	var root = catalog_tree.create_item()
	var tutorial_dir = catalog_tree.create_item(root)
	tutorial_dir.set_text(0, "新手教程")
	tutorial_dir.set_selectable(0, false)

	var magic_dir = catalog_tree.create_item(tutorial_dir)
	magic_dir.set_text(0, "魔法")
	magic_dir.set_selectable(0, false)

	var world_dir = catalog_tree.create_item(tutorial_dir)
	world_dir.set_text(0, "世界")
	world_dir.set_selectable(0, true)

	var npc_dir = catalog_tree.create_item(tutorial_dir)
	npc_dir.set_text(0, "NPC交互")
	npc_dir.set_selectable(0, true)

	var inheritance_dir = catalog_tree.create_item(tutorial_dir)
	inheritance_dir.set_text(0, "继承")
	inheritance_dir.set_selectable(0, true)

	var wand_programming_dir = catalog_tree.create_item(magic_dir)
	wand_programming_dir.set_text(0, "魔杖编程")
	wand_programming_dir.set_selectable(0, true)

	var build_guide_dir = catalog_tree.create_item(magic_dir)
	build_guide_dir.set_text(0, "魔法搭建指南")
	build_guide_dir.set_selectable(0, true)

	var compendium_dir = catalog_tree.create_item(magic_dir)
	compendium_dir.set_text(0, "法术图鉴")
	compendium_dir.set_selectable(0, true)

	var wand_overview_index = _append_section_overview_page(wand_programming_dir, "新手教程 / 魔法 / 魔杖编程", MAGIC_WAND_PROGRAMMING_PATH)
	_append_pages_from_section(wand_programming_dir, "新手教程 / 魔法 / 魔杖编程", MAGIC_WAND_PROGRAMMING_PATH)
	wand_programming_dir.set_metadata(0, wand_overview_index)

	var build_overview_index = _append_section_overview_page(build_guide_dir, "新手教程 / 魔法 / 魔法搭建指南", MAGIC_BUILD_GUIDE_PATH)
	_append_pages_from_section(build_guide_dir, "新手教程 / 魔法 / 魔法搭建指南", MAGIC_BUILD_GUIDE_PATH)
	build_guide_dir.set_metadata(0, build_overview_index)

	var compendium_overview_index = _append_spell_compendium_overview_page(compendium_dir, "新手教程 / 魔法 / 法术图鉴")
	_append_spell_compendium_pages(compendium_dir, "新手教程 / 魔法 / 法术图鉴")
	compendium_dir.set_metadata(0, compendium_overview_index)

	var world_overview_index = _append_section_overview_page(world_dir, "新手教程 / 世界", WORLD_GUIDE_PATH)
	_append_pages_from_section(world_dir, "新手教程 / 世界", WORLD_GUIDE_PATH)
	world_dir.set_metadata(0, world_overview_index)

	var npc_overview_index = _append_section_overview_page(npc_dir, "新手教程 / NPC交互", NPC_GUIDE_PATH)
	_append_pages_from_section(npc_dir, "新手教程 / NPC交互", NPC_GUIDE_PATH)
	npc_dir.set_metadata(0, npc_overview_index)

	var inheritance_overview_index = _append_section_overview_page(inheritance_dir, "新手教程 / 继承", INHERITANCE_GUIDE_PATH)
	_append_pages_from_section(inheritance_dir, "新手教程 / 继承", INHERITANCE_GUIDE_PATH)
	inheritance_dir.set_metadata(0, inheritance_overview_index)
	print("GameplayGuideWindow: built pages = ", _pages.size())

	tutorial_dir.collapsed = false
	magic_dir.collapsed = false
	world_dir.collapsed = false
	npc_dir.collapsed = false
	inheritance_dir.collapsed = false
	wand_programming_dir.collapsed = false
	build_guide_dir.collapsed = false
	compendium_dir.collapsed = true

	if not _pages.is_empty():
		_select_page(wand_overview_index if wand_overview_index >= 0 else 0)

	_sync_web_guide_state()

func _append_section_overview_page(parent_item: TreeItem, path_prefix: String, section_path: String) -> int:
	var section = load(section_path)
	var title_text := parent_item.get_text(0)
	var description_text := ""
	var image_tex: Texture2D = null

	if section != null:
		if section is GuideSectionData:
			title_text = (section as GuideSectionData).title
			description_text = (section as GuideSectionData).description
			var raw_subsections: Array = (section as GuideSectionData).subsections
			for subsection in raw_subsections:
				if subsection == null:
					continue
				if subsection is GuideSubsectionData:
					image_tex = (subsection as GuideSubsectionData).image
					if image_tex != null:
						break
		elif section.has_method("get"):
			title_text = _safe_get_string(section, "title", title_text)
			description_text = _safe_get_string(section, "description", description_text)

	var overview_text := "[b]%s[/b]\n\n%s\n\n[i]点击左侧子页面可查看更细的分步说明。[/i]" % [title_text, description_text]
	var page: Dictionary = {
		"title": title_text,
		"path": path_prefix,
		"content": overview_text,
		"image": image_tex,
	}
	_pages.append(page)
	var page_index := _pages.size() - 1
	var page_item = catalog_tree.create_item(parent_item)
	page_item.set_text(0, title_text)
	page_item.set_metadata(0, page_index)
	return page_index

func _append_pages_from_section(parent_item: TreeItem, path_prefix: String, section_path: String) -> void:
	var section = load(section_path)
	if section == null:
		return

	var raw_subsections: Array = []
	if section is GuideSectionData:
		raw_subsections = (section as GuideSectionData).subsections
	elif section.has_method("get"):
		raw_subsections = _safe_get_array(section, "subsections")

	for subsection in raw_subsections:
		if subsection == null:
			continue

		var title_text := "未命名页面"
		var content_text := ""
		var image_tex: Texture2D = null

		if subsection is GuideSubsectionData:
			title_text = (subsection as GuideSubsectionData).title
			content_text = (subsection as GuideSubsectionData).content
			image_tex = (subsection as GuideSubsectionData).image
		elif subsection.has_method("get"):
			title_text = _safe_get_string(subsection, "title", title_text)
			content_text = _safe_get_string(subsection, "content", content_text)
			var raw_image = subsection.get("image")
			if raw_image is Texture2D:
				image_tex = raw_image

		var page: Dictionary = {
			"title": title_text,
			"path": path_prefix,
			"content": content_text,
			"image": image_tex,
		}
		_pages.append(page)
		var page_item = catalog_tree.create_item(parent_item)
		page_item.set_text(0, title_text)
		page_item.set_metadata(0, _pages.size() - 1)

func _append_spell_compendium_pages(parent_item: TreeItem, path_prefix: String) -> void:
	for spell_id in _collect_spell_ids():
		var display_name = _spell_display_name(spell_id)
		var page: Dictionary = {
			"title": display_name,
			"path": path_prefix,
			"content": _build_spell_compendium_text(spell_id, display_name),
			"image": null,
		}
		_pages.append(page)
		var page_item = catalog_tree.create_item(parent_item)
		page_item.set_text(0, display_name)
		page_item.set_metadata(0, _pages.size() - 1)

func _append_spell_compendium_overview_page(parent_item: TreeItem, path_prefix: String) -> int:
	var overview_page: Dictionary = {
		"title": "法术图鉴",
		"path": path_prefix,
		"content": "[b]法术图鉴[/b]\n\n这里会按法术逐页记录每个法术的名称、获取方式和法术效果。\n你可以把它当作一本游戏内百科，先看总览，再进入具体法术页面。\n\n[i]使用上一页/下一页或点击左侧条目切换页面。[/i]",
		"image": null,
	}
	_pages.append(overview_page)
	var page_index := _pages.size() - 1
	var page_item = catalog_tree.create_item(parent_item)
	page_item.set_text(0, "法术图鉴")
	page_item.set_metadata(0, page_index)
	return page_index

func _collect_spell_ids() -> Array[String]:
	var seen: Dictionary = {}
	for spell_id in BASE_SPELL_IDS:
		seen[spell_id] = true

	if GameState != null and GameState.item_db != null:
		for item_id in GameState.item_db.keys():
			var item = GameState.item_db[item_id]
			if item == null:
				continue
			var logic_type = str(item.get("wand_logic_type"))
			if logic_type != "":
				var id_value = item.get("id")
				var spell_id = str(id_value) if id_value != null else str(item_id)
				seen[spell_id] = true

	var ids: Array[String] = []
	for key in seen.keys():
		ids.append(str(key))
	ids.sort()
	return ids

func _spell_display_name(spell_id: String) -> String:
	var key = "SPELL_" + spell_id.to_upper()
	var translated = tr(key)
	if translated != key:
		return translated
	return spell_id.replace("_", " ").capitalize()

func _build_spell_compendium_text(spell_id: String, display_name: String) -> String:
	var acquisition = _spell_acquire_method(spell_id)
	var effect_summary = _spell_effect_summary(spell_id, display_name)
	var category = _spell_category(spell_id)
	var category_color = _spell_category_color(category)
	return "[center][color=%s][b]%s[/b][/color][/center]\n\n[b]法术名：[/b] %s\n[b]获取方式：[/b] %s\n[b]法术效果：[/b] %s\n\n[b]补充说明：[/b]\n该页面用于记录 %s 的具体数值、使用场景和搭配建议。" % [category_color, category, display_name, acquisition, effect_summary, display_name]

func _spell_category_color(category: String) -> String:
	match category:
		"投射":
			return "#7dd3fc"
		"触发":
			return "#f9a8d4"
		"修饰":
			return "#fcd34d"
		"逻辑":
			return "#c4b5fd"
		"元素":
			return "#86efac"
		"源":
			return "#fca5a5"
		_:
			return "#e5e7eb"

func _spell_acquire_method(spell_id: String) -> String:
	if spell_id == "generator":
		return "新手阶段默认可用，属于基础构筑核心。"
	if spell_id.begins_with("trigger_"):
		return "通常在魔杖编程界面或法术解锁后获得。"
	if spell_id.begins_with("projectile_"):
		return "可通过探索、击败敌人掉落，或在魔法图鉴解锁后获得。"
	if spell_id.begins_with("modifier_"):
		return "多为通用修饰模块，随流程推进逐步解锁。"
	if spell_id.begins_with("element_"):
		return "通常作为元素类组件在中后期解锁。"
	if spell_id.begins_with("logic_"):
		return "属于逻辑模块，常在魔杖编程进阶阶段解锁。"
	return "通过探索、任务奖励或法术解锁流程获得。"

func _spell_effect_summary(spell_id: String, display_name: String) -> String:
	if spell_id == "generator":
		return "提供法术运行的起始节点，负责生成执行链的入口。"
	if spell_id in ["trigger_cast", "trigger_collision", "trigger_timer"]:
		if spell_id == "trigger_cast":
			return "在施放时触发后续链路，适合作为主动型法术的入口。"
		if spell_id == "trigger_collision":
			return "在命中或碰撞时触发，适合弹体接触后分裂、爆炸或附加效果。"
		return "在经过设定时间后触发，适合延迟爆发、持续效果或定时连锁。"
	if spell_id.begins_with("projectile_"):
		if spell_id == "projectile_slime":
			return "发射黏液类弹体，偏向控制与持续干扰。"
		if spell_id == "projectile_tnt":
			return "发射爆炸弹体，偏向范围伤害与破坏。"
		if spell_id == "projectile_blackhole":
			return "制造牵引或聚怪效果，适合控制战场位置。"
		if spell_id == "projectile_teleport":
			return "制造位移型效果，可用于快速转场或战术脱离。"
		if spell_id == "projectile_spark_bolt":
			return "基础轻型飞弹，消耗低，适合教学与早期战斗。"
		if spell_id == "projectile_magic_bolt":
			return "标准魔法飞弹，表现均衡，适合通用输出。"
		if spell_id == "projectile_bouncing_burst":
			return "可弹射的爆裂弹体，适合狭窄地形和连锁打击。"
		if spell_id == "projectile_tri_bolt":
			return "一次发射三连弹，提高命中率与覆盖面。"
		if spell_id == "projectile_chainsaw":
			return "高频近距切割型弹体，偏向贴身压制。"
		if spell_id == "projectile_vampire_bolt":
			return "具备吸血或回复倾向，适合续航型配置。"
		if spell_id == "projectile_healing_circle":
			return "生成治疗区域，为队友或自身提供回复。"
		return "生成具有该类型特性的弹体，主要决定法术的输出形式。"
	if spell_id.begins_with("modifier_"):
		if spell_id == "modifier_damage" or spell_id == "modifier_damage_plus":
			return "强化伤害输出，但通常伴随更高消耗或更慢节奏。"
		if spell_id == "modifier_pierce":
			return "提高穿透能力，可让弹体穿过多个目标。"
		if spell_id == "modifier_speed" or spell_id == "modifier_speed_plus":
			return "提升弹体速度，使命中更直接、飞行更迅速。"
		if spell_id == "modifier_delay":
			return "增加延迟或节奏控制，常用于构造分段触发。"
		if spell_id == "modifier_add_mana":
			return "增加法力投入，允许法术以更高代价换取更强表现。"
		if spell_id == "modifier_element_fire":
			return "为法术附加火焰属性，偏向爆发与持续灼烧。"
		if spell_id == "modifier_element_ice":
			return "为法术附加冰霜属性，偏向减速和控制。"
		if spell_id == "modifier_element_slime":
			return "附加黏液属性，偏向减速、黏连或环境干扰。"
		if spell_id == "modifier_orbit":
			return "让效果围绕施法者或目标旋转，适合防御型构筑。"
		if spell_id == "modifier_mana_to_damage":
			return "把更多法力转化为伤害，偏向高投入高收益。"
		return "修改法术核心参数，如伤害、速度、穿透或成本。"
	if spell_id.begins_with("element_"):
		if spell_id == "element_fire":
			return "附加火焰特性，适合灼烧和爆发伤害。"
		if spell_id == "element_ice":
			return "附加冰霜特性，适合减速和控场。"
		return "附加元素属性，让法术具备对应的环境和状态效果。"
	if spell_id.begins_with("logic_"):
		if spell_id == "logic_splitter":
			return "把一条执行链拆分为多条分支，适合多弹头和多效果。"
		if spell_id == "logic_sequence":
			return "按顺序执行多个节点，适合串联复杂逻辑。"
		return "控制法术执行结构与节点之间的顺序关系。"
	return "这是一项通用法术组件，具体效果取决于它在链路中的位置和组合方式。"

func _spell_category(spell_id: String) -> String:
	if spell_id.begins_with("projectile_"):
		return "投射"
	if spell_id.begins_with("trigger_"):
		return "触发"
	if spell_id.begins_with("modifier_"):
		return "修饰"
	if spell_id.begins_with("logic_"):
		return "逻辑"
	if spell_id.begins_with("element_"):
		return "元素"
	if spell_id == "generator":
		return "源"
	return "功能"

func _on_catalog_item_selected() -> void:
	if _syncing_tree_selection:
		return
	var item = catalog_tree.get_selected()
	if item == null:
		return
	var metadata = item.get_metadata(0)
	if metadata == null:
		return
	var index = int(metadata)
	if index >= 0 and index < _pages.size():
		_select_page(index)

func _select_page(index: int) -> void:
	if index < 0 or index >= _pages.size():
		return
	_current_page_index = index
	var page = _pages[index]
	page_path_label.text = page.get("path", "")
	page_title_label.text = page.get("title", "")
	page_content_label.text = page.get("content", "")

	var image: Texture2D = page.get("image", null)
	if image != null:
		page_image.texture = image
		page_image.show()
	else:
		page_image.texture = null
		page_image.hide()

	page_indicator.text = "第 %d / %d 页" % [index + 1, _pages.size()]
	prev_button.disabled = index <= 0
	next_button.disabled = index >= _pages.size() - 1

	_select_tree_item_by_page_index(index)
	_sync_web_guide_state()

func _select_tree_item_by_page_index(index: int) -> void:
	var root = catalog_tree.get_root()
	if root == null:
		return
	_syncing_tree_selection = true
	var stack: Array[TreeItem] = [root]
	while not stack.is_empty():
		var current = stack.pop_back()
		if current.get_metadata(0) != null and int(current.get_metadata(0)) == index:
			current.select(0)
			catalog_tree.ensure_cursor_is_visible()
			_syncing_tree_selection = false
			return
		var child = current.get_first_child()
		while child != null:
			stack.append(child)
			child = child.get_next()
	_syncing_tree_selection = false

func _on_prev_pressed() -> void:
	if _current_page_index > 0:
		_select_page(_current_page_index - 1)

func _on_next_pressed() -> void:
	if _current_page_index >= 0 and _current_page_index < _pages.size() - 1:
		_select_page(_current_page_index + 1)

func open() -> void:
	## Open the guide window and pause the game
	if is_open:
		return
	
	is_open = true
	if _using_web_shell:
		_ensure_web_shell_instance()
	_build_catalog_and_pages()
	show()
	if _using_web_shell:
		_set_native_shell_visible(false)
		_set_web_shell_visible(true)
		if _web_bridge_ready:
			call_deferred("_sync_web_guide_state")
	_pause_game()
	_animate_in()

func close() -> void:
	## Close the guide window and unpause the game
	if not is_open:
		return
	
	is_open = false
	if _using_web_shell:
		_release_web_shell_focus()
		_set_web_shell_visible(false)
		_destroy_web_shell_instance()
	_animate_out()
	_unpause_game()
	hide()

func _pause_game() -> void:
	## Pause the game tree
	get_tree().paused = true

func _unpause_game() -> void:
	## Resume the game tree
	get_tree().paused = false

func _animate_in() -> void:
	## Fade in animation
	background_overlay.modulate.a = 0.0
	window_container.modulate.a = 0.0
	
	var tween = create_tween()
	tween.parallel().tween_property(background_overlay, "modulate:a", 1.0, 0.3)
	tween.tween_property(window_container, "modulate:a", 1.0, 0.3)

func _animate_out() -> void:
	## Fade out animation
	var tween = create_tween()
	tween.parallel().tween_property(background_overlay, "modulate:a", 0.0, 0.2)
	tween.tween_property(window_container, "modulate:a", 0.0, 0.2)

func _on_close_pressed() -> void:
	close()

func _input(event: InputEvent) -> void:
	## Close guide on ESC key and support book-like keyboard page flips
	if is_open and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_tree().root.set_input_as_handled()
		return

	if not is_open:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_LEFT:
			_on_prev_pressed()
			get_tree().root.set_input_as_handled()
		elif event.keycode == KEY_RIGHT:
			_on_next_pressed()
			get_tree().root.set_input_as_handled()

func _on_visibility_changed() -> void:
	if not visible:
		if _using_web_shell:
			_set_web_shell_visible(false)
			_release_web_shell_focus()
		return

	if not _using_web_shell:
		_set_native_shell_visible(true)
		return

	_ensure_web_shell_instance()
	if is_instance_valid(_web_shell_node):
		_set_native_shell_visible(false)
		_set_web_shell_visible(true)
		if _web_bridge_ready:
			call_deferred("_sync_web_guide_state")
	else:
		_set_native_shell_visible(true)

func _ensure_web_shell_instance() -> void:
	if is_instance_valid(_web_shell_node):
		return

	_web_bridge_ready = false
	_web_ready_watchdog_started = false
	if _try_setup_web_guide_shell():
		_start_web_ready_watchdog()
		return

	_using_web_shell = false
	_set_native_shell_visible(true)

func _release_web_shell_focus() -> void:
	if is_instance_valid(_web_shell_node) and _web_shell_node.has_method("set_forward_input_events"):
		_web_shell_node.call("set_forward_input_events", false)

	if is_instance_valid(_web_shell_node) and _web_shell_node.has_method("focus_parent"):
		_web_shell_node.call("focus_parent")

	if is_instance_valid(_web_shell_node) and _web_shell_node is Control:
		var webview_control := _web_shell_node as Control
		if webview_control.has_focus():
			webview_control.release_focus()

	var viewport := get_viewport()
	if viewport:
		viewport.gui_release_focus()

func _destroy_web_shell_instance() -> void:
	if is_instance_valid(_web_shell_node):
		_web_shell_node.queue_free()
	_web_shell_node = null
	_web_bridge_ready = false
	_web_ready_watchdog_started = false

func _try_setup_web_guide_shell() -> bool:
	var webview_url := _resolve_webview_url(WEB_SHELL_RESOURCE_PATH, "GameplayGuideWindow")
	if webview_url == "":
		return false

	if not ClassDB.class_exists("WebView"):
		push_warning("GameplayGuideWindow: WebView class unavailable. Check godot-wry plugin enabled, exported addons/godot_wry runtime files, WebView2 runtime, and VC++ x64 redistributable; using native fallback.")
		return false

	var candidate: Object = ClassDB.instantiate("WebView")
	if candidate == null or not (candidate is Node):
		push_warning("GameplayGuideWindow: Failed to instantiate WebView, using native fallback.")
		return false

	var webview := candidate as Node
	if webview is Control:
		var webview_control := webview as Control
		webview_control.set_anchors_preset(Control.PRESET_FULL_RECT)
		webview_control.mouse_filter = Control.MOUSE_FILTER_STOP

	if _has_property(candidate, &"full_window_size"):
		candidate.set(&"full_window_size", false)
	if _has_property(candidate, &"url"):
		candidate.set(&"url", webview_url)
	if webview.has_method("set_focused_when_created"):
		webview.call("set_focused_when_created", false)
	if webview.has_method("set_forward_input_events"):
		webview.call("set_forward_input_events", false)

	if webview.has_signal("ipc_message"):
		webview.connect("ipc_message", Callable(self, "_on_guide_web_ipc_message"))

	add_child(webview)
	move_child(webview, get_child_count() - 1)

	if webview.has_method("load_url"):
		webview.call("load_url", webview_url)

	_web_shell_node = webview
	return true

func _has_property(instance: Object, property_name: StringName) -> bool:
	for entry in instance.get_property_list():
		if StringName(entry.name) == property_name:
			return true
	return false

func _resolve_webview_url(resource_path: String, owner_tag: String) -> String:
	var relative_path := resource_path
	if relative_path.begins_with("res://"):
		relative_path = relative_path.substr(6, relative_path.length() - 6)

	var res_path := "res://" + relative_path
	if FileAccess.file_exists(res_path):
		return res_path

	if FileAccess.file_exists(relative_path):
		return relative_path

	push_warning("%s: Web shell HTML missing at %s (check export include_filter includes ui/web/gameplay_guide_shell/index.html), using native fallback." % [owner_tag, res_path])
	return ""

func _set_native_shell_visible(make_visible: bool) -> void:
	if background_overlay:
		background_overlay.visible = make_visible
	if window_container:
		window_container.visible = make_visible

func _set_web_shell_visible(make_visible: bool) -> void:
	if not is_instance_valid(_web_shell_node):
		return

	if _web_shell_node.has_method("set_forward_input_events"):
		_web_shell_node.call("set_forward_input_events", make_visible)

	if not make_visible and _web_shell_node.has_method("focus_parent"):
		_web_shell_node.call("focus_parent")

	if _web_shell_node.has_method("set_visible"):
		_web_shell_node.call("set_visible", make_visible)
		return

	if _web_shell_node is CanvasItem:
		(_web_shell_node as CanvasItem).visible = make_visible
		return

	if make_visible:
		if _web_shell_node.has_method("show"):
			_web_shell_node.call("show")
	else:
		if _web_shell_node.has_method("hide"):
			_web_shell_node.call("hide")

func _on_guide_web_ipc_message(message: String) -> void:
	var data := _normalize_web_payload(message)
	if data.is_empty():
		return

	var msg_type := String(data.get("type", ""))
	match msg_type:
		"guide_ready":
			_web_bridge_ready = true
			_set_native_shell_visible(false)
			_set_web_shell_visible(true)
			_sync_web_guide_state()
		"guide_request_state":
			if not _web_bridge_ready:
				_web_bridge_ready = true
				_set_native_shell_visible(false)
				_set_web_shell_visible(true)
			_sync_web_guide_state()
		"guide_select_page":
			var index := int(data.get("index", -1))
			if index >= 0 and index < _pages.size():
				_select_page(index)
		"guide_prev_page":
			_on_prev_pressed()
		"guide_next_page":
			_on_next_pressed()
		"guide_close":
			close()
		"guide_bridge_error":
			_activate_native_fallback("Shell reported a runtime bridge error.")

func _normalize_web_payload(raw_message: String) -> Dictionary:
	var payload: Variant = JSON.parse_string(raw_message)
	for _i in range(6):
		if typeof(payload) == TYPE_STRING:
			payload = JSON.parse_string(String(payload))
			continue

		if typeof(payload) != TYPE_DICTIONARY:
			return {}

		var data: Dictionary = payload
		if data.has("type"):
			return data

		if data.has("raw_payload") and typeof(data.get("raw_payload")) == TYPE_STRING:
			payload = JSON.parse_string(String(data.get("raw_payload", "")))
			continue

		var stepped := false
		for key in ["detail", "data", "payload", "message"]:
			if data.has(key):
				payload = data.get(key)
				stepped = true
				break

		if stepped:
			continue

		return data

	return {}

func _sync_web_guide_state() -> void:
	if not _using_web_shell:
		return
	if not is_instance_valid(_web_shell_node):
		return
	if not _web_bridge_ready:
		return
	if not _web_shell_node.has_method("post_message"):
		_activate_native_fallback("Web shell post_message is unavailable.")
		return

	_web_shell_node.call("post_message", JSON.stringify(_build_web_guide_payload()))

func _build_web_guide_payload() -> Dictionary:
	var pages_payload: Array = []
	for i in range(_pages.size()):
		var page := _pages[i]
		var image_tex: Texture2D = page.get("image", null)
		pages_payload.append({
			"index": i,
			"title": String(page.get("title", "")),
			"path": String(page.get("path", "")),
			"content": String(page.get("content", "")),
			"image_data_url": _texture_to_data_url(image_tex)
		})

	var title_text := "游戏引导"
	var header_title = get_node_or_null("WindowContainer/PanelContainer/VBoxContainer/HeaderHBoxContainer/TitleLabel")
	if header_title and header_title is Label:
		title_text = String((header_title as Label).text)

	return {
		"type": "guide_state",
		"protocol": WEB_PROTOCOL_VERSION,
		"title": title_text,
		"current_page_index": _current_page_index,
		"total_pages": _pages.size(),
		"pages": pages_payload,
		"catalog": _build_catalog_snapshot(),
		"texts": {
			"close": String(close_button.text),
			"prev": String(prev_button.text),
			"next": String(next_button.text)
		}
	}

func _build_catalog_snapshot() -> Array:
	var root = catalog_tree.get_root()
	if root == null:
		return []

	var result: Array = []
	var child = root.get_first_child()
	while child != null:
		result.append(_serialize_catalog_item(child))
		child = child.get_next()

	return result

func _serialize_catalog_item(item: TreeItem) -> Dictionary:
	var children: Array = []
	var child = item.get_first_child()
	while child != null:
		children.append(_serialize_catalog_item(child))
		child = child.get_next()

	var metadata = item.get_metadata(0)
	var page_index := -1
	if metadata != null:
		page_index = int(metadata)

	return {
		"text": item.get_text(0),
		"page_index": page_index,
		"selectable": item.is_selectable(0),
		"collapsed": item.collapsed,
		"children": children
	}

func _start_web_ready_watchdog() -> void:
	if _web_ready_watchdog_started:
		return
	_web_ready_watchdog_started = true
	var timer := get_tree().create_timer(WEB_READY_WATCHDOG_SECONDS)
	timer.timeout.connect(func() -> void:
		_web_ready_watchdog_started = false
		if _using_web_shell and not _web_bridge_ready:
			_activate_native_fallback("Web shell bridge did not become ready in %.1fs." % WEB_READY_WATCHDOG_SECONDS)
	)

func _activate_native_fallback(reason: String) -> void:
	push_warning("GameplayGuideWindow: %s Falling back to native guide window." % reason)
	_using_web_shell = false
	_release_web_shell_focus()
	_destroy_web_shell_instance()
	_set_native_shell_visible(true)

func _texture_to_data_url(texture: Texture2D) -> String:
	if texture == null:
		return ""

	var cache_key := texture.resource_path
	if cache_key.is_empty():
		cache_key = str(texture.get_instance_id())

	if _web_icon_cache.has(cache_key):
		return String(_web_icon_cache[cache_key])

	var image := _extract_texture_image(texture)
	if image == null or image.is_empty():
		return ""

	var png_bytes := image.save_png_to_buffer()
	if png_bytes.is_empty():
		return ""

	var data_url := "data:image/png;base64,%s" % Marshalls.raw_to_base64(png_bytes)
	_web_icon_cache[cache_key] = data_url
	return data_url

func _extract_texture_image(texture: Texture2D) -> Image:
	if texture is AtlasTexture:
		var atlas_texture := texture as AtlasTexture
		if atlas_texture.atlas == null:
			return null
		var atlas_image := atlas_texture.atlas.get_image()
		if atlas_image == null or atlas_image.is_empty():
			return null

		var region := atlas_texture.region
		var region_rect := Rect2i(
			maxi(int(region.position.x), 0),
			maxi(int(region.position.y), 0),
			maxi(int(region.size.x), 0),
			maxi(int(region.size.y), 0)
		)

		if region_rect.size.x <= 0 or region_rect.size.y <= 0:
			return atlas_image

		region_rect.size.x = mini(region_rect.size.x, atlas_image.get_width() - region_rect.position.x)
		region_rect.size.y = mini(region_rect.size.y, atlas_image.get_height() - region_rect.position.y)
		if region_rect.size.x <= 0 or region_rect.size.y <= 0:
			return null

		return atlas_image.get_region(region_rect)

	return texture.get_image()

func _exit_tree() -> void:
	_release_web_shell_focus()
	_destroy_web_shell_instance()
