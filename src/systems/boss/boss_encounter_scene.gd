extends Node2D
class_name BossEncounterScene

signal encounter_completed(success: bool, reward_core_id: String, encounter_id: String)
signal encounter_phase_visual_event(encounter_id: String, phase: int)

const MAX_COMPACT_ROOM_WIDTH := 1400.0
const MAX_COMPACT_ROOM_HEIGHT := 700.0
const MIN_THEME_CONTRAST_DELTA := 0.14
const REQUIRED_VISUAL_LAYER_NODE_PATHS := [
	"Background/FarLayer",
	"Background/MidLayer",
	"Background/ForeLayer",
]
const DEFAULT_VISUAL_BUDGET_LIMITS := {
	"optional_ambience_nodes": 8,
	"gate_motion_fps": 12,
}
const REQUIRED_BASELINE_NODE_PATHS := [
	"Arena",
	"Background",
	"Gates",
	"PlayerSpawn",
	"BossSpawn",
	"IntroFocus",
	"Arena/Floor/CollisionShape2D",
	"Arena/Ceiling/CollisionShape2D",
	"Arena/LeftWall/CollisionShape2D",
	"Arena/RightWall/CollisionShape2D",
	"Gates/LeftGate/CollisionShape2D",
	"Gates/RightGate/CollisionShape2D",
]

@export var encounter_id: String = ""
@export var encounter_title: String = "Boss Encounter"
@export var reward_core_id: String = ""
@export var boss_scene: PackedScene
@export var is_finale: bool = false
@export var theme_primary_color: Color = Color(0.12, 0.14, 0.2, 0.95)
@export var theme_accent_color: Color = Color(0.95, 0.36, 0.36, 0.94)
@export var theme_fog_intensity: float = 0.34
@export var theme_particle_profile: String = "dust"
@export var gate_pulse_speed: float = 2.4
@export var gate_pulse_scale: float = 0.06

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var intro_focus: Marker2D = $IntroFocus
@onready var boss_spawn: Marker2D = $BossSpawn
@onready var gate_left_shape: CollisionShape2D = $Gates/LeftGate/CollisionShape2D
@onready var gate_right_shape: CollisionShape2D = $Gates/RightGate/CollisionShape2D
@onready var gate_left_visual: CanvasItem = $Gates/LeftGate/Visual
@onready var gate_right_visual: CanvasItem = $Gates/RightGate/Visual
@onready var gate_left_glow: CanvasItem = $Gates/LeftGate.get_node_or_null("Glow")
@onready var gate_right_glow: CanvasItem = $Gates/RightGate.get_node_or_null("Glow")

var _boss: Node = null
var _player: Node2D = null
var _entry_snapshot: Dictionary = {}
var _combat_started: bool = false
var _gate_pulse_time: float = 0.0
var _gate_locked_visual: bool = true
var _gate_motion_enabled: bool = true
var _ambient_motion_time: float = 0.0
var _visual_budget_mode: String = "normal"
var _ambience_optional_nodes: Array[CanvasItem] = []
var _atmosphere_drift_nodes: Array[Node2D] = []

func _ready() -> void:
	_collect_optional_ambience_nodes()
	_apply_theme_to_background_layers()
	_apply_gate_visual_state(true, false)

func _process(delta: float) -> void:
	_ambient_motion_time += delta
	if _gate_locked_visual and _gate_motion_enabled:
		_gate_pulse_time += delta * gate_pulse_speed
		var pulse := 1.0 + sin(_gate_pulse_time) * gate_pulse_scale
		if gate_left_visual:
			gate_left_visual.scale = Vector2(1.0, pulse)
		if gate_right_visual:
			gate_right_visual.scale = Vector2(1.0, pulse)
		if gate_left_glow:
			gate_left_glow.modulate.a = clampf(0.52 + 0.22 * absf(sin(_gate_pulse_time * 1.3)), 0.0, 1.0)
		if gate_right_glow:
			gate_right_glow.modulate.a = clampf(0.52 + 0.22 * absf(sin(_gate_pulse_time * 1.3)), 0.0, 1.0)
	else:
		if gate_left_visual:
			gate_left_visual.scale = Vector2.ONE
		if gate_right_visual:
			gate_right_visual.scale = Vector2.ONE

	for i in range(_atmosphere_drift_nodes.size()):
		var drift_node := _atmosphere_drift_nodes[i]
		if drift_node == null or not is_instance_valid(drift_node):
			continue
		var phase_offset := float(i) * 0.85
		drift_node.position.y = sin(_ambient_motion_time * 0.75 + phase_offset) * (3.0 + theme_fog_intensity * 5.0)
		drift_node.position.x = cos(_ambient_motion_time * 0.55 + phase_offset) * 2.0

func setup(player: Node2D, snapshot: Dictionary) -> void:
	_player = player
	_entry_snapshot = snapshot.duplicate(true)

func get_player_spawn_global() -> Vector2:
	return player_spawn.global_position

func get_intro_focus_global() -> Vector2:
	return intro_focus.global_position

func get_visual_theme_tokens() -> Dictionary:
	return {
		"primary_color": theme_primary_color,
		"accent_color": theme_accent_color,
		"fog_intensity": theme_fog_intensity,
		"particle_profile": theme_particle_profile,
	}

func get_visual_budget_limits() -> Dictionary:
	return DEFAULT_VISUAL_BUDGET_LIMITS.duplicate(true)

func set_visual_budget_mode(mode: String) -> void:
	_visual_budget_mode = mode
	var reduce_ambience := (mode == "low" or mode == "critical")
	for node in _ambience_optional_nodes:
		if node == null or not is_instance_valid(node):
			continue
		if node == gate_left_glow or node == gate_right_glow:
			continue
		node.visible = not reduce_ambience
	_gate_motion_enabled = mode != "critical"

func lock_gates(locked: bool) -> void:
	if gate_left_shape:
		gate_left_shape.disabled = not locked
	if gate_right_shape:
		gate_right_shape.disabled = not locked
	_apply_gate_visual_state(locked, true)

func begin_encounter() -> void:
	if _combat_started:
		return
	_combat_started = true
	lock_gates(true)
	_spawn_boss()

func activate_combat() -> void:
	if _boss and is_instance_valid(_boss) and _boss.has_method("activate_combat"):
		_boss.activate_combat()

func get_active_boss() -> Node:
	if _boss and is_instance_valid(_boss):
		return _boss
	return null

func on_player_defeated() -> void:
	if not _combat_started:
		return
	emit_signal("encounter_completed", false, reward_core_id, encounter_id)

func validate_tutorial_style_baseline() -> bool:
	if not _has_required_baseline_nodes():
		return false
	if not validate_visual_fidelity_baseline():
		return false
	if not validate_combat_readability_baseline():
		return false
	var room_size := get_compact_room_size()
	if room_size.x <= 0.0 or room_size.y <= 0.0:
		return false
	if room_size.x > MAX_COMPACT_ROOM_WIDTH or room_size.y > MAX_COMPACT_ROOM_HEIGHT:
		return false
	return validate_streaming_isolation()

func validate_visual_fidelity_baseline() -> bool:
	for node_path in REQUIRED_VISUAL_LAYER_NODE_PATHS:
		if not has_node(node_path):
			return false
	if theme_fog_intensity < 0.0 or theme_fog_intensity > 1.0:
		return false
	if String(theme_particle_profile).strip_edges().is_empty():
		return false
	return true

func validate_combat_readability_baseline() -> bool:
	var contrast_delta := absf(_get_luminance(theme_accent_color) - _get_luminance(theme_primary_color))
	return contrast_delta >= MIN_THEME_CONTRAST_DELTA

func validate_streaming_isolation() -> bool:
	# Boss encounter scenes should not depend on world streaming/chunk runtime.
	return not _has_streaming_like_nodes(self)

func get_compact_room_size() -> Vector2:
	var floor_shape_node: CollisionShape2D = get_node_or_null("Arena/Floor/CollisionShape2D")
	var ceiling_shape_node: CollisionShape2D = get_node_or_null("Arena/Ceiling/CollisionShape2D")
	var left_wall_shape_node: CollisionShape2D = get_node_or_null("Arena/LeftWall/CollisionShape2D")
	var right_wall_shape_node: CollisionShape2D = get_node_or_null("Arena/RightWall/CollisionShape2D")
	if floor_shape_node == null or ceiling_shape_node == null or left_wall_shape_node == null or right_wall_shape_node == null:
		return Vector2.ZERO

	var floor_shape := floor_shape_node.shape as RectangleShape2D
	var ceiling_shape := ceiling_shape_node.shape as RectangleShape2D
	var left_wall_shape := left_wall_shape_node.shape as RectangleShape2D
	var right_wall_shape := right_wall_shape_node.shape as RectangleShape2D
	if floor_shape == null or ceiling_shape == null or left_wall_shape == null or right_wall_shape == null:
		return Vector2.ZERO

	var left_bound := left_wall_shape_node.position.x - (left_wall_shape.size.x * 0.5)
	var right_bound := right_wall_shape_node.position.x + (right_wall_shape.size.x * 0.5)
	var top_bound := ceiling_shape_node.position.y - (ceiling_shape.size.y * 0.5)
	var bottom_bound := floor_shape_node.position.y + (floor_shape.size.y * 0.5)
	return Vector2(absf(right_bound - left_bound), absf(bottom_bound - top_bound))

func _has_required_baseline_nodes() -> bool:
	for node_path in REQUIRED_BASELINE_NODE_PATHS:
		if not has_node(node_path):
			return false
	return true

func _has_streaming_like_nodes(root: Node) -> bool:
	for child in root.get_children():
		var child_name := String(child.name).to_lower()
		if child_name.find("stream") != -1 or child_name.find("chunk") != -1:
			return true
		var child_script = child.get_script()
		if child_script is Script:
			var script_path := String(child_script.resource_path).to_lower()
			if script_path.find("stream") != -1 or script_path.find("chunk") != -1:
				return true
		if _has_streaming_like_nodes(child):
			return true
	return false

func _spawn_boss() -> void:
	if boss_scene == null:
		push_warning("BossEncounterScene: boss_scene is missing for encounter %s" % encounter_id)
		emit_signal("encounter_completed", false, reward_core_id, encounter_id)
		return

	_boss = boss_scene.instantiate()
	if _boss == null:
		emit_signal("encounter_completed", false, reward_core_id, encounter_id)
		return

	add_child(_boss)
	# Set world position after parenting to avoid double-transform offsets.
	if _boss is Node2D:
		(_boss as Node2D).global_position = boss_spawn.global_position
		if is_finale and _player and is_instance_valid(_player):
			(_boss as Node2D).global_scale = _player.global_scale

	if _boss.has_method("set_player"):
		_boss.set_player(_player)

	if is_finale and _boss.has_method("apply_player_snapshot"):
		var health_snapshot := float(_entry_snapshot.get("player_health", 180.0))
		var wand_snapshot: Variant = _entry_snapshot.get("wand_item_snapshot", null)
		if wand_snapshot == null:
			wand_snapshot = _entry_snapshot.get("wand_data_snapshot", null)
		if wand_snapshot == null and _player and _player.get("current_wand") != null:
			var live_wand = _player.get("current_wand")
			if live_wand is WandData:
				wand_snapshot = (live_wand as WandData).duplicate(true)
		_boss.apply_player_snapshot(health_snapshot, wand_snapshot)

	if _boss.has_signal("boss_defeated"):
		_boss.boss_defeated.connect(_on_boss_defeated)
	if _boss.has_signal("phase_changed"):
		_boss.phase_changed.connect(_on_boss_phase_changed)

func _collect_optional_ambience_nodes() -> void:
	_ambience_optional_nodes.clear()
	_atmosphere_drift_nodes.clear()
	for candidate in get_tree().get_nodes_in_group("encounter_ambience_optional"):
		if candidate == null or not is_instance_valid(candidate):
			continue
		if not (candidate is Node):
			continue
		var candidate_node := candidate as Node
		if candidate_node == self or not is_ancestor_of(candidate_node):
			continue
		if candidate is CanvasItem:
			_ambience_optional_nodes.append(candidate)
		if candidate is Node2D and String(candidate_node.name).to_lower().find("drift") != -1:
			_atmosphere_drift_nodes.append(candidate)

func _apply_theme_to_background_layers() -> void:
	var far_layer := get_node_or_null("Background/FarLayer") as CanvasItem
	var mid_layer := get_node_or_null("Background/MidLayer") as CanvasItem
	var fore_layer := get_node_or_null("Background/ForeLayer") as CanvasItem
	if far_layer:
		far_layer.modulate = theme_primary_color.darkened(0.1)
	if mid_layer:
		mid_layer.modulate = theme_primary_color
	if fore_layer:
		fore_layer.modulate = theme_primary_color.lightened(clampf(theme_fog_intensity * 0.32, 0.0, 0.3))

func _apply_gate_visual_state(locked: bool, animated: bool) -> void:
	_gate_locked_visual = locked
	var target_visual_color := theme_accent_color if locked else theme_primary_color.lightened(0.45)
	target_visual_color.a = 0.92 if locked else 0.76
	var target_glow_color := target_visual_color.lightened(0.4)
	target_glow_color.a = 0.62 if locked else 0.34

	if animated:
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)
		if gate_left_visual:
			tween.tween_property(gate_left_visual, "modulate", target_visual_color, 0.22)
		if gate_right_visual:
			tween.parallel().tween_property(gate_right_visual, "modulate", target_visual_color, 0.22)
		if gate_left_glow:
			tween.parallel().tween_property(gate_left_glow, "modulate", target_glow_color, 0.24)
		if gate_right_glow:
			tween.parallel().tween_property(gate_right_glow, "modulate", target_glow_color, 0.24)
	else:
		if gate_left_visual:
			gate_left_visual.modulate = target_visual_color
		if gate_right_visual:
			gate_right_visual.modulate = target_visual_color
		if gate_left_glow:
			gate_left_glow.modulate = target_glow_color
		if gate_right_glow:
			gate_right_glow.modulate = target_glow_color

	if not locked:
		_gate_pulse_time = 0.0

func _on_boss_phase_changed(new_phase: int) -> void:
	emit_signal("encounter_phase_visual_event", encounter_id, int(new_phase))
	var mid_layer := get_node_or_null("Background/MidLayer") as CanvasItem
	if mid_layer:
		var flash_color := theme_accent_color.lightened(0.55)
		flash_color.a = 0.95
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(mid_layer, "modulate", flash_color, 0.12)
		tween.tween_property(mid_layer, "modulate", theme_primary_color, 0.26)
	if UIManager:
		var phase_text := tr("MSG_BOSS_PHASE_CHANGE")
		if phase_text == "MSG_BOSS_PHASE_CHANGE":
			phase_text = "Boss phase %d" % int(new_phase)
		UIManager.show_floating_text(phase_text, boss_spawn.global_position + Vector2(0, -46), theme_accent_color.lightened(0.25))

func _get_luminance(color: Color) -> float:
	return color.r * 0.299 + color.g * 0.587 + color.b * 0.114

func _on_boss_defeated(_boss_id: String) -> void:
	lock_gates(false)
	emit_signal("encounter_completed", true, reward_core_id, encounter_id)
