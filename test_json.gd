@tool
class_name TestJsonScript
extends EditorScript
func _run():
	var d = { " name\: \冒险�?\ }
 print(\JSON: \, JSON.stringify(d))

