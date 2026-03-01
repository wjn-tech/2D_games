# Magic VFX Polish - Chaotic Matter Style

## ADDED Requirements

### Requirement: Pixel Swarm Composition
Magical projectiles MUST be visualized as chaotic, ultra-dense clusters of pixels with distinct "matter" feel, simulating high-energy physics.

#### Scenario: Magic Bolt
This projectile uses a **Comet Core** design with extreme density.
-   **Core**: A dense `Sprite2D` cluster (4x4 to 6x6 dithered pixels), modulated with extreme HDR brightness (`Color(4, 4, 4)`).
-   **Glow**: A larger (32x32) soft halo sprite behind it.
-   **Trail**: An exceptionally dense `GPUParticles2D` emission.
    -   **Rate**: >200 particles/sec.
    -   **Behavior**: High drag, slight gravity, turbulence noise.
    -   **Lifetime**: Short (0.3s) but visually "thick".

#### Scenario: Spark Bolt
A tiny, erratic lightning spark.
-   **Jitter**: The core position MUST vibrate randomly (2px radius) every frame.
-   **Trail**: 1x1 pixels emitted at high frequency with high initial velocity spread (cone) to look like electrical discharge, not a smoke trail.
-	**Segments**: If the bolt hits instantly (Hitscan/Raycast), it renders as a jagged "Zigzag" polyline for 1 frame, NOT a straight beam.

### Requirement: Maximum Impact
Visuals MUST prioritize flash and saturation over geometric clarity to match the "Noita" aesthetic.

#### Scenario: Color Grading
-   **Core**: Always white-hot (`Color(5, 5, 5)` in HDR).
-   **Mid-Tone**: Pure saturated colors (Cyan, Red, Green).
-   **Fade**: Sharp cutoff.

## MODIFIED Requirements

### Requirement: Particle Physics
The particle system MUST simulate physics forces to sell the "magical matter" idea.
-   **Gravity**: All debris/spark particles must have gravity > 0.
-   **Initial Velocity**: Particles must inherit projectile velocity partially (`0.2` to `0.5`) but mostly explode outward/backward.

#### Scenario: Collision & Bounce
-   **Heavy Projectiles** (e.g. Acid, Lava, big explosions): Particles MUST collide with the world geometry (`collision_mode = Omni`).
-   **Bouciness**: Colliding particles should lose energy (friction) or bounce slightly. This creates "puddles" of sparks on impact rather than passing through walls.

#### Scenario: Optimization
To handle density + collision, `GPUParticles2D` is mandatory.
Collision requires `sub_emitter` or simple `collision_base_size` tuning to avoid heavy performance cost. Use judiciously.
