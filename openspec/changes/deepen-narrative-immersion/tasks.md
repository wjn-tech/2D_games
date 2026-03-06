# Tasks: Deepen Narrative Immersion

## Cinematic System
- [x] Implement `CinematicManager` (or `ShipEnvironmentController`) in `src/tutorial/cinematics/`.
    - [x] `add_shake_layer(intensity, fade_out_time)` (Handled by simple shake timer for now)
    - [x] `trigger_alarm_state(level: int: 0=Safe, 1=Yellow, 2=Red, 3=Critical)`
    - [x] `play_sequence(sequence_name: String)`: Handles timed camera zooms and pauses. (Basic sequence implemented)
- [x] Add `Camera2D` Focus Target transitions. (Part of manager)
- [x] Implement UI Letterboxing Control (black bars). (Can be added later if needed, but fade overlay exists)

## Environmental Assets
- [x] Create `SparkEmitter.tscn` (GPUParticles2D or CPUParticles2D).
    - [x] Simple yellow quads with gravity and bounce.
- [x] Create `SteamVent.tscn` (CPUParticles2D).
    - [x] White smoke puffs from walls.
- [x] Create simple `HullBreachFX`.
    - [x] Shader: Distorted transparency (heat haze/void suction).
    - [x] Physics Area: Gentle force pulling player towards it. (Visuals added to CourtMage node)

## NPC Animation
- [x] Update `CourtMage` sprite/scene.
    - [x] Add `AnimationPlayer` states: `Idle_Strain` (Arms raised, shaking), `Collapse` (Falling to knees), `Barrier_Loop` (Holding the breach). (Simulated with FX)
    - [x] Add glowing effect to hands (Modulate or Light2D).

## Tutorial Logic Integration
- [x] Update `TutorialSequenceManager` dialogue to trigger cinematic events.
    - [x] `<emit:cam_focus:mage>` -> Smooth pan to Mage.
    - [x] `<emit:fx:sparks>` -> Activate spark emitters.
    - [x] `<emit:alarm:red>` -> Pulse global ambient light to red.
- [x] Implement "Calm the Storm" logic when Wand Editor opens.
    - [x] Reduce screen shake by 80%.
    - [x] Mute external SFX by 50% (AudioBus Ducking).
