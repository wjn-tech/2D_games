# Design: Magic VFX Polish

## Visual Language: "Chaotic Particle Matter"

Targeting: **Noita-like "Simulation" Aesthetic**
Based on gameplay reference analysis, the magic shouldn't look like "sprites moving linearly". It must look like **projected matter**:

1.  **High-Octane Density**:
    -   A "Laser" isn't a line; it's a tight stream of 100+ sparks per second.
    -   A "Fireball" isn't a round sprite; it's a spinning erratic core spewing a cone of smoke and embers.
    -   **Reference Note**: Noita wands effectively act like particle emitters with physics.

2.  **Chaotic Trajectory**:
    -   Projectiles shouldn't move in perfect straight lines.
    -   **Jitter**: The core position should vibrate slightly (0.5-2px) each frame to simulate unstable energy.
    -   **Turbulence**: Trail particles must use `turbulence` or high `spread` so they don't form a perfect line, but a "messy" trail.

3.  **Extreme HDR Contrast**:
    -   **White Hot Cores**: The center of *every* energetic projectile is pure white (`Color(4,4,4)`).
    -   **Glow as Halo**: The color comes *only* from the surrounding glow sprite and the fading particles.
    -   **Flash over Form**: Short-lived, high-intensity flashes (muzzle/impact) are more important than the flying projectile's detail.

## Core Architecture Refactor

### 1. `MagicProjectileVisualizer` -> `ParticleProjectileEmitter`
We are effectively changing the visualizer from a "Sprite Manager" to mobile "Particle Emitter".
-   **Core**: A "leading" spark (Sprite2D) that jitters.
-   **Main Trail**: High-rate `GPUParticles2D` (World Space).
-   **Secondary Trail**: Low-rate, larger "smoke/gas" particles for volume (optional, for Fire/Poison).
-   **Physics**: Simple gravity applied to particles helps sell the "liquid/heavy" feel.

### 2. Particle Configuration Strategy
To achieve the "Thick" look without killing the GPU:
-   **Texture**: 2x2 Pixel (dithered).
-   **Emission**: ~200/sec.
-   **Lifetime**: Short (0.3s).
-   **Result**: ~60 particles alive per projectile. 10 projectiles = 600 particles. Very manageable.
-   **Critical**: `process_material.scale` should start at `1.0` and scale down/fade out.

### 3. Feedback Systems
-   **Muzzle Flash**: NOT just a circle. A **Cone** of sparks exiting the wand.
-   **Impact**:
    -   **Flash**: 1-frame giant light.
    -   **Sparks**: High velocity, high drag (bouncing functionality if possible).
    -   **Debris**: Actual texture chunks (if hitting ground).

## Why this approach?
The user's reference images show "messy" magic. Lines are jagged, sparks fly everywhere, and light saturates the screen. Our previous "clean pixel art" approach was too sterile. We need to introduce **controlled noise** and **saturation** to match the reference.
