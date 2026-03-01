# Specialize Spell Visuals Tasks

- [ ] 1. Modify `_create_pixel_fade_gradient()` or add `_create_complex_fade_gradient()` in `MagicProjectileVisualizer` to generate a multi-stage gradient (`White-Hot -> Saturated Base -> Dark/Clear`).
- [ ] 2. Update `Magic Bolt` identity: Enforce zero gravity, tight spread, making it a perfect straight comet tail. (Cyan to Deep Blue).
- [ ] 3. Update `Spark Bolt` identity: Apply `tangential_accel` to its particles so it physically zig-zags and spirals. Define a custom string for the muzzle flash type to use an arc style instead of a puff.
- [ ] 4. Update `Fireball` identity: Add logic to spawn a secondary `_trail_smoke_particles` just for fireball. The primary gives dropping red bouncing embers, the secondary gives scaling-up dark grey smoke.
- [ ] 5. Update `Bouncing Burst` identity: Reduce HDR color intensity for a duller look. Set high gravity on trails so droplets rain straight down.
- [ ] 6. Update `Chainsaw` identity: Hide the trailing core entirely. Convert it to a massive 180-degree spray of yellow/white metal sparks. 
- [ ] 7. Update `Black Hole / Teleport` identity: Use `BLEND_MODE_SUB` as its material blending mode, utilizing deep black/purple colors and inward radial acceleration to create an inverted void visual.
- [ ] 8. Refactor `play_muzzle_flash()`: Match the flash behavior to the spell's dominant color and shape requirements (arc vs puff).