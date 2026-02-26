extends CPUParticles2D

func _ready() -> void:
    emitting = true
    one_shot = true
    finished.connect(queue_free)