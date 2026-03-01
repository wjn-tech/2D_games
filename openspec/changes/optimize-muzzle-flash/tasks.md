# Muzzle Flash Optimization Tasks

- [x] 1. Delete all `Sprite2D` and `Tween` instantiating code from the `play_muzzle_flash()` function inside `src/systems/magic/visuals/magic_projectile_visualizer.gd`.
- [x] 2. Update `play_muzzle_flash()` to dynamically create a `GPUParticles2D` node with `one_shot = true` and `explosiveness = 1.0`.
- [x] 3. Apply the standard 1x1 white pixel texture and additive material (`BLEND_MODE_ADD`) to the flash particles.
- [x] 4. Create a `ParticleProcessMaterial` inside `play_muzzle_flash()` that shoots particles forward (or omnidirectionally) with high initial velocity, but extremely high damping so they form a sudden short-lived "puff" of magical debris.
- [x] 5. Connect the `finished` signal (or a timer fallback) of the particle system to `queue_free()` to ensure the temporary particle flash cleans itself up.