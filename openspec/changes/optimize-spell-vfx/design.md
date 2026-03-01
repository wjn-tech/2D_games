# Design: Spell VFX Optimization

## Overview
This design outlines the implementation of enhanced visual effects for magic projectiles using Godot's `GPUParticles2D` system, replacing simple drawing logic. The goal is to match the dynamic feel of the reference (`magic` folder) while adhering to the project's minimalist sci-fi pixel art style.

## Architecture

### 1. VFX Component Structure
Instead of hardcoding VFX logic in `ProjectileBase`, we will introduce a `ProjectileVFX` component (or specialized scenes) attached to each projectile.
This component may be a `Script` inheriting `ProjectileVFX` or simply a composition of nodes:
-   **Core**: `Sprite2D` (glowing orb/projectile core).
-   **Lighting**: **`PointLight2D`** (dynamic environment lighting, required by spec).
-   **Trail**: `GPUParticles2D` (constant emission in local or global space).
-   **Impact**: `GPUParticles2D` (one-shot emission triggered on collision).
-   **Ambient**: `GPUParticles2D` (constant emission for idle/flying state, e.g., glowing core).

### 2. Particle Materials & Textures
-   **Textures**: Strict adherence to **Simple Shapes**:
    -   Use generated `GradientTexture2D` (1x1 to 4x4 pixels) or `CurveTexture` for shapes.
    -   Avoid loading external PNG sprites for smoke/runes; stick to procedural circles/squares.
-   **Materials**: `ParticleProcessMaterial` resources will be created for each spell type to control movement (velocity, gravity, damping).
-   **Shaders**: Use `CanvasItemMaterial` with `Blend Mode: Add` for glowing effects (Science-Fantasy style).

### 3. Spell-Specific Designs (Reference Adaptation)
Based on `magic/src/lib/game/utils.ts`:

| Spell Type | Reference Effect | Godot Implementation | Palette Color (Approx) |
| :--- | :--- | :--- | :--- |
| **Fireball** | Explosion + Trail | Orange/Red particles with gravity/drag. Impact bursts outward. | `#FF4500` (Red-Orange) |
| **Frost** | Ice Crystals + Mist | Cyan/White sharp particles + soft slow mist. | `#00FFFF` (Cyan) |
| **Lightning** | Arc + Branch | Instant line drawing (using Line2D or stretched particles) + spark particles. | `#FFFF00` (Yellow) / `#FFFFFF` |
| **Magic Bolt** | Spiral Trail + Dust | Pink/Purple particles orbiting center (using orbit velocity). | `#FF00FF` (Magenta) |
| **Blackhole** | Implosion + Distortion | Particles subjected to radial attraction (negative radial accel). Dark core. | `#4B0082` (Indigo/Black) |
| **Slime** | Dripping + Splat | Green particles with high gravity + wall-stick logic (optional). | `#00FF00` (Lime) |
| **TNT** | Fuse Spark + Big Boom | Fuse spark trail + Large expanding ring explosion. | `#FF0000` (Red) |
| **Chainsaw** | Sparks + Blur | Rapid short-life yellow sparks + motion blur trail. | `#FFFF00` (Yellow) |
| **Teleport** | Flash + Fade | Quick scaling circle/flash + fading trail. | `#8A2BE2` (Blue-Violet) |

## Integration with Projectile System
-   **Modify `ProjectileBase`**:
    -   Remove `_draw()` logic related to simple shapes if replacing with sprites/particles.
    -   Add `on_impact()` hook to trigger impact particles before `queue_free()`.
    -   Manage `z_index` to ensure particles layer correctly (add mode).

## Unification Strategy
-   **Palette**: Use `minimalist_palette.png` colors directly where possible. For additive blending, use brighter versions of palette colors.
-   **Pixel Scale**: Ensure particle `scale` combined with texture size matches the pixel grid (e.g., 2x2 logical pixels).

## Performance Considerations
-   Use `GPUParticles2D` for all high-count effects.
-   Limit `amount` based on platform (though PC target allows 1000s).
-   Use `visibility_rect` culling.
