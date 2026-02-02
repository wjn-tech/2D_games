extends Node

const SAVE_PATH = "user://savegame.tres"

func save_game():
	var save_data = {
		"player_pos": get_tree().get_first_node_in_group("player").global_position if get_tree().has_group("player") else Vector2.ZERO,
		"game_time": GameState.current_time,
		"player_stats": GameState.player_data.stats,
		"inventory_slots": GameState.inventory.slots
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("游戏已保存")

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		GameState.current_time = save_data.get("game_time", 0.0)
		GameState.player_data.stats = save_data.get("player_stats", GameState.player_data.stats)
		GameState.inventory.slots = save_data.get("inventory_slots", [])
		GameState.inventory.inventory_changed.emit()
		
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.global_position = save_data.get("player_pos", Vector2.ZERO)
		
		print("游戏已加载")
