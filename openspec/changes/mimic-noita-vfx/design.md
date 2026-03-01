# Design: Noita-Style Magic VFX

## Visual Analysis
The reference screenshots reveal several distinct characteristics:
1.  **Dense Particle Trails**:
    -   *Noita*: Continuous "lines" made of particles.
    -   *Current*: Discrete, uniformly spaced orbs.
2.  **Physics-Affected Trails**:
    -   *Noita*: Particles have momentum (they keep moving forward but slow down) and gravity (they often arc or fall).
    -   *Current*: Particles appear to be static "smoke puffs" left behind in world space, with no physics.
3.  **Color Grading**:
    -   *Noita*: White-hot centers -> Saturated edges -> Black. The "glow" is often an additive blend mode.
    -   *Current*: Flat blue circles.
4.  **Material Variety**:
    -   *Noita*: "Sparks" bounce; "Plasma" drifts; "Acid" drips.
    -   *Current*: Everything looks like the same blue gas, just different colors.

## Implementation Strategy

### 1. High-Density Particle Emission
-   **Old**: 10 particles/sec, lifetime 1.0s. Result: gaps.
-   **New**: 60-120 particles/sec, lifetime 0.3-0.5s. Result: dense, short trail.
-   **Texture**: 1x1 or 2x2 white pixel. Rely on count, not size.

### 2. Physics & Chaos
-   **Gravity**: Add `gravity = Vector3(0, 98, 0)` to spark-like trails.
-   **Spread**: Add `spread = 15` degrees to emitters.
-   **Damping**: Add `damping_min = 20`, `damping_max = 50` so particles don't fly forever; they should burst out and stop, forming a cloud.
-   **Turbulence**: Use `turbulence_enabled = true` (Godot 4 feature) for magical/gaseous trails to make them swirl.

### 3. HDR Color Strategy
-   **Start Color**: `Color(2, 2, 2, 1)` (HDR White).
-   **Mid Color**: The element's core color (e.g., `Color(2, 0.5, 0, 1)` for fire).
-   **End Color**: Transparent shielding or black.
-   **Color Ramp**: Use a `GradientTexture1D` for smooth transition.

### 4. Jitter / Offset
-   For "Lightning" or "Energy" bolts, the main sprite itself should jitter position every frame by 1-2 pixels perpendicular to velocity.
-   Trails should spawn with random initial velocity perpendicular to the projectile path to widen the "beam".

## Architectural Changes
-   Modify `MagicProjectileVisualizer` to configure `GPUParticles2D` with these high-density settings.
-   Create specialized `ParticleProcessMaterial` resources for different archetypes:
    -   `material_sparks.tres`: High gravity, high spread, high bounce (collision).
    -   `material_plasma.tres`: Low gravity, turbulence, additive blend.
    -   `material_gas.tres`: Negative gravity (rises), high damping, slow fade.

## Bespoke Spell Optimizations

We map each existing spell behavior to a specific Noita-style archetype:

### 1. High-Energy Projectiles (Plasma Archetype)
*   **Behaviors**: `magic_bolt`, `magic_arrow`, `homing`, `tri_bolt`
*   **Visual**: Intense, smooth-swirling plasma wake.
*   **Physics**: Turbulence enabled, Gravity ~0.
*   **Jitter**: Moderate sprite displacement to look "unstable".

### 2. Physical Projectiles (Spark Archetype)
*   **Behaviors**: `spark_bolt`, `chainsaw` (sparks), `cluster_bomb` (fragmentation)
*   **Visual**: Shower of heavy, bouncing sparks.
*   **Physics**: High Gravity (9.8), Bounce Collision (0.5), High Spread (45 deg).
*   **Jitter**: High, erratic movement.

### 3. gaseous/Combustion Projectiles (Gas Archetype)
*   **Behaviors**: `fireball`, `tnt` (smoke trail), `blackhole` (reverse gas)
*   **Visual**: Rising smoke/flame trail that slows down quickly.
*   **Physics**: Negative Gravity (Rising), High Damping (Drag).
*   **Jitter**: Low, mostly smooth expansion.

### 4. Biological/Fluid Projectiles (Slime Archetype)
*   **Behaviors**: `bouncing_burst` (Slime)
*   **Visual**: Dripping fluid trail.
*   **Physics**: Gravity (9.8), Sticky Collision (No Bounce), Drips leave stains (if possible, otherwise just fade).
*   **Jitter**: Squash and stretch deformation instead of position jitter.

