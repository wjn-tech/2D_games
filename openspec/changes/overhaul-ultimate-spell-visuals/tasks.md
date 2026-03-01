# Tasks

1. [x] **Implement Subtractive & Shader Support for Black Hole**
   - Create a `BackBufferCopy` + `ColorRect` combo inside `MagicProjectileVisualizer` for screen distortion.
   - Attach a custom distortion shader using `sampler2D screen_tex : hint_screen_texture`.
   - Update `blackhole` logic in `_apply_behavior_identity()` to use a `CanvasItemMaterial.BLEND_MODE_SUB` GPUParticles2D layer for the absolute black core.
2. [x] **Implement Procedural Lightning for Spark Bolt**
   - Add a `Node2D` container for dynamic `Line2D` arcs in the visualizer.
   - Write standard noise/jitter logic in `_process()` that draws multi-segment lines radiating outward from the Spark Bolt's core if `behavior_name == "spark_bolt"`.
   - Boost Spark Bolt's particle amount to 800+ and tweak high velocity tangentials to mask the jagged lines in a chaotic storm of electricity.
3. [x] **Implement Continuous Ribbon Trails**
   - Update the particle generation logic to support Godot 4's native `trail_enabled` parameter.
   - For `magic_bolt` and `magic_arrow`, set `_trail_particles.trail_enabled = true` and define a sensible `trail_lifetime` / `trail_sections` in a new ribbon texture.
   - Verify that this solves the "dotted line" issue at high speeds.
4. [x] **Overhaul Slime & Liquids (Mix Blending)**
   - Update `bouncing_burst` and `slime` to bypass the default Additive blended material. Ensure they use `CanvasItemMaterial.BLEND_MODE_MIX`.
   - Enhance the size, scale curves, and collision shapes of the drops to represent heavy globs of viscosity.
5. [x] **Implement Complete Spell Differentiation Matrix**
   - Refactor `_apply_behavior_identity()` to include explicit `match` blocks for *all* instantiated project ids (e.g., `magic_arrow`, `teleport`, `energy_sphere`, `tri_bolt`, `tnt`, `cluster_bomb`).
   - Assign the exact structural archetype (Line2D, Ribbon, Physics-Mix, Subtractive) and signature parameters defined in `design.md` for every single spell.
6. [x] **Validate Performance and Integrity**
   - Spawn multiple of these new spells at once (using the Wand Editor).
   - Ensure the `queue_free()` logic properly cleans up Shaders and Line2D components so memory doesn't leak.