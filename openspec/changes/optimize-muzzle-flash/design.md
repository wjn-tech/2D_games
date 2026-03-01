# Muzzle Flash Particle Design

## Problem
The `play_muzzle_flash()` creates a flat `Sprite2D` gradient that scales up heavily and rapidly using a tween. When combined with nearest-neighbor texture filtering and high HDR values, this massive square completely overwhelms the scene with a gigantic diamond/square blob. It is fundamentally against the "densely clustered individual pixel particles" visual language established for the game.

## Solution Architecture
1. **Remove Flat Sprite Tween**: The `play_muzzle_flash` will no longer instantiate a `Sprite2D` that scales up.
2. **Instant Particle Burst**: The muzzle flash will instantiate a one-shot `GPUParticles2D`. 
   - Takes 20-40 particles.
   - Instantly blasts them out (`explosiveness = 1.0`).
   - Uses `spread = 45.0` to `90.0` depending on the spell (like a shotgun blast of magical dust at the tip of the wand).
   - Speed should be high (`initial_velocity > 150`) but with intense damping (`damping > 200`) so they burst and freeze quickly before fading, creating a "puff" rather than a continuous stream.
3. **Additive Blending**: Follow the same rules as the core particles (`BLEND_MODE_ADD`, solid white 1x1 texture).

This ensures every visual element (core, trail, muzzle flash, impact debris) is universally composed of `1x1` physics/math driven pixel points.