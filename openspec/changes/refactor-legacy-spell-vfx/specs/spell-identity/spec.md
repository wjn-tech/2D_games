# Spec: Spell Identity Migration

## MODIFIED Requirements

### Requirement: Magic Bolt Identity
The `magic_bolt` MUST be rendered as a **High-Density Plasma Stream** using the exact HDR color `Color(20.0, 1.0, 50.0)`.

#### Scenario: Visual Consistency
-   **Given** a fired `magic_bolt`.
-   **When** rendered.
-   **Then** the sprite is a jagged orb modulated by `Color(20, 1, 50)`.
-   **And** the trail emits 120 particles/sec in a turbulent stream using the same color ramp (White -> Purple -> Transparent).
-   **And** the sprite pulses scale rhythmically.

### Requirement: Spark Bolt Identity
The `spark_bolt` MUST be rendered as a **Violent White-Blue Spark** using the exact HDR color `Color(1.0, 5.0, 50.0)`.

#### Scenario: Visual Consistency
-   **Given** a fired `spark_bolt`.
-   **When** rendered.
-   **Then** the sprite is a 1-pixel jagged line segment modulated by `Color(1, 5, 50)`.
-   **And** the sprite jitters position by `+/- 2px` every frame.
-   **And** the trail emits heavy bouncing sparks (Gravity 98, Bounce Enabled).

### Requirement: Bouncing Burst Identity
The `bouncing_burst` MUST be rendered as a **Pulsating Radioactive Slime** using the exact HDR color `Color(40.0, 40.0, 2.0)`.

#### Scenario: Visual Consistency
-   **Given** a fired `bouncing_burst`.
-   **When** rendered.
-   **Then** the sprite is an irregular blob modulated by `Color(40, 40, 2)`.
-   **And** the sprite scales `1.0 -> 1.5 -> 1.0` continuously to mimic the old "ring pulsate" effect.
-   **And** the trail emits sticky slime droplets.

### Requirement: Legacy Code Removal
The legacy function `_add_heavy_trail`, `_add_spark_trail`, `_add_ring_pulsate`, and `_add_explosion_on_spawn` MUST be removed from `projectile_base.gd`.
The variables `trail`, `body_line`, and `gpu_particles` MUST NOT be used for rendering active projectiles.

#### Scenario: Code Clarity
-   **Given** `projectile_base.gd`.
-   **When** `_update_visuals` is called.
-   **Then** it delegates entirely to `MagicProjectileVisualizer`.
-   **And** no `Line2D` or old `GPUParticles2D` nodes are created or updated.
