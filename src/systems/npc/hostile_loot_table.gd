extends RefCounted
class_name HostileLootTable

const LOOT_TABLE_PATH := "res://data/npcs/hostile_loot_table.json"

static var _loaded: bool = false
static var _cache: Dictionary = {}

static func resolve_rolls(rule_id: String, monster_type: String) -> Array[Dictionary]:
	_ensure_loaded()
	if _cache.is_empty():
		return []

	var entry := _resolve_entry(rule_id, monster_type)
	if entry.is_empty():
		entry = _cache.get("global_fallback", {})

	return _roll_entry(entry)

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true

	if not FileAccess.file_exists(LOOT_TABLE_PATH):
		_cache = {}
		return

	var file := FileAccess.open(LOOT_TABLE_PATH, FileAccess.READ)
	if file == null:
		_cache = {}
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_cache = parsed
	else:
		_cache = {}

static func _resolve_entry(rule_id: String, monster_type: String) -> Dictionary:
	var overrides: Dictionary = _cache.get("rule_overrides", {})
	if not rule_id.is_empty() and overrides.has(rule_id):
		return overrides[rule_id]

	var defaults: Dictionary = _cache.get("monster_type_defaults", {})
	if not monster_type.is_empty() and defaults.has(monster_type):
		return defaults[monster_type]

	return {}

static func _roll_entry(entry: Dictionary) -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	if entry.is_empty():
		return drops

	var signature: Dictionary = entry.get("signature_drop", {})
	if not signature.is_empty():
		var qty := _roll_qty(signature)
		if qty > 0:
			drops.append({"item_id": String(signature.get("item_id", "")), "count": qty})

	var common_pool: Array = entry.get("common_pool", [])
	for common_var in common_pool:
		if not (common_var is Dictionary):
			continue
		var common: Dictionary = common_var
		var qty := _roll_qty(common)
		if qty > 0:
			drops.append({"item_id": String(common.get("item_id", "")), "count": qty})

	return drops

static func _roll_qty(drop_entry: Dictionary) -> int:
	var item_id := String(drop_entry.get("item_id", "")).strip_edges()
	if item_id.is_empty():
		return 0

	var chance := clampf(float(drop_entry.get("chance", 0.0)), 0.0, 1.0)
	if chance <= 0.0 or randf() > chance:
		return 0

	var min_qty := maxi(1, int(drop_entry.get("min_qty", 1)))
	var max_qty := maxi(min_qty, int(drop_entry.get("max_qty", min_qty)))
	return randi_range(min_qty, max_qty)
