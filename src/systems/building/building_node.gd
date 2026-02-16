extends StaticBody2D

@onready var sprite = $Sprite2D

enum BuildingType { DECOR, WORKSHOP, HOUSING, STORAGE }
@export var type: BuildingType = BuildingType.DECOR
@export var buff_radius: float = 200.0
@export var efficiency_bonus: float = 0.2

var building_resource: BuildingResource

func _ready() -> void:
	add_to_group("settlement_buildings")
	_apply_buffs()

func setup(resource: BuildingResource):
	building_resource = resource
	if not resource: return
	
	buff_radius = resource.influence_radius
	
	# 如果 Ready 还没运行，手动获取 Sprite
	if not sprite: sprite = get_node_or_null("Sprite2D")
	
	if sprite:
		if resource.atlas_coords != Vector2i(-1, -1):
			# Atlas texture logic is handled by BuildingManager during instantiation
			pass
		elif resource.icon:
			sprite.texture = resource.icon
			sprite.centered = true
			sprite.scale = Vector2(1, 1)
			# 如果是多格瓦片，补偿位置到中心
			var gs = resource.grid_size
			sprite.position = Vector2(gs.x * 16 / 2.0, gs.y * 16 / 2.0)
	
	# Add interaction logic for functional buildings
	if resource.id == "workbench":
		if not is_in_group("p_interactable"): add_to_group("p_interactable")
		if not is_in_group("workbench"): add_to_group("workbench")
		_ensure_interaction_area()

func _ensure_interaction_area():
	if has_node("InteractionArea"): return
	var area = Area2D.new()
	area.name = "InteractionArea"
	area.collision_layer = 8
	area.collision_mask = 2
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(48, 48)
	col.shape = shape
	# Center it on the building (2x1 for workbench usually)
	if building_resource:
		var gs = building_resource.grid_size
		col.position = Vector2(gs.x * 16 / 2.0, gs.y * 16 / 2.0)
	area.add_child(col)
	add_child(area)

func interact(_player) -> void:
	if building_resource and building_resource.id == "workbench":
		if self.has_method("toggle_window"):
			# Fallback for old scene-based implementation
			self.call("toggle_window")
		elif has_node("/root/UIManager"):
			var ui = get_node("/root/UIManager")
			ui.toggle_window("CraftingWindow", "res://scenes/ui/CraftingWindow.tscn")
		else:
			# Try Autoload name directly
			UIManager.toggle_window("CraftingWindow", "res://scenes/ui/CraftingWindow.tscn")
	
func _apply_buffs() -> void:
	# 简单的逻辑：影响范围内正在采集/工作的 NPC
	# 注意：注册动作现在由 BuildingManager 统一处理，以确保传递正确的 BuildingResource
	pass
