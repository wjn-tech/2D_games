extends Node
class_name VisualCueComponent

# Ranges in pixels (1 unit = 16 pixels)
const UNIT_SIZE = 16.0
@export var interact_dist: float = 5.0 * UNIT_SIZE
@export var badge_dist: float = 10.0 * UNIT_SIZE

@export var visual_entity: MinimalistEntity
@export var prompt_control: Control

var _player: Node2D
var _parent_npc: Node

func _ready() -> void:
	_parent_npc = get_parent()

func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if not _player: return

	var dist = _parent_npc.global_position.distance_to(_player.global_position)
	_update_visuals(dist)

func _update_visuals(dist: float) -> void:
	if not visual_entity: return
	
	# Fetch Data from NPC
	var occ = _get_npc_occupation()
	var rel = _get_npc_relationship()
	
	if dist > badge_dist:
		# State: HIDDEN
		visual_entity.occupation_type = ""
		if prompt_control: prompt_control.visible = false
		
	elif dist > interact_dist:
		# State: BADGE ONLY
		visual_entity.occupation_type = occ
		if prompt_control: prompt_control.visible = false
		
	else:
		# State: FULL INTERACTION
		# Hide badge to avoid overlap with Nameplate/Prompt logic if desired, 
		# or keep it. Spec implies Badge is for medium distance. 
		# Let's hide badge to declutter close-up view.
		visual_entity.occupation_type = "" 
		
		if prompt_control: 
			prompt_control.visible = true
			# Update prompt text if method exists
			if prompt_control.has_method("update_prompt"):
				prompt_control.update_prompt(_parent_npc)

func _get_npc_occupation() -> String:
	# Try properties or methods
	if "occupation" in _parent_npc: return _parent_npc.occupation
	if _parent_npc.has_method("get_occupation"): return _parent_npc.get_occupation()
	return ""

func _get_npc_relationship() -> float:
	# Try various data sources
	# 1. Direct property
	if "relationship_level" in _parent_npc: return float(_parent_npc.relationship_level) / 100.0
	if "relationship" in _parent_npc: return float(_parent_npc.relationship) / 100.0
	
	# 2. Social Component
	# if _parent_npc.has_node("SocialComponent"): ...
	
	return 0.5 # Default neutral
