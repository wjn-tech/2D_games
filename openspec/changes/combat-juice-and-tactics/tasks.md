# Tasks: Combat Polish & Tactical AI

**Change ID**: `combat-juice-and-tactics`

## Phase 1: Infrastructure & Feedback (The Feel)

- [ ] `sys.combat.feedback_manager`: Create `FeedbackManager` autoload.
    - [ ] Implement `trigger_hit_stop(duration, time_scale)` with tween recovery.
    - [ ] Implement `trigger_screen_shake(intensity, duration, decay)`.
    - [ ] Implement `spawn_floating_text(position, value, type)`.
- [ ] `sys.combat.vfx`: Create standard VFX scenes.
    - [ ] `HitFlashShader`: precise shader for sprite whining.
    - [ ] `BloodParticles`: GPUParticles2D for flesh hits.
    - [ ] `BlockSparks`: GPUParticles2D for parries/blocks.
- [ ] `sys.combat.integration`: Hook into `ProjectileBase` and `WeaponSystem`.
    - [ ] Modify `take_damage` interface to accept `hit_info` (position, normal, force).
    - [ ] Fire feedback events upon damage application.

## Phase 2: NPC Intelligence (The Brain)

- [ ] `sys.npc.fsm`: Implement generic `StateMachine` and `State` classes for NPCs.
- [ ] `sys.npc.states`: Implement core states.
    - [ ] `StateIdle` / `StatePatrol`.
    - [ ] `StateChase` (with navigation smoothing).
    - [ ] `StateFlank` (circle around target).
    - [ ] `StateAttack` (Charge -> Active -> Recovery phases).
    - [ ] `StateStagger` (interruption logic).
- [ ] `sys.npc.telegraph`: Add visual indicators.
    - [ ] `WarningIndicator` (exclamation mark or flash) pre-attack.

## Phase 3: Player Mechanics & Tuning

- [ ] `sys.player.stamina`: specific `StaminaComponent`.
- [ ] `sys.balance`: Create resource `CombatConfig.tres` for global tuning (hit stop times, shake curves).
- [ ] `sys.test`: Create `gym_combat.tscn` for testing mechanics in isolation.
