extends BossBase

const SPELL_SPAWN_OFFSET := Vector2(0, -18)
const WAND_PIVOT_OFFSET := Vector2(0, -12)
const WAND_MUZZLE_OFFSET := Vector2(48, 0)
const CONTROL_EFFECT_DURATION := 10.0
const CONTROL_WINDOW_INTERVAL := 4.2
const CONTROL_MECHANIC_COOLDOWN := 9.0
const PERIODIC_INVULNERABLE_INTERVAL := 10.0
const PERIODIC_INVULNERABLE_DURATION := 2.2
const THRESHOLD_INVULNERABLE_DURATION := 3.0
const PROJECTILE_DEVOUR_RADIUS := 132.0
const DEVOUR_DAMAGE_STEP := 0.01
const DEVOUR_DAMAGE_CAP := 3.0

var _attack_timer: float = 0.7
var _snapshot_wand: Variant = null
var _snapshot_wand_data: WandData = null
var _last_cast_direction: Vector2 = Vector2.RIGHT
var _fallback_attack_interval: float = 0.72
var _warned_missing_wand_snapshot: bool = false
var _wand_pivot: Marker2D = null
var _wand_sprite: Sprite2D = null
var _wand_muzzle: Marker2D = null
var _control_window_timer: float = CONTROL_WINDOW_INTERVAL
var _periodic_invulnerable_timer: float = PERIODIC_INVULNERABLE_INTERVAL
var _invulnerable_remaining: float = 0.0
var _devour_damage_multiplier: float = 1.0
var _devoured_projectile_count: int = 0
var _next_health_threshold_ratio: float = 0.8
var _mechanic_cooldowns := {
	"swap": 0.0,
	"angina": 0.0,
	"projectile_lock": 0.0,
	"input_inversion": 0.0,
	"gravity_flip": 0.0,
}
var _devour_feedback_cooldown: float = 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	boss_id = "mina_finale"
	display_name = "Mina"
	max_health = 420.0
	move_speed = 118.0
	contact_damage = 18.0
	phase_two_threshold = 0.45
	super._ready()
	_rng.randomize()
	_setup_wand_visual()

func _process(delta: float) -> void:
	if _snapshot_wand_data:
		_snapshot_wand_data.update_mana(delta)
	_update_encounter_mechanics(delta)
	_sync_wand_visual_transform()

func apply_player_snapshot(player_health: float, wand_item: Resource) -> void:
	max_health = clampf(player_health, 120.0, 560.0)
	current_health = max_health
	_snapshot_wand = wand_item.duplicate(true) if wand_item else null
	_snapshot_wand_data = _resolve_snapshot_wand_data(_snapshot_wand)
	_fallback_attack_interval = 0.72
	_warned_missing_wand_snapshot = false
	_control_window_timer = CONTROL_WINDOW_INTERVAL
	_periodic_invulnerable_timer = PERIODIC_INVULNERABLE_INTERVAL
	_invulnerable_remaining = 0.0
	_devour_damage_multiplier = 1.0
	_devoured_projectile_count = 0
	_next_health_threshold_ratio = 0.8
	for key in _mechanic_cooldowns.keys():
		_mechanic_cooldowns[key] = 0.0
	_devour_feedback_cooldown = 0.0

	if _snapshot_wand_data and _snapshot_wand_data.embryo:
		var recharge = float(_snapshot_wand_data.embryo.get("recharge_time"))
		if recharge > 0.01:
			_fallback_attack_interval = clampf(recharge * 1.35, 0.3, 1.05)

	_update_wand_visual_from_snapshot()

func get_spell_spawn_transform() -> Dictionary:
	return {
		"position": _get_spell_spawn_position(_last_cast_direction),
		"direction": _last_cast_direction,
	}

func _process_attack(delta: float) -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	if not combat_active:
		return
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return

	var aim := (player_ref.global_position - global_position).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT
	_last_cast_direction = aim
	if _wand_pivot:
		_wand_pivot.rotation = aim.angle()

	if _snapshot_wand_data == null:
		_attempt_recover_wand_snapshot_from_player()

	if _snapshot_wand_data:
		var cast_position := _get_spell_spawn_position(aim)
		var total_cooldown := SpellProcessor.cast_spell(_snapshot_wand_data, self, aim, cast_position)
		if total_cooldown > 0.0:
			_attack_timer = maxf(0.08, total_cooldown)
			if phase >= 2:
				velocity.x = signf(aim.x) * move_speed * 1.8
		else:
			# Keep Mina on the wand pipeline: if this frame can't cast due cooldown/mana, retry shortly.
			_attack_timer = 0.08
		return

	# Hard constraint: Mina must use player's wand pipeline and should not fire boss-native projectiles.
	if not _warned_missing_wand_snapshot:
		_warned_missing_wand_snapshot = true
		push_warning("MinaFinale: missing wand snapshot, wand-only attack is temporarily disabled")
	_attack_timer = maxf(0.18, _fallback_attack_interval)

func take_damage(amount: float, damage_type: String = "physical", source: Node = null) -> void:
	if _is_invulnerable():
		if UIManager:
			UIManager.show_floating_text("Immune", global_position + Vector2(0, -36), Color(0.9, 0.92, 1.0))
		return
	super.take_damage(amount, damage_type, source)

func get_combat_damage_multiplier() -> float:
	return _devour_damage_multiplier

func _is_invulnerable() -> bool:
	return _invulnerable_remaining > 0.0

func _activate_invulnerable_window(duration: float, source: String = "") -> void:
	var was_invulnerable := _invulnerable_remaining > 0.0
	_invulnerable_remaining = maxf(_invulnerable_remaining, duration)
	if not was_invulnerable and UIManager:
		var tag := "吞噬防护"
		if source == "threshold":
			tag = "阈值防护"
		UIManager.show_floating_text(tag, global_position + Vector2(0, -52), Color(0.85, 0.93, 1.0))

func _update_encounter_mechanics(delta: float) -> void:
	if not combat_active:
		return

	_control_window_timer = maxf(0.0, _control_window_timer - delta)
	_periodic_invulnerable_timer -= delta
	if _devour_feedback_cooldown > 0.0:
		_devour_feedback_cooldown = maxf(0.0, _devour_feedback_cooldown - delta)
	for key in _mechanic_cooldowns.keys():
		_mechanic_cooldowns[key] = maxf(0.0, float(_mechanic_cooldowns.get(key, 0.0)) - delta)
	if _periodic_invulnerable_timer <= 0.0:
		while _periodic_invulnerable_timer <= 0.0:
			_periodic_invulnerable_timer += PERIODIC_INVULNERABLE_INTERVAL
		_activate_invulnerable_window(PERIODIC_INVULNERABLE_DURATION, "periodic")

	if _invulnerable_remaining > 0.0:
		_invulnerable_remaining = maxf(0.0, _invulnerable_remaining - delta)
		_devour_projectiles_in_range()

	_process_health_threshold_effects()

	if _control_window_timer <= 0.0:
		_control_window_timer = CONTROL_WINDOW_INTERVAL
		_trigger_control_disruption_skill()

func _process_health_threshold_effects() -> void:
	if max_health <= 0.0:
		return
	var ratio := current_health / max_health
	while _next_health_threshold_ratio > 0.0 and ratio <= _next_health_threshold_ratio + 0.0001:
		_activate_invulnerable_window(THRESHOLD_INVULNERABLE_DURATION, "threshold")
		if player_ref and is_instance_valid(player_ref) and player_ref.has_method("apply_mina_attack_reduction_step"):
			player_ref.apply_mina_attack_reduction_step()
			if UIManager and player_ref.has_method("get_combat_damage_multiplier"):
				var player_multiplier := float(player_ref.call("get_combat_damage_multiplier"))
				UIManager.show_floating_text("攻击衰减 x%.2f" % player_multiplier, player_ref.global_position + Vector2(0, -52), Color(1.0, 0.7, 0.45))
		_next_health_threshold_ratio = maxf(0.0, _next_health_threshold_ratio - 0.2)

func _trigger_control_disruption_skill() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	var weighted_pool: Array[String] = []
	if _is_mechanic_available("swap"):
		weighted_pool.append("swap")
	if _is_mechanic_available("angina") and (not player_ref.has_method("is_mina_angina_active") or not bool(player_ref.call("is_mina_angina_active"))):
		weighted_pool.append("angina")
		weighted_pool.append("angina")
	if _is_mechanic_available("projectile_lock") and (not player_ref.has_method("is_mina_projectile_lock_active") or not bool(player_ref.call("is_mina_projectile_lock_active"))):
		weighted_pool.append("projectile_lock")
	if _is_mechanic_available("input_inversion") and (not player_ref.has_method("is_mina_input_inversion_active") or not bool(player_ref.call("is_mina_input_inversion_active"))):
		weighted_pool.append("input_inversion")
	if _is_mechanic_available("gravity_flip") and (not player_ref.has_method("is_mina_gravity_flip_active") or not bool(player_ref.call("is_mina_gravity_flip_active"))):
		weighted_pool.append("gravity_flip")

	if weighted_pool.is_empty():
		if _is_mechanic_available("swap"):
			_apply_selected_mechanic("swap")
		return

	var selected := weighted_pool[_rng.randi_range(0, weighted_pool.size() - 1)]
	_apply_selected_mechanic(selected)

func _is_mechanic_available(mechanic_id: String) -> bool:
	return float(_mechanic_cooldowns.get(mechanic_id, 0.0)) <= 0.0

func _set_mechanic_cooldown(mechanic_id: String, duration: float = CONTROL_MECHANIC_COOLDOWN) -> void:
	_mechanic_cooldowns[mechanic_id] = maxf(float(_mechanic_cooldowns.get(mechanic_id, 0.0)), duration)

func _apply_selected_mechanic(mechanic_id: String) -> void:
	match mechanic_id:
		"swap":
			if UIManager:
				UIManager.show_floating_text("空间扰动", global_position + Vector2(0, -42), Color(0.72, 0.9, 1.0))
			_try_swap_positions_with_player()
			_set_mechanic_cooldown("swap")
		"angina":
			if player_ref.has_method("apply_mina_angina"):
				player_ref.apply_mina_angina(CONTROL_EFFECT_DURATION)
				if UIManager:
					UIManager.show_floating_text("心绞痛", player_ref.global_position + Vector2(0, -42), Color(1.0, 0.55, 0.55))
				_set_mechanic_cooldown("angina")
		"projectile_lock":
			if player_ref.has_method("apply_mina_projectile_lock"):
				player_ref.apply_mina_projectile_lock(CONTROL_EFFECT_DURATION)
				if UIManager:
					UIManager.show_floating_text("禁射", player_ref.global_position + Vector2(0, -42), Color(1.0, 0.45, 0.45))
				_set_mechanic_cooldown("projectile_lock")
		"input_inversion":
			if player_ref.has_method("apply_mina_input_inversion"):
				player_ref.apply_mina_input_inversion(CONTROL_EFFECT_DURATION)
				if UIManager:
					UIManager.show_floating_text("输入颠倒", player_ref.global_position + Vector2(0, -42), Color(1.0, 0.8, 0.5))
				_set_mechanic_cooldown("input_inversion")
		"gravity_flip":
			if player_ref.has_method("apply_mina_gravity_flip"):
				player_ref.apply_mina_gravity_flip(CONTROL_EFFECT_DURATION)
				if UIManager:
					UIManager.show_floating_text("重力翻转", player_ref.global_position + Vector2(0, -42), Color(0.72, 0.9, 1.0))
				_set_mechanic_cooldown("gravity_flip")

func _try_swap_positions_with_player() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	var mina_pos := global_position
	var player_pos := player_ref.global_position
	if _is_position_swap_safe(player_pos) and _is_position_swap_safe(mina_pos):
		global_position = player_pos
		player_ref.global_position = mina_pos
	else:
		var dir := signf(player_pos.x - mina_pos.x)
		if dir == 0.0:
			dir = 1.0
		global_position += Vector2(56.0 * dir, -8.0)

func _is_position_swap_safe(pos: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = int(LayerManager.LAYER_WORLD_0) | int(LayerManager.LAYER_WORLD_1) | int(LayerManager.LAYER_WORLD_2) | int(LayerManager.LAYER_WORLD_3) | int(LayerManager.LAYER_WORLD_4)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hits := space.intersect_point(query, 8)
	for hit in hits:
		var collider: Object = hit.get("collider", null) as Object
		if collider is StaticBody2D or collider is TileMapLayer:
			return false
	return true

func _devour_projectiles_in_range() -> void:
	var groups := ["magic_projectiles", "boss_projectiles"]
	for group_name in groups:
		for candidate in get_tree().get_nodes_in_group(group_name):
			_try_devour_projectile(candidate)

func _try_devour_projectile(candidate: Node) -> void:
	if candidate == null or not is_instance_valid(candidate):
		return
	if not (candidate is Node2D):
		return
	if candidate == self:
		return
	var projectile_pos := (candidate as Node2D).global_position
	if projectile_pos.distance_to(global_position) > PROJECTILE_DEVOUR_RADIUS:
		return
	if candidate.has_method("queue_free"):
		candidate.queue_free()
		_devoured_projectile_count += 1
		_devour_damage_multiplier = minf(DEVOUR_DAMAGE_CAP, _devour_damage_multiplier * (1.0 + DEVOUR_DAMAGE_STEP))
		if UIManager and _devour_feedback_cooldown <= 0.0:
			UIManager.show_floating_text("吞噬 +1%%", global_position + Vector2(0, -30), Color(0.74, 0.95, 1.0))
			_devour_feedback_cooldown = 0.25

func _resolve_snapshot_wand_data(wand_snapshot: Variant) -> WandData:
	if wand_snapshot == null:
		return null

	var extracted: WandData = null
	if wand_snapshot is WandData:
		extracted = (wand_snapshot as WandData).duplicate(true)
	elif wand_snapshot is Resource and wand_snapshot.get("wand_data") != null:
		var wand_data_variant = wand_snapshot.get("wand_data")
		if wand_data_variant is WandData:
			extracted = (wand_data_variant as WandData).duplicate(true)

	if extracted == null:
		return null

	extracted.cast_delay_timer = 0.0
	extracted.recharge_timer = 0.0
	extracted.is_recharging = false
	if extracted.embryo:
		extracted.current_mana = float(extracted.embryo.mana_capacity)
	return extracted

func _get_scaled_spell_spawn_offset() -> Vector2:
	var scale_factor := maxf(1.0, maxf(absf(global_scale.x), absf(global_scale.y)))
	return Vector2(SPELL_SPAWN_OFFSET.x * scale_factor, SPELL_SPAWN_OFFSET.y * scale_factor)

func _get_spell_spawn_position(direction: Vector2) -> Vector2:
	var dir_norm := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	var scale_factor := maxf(1.0, maxf(absf(global_scale.x), absf(global_scale.y)))
	var launch_clearance := dir_norm * (8.0 * scale_factor)
	var base_position := global_position + _get_scaled_spell_spawn_offset()
	if _wand_muzzle and is_instance_valid(_wand_muzzle):
		base_position = _wand_muzzle.global_position
	return base_position + launch_clearance

func _attempt_recover_wand_snapshot_from_player() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	if player_ref.has_method("get_last_known_wand_snapshot"):
		var snapshot = player_ref.get_last_known_wand_snapshot()
		_snapshot_wand_data = _resolve_snapshot_wand_data(snapshot)
		if _snapshot_wand_data:
			_warned_missing_wand_snapshot = false
			_update_wand_visual_from_snapshot()

func _setup_wand_visual() -> void:
	_wand_pivot = Marker2D.new()
	_wand_pivot.name = "WandPivot"
	_wand_pivot.position = WAND_PIVOT_OFFSET
	_wand_pivot.z_as_relative = false
	_wand_pivot.z_index = 40
	add_child(_wand_pivot)

	_wand_sprite = Sprite2D.new()
	_wand_sprite.name = "WandVisual"
	_wand_sprite.centered = false
	_wand_sprite.offset = Vector2(-8, -48)
	_wand_sprite.rotation = PI / 2
	_wand_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_wand_sprite.z_as_relative = false
	_wand_sprite.z_index = 41
	_wand_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_wand_sprite.visible = false
	_wand_pivot.add_child(_wand_sprite)

	_wand_muzzle = Marker2D.new()
	_wand_muzzle.name = "WandMuzzle"
	_wand_muzzle.position = WAND_MUZZLE_OFFSET
	_wand_pivot.add_child(_wand_muzzle)
	_sync_wand_visual_transform()

func _update_wand_visual_from_snapshot() -> void:
	if _wand_sprite == null:
		return
	if _snapshot_wand_data == null:
		_wand_sprite.texture = _build_fallback_wand_texture()
		_wand_sprite.visible = true
		return

	var tex: Texture2D = null
	if _snapshot_wand and _snapshot_wand is Resource and _snapshot_wand.get("icon") != null:
		var icon_variant = _snapshot_wand.get("icon")
		if icon_variant is Texture2D:
			tex = icon_variant

	if tex == null:
		var generated := WandTextureGenerator.generate_texture(_snapshot_wand_data)
		if _texture_has_visible_pixels(generated):
			tex = generated

	if tex == null:
		tex = _build_fallback_wand_texture()

	_wand_sprite.texture = tex
	_wand_sprite.visible = true

func _sync_wand_visual_transform() -> void:
	if _wand_pivot == null or _wand_sprite == null or _wand_muzzle == null:
		return
	var local_scale_factor := maxf(0.001, maxf(absf(scale.x), absf(scale.y)))
	var compensation := clampf(1.0 / local_scale_factor, 1.0, 8.0)
	_wand_pivot.position = WAND_PIVOT_OFFSET * compensation
	_wand_muzzle.position = WAND_MUZZLE_OFFSET * compensation
	_wand_sprite.scale = Vector2.ONE * compensation

func _texture_has_visible_pixels(tex: Texture2D) -> bool:
	if tex == null:
		return false
	var image := tex.get_image()
	if image == null:
		return false
	var has_visible := false
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.05:
				has_visible = true
				break
		if has_visible:
			break
	return has_visible

func _build_fallback_wand_texture() -> Texture2D:
	var img := Image.create(16, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(6, 46):
		img.set_pixel(8, y, Color(0.83, 0.63, 0.38, 1.0))
		img.set_pixel(7, y, Color(0.68, 0.48, 0.25, 1.0))
		img.set_pixel(9, y, Color(0.68, 0.48, 0.25, 1.0))
	for y in range(0, 11):
		for x in range(5, 12):
			img.set_pixel(x, y, Color(0.58, 0.92, 1.0, 1.0))
	img.set_pixel(8, 45, Color(0.95, 0.88, 0.72, 1.0))
	return ImageTexture.create_from_image(img)
