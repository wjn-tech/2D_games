extends StaticBody2D
class_name InteractiveDoor

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

var is_open: bool = false
var hp: float = 2.0 # 门比石头脆弱

func _ready() -> void:
    add_to_group("destructible")
    add_to_group("interactable")
    _update_state()

func load_custom_data(data: Dictionary):
    if data.has("height"):
        var h = data["height"]
        # 调整 Sprite 和碰撞体以匹配高度
        var pixel_h = h * 16 # TILE_SIZE
        # 更新纹理拉伸
        if sprite.texture is GradientTexture2D:
            sprite.texture.height = pixel_h
        sprite.offset.y = -pixel_h
        
        # 更新碰撞体
        if collision.shape is RectangleShape2D:
            collision.shape.size.y = pixel_h
            collision.position.y = -pixel_h / 2.0
            
        # 更新检测区域
        var detect_col = $DetectionArea/CollisionShape2D
        if detect_col.shape is RectangleShape2D:
            detect_col.shape.size.y = pixel_h
            detect_col.position.y = -pixel_h / 2.0

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        open_door()

func _on_body_exited(body: Node2D) -> void:
    if body.is_in_group("player"):
        # 延迟一下关闭，防止卡在门口边缘一直闪烁
        await get_tree().create_timer(0.2).timeout
        # 再次检查区域内是否还有玩家
        if $DetectionArea.get_overlapping_bodies().is_empty():
            close_door()

func open_door():
    if is_open: return
    is_open = true
    _update_state()

func close_door():
    if not is_open: return
    is_open = false
    _update_state()

func _update_state():
    if is_open:
        sprite.modulate.a = 0.3 # 半透明表示打开
        collision.set_deferred("disabled", true)
    else:
        sprite.modulate.a = 1.0
        collision.set_deferred("disabled", false)

# 被挖掘/攻击时的逻辑
func hit(damage: float, _damage_source: Variant = null) -> void:
    hp -= damage
    # 简单的抖动视觉效果
    var tween = create_tween()
    tween.tween_property(sprite, "position:x", 2.0, 0.05)
    tween.tween_property(sprite, "position:x", -2.0, 0.05)
    tween.tween_property(sprite, "position:x", 0.0, 0.05)
    
    if hp <= 0:
        _destroy()

func _destroy():
    # 掉落物品逻辑
    _spawn_drop()
    queue_free()

func _spawn_drop():
    var loot_scene = load("res://scenes/world/loot_item.tscn")
    if loot_scene:
        var loot = loot_scene.instantiate()
        get_parent().add_child(loot)
        loot.global_position = global_position + Vector2(8, -16)
        
        # 加载门的数据资源并设置掉落物
        var door_item = load("res://data/items/door.tres")
        if door_item:
            loot.setup(door_item, 1)
        
        print("Door: 门已被挖掘，掉落物品: 门")
