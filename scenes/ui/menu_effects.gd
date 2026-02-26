extends Control

@onready var sparkles: GPUParticles2D = $Sparkles
@onready var runes: GPUParticles2D = $Runes

func _ready() -> void:
	# Connect to resize signal to handle dynamic resolution changes
	get_tree().root.size_changed.connect(_on_viewport_resized)
	# Wait for layout
	await get_tree().process_frame
	_on_viewport_resized()

func _on_viewport_resized() -> void:
	var viewport_size = get_viewport_rect().size
	var center_pos = viewport_size / 2
	var extents = Vector3(viewport_size.x / 2, viewport_size.y / 2, 1)

	if sparkles:
		sparkles.position = center_pos
		# Accessing process material safely
		if sparkles.process_material is ParticleProcessMaterial:
			sparkles.process_material.emission_box_extents = extents

	if runes:
		runes.position = center_pos
		if runes.process_material is ParticleProcessMaterial:
			runes.process_material.emission_box_extents = extents

