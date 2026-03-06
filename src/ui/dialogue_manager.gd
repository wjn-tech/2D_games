extends Node

## DialogueManager (Autoload)
## 处理 NPC 对话逻辑。

signal dialogue_started(npc_name: String)
signal dialogue_finished
signal dialogue_event(event_name: String) # Added for tutorial sequences

func start_dialogue(npc_name: String, lines: Array, options: Array = []) -> void:
	var window = UIManager.open_window("DialogueWindow", "res://scenes/ui/DialogueWindow.tscn")
	if window and window.has_method("setup"):
		window.setup(npc_name, lines, options)
		dialogue_started.emit(npc_name)

func end_dialogue() -> void:
	UIManager.close_window("DialogueWindow")
	dialogue_finished.emit()

func pause_dialogue() -> void:
	var window = UIManager.active_windows.get("DialogueWindow")
	if window and window.has_method("pause"):
		window.pause()

func resume_dialogue() -> void:
	var window = UIManager.active_windows.get("DialogueWindow")
	if window and window.has_method("resume"):
		window.resume()

func next_line() -> void:
	var window = UIManager.active_windows.get("DialogueWindow")
	if window and window.has_method("_on_next_pressed"):
		window._on_next_pressed()
