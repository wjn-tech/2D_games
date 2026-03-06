extends Node2D
class_name ShipEnvironmentController

# Configuration
@export var max_shake_strength: float = 30.0
@export var alarm_pulse_speed: float = 5.0
@export var alarm_color_normal: Color = Color.RED
@export var alarm_color_critical: Color = Color.MAGENTA

# Scene References
@onready var global_light: CanvasModulate = $CanvasModulate
@onready var alarm_light: PointLight2D = $Lights/AlarmLight
@onready var console_light: PointLight2D = $Lights/ConsoleLight
@onready var spark_emitters: Node2D = $SparkEmitters
@onready var steam_vents: Node2D = $SteamVents
@onready var props: Node2D = $Props

# State
enum AlertLevel { CALM, YELLOW, RED, CRITICAL, BREACH }
var current_alert_level: int = AlertLevel.CALM
var time_accum: float = 0.0
var shake_intensity: float = 0.0

func _ready() -> void:
    if not global_light:
        push_warning("ShipEnvironmentController: CanvasModulate not found")
    
    set_alert_level(AlertLevel.CALM)

func _process(delta: float) -> void:
    time_accum += delta
    _process_lighting(delta)
    _process_shake(delta)

func set_alert_level(level: int) -> void:
    current_alert_level = level
    match level:
        AlertLevel.CALM:
            _set_particles_active(false)
            if global_light: global_light.color = Color(0.8, 0.8, 0.8, 1) # Normal lighting
            if alarm_light: alarm_light.enabled = false
            
        AlertLevel.YELLOW:
            _set_particles_active(false)
            if global_light: global_light.color = Color(0.6, 0.6, 0.5, 1) # Dim
            if alarm_light: 
                alarm_light.enabled = true
                alarm_light.color = Color.YELLOW
                alarm_light.energy = 0.5

        AlertLevel.RED:
            _set_particles_active(true, 1.0)
            if global_light: global_light.color = Color(0.3, 0.3, 0.4, 1) # Dark
            if alarm_light:
                alarm_light.enabled = true
                alarm_light.color = alarm_color_normal
                alarm_light.energy = 1.5

        AlertLevel.CRITICAL:
            _set_particles_active(true, 2.0)
            if global_light: global_light.color = Color(0.2, 0.1, 0.1, 1) # Very dark red
            if alarm_light:
                alarm_light.enabled = true
                alarm_light.color = alarm_color_critical
                alarm_light.energy = 2.0

        AlertLevel.BREACH:
            breach_hull()

func _process_lighting(_delta: float) -> void:
    if current_alert_level >= AlertLevel.RED:
        # Pulse alarm light
        var pulse = (sin(time_accum * alarm_pulse_speed) + 1.0) * 0.5
        if alarm_light and alarm_light.enabled:
            alarm_light.energy = 1.0 + (pulse * 1.5)
            
        # Flicker console light occasionally
        if randf() < 0.05:
            console_light.enabled = !console_light.enabled

func _process_shake(delta: float) -> void:
    if shake_intensity > 0:
        shake_intensity = lerp(shake_intensity, 0.0, delta * 2.0)

func flicker_lights(_duration: float = 0.5) -> void:
    # Rapidly toggle global light visibility or energy
    var tween = create_tween()
    for i in range(5):
        tween.tween_callback(func(): global_light.visible = !global_light.visible)
        tween.tween_interval(0.05)
    tween.tween_callback(func(): global_light.visible = true)

func breach_hull() -> void:
    current_alert_level = AlertLevel.BREACH
    _set_particles_active(true, 5.0)
    
    # Violent changes
    if global_light:
        global_light.color = Color(0.1, 0.1, 0.3, 1) # Cold vacuum blue
    
    if alarm_light:
        alarm_light.color = Color.CYAN # Emergency seal color?
        alarm_light.energy = 3.0
    
    shake_intensity = 1.0

func _set_particles_active(active: bool, scale: float = 1.0) -> void:
    if spark_emitters:
        for child in spark_emitters.get_children():
            if child is CPUParticles2D:
                child.emitting = active
                child.scale_amount_min = scale
    if steam_vents:
        for child in steam_vents.get_children():
            if child is CPUParticles2D:
                child.emitting = active
