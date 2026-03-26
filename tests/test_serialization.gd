extends SceneTree

func _init():
	var chunk = WorldChunk.new()
	chunk.coord = Vector2i(1, 1)
	
	# 测试 Vector2i 作为键
	var pos_key = Vector2i(10, 20)
	chunk.add_delta(0, pos_key, 1, Vector2i(0, 0))
	
	print("Before saving, deltas[0] has key: ", chunk.deltas[0].has(pos_key))
	print("Deltas before: ", chunk.deltas)
	
	var save_path = "user://test_chunk_serialization.tres"
	var err = ResourceSaver.save(chunk, save_path)
	if err != OK:
		print("Save failed with error: ", err)
		quit()
		return

	# 重新加载
	var loaded_chunk = ResourceLoader.load(save_path)
	if not loaded_chunk:
		print("Load failed")
		quit()
		return
		
	print("After loading, deltas[0] keys: ", loaded_chunk.deltas[0].keys())
	
	var found = false
	for key in loaded_chunk.deltas[0].keys():
		if key is Vector2i:
			print("Found Vector2i key: ", key)
			if key == pos_key:
				found = true
		else:
			print("Found key of type: ", typeof(key), " value: ", str(key))
			if str(key) == str(pos_key):
				print("Wait, it was converted to string?")

	if found:
		print("SUCCESS: Vector2i key preserved.")
	else:
		print("FAILURE: Vector2i key lost or converted.")
	
	# 清理
	var dir = DirAccess.open("user://")
	dir.remove("test_chunk_serialization.tres")
	
	quit()
