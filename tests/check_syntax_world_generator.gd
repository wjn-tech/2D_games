extends SceneTree

func _init():
    var script = load("res://src/systems/world/world_generator.gd")
    if script:
        var instance = script.new()
        print("Syntax OK")
    else:
        print("Syntax Error")
    quit()