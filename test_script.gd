@tool
extends EditorScript
func _run():
	var enc = Marshalls.utf8_to_base64(" hello\)
 print(\Encoded: \, enc)
