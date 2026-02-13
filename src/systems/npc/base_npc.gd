extends CharacterBody2D
class_name BaseNPC

@export var npc_data: CharacterData
@export var interaction_area: Area2D
@export var custom_sprite_frames: SpriteFrames 
@export var speed: float = 100.0
@export var detection_range: float = 300.0
@export var attack_range: float = 50.0
@export var wander_radius: float = 300.0 

# Progression & Execution
var is_executable: bool = false
var _execution_prompt_instance: Control = null
var loot_item_scene: PackedScene = preload("res://scenes/world/loot_item.tscn")

var stun_timer: float = 0.0

# LimboAI components
@onready var bt_player: BTPlayer = $BTPlayer
@onready var hsm: LimboHSM = $LimboHSM
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

# 新增：AI 类型定义 (Terraria 风格) - 保持以做属性参考
enum AIType { FIGHTER, FLYER, WORM, PASSIVE }
@export var ai_type: AIType = AIType.FIGHTER

@export var quest_template: QuestResource 

var spawn_position: Vector2 = Vector2.ZERO
var home_position: Vector2 = Vector2.ZERO 
var gravity: float = 2000.0
var chatter_timer: float = 0.0
var happiness_timer: float = 5.0 
var inventory: Array = [] 
const STEP_HEIGHT = 18.0 
var wall_hit_cooldown: float = 0.0 

# @onready var animator: AnimatedSprite2D = find_child("AnimatedSprite2D")
# Minimalist visual reference
@onready var min_visual = $MinimalistEntity

var visual_cue_comp: VisualCueComponent
var relationship: float = 50.0 # 0-100 relationship level
var occupation: String = "" # Merchant, Guard, etc.

var speech_bubble: SpeechBubble
var nameplate: Control
var hp_bar: ProgressBar
var name_label: Label

func _ready() -> void:
	spawn_position = global_position
	
	if npc_data:
		# 加载数据驱动的行为树
		if not npc_data.behavior_tree_path.is_empty():
			var bt = load(npc_data.behavior_tree_path)
			if bt is BehaviorTree:
				bt_player.behavior_tree = bt
				bt_player.restart()
		
		# 初始化黑板属性
		bt_player.blackboard.set_var(&"max_health", npc_data.max_health)
		bt_player.blackboard.set_var(&"is_hostile", npc_data.npc_type == "Hostile")
		bt_player.blackboard.set_var(&"preferred_biome", npc_data.preferred_biome)

	# 初始化导航代理
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	
	# --- Visual Style Injection ---
	# Turn off traditional sprites and activate Minimalist Mode
	# if animator:
	# 	animator.visible = false
	
	# Try to find existing Sprite2D if AnimatedSprite2D missing
	var spr = find_child("Sprite2D")
	if spr: spr.visible = false
		
	# Instantiate MinimalistEntity
	# Configured in scene now!
	
	var sm = get_node_or_null("/root/SettlementManager")
	if sm:
		sm.night_toggled.connect(_on_night_toggled)
		# 初始检查
		if sm.is_night:
			_on_night_toggled(true)

	# if custom_sprite_frames and animator:
	#	animator.sprite_frames = custom_sprite_frames
	#	# 确保播放默认动画
	#	if animator.sprite_frames.has_animation("idle"):
	#		animator.play("idle")

	if not npc_data:
		npc_data = CharacterData.new()
		
	# --- Apply Minimalist Config ---
	if min_visual and min_visual.has_method("setup_from_npc"):
		# Use display_name (like "Slime") or alignment
		var d_name = npc_data.display_name
		if d_name == "": d_name = npc_data.npc_type # Fallback
		min_visual.setup_from_npc(d_name, npc_data.alignment, ai_type, npc_data.npc_type)

	# 处理敌对染色 (Minimalist handles this inside setup_from_npc via color)
	# if npc_data.alignment == "Hostile":
	# 	modulate = Color(1.0, 0.4, 0.4)

	add_to_group("npcs")
	# 自动归类敌人
	if npc_data and npc_data.alignment == "Hostile":
		add_to_group("enemies")

	# 实例化气泡对话框 (保留用于手动say，但移除自动闲聊)
	var bubble_scene = load("res://scenes/ui/speech_bubble.tscn")
	if bubble_scene:
		speech_bubble = bubble_scene.instantiate()
		add_child(speech_bubble)
		speech_bubble.position = Vector2(0, -40) # 在头顶显示

	# 初始化头顶信息 (种族与血量)
	_setup_nameplate()
	_setup_visual_cue_component()
	
	# 更新初始成长视觉
	update_growth_visual()

	# 确保碰撞层正确
	collision_layer = LayerManager.LAYER_NPC
	# NPC 默认位于第 0 层 (LAYER_WORLD_0)
	collision_mask = LayerManager.LAYER_WORLD_0
	
	if interaction_area:
		interaction_area.collision_layer = LayerManager.LAYER_INTERACTION
		interaction_area.collision_mask = 0
		
	# 同步初始数据 (在行为树启动前执行，确保变量可用)
	sync_data_to_blackboard()

	# 初始化 LimboHSM
	if hsm:
		hsm.initialize(self)
		
		if bt_player and bt_player.blackboard:
			# 修复：LimboHSM 的 blackboard 属性在某些版本中是只读的，
			# 我们应该通过其内部方法或在初始化后同步数据。
			# 另一种方式是让 HSM 直接使用代理的黑板（如果插件支持）
			# 这里采用手动同步关键变量的方式，确保 target 能互通
			print("[BaseNPC] HSM initialized with blackboard.")
		
		# 强制设置初始状态
		var idle_state = hsm.get_node_or_null("Idle")
		var combat_state = hsm.get_node_or_null("Combat")
		var home_state = hsm.get_node_or_null("Home")
		
		if idle_state:
			print("[BaseNPC] Setting initial state to Idle.")
			hsm.initial_state = idle_state
		else:
			push_error("[BaseNPC] CRITICAL: Idle state node not found!")
			
		# 关键修复：注册状态转换
		if idle_state and combat_state:
			print("[BaseNPC] Registering HSM transitions.")
			hsm.add_transition(idle_state, combat_state, &"enemy_detected")
			hsm.add_transition(combat_state, idle_state, &"threat_cleared")
			
			if home_state:
				hsm.add_transition(idle_state, home_state, &"night_started")
				hsm.add_transition(home_state, idle_state, &"day_started")
				hsm.add_transition(combat_state, home_state, &"night_started")
				hsm.add_transition(home_state, combat_state, &"enemy_detected")
		else:
			push_error("[BaseNPC] CRITICAL: Cannot register transitions, missing states.")
			
		hsm.set_active(true)
		print("[BaseNPC] HSM active set to true.")

func _setup_nameplate() -> void:
	nameplate = Control.new()
	nameplate.name = "Nameplate"
	nameplate.position = Vector2(0, -60) 
	
	# Create children BEFORE adding nameplate to tree or setting script
	# to avoid @onready race conditions or "Node not found" errors
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	vbox.size = Vector2(100, 40)
	vbox.position = Vector2(-50, -20)
	nameplate.add_child(vbox)

	name_label = Label.new()
	name_label.name = "Label"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_label)
	
	var action_box = VBoxContainer.new()
	action_box.name = "ActionContainer"
	action_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(action_box)

	# Now attach script and add to tree
	nameplate.set_script(load("res://src/ui/context_prompt.gd")) 
	add_child(nameplate)

	# Initial Setup
	var type_str = name
	if npc_data and npc_data.display_name != "":
		type_str = npc_data.display_name
	
	if nameplate.has_method("setup"):
		nameplate.setup(type_str, npc_data.alignment)

	var container = vbox 
	
	# Continue with HP Bar (attached to vbox)

	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(60, 6)
	hp_bar.show_percentage = false
	
	# 设置背景样式
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.6)
	style_bg.set_corner_radius_all(2)
	hp_bar.add_theme_stylebox_override("background", style_bg)
	
	# 设置填充颜色样式 (根据阵营)
	var style_fg = StyleBoxFlat.new()
	if npc_data.alignment == "Friendly":
		style_fg.bg_color = Color(0.1, 0.6, 1.0) # 亮蓝色
	else:
		style_fg.bg_color = Color(1.0, 0.1, 0.1) # 亮红色 (Hostile 或其他)
		
	style_fg.set_corner_radius_all(2)
	hp_bar.add_theme_stylebox_override("fill", style_fg)
	
	hp_bar.max_value = npc_data.max_health
	hp_bar.value = npc_data.health
	container.add_child(hp_bar)

func _setup_visual_cue_component() -> void:
	visual_cue_comp = VisualCueComponent.new()
	visual_cue_comp.name = "VisualCueComponent"
	visual_cue_comp.visual_entity = min_visual
	visual_cue_comp.prompt_control = nameplate
	add_child(visual_cue_comp)
	
	# Initialize Occupation/Relationship based on NPC Type
	if npc_data.npc_type == "Merchant" or name.contains("Merchant"):
		occupation = "Merchant"
	elif npc_data.npc_type == "Guard":
		occupation = "Guard"
	elif npc_data.npc_type == "Blacksmith":
		occupation = "Blacksmith"
	
	# Default Relationship based on Alignment
	if npc_data.alignment == "Friendly":
		relationship = 80.0
	elif npc_data.alignment == "Hostile":
		relationship = 0.0

func _update_hp_bar() -> void:
	if hp_bar and npc_data:
		hp_bar.max_value = npc_data.max_health
		hp_bar.value = npc_data.health

func sync_data_to_blackboard() -> void:
	if not bt_player or not bt_player.blackboard: return
	var bb = bt_player.blackboard
	
	if npc_data:
		bb.set_var("alignment", npc_data.alignment)
		bb.set_var("role", npc_data.role)
		bb.set_var("display_name", npc_data.display_name)
		bb.set_var("speed", speed)
		bb.set_var("detection_range", detection_range)
		bb.set_var("attack_range", attack_range)
		bb.set_var("home_pos", home_position)
		bb.set_var("spawn_pos", spawn_position)
		bb.set_var("ai_type", ai_type)
	
	var sm = get_node_or_null("/root/SettlementManager")
	var is_night = sm.is_night if sm else false
	bb.set_var("is_night", is_night)
	bb.set_var("current_layer", get_meta("current_layer", 0))

func _physics_process(delta: float) -> void:
	# 0. 击退衰减处理 (Removed in favor of direct velocity manipulation)
	
	# 1. 重力处理 (仅限行走类 AI)
	if ai_type != AIType.FLYER and ai_type != AIType.WORM:
		if not is_on_floor():
			velocity.y += gravity * delta
	else:
		# 飞行 AI 缓慢摩擦减速
		velocity = velocity.lerp(Vector2.ZERO, delta * 2.0)

	if wall_hit_cooldown > 0:
		wall_hit_cooldown -= delta

	if stun_timer > 0:
		stun_timer -= delta
		# Stunned: Just apply friction/gravity (handled above)
		# Do NOT run AI movement logic below
	else:
		# AI only runs if not stunned
		# 实际上 AI 决策现在完全交给 BTPlayer 和 LimboHSM
		pass # Logic continues to move_and_slide

	_handle_happiness_logic(delta)
	
	# 注意：AI 决策现在完全交给 BTPlayer 和 LimboHSM，它们会自动调用更新。
	# 我们只需要处理 move_and_slide 物理反馈
	
	var was_on_floor = is_on_floor()
	move_and_slide()
	
	# 自动跳跃/上台阶逻辑 (FIGHTER 特有)
	if ai_type == AIType.FIGHTER and is_on_wall() and was_on_floor:
		_handle_vertical_navigation()
		
	_update_animations()

func move_along_path(destination: Vector2) -> void:
	nav_agent.target_position = destination
	
	if nav_agent.is_navigation_finished():
		velocity.x = 0
		return
		
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = (next_path_pos - global_position).normalized()
	
	# Fallback: 如果导航未准备好或返回当前位置 (常见于无 NavMesh)，直接向目标水平移动
	# 这是一个针对 2D 侧滚游戏的常见修正，防止因为缺少 NavMesh 导致 NPC 不动
	if global_position.distance_to(next_path_pos) < 5.0 and global_position.distance_to(destination) > 20.0:
		dir = (destination - global_position).normalized()
	
	var new_velocity = dir * speed
	
	# 这里使用避障逻辑
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)

func stop_movement() -> void:
	velocity.x = 0
	nav_agent.target_position = global_position

func jump(force_x: float, force_y: float) -> void:
	if is_on_floor():
		velocity.y = -force_y
		velocity.x = force_x
		# 短暂禁用水平阻力，让跳跃更自然
		wall_hit_cooldown = 0.2

func shoot_at(target_pos: Vector2, projectile_scene: PackedScene) -> void:
	if not projectile_scene: return
	var proj = projectile_scene.instantiate()
	get_parent().add_child(proj)
	proj.global_position = global_position
	
	# Ensure enemy projectiles can hit the player and world
	if proj is CharacterBody2D:
		proj.collision_mask = LayerManager.LAYER_WORLD_0 | LayerManager.LAYER_PLAYER
	
	if proj.has_method("launch"):
		proj.launch(global_position.direction_to(target_pos))

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if ai_type == AIType.FLYER:
		velocity = safe_velocity
	else:
		velocity.x = safe_velocity.x

# 移除所有旧的状态逻辑代码块（从 _process_state 到 _state_go_home）

func _handle_vertical_navigation() -> void:
	# 尝试上台阶 (保持此逻辑作为基础物理能力)
	_handle_step_up()
	# 如果还是被卡住 (墙很高)，尝试跨越
	if is_on_wall() and wall_hit_cooldown <= 0:
		velocity.y = -500
		wall_hit_cooldown = 0.5

func _handle_step_up() -> void:
	if velocity.x == 0: return
	var direction = sign(velocity.x)
	
	# 1. 向上探测
	var step_test_up = Vector2(0, -STEP_HEIGHT)
	if test_move(global_transform, step_test_up):
		return
		
	# 2. 向前探测
	var test_transform = global_transform.translated(step_test_up)
	if test_move(test_transform, Vector2(direction * 2, 0)):
		return
		
	# 3. 执行位移
	global_position.y -= STEP_HEIGHT
	global_position.x += direction * 2

func update_home_position(pos: Vector2) -> void:
	home_position = pos
	if bt_player and bt_player.blackboard:
		bt_player.blackboard.set_var("home_pos", pos)
	print(name, " 更新住所位置: ", pos)

func _on_night_toggled(is_night: bool) -> void:
	if bt_player and bt_player.blackboard:
		bt_player.blackboard.set_var("is_night", is_night)
	
	if hsm:
		if is_night:
			hsm.dispatch(&"night_started")
		else:
			hsm.dispatch(&"day_started")
	
	# Terraria 风格：夜晚时如果玩家不在视野，NPC 瞬移回家
	if is_night and npc_data and npc_data.is_settled:
		var dist_to_home = global_position.distance_to(npc_data.home_pos)
		if dist_to_home > 32:
			# 简单的离屏判断 (简化版)
			var player = get_tree().get_first_node_in_group("player")
			if player and global_position.distance_to(player.global_position) > 600:
				global_position = npc_data.home_pos
				print(name, ": 瞬移回住所")

## 分配住所接口 (由 SettlementManager 调用)
func assign_home(room_info: Dictionary):
	if npc_data:
		npc_data.is_settled = true
		# 取填充列表的第一个点作为家
		if not room_info.interior.is_empty():
			# 转换 map_pos 为 global_pos
			var lm = get_node_or_null("/root/LayerManager")
			var l0 = lm.layer_nodes.get(0) if lm else null
			if l0:
				npc_data.home_pos = l0.to_global(l0.map_to_local(room_info.interior[0]))
				home_position = npc_data.home_pos

func take_damage(amount: float, _type: String = "physical") -> void:
	if npc_data:
		var old_hp = npc_data.health
		npc_data.health -= amount
		print(name, " takes damage: ", amount, " | HP: ", old_hp, " -> ", npc_data.health)

		# Check Execution Threshold (20%)
		if npc_data.health <= npc_data.max_health * 0.2 and npc_data.health > 0:
			_check_execution_state()
		
		# Visual feedback: Flash Red
		if min_visual:
			var tween = create_tween()
			tween.tween_property(min_visual, "modulate", Color(5, 1, 1), 0.1) 
			tween.tween_property(min_visual, "modulate", Color.WHITE, 0.1)
		
		# 彻底删除了卡肉逻辑 (HitStop)，确保子弹命中后不产生顿挫感

		# Floating Damage Text
		if UIManager:
			UIManager.show_floating_text(str(int(amount)), global_position + Vector2(0, -20), Color.ORANGE_RED)

		# 更新血条显示
		_update_hp_bar()

		if npc_data.health <= 0:
			_die()

func update_growth_visual() -> void:
	if not npc_data: return
	
	# 设置缩放比例
	var target_scale = 1.0
	
	# 只有名字里包含 "Child" 的子嗣才应用婴儿期缩放逻辑
	# 其他所有 NPC（公主、商人、敌人等）默认全部 1.0，对标玩家
	if npc_data.display_name.contains("Child"):
		match npc_data.growth_stage:
			0: target_scale = 0.5
			1: target_scale = 0.75
			2: target_scale = 1.0
	else:
		# 非子嗣 NPC 强制 1.0
		target_scale = 1.0
	
	# 同步根节点缩放
	self.scale = Vector2(target_scale, target_scale)
	
	# 同步子节点位置，确保脚底对齐玩家 (标准偏移 -7)
	if min_visual:
		min_visual.scale = Vector2.ONE
		min_visual.position = Vector2(0, -7)
	
	print(name, " [", npc_data.display_name, "] 尺寸对齐完成: Scale ", target_scale)

func _die() -> void:
	print(name, " died.")
	
	# 触发群体仇恨
	var player = get_tree().get_first_node_in_group("player")
	if player and get_node_or_null("/root/FactionManager"):
		get_node("/root/FactionManager").notify_attack(player, self)
		
	# 给予经验奖励
	if GameState.player_data:
		var xp_gain = 25 # 基础经验
		if npc_data:
			xp_gain += npc_data.level * 10
		GameState.player_data.add_experience(xp_gain)
		
		# --- 新增：击败敌对目标产出金币 ---
		if npc_data and npc_data.alignment == "Hostile":
			var gold_drop = randi_range(5, 15) + (npc_data.level * 2)
			GameState.player_data.change_money(gold_drop)
			if UIManager:
				UIManager.show_floating_text("+%d Gold" % gold_drop, global_position + Vector2(0, -20), Color.YELLOW)
		
		if UIManager:
			UIManager.show_floating_text("+%d XP" % xp_gain, global_position, Color.SKY_BLUE)
	
	if EventBus:
		EventBus.enemy_killed.emit(npc_data.display_name, npc_data.alignment)
		
	queue_free()

func get_faction() -> String:
	return npc_data.alignment # 暂时用 alignment 代替具体阵营名

func get_uuid() -> int:
	if npc_data:
		return npc_data.uuid
	return -1

func on_ally_attacked(attacker: Node2D) -> void:
	if npc_data.alignment != "Hostile":
		npc_data.alignment = "Hostile" # 变敌对
		if bt_player and bt_player.blackboard:
			bt_player.blackboard.set_var("target", attacker)
		if hsm:
			hsm.dispatch("enemy_detected")

func apply_knockback(force: Vector2) -> void:
	velocity += force
	# Stun briefly to allow physics to happen without AI fighting back
	stun_timer = 0.3 # Increased to match Slime logic
	
	# Cancel navigation if possible (Optional)
	if nav_agent: nav_agent.target_position = global_position

func _handle_happiness_logic(delta: float) -> void:
	if not npc_data or npc_data.npc_type != "Town": return
	
	happiness_timer -= delta
	if happiness_timer <= 0:
		happiness_timer = 10.0 # 每 10 秒刷新一次
		_update_happiness()

func _update_happiness() -> void:
	if not npc_data: return
	
	var score = 1.0 # 1.0 为基础价格 (100%)
	
	# 1. 检查邻居 (400像素内)
	var neighbors = get_tree().get_nodes_in_group("npcs")
	var neighbor_count = 0
	for n in neighbors:
		if n == self or not n is BaseNPC: continue
		var dist = global_position.distance_to(n.global_position)
		if dist < 400.0:
			neighbor_count += 1
			# 检查喜爱的邻居
			if npc_data.loved_neighbors.has(n.npc_data.display_name):
				score -= 0.1 # 减价 (更快乐)
			# 检查讨厌的邻居
			if npc_data.hated_neighbors.has(n.npc_data.display_name):
				score += 0.2 # 涨价 (不快乐)

	# 密集恐惧症 (Terraria 设定)
	if neighbor_count > 3:
		score += 0.05 * (neighbor_count - 3)

	# 2. 检查生物群落 (示例逻辑)
	# if current_biome != npc_data.preferred_biome:
	#     score += 0.1
	
	npc_data.happiness = clamp(score, 0.75, 1.5)
	
	# 同步到 Blackboard 让 BT 也能感知情绪变化
	if bt_player and bt_player.blackboard:
		bt_player.blackboard.set_var("happiness", npc_data.happiness)

func say(text: String) -> void:
	if speech_bubble:
		speech_bubble.show_text(text)

func _handle_neutral_interaction() -> void:
	# 允许子类覆盖的默认行为
	pass

func interact(_interactor: Node = null) -> void:
	# 停止移动并面向玩家
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var dir = (player.global_position - global_position).normalized()
		# if animator:
		# 	animator.flip_h = dir.x < 0
		if min_visual:
			if dir.x < 0: min_visual.scale.x = -abs(min_visual.scale.x)
			elif dir.x > 0: min_visual.scale.x = abs(min_visual.scale.x)

	if bt_player and bt_player.blackboard:
		bt_player.blackboard.set_var("is_interacting", true)
		# 可以在这里设置一个计时器来重置，或者由对话 UI 控制
		get_tree().create_timer(5.0).timeout.connect(func(): 
			if bt_player and bt_player.blackboard:
				bt_player.blackboard.set_var("is_interacting", false)
		)

	# --- Unified Interaction Logic ---
	_start_default_dialogue()

func _perform_heal() -> void:
	if npc_data.alignment == "Hostile": return
	# TODO: Heal logic implementation
	pass

func _start_default_dialogue() -> void:
	var dm = get_node_or_null("/root/DialogueManager")
	if not dm: return

	if npc_data.alignment == "Hostile":
		dm.start_dialogue(npc_data.display_name, ["... (Growls at you) ..."], [{"text": "Leave", "action": func(): pass}])
		return

	var options = []

	# 1. Occupation Actions
	match occupation:
		"Merchant":
			options.append({"text": "交易", "action": func(): _open_trade()})
		"Healer":
			options.append({"text": "治疗", "action": func(): _perform_heal()})
		"Guard":
			options.append({"text": "报告", "action": func(): pass})

	# 2. Quest Actions
	if quest_template and get_node_or_null("/root/QuestManager"):
		var qm = get_node("/root/QuestManager")
		if not qm.is_quest_active(quest_template.quest_id) and not qm.is_quest_completed(quest_template.quest_id):
			# Offer Quest -> Chains to Quest Description (Don't close window)
			options.append({"text": "任务", "action": func(): _offer_quest(), "close_after": false})
		elif qm.is_quest_active(quest_template.quest_id):
			options.append({"text": "交付任务", "action": func(): _check_quest_completion(), "close_after": false})

	# 3. Recruitment Actions
	if npc_data.npc_type != "Town":
		options.append({"text": "招募", "action": func(): _try_recruit(), "close_after": false})
	
	# 4. Social Actions
	options.append({"text": "送礼", "action": func(): _open_gift_menu()})

	# 5. Exit
	options.append({"text": "离开", "action": func(): pass})

	dm.start_dialogue(npc_data.display_name, ["你好！我是" + npc_data.display_name + "。", "有什么我可以帮你的吗？"], options)

func _open_gift_menu() -> void:
	# Placeholder for gift menu
	pass

func _offer_quest() -> void:
	if not quest_template: return
	var dm = get_node("/root/DialogueManager")
	
	var accept_action = func():
		var qm = get_node("/root/QuestManager")
		qm.accept_quest(quest_template)
	
	# Display description and offer
	dm.start_dialogue(npc_data.display_name, [quest_template.description], [
		{"text": "接受", "action": accept_action},
		{"text": "拒绝", "action": func(): pass}
	])

func _check_quest_completion() -> void:
	var qm = get_node("/root/QuestManager")
	var dm = get_node("/root/DialogueManager")
	
	if qm.complete_quest(quest_template.quest_id):
		if dm: dm.start_dialogue(npc_data.display_name, ["太感谢了！这是给你的报酬。"], [{"text": "不用谢", "action": func(): pass}])
	else:
		if dm: dm.start_dialogue(npc_data.display_name, ["你还没有完成任务要求。", "请完成后再来找我。"], [{"text": "好的", "action": func(): pass}])

func _open_trade() -> void:
	if UIManager:
		var win = UIManager.open_window("TradeWindow", "res://scenes/ui/TradeWindow.tscn")
		if win and win.has_method("set_merchant"):
			win.set_merchant(self)

func _try_recruit() -> void:
	if npc_data.npc_type == "Town":
		return
		
	var dm = get_node("/root/DialogueManager")
	
	if npc_data.loyalty >= 50:
		npc_data.npc_type = "Town"
		npc_data.alignment = "Friendly"
		var sm = get_node_or_null("/root/SettlementManager")
		if sm:
			sm.recruited_npcs.append(npc_data)
			sm._recalculate_stats()
			
		if dm: dm.start_dialogue(npc_data.display_name, ["我愿意加入你的队伍！"], [{"text": "太棒了！", "action": func(): pass}])
	else:
		# Failure feedback
		npc_data.loyalty += 5
		if dm: dm.start_dialogue(npc_data.display_name, ["我还不够信任你... (需要 50 忠诚度)"], [{"text": "我会努力的", "action": func(): pass}])

# --- Execution & Loot Logic ---
func _check_execution_state() -> void:
	if is_executable: return
	is_executable = true
	_show_execution_prompt()

func _show_execution_prompt() -> void:
	if not _execution_prompt_instance:
		var label = Label.new()
		label.text = "[F] 斩杀"
		label.modulate = Color(1.0, 0.3, 0.3)
		label.position = Vector2(-25, -45)
		label.z_index = 100
		add_child(label)
		_execution_prompt_instance = label
		
		# Pulse Animation
		var tween = create_tween().set_loops()
		tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.5)
		tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.5)

func execute_by_player(player: Node2D) -> void:
	if not is_executable: return
	is_executable = false
	
	# Disable AI
	if bt_player: bt_player.set_active(false)
	if nav_agent: nav_agent.set_velocity(Vector2.ZERO)
	
	# Player Invincibility during execution sequence
	var original_invincible = player.get("invincible") if "invincible" in player else false
	if "invincible" in player:
		player.invincible = true
		# 强制修改碰撞检测 (如果玩家脚本里有这个变量)
		player.set_deferred("monitoring", false) # 如果玩家是 Area2D，暂时关闭检测
	
	# Stop player movement briefly
	if player.has_method("set_physics_process"):
		player.set_physics_process(false)
	
	# Pull Effect
	var tween = create_tween()
	tween.tween_property(self, "global_position", player.global_position, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		# Effect
		if UIManager and UIManager.has_method("show_floating_text"):
			UIManager.show_floating_text("斩杀!", global_position + Vector2(0, -30), Color(1.0, 0.2, 0.2))
		
		# Restore player state
		if is_instance_valid(player):
			if "invincible" in player:
				player.invincible = original_invincible
			player.set_deferred("monitoring", true)
			if player.has_method("set_physics_process"):
				player.set_physics_process(true)
		
		_drop_execution_loot()
		_die()
	)

func _drop_execution_loot() -> void:
	# 1. Determine Material and Spell ID based on NPC identity
	var mat_id = "gold_nugget" # Default material
	var spell_id = "projectile_magic_missile" # Default spell
	
	var d_name = npc_data.display_name
	
	if "史莱姆" in d_name or "Slime" in d_name:
		mat_id = "slime_essence"
		if randf() < 0.15: 
			spell_id = "projectile_tnt"
		else:
			spell_id = "projectile_slime"
	elif "骨" in d_name or "Skeleton" in d_name or "僵尸" in d_name or "Zombie" in d_name:
		mat_id = "bone_fragment"
		spell_id = "modifier_pierce"
	elif "眼" in d_name or "Eye" in d_name:
		mat_id = "crystalline_lens"
		var r = randf()
		if r < 0.2: spell_id = "projectile_blackhole"
		elif r < 0.4: spell_id = "projectile_teleport"
		else: spell_id = "modifier_speed" 
	elif "蚁" in d_name or "Antlion" in d_name:
		mat_id = "scrap_metal"
		spell_id = "logic_splitter"
	elif "公主" in d_name or "Princess" in d_name:
		mat_id = "noble_essence" 
		spell_id = "logic_sequence" # New Order Relay
	
	# Load material resource safely
	var mat_path = "res://data/items/" + mat_id + ".tres"
	if ResourceLoader.exists(mat_path):
		var item_res = load(mat_path)
		if item_res:
			_spawn_loot(item_res, 1)
	else:
		# Fallback if specific resource doesn't exist yet
		var default_mat = load("res://data/items/gold_nugget.tres")
		if default_mat: _spawn_loot(default_mat, randi_range(2, 5))
	
	# 2. Chance for Spell (50%)
	if randf() < 0.5:
		if spell_id != "":
			_spawn_spell_item(spell_id)

func _spawn_loot(item: Resource, count: int) -> void:
	if not loot_item_scene or not item: return
	var loot = loot_item_scene.instantiate()
	get_parent().call_deferred("add_child", loot)
	loot.global_position = global_position
	if loot.has_method("setup"):
		loot.call_deferred("setup", item, count)

func _spawn_spell_item(spell_id: String) -> void:
	var spell_item = SpellItem.new()
	spell_item.id = "spell_scroll_" + spell_id
	spell_item.spell_unlock_id = spell_id
	spell_item.display_name = "法术: " + spell_id
	spell_item.item_type = "Consumable"
	# Placeholder icon from palette
	var atlas = AtlasTexture.new()
	atlas.atlas = load("res://assets/minimalist_palette.png")
	atlas.region = Rect2(48, 0, 16, 16) # Magic looking region
	spell_item.icon = atlas
	
	_spawn_loot(spell_item, 1)

func get_inventory():
	# 移除之前的随机生成逻辑，现在由 WorldGenerator 在生成时初始化
	return inventory

func _update_animations() -> void:
	# if not animator: return
	
	if min_visual:
		if velocity.x < 0: min_visual.scale.x = -abs(min_visual.scale.x)
		elif velocity.x > 0: min_visual.scale.x = abs(min_visual.scale.x)

	# if velocity.length() > 0:
	# 	if animator.sprite_frames.has_animation("run"):
	# 		animator.play("run")
	# 	animator.flip_h = velocity.x < 0
	# else:
	# 	if animator.sprite_frames.has_animation("idle"):
	# 		animator.play("idle")
