# Proposal: Optimize Spell VFX & Unify Art Style

## Summary
Refactor and enhance the visual effects (VFX) of all magic projectiles to match the dynamic, particle-rich style of the reference implementation (`magic` folder example), adapted to the project's "Minimalist Sci-Fi Pixel Art" aesthetic. This involves replacing simple sprite/draw logic with dedicated `GPUParticles2D` systems.

## Motivation
The current spell effects rely on basic sprites or simple `_draw()` calls which lack visual impact and game-feel feedback compared to the reference implementation. Aligning these effects with the unified art style (minimalist sci-fi) will improve visual coherence and player satisfaction.

## Proposed Changes
1.  **Create Particle VFX Scenes**: Implement dedicated scenes (e.g., `vfx_fireball.tscn`, `vfx_blackhole.tscn`) using `GPUParticles2D` to mimic the behavior of the reference particles (trails, explosions, glows).
2.  **Integrate with Projectile System**: Update `ProjectileBase` and specific projectile scenes to instantiate and manage these VFX scenes.
3.  **Unify Art Style**: Ensure all particles use the project's color palette (`minimalist_palette.png`) as a base, leveraging additive blending for sci-fi glows. Use pixel-art friendly textures (1x1, 2x2, or simple shapes).
4.  **Optimize Performance**: Use GPU particles instead of CPU-intensive drawing where possible.

## Clarifying Questions & Assumptions
-   **VFX Tech**: We will use `GPUParticles2D` as the primary method.
-   **Scope**: We will update all existing spells in Godot (Fireball, Magic Bolt, Bouncing Burst, Tri-Bolt, Chainsaw, Slime, TNT, Blackhole, Teleport) to match the new style.
-   **Palette**: We will adhere to the `minimalist_palette.png` but allow additive blending for critical game-feel elements (glows, explosions).

## Alternatives Considered
-   **Custom `_draw()`**: Rejected due to performance concerns with high particle counts in GDScript.
-   **Shader-only**: Partially used (for trails/glows), but particles offer more flexible "physical" behavior like the reference.
