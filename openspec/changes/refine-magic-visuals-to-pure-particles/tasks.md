# Refine Magic Visuals To Pure Particles Tasks

- [x] 1. Modify `MagicProjectileVisualizer` initialization to remove entirely the `_core_sprite` and `_glow_sprite` creation and cleanup code.
- [x] 2. Update `MagicProjectileVisualizer` to initialize a new `_core_particles` GPUParticles2D node initialized with a 1x1 dot texture, tight spread, high density, and local coordinates to act as the projectile 'head'.
- [x] 3. Update the `_apply_behavior_identity()` method in `MagicProjectileVisualizer` to configure both `_core_particles` and `_trail_particles`. The core should have its scale/emission radius adjusted rather than a Sprite scale.
- [x] 4. Remove `_jitter_amount` and `_pulse_amount` logic that transforms the `_core_sprite` in `_process()`, instead relying entirely on the native jitter/velocities/turbulence of the particle material.
- [x] 5. Tune the `PointLight2D` glow to be substantially softer (or removed) to ensure the sharp edges of individual pixel particles remain the most striking visual element.
- [x] 6. Test all standard magical bolt types (magic_bolt, spark_bolt, fireball, bouncing_burst) in the wand editor/game scene to ensure they correctly render as swarms of distinct pixels without rotating square artifacts.