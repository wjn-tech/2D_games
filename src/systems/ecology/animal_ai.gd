extends BaseNPC

## AnimalAI
## 简单的生态系统 AI：实现饥饿感与捕食/逃跑逻辑。

@export var prey_groups: Array[String] = [] # 捕食目标组名
@export var predator_groups: Array[String] = [] # 天敌组名
@export var hunger_rate: float = 0.05 # 每秒增加的饥饿度

var hunger: float = 0.0

func _ready() -> void:
	super._ready()
	# 将自己加入对应的生态组
	# 例如：狼加入 "wolves"，兔子加入 "rabbits"
	pass

func _physics_process(delta: float) -> void:
	hunger += hunger_rate * delta
	if bt_player and bt_player.blackboard:
		bt_player.blackboard.set_var("hunger", hunger)
	
	_check_for_predators()
	super._physics_process(delta)

## 检查天敌并逃跑
func _check_for_predators() -> void:
	if not bt_player or not bt_player.blackboard: return
	
	for group in predator_groups:
		var predators = get_tree().get_nodes_in_group(group)
		for p in predators:
			if is_instance_valid(p) and global_position.distance_to(p.global_position) < detection_range:
				bt_player.blackboard.set_var("target", p)
				if hsm:
					hsm.dispatch("enemy_detected")
				return
				return

## 该逻辑现在建议迁移到行为树任务中
func _check_for_prey() -> void:
	if not bt_player or not bt_player.blackboard: return
	
	# 只有饥饿度高时才捕食
	if hunger > 30.0:
		for group in prey_groups:
			var preys = get_tree().get_nodes_in_group(group)
			for p in preys:
				if is_instance_valid(p) and global_position.distance_to(p.global_position) < detection_range:
					bt_player.blackboard.set_var("target", p)
					if hsm:
						hsm.dispatch("enemy_detected")
					return
