# Design: Legacy VFX Reconstruction

## Visual Design Logic

We will extract the "Soul" of each spell from the `projectile_base.gd` logic and map it to 3 specific `MagicProjectileVisualizer` components:
1.  **Sprite** (The main shape/core)
2.  **Trail** (The particle/line wake)
3.  **Behavior** (Blinks, pulses, spins, jitters)

### 1. Magic Bolt (Refactor)
*   **Old Soul**: `Color(20.0, 1.0, 50.0)` (Magenta/Purple HDR), `core_width = 6.0`. Dense, heavy, slow pulse.
*   **New Implementation**:
    *   **Sprite**: `ProceduralGenerator.make_jagged_orb(8)` (White Core, Purple Rim).
    *   **Trail**: `Plasma` archetype (Turbulence enabled). Color Ramp: White -> Magenta (`Color(20, 1, 50)`) -> Transparent.
    *   **Behavior**: Slow, rhythmic pulse `scale = 1.0 + sin(t*5)*0.2`. Jitter is low-frequency, high-amplitude (wobble).

### 2. Spark Bolt (Refactor)
*   **Old Soul**: `Color(1.0, 5.0, 50.0)` (Blue/White HDR), `core_width = 1.5` (Needle). Erratic, fast.
*   **New Implementation**:
    *   **Sprite**: `ProceduralGenerator.make_pixel_spark(4)` (1px jagged line segment).
    *   **Trail**: `Sparks` archetype (Gravity 9.8, Bounce). Color Ramp: White -> Cyan -> Blue.
    *   **Behavior**: Main sprite rotates randomly every frame (`rotation = randf()*TAU`). Position jitters violently (`+/- 2px`).

### 3. Bouncing Burst / Slime (Refactor)
*   **Old Soul**: `Color(40.0, 40.0, 2.0)` (Yellow/Green HDR). Expanding ring pulse.
*   **New Implementation**:
    *   **Sprite**: `ProceduralGenerator.make_slime_blob(6)` (Irregular blob).
    *   **Trail**: `Slime` archetype (Gravity 9.8, Sticky/Drip). Color Ramp: White -> HDR Yellow -> Green slime.
    *   **Behavior**: Sprite squashes on bounce (listen to `body_entered`?). Continuous `scale` pulse `1.0 -> 1.5 -> 1.0` (Ring effect simulation).

### 4. Chainsaw (Refactor)
*   **Old Soul**: `Color(100, 100, 100)` (Blinding White). Instant damage, explosion on spawn.
*   **New Implementation**:
    *   **Sprite**: `ProceduralGenerator.make_sawblade(12)` (Spiky wheel).
    *   **Trail**: `Sparks` archetype (Heavy metallic). Color: Pure White -> Grey.
    *   **Behavior**: Sprite spins extremely fast (`rotation += delta * 20`). Muzzle flash is a large `ProceduralGenerator.make_explosion_cloud` sprite.

### 5. Fireball (Refactor)
*   **Old Soul**: `Color(10.0, 2.0, 0.1)` (Deep Orange). Large core, burning trail.
*   **New Implementation**:
    *   **Sprite**: `ProceduralGenerator.make_fire_core(10)` (Orange noise).
    *   **Trail**: `Gas` archetype (Rising smoke). Color Ramp: White -> Orange -> Red -> Black.
    *   **Behavior**: Sprite flickers opacity `modulate.a = randf_range(0.8, 1.0)`.

## Code Cleanup
-   **Remove**: `_add_heavy_trail`, `_add_spark_trail`, `_add_ring_pulsate`, `_add_explosion_on_spawn` from `projectile_base.gd`.
-   **Remove**: `trail`, `body_line`, `gpu_particles` variables from `projectile_base.gd` (or disable their usage entirely).
