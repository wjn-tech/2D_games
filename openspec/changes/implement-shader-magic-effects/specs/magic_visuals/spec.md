# Capability: Magic Visuals

The system responsible for the visual representation of magical entities (projectiles, triggers, energy fields).

## ADDED Requirements

### Requirement: [MV-001] GPU-Driven Particle Substances
The magic system MUST use `GPUParticles2D` for all elemental magic to simulate fluid-like substances.
#### Scenario: Fire Elemental Trail
- **GIVEN** a fire-elemental projectile.
- **WHEN** the projectile is moving.
- **THEN** it must leave a trail of GPU particles with turbulence and color gradients (Red -> Yellow -> Grey).

### Requirement: [MV-002] Dynamic Energy Flow Shaders
Magic projectiles MUST use custom CanvasItem shaders for their core visual representation.
#### Scenario: Arcane Flow
- **GIVEN** a non-elemental magic bolt.
- **WHEN** rendered on screen.
- **THEN** it must display a scrolling noise-based energy flow effect rather than a solid color.

### Requirement: [MV-003] Performance-Integrated Materials
Shader materials and particle resources MUST be cached and reused to maintain 60FPS with 50+ active projectiles.
#### Scenario: Multi-Casting
- **GIVEN** a wand casting 20 projectiles per second.
- **WHEN** many projectiles are active simultaneously.
- **THEN** draw calls must be minimized by sharing `ParticleProcessMaterial` resources where possible.
