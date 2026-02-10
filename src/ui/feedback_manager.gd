extends Node

## FeedbackManager (Autoload)
## Central system for spawning juice effects (Floating text, shakes, particles).

var floating_text_scene_path: String = "res://scenes/ui/effects/floating_text.tscn"

func play_shake(node: Control, intensity: float = 5.0, duration: float = 0.4) -> void:
    if not node: return
    
    # Check A11y
    if SettingsManager.get_value("General", "reduced_motion") == true:
        return

    # Simple tween shake
    var original_pos = node.position
    var tween = create_tween()
    tween.set_loops(int(duration * 10)) # frequency
    
    tween.tween_callback(func():
        var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
        node.position = original_pos + offset
    )
    tween.tween_interval(0.05)
    
    tween.finished.connect(func():
        node.position = original_pos
    )

func spawn_floating_text(pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
    # Ensure directory exists or check if loaded
    # For now, we'll create the text dynamically if scene doesn't exist to avoid crashing
    
    var label = Label.new()
    label.text = text
    label.add_theme_color_override("font_color", color)
    label.add_theme_font_size_override("font_size", 14)
    label.add_theme_color_override("font_outline_color", Color.BLACK)
    label.add_theme_constant_override("outline_size", 4)
    
    # Add to a high layer (e.g. UIManager or current scene root)
    var root = get_tree().current_scene
    root.add_child(label)
    label.global_position = pos + Vector2(0, -20) # Start slightly above
    
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(label, "global_position", pos + Vector2(0, -80), 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(label, "modulate:a", 0.0, 1.5).set_ease(Tween.EASE_IN).set_delay(0.5)
    
    tween.chain().tween_callback(label.queue_free)

func spawn_success_particles(pos: Vector2) -> void:
    # TODO: Implement particle scene
    pass
