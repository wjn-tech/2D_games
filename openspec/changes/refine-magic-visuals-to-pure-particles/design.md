# Magic Pure Particle Design

## Problem
The `Sprite2D` implementation of the payload creates a noticeable, rotating square. When scaled, it completely breaks the illusion of "matter" and looks like cheap developer art. 

## Architectural Decision
Instead of drawing the core with a `Sprite2D`, we will construct the projectile *entirely* out of `GPUParticles2D`. 

A projectile will be composed of:
1. **Core Emitter (`local_coords = true`)**: A high-density emitter with zero/low spread and zero/low velocity. It constantly emits pixels in a tight radius, giving the body of the projectile organic jitter and fluid-like edges.
2. **Trail Emitter (`local_coords = false`)**: Inherits from `MagicParticleFactory`. Continuously drops pixels behind the core in world space.
3. No Sprites. Total reliance on `TEXTURE_FILTER_NEAREST` and `BLEND_MODE_ADD`.

## Rendering Details
To achieve brilliant glowing and distinct pixel boundaries at the same time:
- Each particle's size MUST strictly be 1x1 or 2x2. No upscaling flat textures. If we need a bigger pixel, we scale the particle `scale_min/max` by integer values but keep the texture a strict 1x1 white pixel.
- Additive blending (`BLEND_MODE_ADD` or `BLEND_MODE_ADD` mapped materials) will handle glow organically as multiple 1x1 particles overlap at the core.
- The `PointLight2D` glow should be purely atmospheric, very soft, and low opacity to avoid drowning out the sharp pixel contrasts.