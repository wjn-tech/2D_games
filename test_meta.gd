@tool
extends EditorScript
func _run():
	var f = FileAccess.open(" user://saves/metadata.json\, FileAccess.READ)
 var t = f.get_as_text()
 print(\JSON length: \, t.length())
 var p = JSON.parse_string(t)
 print(\Parsed: \, typeof(p))

