# Ultimate Spell Visuals Architecture & Design

## Context
Our current `MagicProjectileVisualizer` was successful in stripping out bad `Sprite2D` artifacts and moving the game to a pure particle foundation. However, every spell is still built from the same blueprint: `GPUParticles2D` with `BLEND_MODE_ADD`.

This limitation prevents representation of dark energy, physical liquids, and sharp electrical branches. A black hole made of "dark additive light" doesn't make sense, and high-speed particles look like dotted lines without proper trailing.

## Proposed VFX Architecture

To achieve the "ultimate gorgeous" tier, `MagicProjectileVisualizer` will be structured to inject **Heterogeneous Rendering Nodes** based on spell identity:

### 1. Screen Distortion & Subtractive Rendering (Black Hole)
- **Node**: TextureRect with `ShaderMaterial`
- A spatial distortion shader reading `SCREEN_TEXTURE` to simulate gravitational lensing.
- A core `GPUParticles2D` utilizing `CanvasItemMaterial.BLEND_MODE_SUB` (Subtractive) instead of Additive. This explicitly subtracts RGB values from the background, creating true, deep, crushing void-black.

### 2. Procedural Lightning (Spark Bolt & Chainsaw)
- **Node**: Array of `Line2D` nodes driven by a noise-based jitter script.
- Particles alone are too soft for electricity. We will add a hard, zigzagging Line2D that updates every physics frame to draw jagged branches of lightning.
- Combined with a massive boost in particle quantity (100 -> 800) utilizing extreme tangential acceleration.

### 3. Native Particle Trails & Ribbons (Magic Bolt / Arrow)
- **Node Property**: `GPUParticles2D.trail_enabled = true`
- Godot 4 supports native trail rendering on GPU particles. By heavily modifying the `ParticleProcessMaterial.trail_length` and giving particles physical geometry, fast-moving spells will paint continuous glowing ribbons (comet tails) rather than a dotted Morse-code sequence.

### 4. Slime & Viscosity (Slime / Bouncing Burst)
- **Node Property**: `CanvasItemMaterial.BLEND_MODE_MIX` + Collision Sub-Emitters.
- Additive blending ruins the "wet/heavy" feel of poison and slime. These will use standard MIX blending to maintain a thick, opaque liquid look. 
- When hitting the ground, they will trigger a secondary particle mesh representing splashes.

## Extensibility
The `_apply_behavior_identity()` function will be expanded. Instead of just configuring a single trail and core material, it will orchestrate the instantiation of these auxiliary renderers (Shaders, Line2Ds) dynamically. Cleanup remains identical via `queue_free()` on the visualizer.

## Spell Differentiation Matrix

To ensure no spell looks generic or overlaps with another, all spells belong to an **Archetype** that acts as the hardware foundation, but overrides specific aesthetic parameters:

| Spell `id` | Archetype | Core Visual Concept & Signature Parameter |
|:---|:---:|:---|
| `magic_bolt` | **Energy** | Straight cyan light beam. *Signature:* High `trail_length`, dense emission. |
| `magic_arrow` | **Energy** | Purple razor-thin piercing needle. *Signature:* Narrow `scale`, extreme velocity. |
| `energy_sphere` | **Energy** | Slow pulsing orb. *Signature:* Sine-wave `scale_curve`, bright halo. |
| `spark_bolt` | **Electric** | Chaotic blue discharge. *Signature:* Procedural `Line2D` arcs, high spread. |
| `chainsaw` | **Electric** | Extreme forward friction sparks. *Signature:* Ultra-high `damping`, reverse-firing cones. |
| `fireball` | **Plasma** | Burning comet with ash. *Signature:* Secondary smoke emitter w/ heavy upward `scale_curve`. |
| `tnt` / `cluster_bomb` | **Plasma** | Heavy volatile chunk. *Signature:* Dropping spark embers, flashing core. |
| `slime` | **Fluid** | Caustic heavy drip. *Signature:* Opaque green `BLEND_MODE_MIX`, collision splashes. |
| `bouncing_burst` | **Fluid** | Voluminous acid globs. *Signature:* Opaque mixed neon, extreme positive gravity. |
| `blackhole` | **Void** | Light-eating abyss. *Signature:* `BLEND_MODE_SUB` pure black, Screen distortion Shader. |
| `teleport` | **Void** | Spatial rip. *Signature:* High `radial_accel` inward, instant flashing sub-core. |
| `tri_bolt` | **Energy** | (Normally shot in 3s via logic). Split-tail geometry. *Signature:* Wobbling `turbulence`. |
