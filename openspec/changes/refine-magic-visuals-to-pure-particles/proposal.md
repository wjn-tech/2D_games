# Make Magic Visuals Pure Particles

## What changes
Convert the current magic projectile core and glow sprites into pure pixel particle emitters to match the Noita-inspired aesthetic of "dense collections of individual glowing pixels" rather than rotated solid quads. We will remove the large `Sprite2D` nodes entirely and instead use purely dense swarms of `GPUParticles2D`.

## Why
The magic visualizer uses `Sprite2D` nodes with a `4x4` hard-edged block for the core and a `32x32` gradient for the glow. Because these are scaled and then rotated based on velocity, they look like stiff, flat geometric planes. The user has specifically requested that "each pixel particle glows individually, magic is a collection of dense pixel particles, and the trail is the same". Relying solely on `BLEND_MODE_ADD` with 1x1 or 2x2 particles eliminates the rotating flat plane artifact while preserving high HDR saturation at the densest cluster.

## Scope
Affects `MagicProjectileVisualizer`. Particle materials in `MagicParticleFactory` may need minor adjustments to fit the new core-particle requirement. Does not change gameplay logic.