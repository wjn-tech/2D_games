@tool
extends SceneTree

const InfiniteChunkManagerScript = preload("res://src/systems/world/infinite_chunk_manager.gd")

func _init() -> void:
	var mgr = InfiniteChunkManagerScript.new()
	mgr.name = "InfiniteChunkManagerValidation"
	get_root().add_child(mgr)
	mgr._ready()

	_validate_telemetry_contract(mgr)
	_validate_dirty_flush_contract(mgr)

	print("Streaming hitch contract validation passed.")
	quit()

func _validate_telemetry_contract(mgr: Node) -> void:
	_assert(mgr.has_method("get_runtime_stage_telemetry"), "Missing telemetry query API")
	_assert(mgr.has_method("clear_runtime_stage_telemetry"), "Missing telemetry clear API")
	_assert(mgr.has_method("get_streaming_queue_snapshot"), "Missing queue snapshot API")

	var snapshot: Dictionary = mgr.get_streaming_queue_snapshot()
	for key in ["pending_critical", "pending_enrichment", "pending_unload", "pending_entity_spawn", "pending_dirty_flush", "dirty_coords"]:
		_assert(snapshot.has(key), "Queue snapshot missing key: %s" % key)

func _validate_dirty_flush_contract(mgr: Node) -> void:
	_assert(mgr.has_method("has_pending_dirty_flushes"), "Missing pending dirty flush API")
	_assert(mgr.has_method("request_dirty_flush_all"), "Missing request dirty flush API")	
	_assert(mgr.has_method("flush_pending_dirty_writes_sync"), "Missing sync dirty flush API")

	mgr.record_delta(Vector2(8, 8), 0, 1, Vector2i(0, 0))
	mgr.save_all_deltas(false, false)
	_assert(mgr.has_pending_dirty_flushes(), "Expected async dirty flush queue to contain work")

	mgr.flush_pending_dirty_writes_sync()
	_assert(not mgr.has_pending_dirty_flushes(), "Expected sync dirty flush to drain queue")

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
