extends Node2D

@onready var player = $Player
@onready var fade_rect = $FadeLayer/FadeRect
@onready var shake_timer = $ShakeTimer
@onready var camera = $Player/Camera2D

var _shake_amplitude: float = 0.0
var _original_cam_pos: Vector2

var _waiting_for_magic: bool = false
var _waiting_for_crafting: bool = false
var _has_skip_started: bool = false

var dialogue_lines = [
	"The Kingdom of Magic... shattered. The stars are crying out.",
	"Those abominations from the planet below have robbed the logic of magic itself from our dimension.",
	"<emit:rumble_mild> The ship cannot hold! They are shooting at us with our own stolen powers!",
	"<emit:give_items> Take this... it's the last wand embryo of the Royal Guard, and some scrap materials.",
	"They broke our rules, but the spark remains. You must reconnect the logic.",
	"<emit:show_magic> Quick, assemble a basic combat spell! Use the trigger and the core!",
	"Good... it might just save you. But we are also out of supplies.",
	"<emit:show_crafting> Open your pack. Familiarize yourself with manual crafting if you survive the landing.",
    "<emit:crash_start> BRACE FOR IMPACT! Rebuild the Kingdom...!"
]

func _ready():
	print("Tutorial Sequence Manager Ready")
	# Lock player input and hide HUD if possible
	await get_tree().process_frame
	if player:
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)
	# Player input disable
	if EventBus and EventBus.has_signal("player_input_enabled"):
		EventBus.player_input_enabled.emit(false)
	
	if camera:
		_original_cam_pos = camera.position
	
	if shake_timer:
		shake_timer.timeout.connect(_on_shake_timer)
		shake_timer.start()
	
	if DialogueManager and DialogueManager.has_signal("dialogue_event"):
		DialogueManager.dialogue_event.connect(_on_dialogue_event)
	if DialogueManager and DialogueManager.has_signal("dialogue_finished"):
		DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	
	if UIManager and UIManager.has_signal("window_closed"):
		UIManager.window_closed.connect(_on_ui_closed)
	
	await get_tree().create_timer(1.0).timeout
	if DialogueManager:
		DialogueManager.start_dialogue("Court Mage", dialogue_lines)

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel") and not _waiting_for_magic and not _waiting_for_crafting and not _has_skip_started:
		# Skip mechanism
		if DialogueManager:
			DialogueManager.end_dialogue()
		_start_crash_sequence()

func _on_shake_timer():
	if camera and _shake_amplitude > 0:
		camera.position = _original_cam_pos + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_amplitude
	else:
		if camera:
			camera.position = _original_cam_pos

func _on_dialogue_event(event_name: String):
	match event_name:
		"rumble_mild":
			_shake_amplitude = 5.0
		"give_items":
			_give_tutorial_items()
		"show_magic":
			_waiting_for_magic = true
			_open_wand_editor()
		"show_crafting":
			_waiting_for_crafting = true
			if UIManager:
				UIManager.open_window("CraftingWindow", "res://scenes/ui/CraftingWindow.tscn", true)
		"crash_start":
			_start_crash_sequence()

func _open_wand_editor():
	if UIManager:
		UIManager.open_window("WandEditor", "res://src/ui/wand_editor/wand_editor.tscn", true)

func _give_tutorial_items():
	var wand = load("res://scenes/test_wand.tres")
	if wand and GameState and GameState.inventory:
		var copy = wand.duplicate(true) # Give a fresh clone
		GameState.inventory.add_item(copy)
	
	var materials = [
		"res://data/items/bone_fragment.tres",
		"res://data/items/magic_crystal.tres",
        "res://data/items/slime_essence.tres"
	]
	
	var inventory_autoload = GameState.inventory if GameState else null
	if inventory_autoload:
		for mat_path in materials:
			var item = load(mat_path)
			if item:
				inventory_autoload.add_item(item, 1)

func _on_ui_closed(window_name: String):
	if window_name == "WandEditor" and _waiting_for_magic:
		var is_valid = false
		var inventory_autoload = GameState.inventory if GameState else null
		if inventory_autoload and inventory_autoload.hotbar:
			for slot in inventory_autoload.hotbar.slots:
				if slot and slot.item and "wand_data" in slot.item:
					var w_data = slot.item.wand_data
					if w_data and "logic_nodes" in w_data and w_data.logic_nodes.size() > 0:
						is_valid = true
						break
		
		if is_valid:
			_waiting_for_magic = false
		else:
			# Reopen immediately and print warning to console
			print("TUTORIAL: Must assemble magic!")
			call_deferred("_open_wand_editor")
			
	elif (window_name == "Inventory" or window_name == "CraftingWindow") and _waiting_for_crafting:
		_waiting_for_crafting = false

func _on_dialogue_finished():
	if not _has_skip_started:
		_start_crash_sequence()

func _start_crash_sequence():
	if _has_skip_started: return
	_has_skip_started = true
	_shake_amplitude = 30.0
	
	if fade_rect:
		var tween = create_tween()
		tween.tween_property(fade_rect, "color:a", 1.0, 2.0)
		await tween.finished
	
	# Unlock input before transitioning
	if EventBus and EventBus.has_signal("player_input_enabled"):
		EventBus.player_input_enabled.emit(true)
	get_tree().change_scene_to_file("res://scenes/main.tscn")
