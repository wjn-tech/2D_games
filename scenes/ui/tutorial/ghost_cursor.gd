class_name GhostCursor
extends Control

@onready var hand_sprite: Node2D = $HandSprite
@onready var item_icon: Sprite2D = $ItemIcon
@onready var line_2d: Line2D = $ConnectionLine

var start_pos: Vector2
var end_pos: Vector2
var duration: float = 1.5
var loop_timer: float = 0.0
var active: bool = false
var curve: Curve

func _ready() -> void:
    # Setup curve for smooth movement
    curve = Curve.new()
    curve.add_point(Vector2(0, 0))
    curve.add_point(Vector2(1, 1), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)

func start_drag(start: Vector2, end: Vector2, icon_texture: Texture2D = null):
    start_pos = start
    end_pos = end
    active = true
    loop_timer = 0.0
    
    if icon_texture:
        item_icon.texture = icon_texture
        item_icon.visible = true
    else:
        item_icon.visible = false
        
    line_2d.visible = false
    visible = true
    
func start_connect(start: Vector2, end: Vector2):
    start_pos = start
    end_pos = end
    active = true
    loop_timer = 0.0
    
    item_icon.visible = false
    line_2d.visible = true
    line_2d.points = [Vector2.ZERO, Vector2.ZERO]
    visible = true

func stop():
    active = false
    visible = false
    queue_free()

func _process(delta: float) -> void:
    if not active: return
    
    loop_timer += delta
    if loop_timer > duration:
        loop_timer = 0.0
    
    var t = loop_timer / duration
    # Simple ease-in-out or linear
    t = smoothstep(0.0, 1.0, t)

    if line_2d.visible:
        # Connecting wire
        var current_pos = start_pos.lerp(end_pos, t)
        hand_sprite.global_position = current_pos
        line_2d.points = [start_pos - global_position, current_pos - global_position]
    else:
        # Dragging item
        var current_pos = start_pos.lerp(end_pos, t)
        hand_sprite.global_position = current_pos
        if item_icon.visible:
            item_icon.global_position = current_pos + Vector2(10, 10) # Offset slightly
            
            # Fade out item near end to imply "drop"
            if t > 0.8:
                item_icon.modulate.a = 1.0 - ((t - 0.8) * 5.0)
            else:
                item_icon.modulate.a = 1.0
