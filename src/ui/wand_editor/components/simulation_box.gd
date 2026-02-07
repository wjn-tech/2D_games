extends PanelContainer

var wand_data: WandData
@onready var arena = $VBox/ViewportContainer/SubViewport/Arena
@onready var spawn_point = $VBox/ViewportContainer/SubViewport/Arena/SpawnPoint
@onready var btn_run = $VBox/Controls/BtnRun
@onready var btn_close = $VBox/Header/BtnClose

func _ready():
	btn_run.pressed.connect(_run_sim)
	if btn_close:
		btn_close.pressed.connect(func(): visible = false)

func setup(data: WandData):
	wand_data = data
	visible = true

func _run_sim():
	if not wand_data: return
	
	# Clear previous
	for child in arena.get_children():
		if child is Node2D and child != spawn_point and child.name != "BG" and child.name != "Camera2D":
			child.queue_free()
			
	# Compile
	var program = WandCompiler.compile(wand_data)
	if not program.is_valid:
		print("Sim Error: ", program.compilation_errors)
		return
		
	# Execute
	# World Context is 'arena'
	SpellProcessor.execute_tier(program.root_tier, spawn_point.position, Vector2.RIGHT, arena)
