# Tasks

- [x] Modify `MagicProjectileVisualizer` to use `GPUParticles2D` for high-density trails (60-120/sec). <!-- id: 0 -->
- [x] Create shared `GPUParticles2D` materials for standard elements: `vfx_material_sparks.tres`, `vfx_material_plasma.tres`, `vfx_material_gas.tres`, `vfx_material_void.tres`. <!-- id: 1 -->
- [x] Implement color variation logic in `MagicProjectileVisualizer` to set `color_ramp` for specific elements (Fire=White->Red, Magic=White->Cyan). <!-- id: 2 -->
- [x] Add `jitter` logic to `_process`: Offset the visual sprite by `(randf()-0.5)*2` perpendicular to velocity each frame. <!-- id: 3 -->
- [x] Implement `collision` on particle materials (if performant) for physical spark bounce. <!-- id: 4 -->
- [x] Tune particle density and lifetime to create "continuous beam" look instead of "discrete puffs". <!-- id: 5 -->
- [x] **Bespoke Polish 1**: `magic_bolt`, `magic_arrow`, `homing`, `tri_bolt` -> use `plasma` archetype (Turbulence). <!-- id: 6 -->
- [x] **Bespoke Polish 2**: `spark_bolt`, `chainsaw`, `tnt` -> use `sparks` archetype (Gravity/Bounce). <!-- id: 7 -->
- [x] **Bespoke Polish 3**: `fireball`, `cluster_bomb` -> use `gas` archetype (Rising/Expansion). <!-- id: 8 -->
- [x] **Bespoke Polish 4**: `blackhole` -> use `void` archetype (Radial Inward Gravity). <!-- id: 9 -->
- [x] Verify performance impact with 50+ active projectiles. <!-- id: 10 -->
