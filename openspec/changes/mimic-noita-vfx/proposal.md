# Proposal: Noita-Style Magic VFX

[Metadata]
- Author: Agent
- Status: Draft
- Created: 2026-02-28
- Type: Polish
- Scope: ProjectileBase, MagicProjectileVisualizer, Shaders

## Summary
The current VFX implementation (a sparse, linear trail of identical blue orbs) fails to capture the "chaotic energy" and "high-density materiality" seen in the reference *Noita* screenshots. This proposal shifts the visual strategy from "discrete sprites" to **"high-density, physics-lite particle systems"**. We aim to replace the "string of pearls" look with a "surging energy stream" composed of hundreds of tiny, short-lived, glowing pixels that scatter and fade non-uniformly.

## Problem Statement
Comparing our current state (Image 4) to the reference material (Images 1-3):
1.  **Density Gap**: Our trails have large gaps between particles (10-20px); *Noita* trails are a continuous stream of overlapping pixels.
2.  **Uniformity Issue**: Our particles are identical in size/opacity; *Noita* particles vary wildly in lifespan, velocity, and brightness.
3.  **Lack of Chaos**: Our trails are perfectly straight; *Noita* trails have "jitter" (perpendicular velocity), gravity influence, and drag interaction.
4.  **Flat Lighting**: Our sprites are flat-colored circles; *Noita* effects use intense HDR bloom where the core is white-hot and the edge is saturated.
5.  **Materiality**: Currently, everything looks like "blue gas". The reference images show "yellow sparks" (heavy, bouncing), "purple plasma" (light, seeking), and "green acid" (dripping).

## Proposed Solution
We will overhaul the `MagicProjectileVisualizer` to prioritize **Particle Volume** over single-sprite fidelity.

1.  **High-Frequency Emitters**: Increase emission rate from ~10/sec to ~60-120/sec per projectile, using `GPUParticles2D` for performance.
2.  **Physics Simulation**:
    -   **Gravity**: Sparks fall, plasma floats.
    -   **Drag**: Particles should slow down rapidly, creating a "cloud" behind the projectile.
    -   **Spread**: Emitters need a `spread` angle (e.g., 15-30 degrees) so trails aren't perfect lines.
3.  **Color Temperature**:
    -   Use `Color(2.0, 2.0, 2.0)` (HDR White) for the particle *start* color.
    -   Fade to the elemental color (Red/Cyan) over the particle's lifetime.
4.  **Pixel Fidelity**:
    -   Use `1x1` or `2x2` pixel textures exclusively for the trail to allow for high counts without fill-rate issues.
    -   Apply a "Jitter" shader or script logic to randomly offset trail points.

## Risks & Mitigation
-   **Performance**: 100 projectiles * 100 particles = 10,000 particles.
    -   *Mitigation*: Use `GPUParticles2D` only. Use `visibility_rect` to cull off-screen particles. Lower counts on low-end hardware settings.
-   **Visual Noise**: Too much chaos can obscure gameplay.
    -   *Mitigation*: Keep the *projectile head* distinct and bright; make trail particles fade quickly (0.3s - 0.5s).

## Staffing
-   Agent
