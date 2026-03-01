# Tasks: Optimize Spell VFX

- [x] 0.1 Prepare Particle Resources
    - Create `res://assets/particles/particle_square.tres` (GradientTexture2D 2x2 white square)
    - Create `res://assets/particles/particle_circle.tres` (GradientTexture2D 4x4 or 8x8 circle)
    - Create `res://assets/particles/particle_spark.tres` (GradientTexture2D 1x3 line)

- [x] 0.2 Create VFX Base Components
    - Create reusable `res://src/systems/magic/vfx/vfx_trail.tscn` (GPUParticles2D + PointLight2D)
    - Create reusable `res://src/systems/magic/vfx/vfx_impact.tscn` (GPUParticles2D + PointLight2D One-Shot)

- [x] 1.0 Implement Core Spells (Matching Reference)
    - [x] 1.1 **Fireball**: Create `vfx_fireball_trail.tscn` (Orange/Red) & `vfx_fireball_impact.tscn`
    - [x] 1.2 **Magic Bolt**: Create `vfx_magic_trail.tscn` (Purple/Pink Spiral) & Impact
    - [x] 1.3 **Blackhole**: Create `vfx_blackhole_core.tscn` (Implosion) & Impact
    - [x] 1.4 **Teleport**: Create `vfx_teleport_flash.tscn` (Blue Flash)

- [x] 2.0 Implement Godot-Exclusive Spells
    - [x] 2.1 **Slime**: Create `vfx_slime_trail.tscn` (Green drip) & Splat
    - [x] 2.2 **TNT**: Create `vfx_tnt_fuse.tscn` (Sparkle) & Explosion
    - [x] 2.3 **Chainsaw**: Create `vfx_chainsaw_sparks.tscn` (Rapid yellow sparks)
    - [x] 2.4 **Tri-Bolt**: Create `vfx_tribolt_trail.tscn` (Cyan triple stream)

- [x] 3.0 Integrate with Projectiles
    - [x] 3.1 Modify `ProjectileBase` to instantiate impact VFX on collision.
    - [x] 3.2 Update `Fireball.tscn` to use new VFX scenes.
    - [x] 3.3 Update `MagicBolt.tscn` to use new VFX scenes.
    - [x] 3.4 Update all other projectile scenes.

- [x] 4.0 Art Style Verify
    - [x] 4.1 Ensure all colors match `minimalist_palette.png` (or additive variants).
    - [x] 4.2 Verify pixel scale consistency across all effects.

- [x] 5.0 Performance Tune
    - [x] 5.1 Check `draw_calls` and particle counts.
    - [x] 5.2 Optimize `visibility_rect`.
