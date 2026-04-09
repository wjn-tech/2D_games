extends SceneTree
func _init():
    var text = "Hello"
    var b64
    if ClassDB.class_exists("Marshalls"):
        b64 = Marshalls.utf8_to_base64(text)
    else:
        var buf = text.to_utf8_buffer()
        b64 = Marshalls.utf8_to_base64(text) if "Marshalls" in buf else "Marshalls removed! -> " + Marshalls.utf8_to_base64(text) 
    print(b64)
    quit()
