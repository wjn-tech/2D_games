# Proposal: Comprehensive Magic VFX Polish

[Metadata]
- Author: Agent
- Status: In-Progress
- Created: 2026-02-28
- Type: Polish
- Scope: Visuals Only (ProjectileBase + MagicProjectileVisualizer)

## Summary

Based on detailed user critique, the previous "minimalist pixel" approach was too faint and weak. The user clarified they want a **"Collection of Pixel Dots"** similar to *Noita's Magic Bolt*—a dense, high-energy cluster of pixels with a thick, heavy trail, not just a single fleeing dot.

## Problem Statement

1.  **Too Faint**: The 1x1/2x2 single sprite approach is invisible in the game world.
2.  **Lack of Volume**: The projectile lacks "mass". Noita's magic feels like a heavy glob of energy.
3.  **Trail Thinness**: Current particle counts (30-50) are too low to create a "solid" trail look.

## Proposed Solution (Heavy Pixel)

We will shift from "Minimalist Dot" to **"High-Density Cluster"**:

1.  **Core Composition**:
    -   **Primary Sprite**: Increase core size to **4x4 or 6x6 pixels** (dithered circle or noise pattern), not just 1x1.
    -   **Glow Sprite**: Add a larger, low-opacity sprite behind it (16x16) to simulate bloom without HDR if needed, or rely on HDR `Color(3, 3, 3)`.
2.  **Particle Density**:
    -   **Massive Count Increase**: Increase trail particle counts from ~30 to **200+**.
    -   **Short Lifetime, High Emission**: Visualize the "comet tail" by emitting hundreds of 1x1 pixels per second.
3.  **Behavior**:
    -   **Gravity**: Add slight gravity to trail particles so they "drip" or "fall" like heavy plasma (classic Noita look).
    -   **Color Ramp**: Bright White -> Saturated Color -> Invisible (Sharp cutoff).

## Risks
-   **Performance**: 200 particles per projectile * 100 projectiles = 20,000 particles. *Mitigation*: ensure `GPUParticles2D` is used efficiently, use low lifetimes.

## Staffing
-   Agent (Implementation)
