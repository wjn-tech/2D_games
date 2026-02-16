extends Node

# Utility helpers for safe transform operations to avoid Transform2D inversion errors
class_name TransformHelper

static func safe_to_local(node: Node2D, world_point: Vector2) -> Vector2:
    # Obtain the global transform and compute determinant of basis vectors
    var t: Transform2D = node.get_global_transform()
    var a: Vector2 = t[0]
    var b: Vector2 = t[1]
    var det: float = a.x * b.y - a.y * b.x
    if abs(det) < 1e-8:
        # Degenerate transform: fallback to simple translation-only conversion
        return world_point - node.global_position
    return node.to_local(world_point)
