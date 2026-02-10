extends Node

## LineageManager (Autoload)
## 处理繁育、变异、成长与世代更替逻辑。

signal baby_born(child: Node, parent_a: CharacterData, parent_b: CharacterData)

const MUTATION_CHANCE = 0.073 # 7.3%
const GROWTH_TIME_SECONDS = 300.0 # 5 minutes for demo/prototype

# Variable to track all living descendants for heir selection
var descendants: Array[CharacterData] = []

func process_growth(delta: float) -> void:
	for child in descendants:
		if child.growth_stage >= 2: continue # Previously ADULT (2)
		
		# Updates only happen for children who are "simulated" or just data?
		# If they are just data, we update age.
		# If they are entities in the world, the Entity script should query data for scale.
		
		child.age += (delta / GROWTH_TIME_SECONDS) # Simple normalized age: 0 -> 1.0 (Adult)
		
		# Define stages based on normalized age 0-1
		# 0.0 - 0.5: Baby
		# 0.5 - 1.0: Juvenile
		# >= 1.0: Adult
		
		var old_stage = child.growth_stage
		if child.age >= 1.0:
			child.growth_stage = 2 # ABULT
			child.age = 1.0 # Cap normalized age for growth purpose (lifespan manager handles real years)
		elif child.age >= 0.5:
			child.growth_stage = 1 # JUVENILE
		else:
			child.growth_stage = 0 # BABY
			
		if child.growth_stage != old_stage:
			_on_growth_stage_changed(child)
			
		# TODO: Emit signal for visual updates if Entity exists

func imprint_on_child(child: CharacterData, amount: float = 0.1) -> void:
	if child.growth_stage >= 2: return # Too late
	child.imprint_quality = clamp(child.imprint_quality + amount, 0.0, 1.0)
	print("LineageManager: Imprinted on ", child.display_name, ", Quality: ", child.imprint_quality)

func _on_growth_stage_changed(child: CharacterData) -> void:
	print("LineageManager: ", child.display_name, " reached stage ", child.growth_stage)
	# Here we could apply stat multipliers for stages if we want "weak babies"
	pass

func try_breed(parent_a: Node, parent_b: Node) -> bool:
	var data_a = parent_a.attributes.data if parent_a.has_node("AttributeComponent") else parent_a.npc_data
	var data_b = parent_b.npc_data
	
	if not _can_breed(data_a, data_b):
		print("条件不满足，无法繁育。")
		return false
	
	print("繁育开始...")
	var child_data = _generate_offspring_data(data_a, data_b)
	_spawn_baby(child_data, parent_b.global_position)
	return true

func _can_breed(a: CharacterData, b: CharacterData) -> bool:
	# Check marriage
	if a.spouse_id != b.uuid and b.spouse_id != a.uuid:
		return false
	# Check gender (optional)
	# Check cooldowns (optional)
	return true

const MALE_NAMES = ["亚瑟", "塞缪尔", "罗宾", "奥斯卡", "李维", "艾瑞克", "哈里", "费利克斯", "托马斯", "卢卡斯"]
const FEMALE_NAMES = ["艾米莉", "索菲亚", "伊莎贝尔", "克拉拉", "爱丽丝", "艾琳娜", "露西", "奥莉薇亚", "米娅", "诺拉"]

func _generate_offspring_data(father: CharacterData, mother: CharacterData) -> CharacterData:
	var child = CharacterData.new()
	
	# 设置为城镇居民类型，确保视觉系统识别为人类
	child.npc_type = "Town"
	
	# 随机决定性别并从对应名字库中选择
	child.gender = randi() % 2
	var name_pool = MALE_NAMES if child.gender == 0 else FEMALE_NAMES
	child.display_name = name_pool.pick_random()
	
	child.generation = max(father.generation, mother.generation) + 1
	child.uuid = randi()
	
	# Inherit Stats
	for stat in CharacterData.BASE_STATS.keys():
		var father_lvl = father.stat_levels.get(stat, {}).get("wild", 0)
		var mother_lvl = mother.stat_levels.get(stat, {}).get("wild", 0)
		
		# 55% chance to inherit higher
		var inherited_lvl = 0
		if randf() < 0.55:
			inherited_lvl = max(father_lvl, mother_lvl)
		else:
			inherited_lvl = min(father_lvl, mother_lvl)
			
		child.stat_levels[stat] = {
			"wild": inherited_lvl,
			"tamed": 0,
			"mutation": 0
		}
	
	# Mutation Logic
	var pat_mut = father.mutations.get("patrilineal", 0) + father.mutations.get("matrilineal", 0)
	var mat_mut = mother.mutations.get("patrilineal", 0) + mother.mutations.get("matrilineal", 0)
	
	child.mutations["patrilineal"] = pat_mut
	child.mutations["matrilineal"] = mat_mut
	
	# Try Mutate
	# Only if total < 20 on respective capability?
	# Ark Logic: If checks < 20, mutation possible.
	if pat_mut < 20 or mat_mut < 20: # Simplified check
		if randf() < MUTATION_CHANCE:
			_apply_mutation(child)

	descendants.append(child)
	return child

func _apply_mutation(child: CharacterData) -> void:
	# Pick random stat
	var stats = CharacterData.BASE_STATS.keys()
	var pick = stats[randi() % stats.size()]
	
	# +2 Wild Levels
	child.stat_levels[pick]["wild"] += 2
	child.stat_levels[pick]["mutation"] = 1 # Mark as mutated
	
	# Increment counter (Randomly assign to pat or mat side logic, usually determined by source)
	# For simplicity, assign to patrilineal
	child.mutations["patrilineal"] += 1
	print("Mutation occurred on ", pick)

func _spawn_baby(data: CharacterData, pos: Vector2) -> void:
	# 加载基础 NPC 场景
	var scene_path = "res://NPC.tscn"
	var scene = load(scene_path)
	
	if not scene:
		print("Error: Could not load NPC base scene for baby at ", scene_path)
		return
		
	var baby = scene.instantiate()
	baby.npc_data = data
	baby.global_position = pos
	
	# 设置成长阶段为 0 (婴儿)
	data.growth_stage = 0
	
	# 加入场景树
	var world = get_tree().current_scene
	world.add_child(baby)
	
	# 设置视觉缩放 (婴儿较小)
	# 委托给 NPC 自身的 update_growth_visual 处理，避免逻辑冲突
	if baby.has_method("update_growth_visual"):
		baby.update_growth_visual()
	else:
		baby.scale = Vector2(0.5, 0.5)

	print("Spawned Baby: ", data.display_name, " at ", pos)
	baby_born.emit(baby, null, null)
