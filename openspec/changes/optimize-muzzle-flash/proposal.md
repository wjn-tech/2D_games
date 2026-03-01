# Optimize Muzzle Flash Visuals

## What changes
Rewriting the `play_muzzle_flash()` function in `MagicProjectileVisualizer` to replace the single gigantic tweened `Sprite2D` plane with an explosive outward burst of zero-gravity pixel particles (`GPUParticles2D`). We will also remove or substantially soften the massive start-up hard light flicker.

## Why
Currently, the muzzle flash uses a tweened radial gradient `Sprite2D` that scales up dramatically when a spell is cast. Since we just enforced a pure-particle policy for the projectiles (#refine-magic-visuals-to-pure-particles), having a massive, smooth gradient sprite burst out on launch completely breaks visual consistency. It creates a giant, ugly blue diamond/square overlay in the world (as seen in user screenshot) because the edge filtering scales the 32x32 gradient inappropriately. Converting the muzzle flash to a localized, explosive particle blast (like sparks shooting backward or a puff of colored dust) fits the chaotic pixel aesthetic perfectly.

## Scope
Touches `MagicProjectileVisualizer.gd`, specifically the `play_muzzle_flash()` function. Does not affect game logic, physics bodies, or other VFX configurations.