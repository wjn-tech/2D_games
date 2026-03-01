# Spec: Detailed Particle Systems

## ADDED Requirements

### Requirement: Bespoke Spell Optimizations
Each projectile type MUST use a distinct physical particle simulation model.

#### Scenario: Magic Bolt (Plasma Archetype)
-   **Given** a `magic_bolt`, `magic_arrow`, or `tri_bolt` projectile.
-   **When** rendered.
-   **Then** the trail uses `material_plasma.tres` (Turbulence enabled, Gravity ~0, Additive Blend).
-   **And** the particle count is High (~100/sec) with short life (0.3s) to form a dense "beam".
-   **And** the main sprite jitters position by `+/- 1.5px` perpendicular to velocity.

#### Scenario: Spark Bolt / Chainsaw (Spark Archetype)
-   **Given** a `spark_bolt` or `chainsaw` projectile.
-   **When** rendered.
-   **Then** the trail uses `material_sparks.tres` (Gravity 98, Bounce Enabled, Spread 45 deg).
-   **And** particles are **heavy** (high initial velocity, drag slows them down, gravity pulls them).
-   **And** particles collide with the world map (bounce).

#### Scenario: Fireball (Gas Archetype)
-   **Given** a `fireball` or `cluster_bomb` projectile.
-   **When** rendered.
-   **Then** the trail uses `material_gas.tres` (Negative Gravity -10, High Damping).
-   **And** particles start small and expand in size over time (`scale_curve` up).
-   **And** color ramps from White -> Yellow -> Red -> Black Smoke.

#### Scenario: Bouncing Burst (Slime Archetype)
-   **Given** a `bouncing_burst` projectile.
-   **When** rendered.
-   **Then** the trail uses `material_slime.tres` (Gravity 98, Low Bounce/Sticky).
-   **And** particles are "dripping" (low initial velocity relative to projectile, just falling off).
-   **And** the main projectile deforms (squash/stretch) rather than vibrating.

#### Scenario: Blackhole (Void Archetype)
-   **Given** a `blackhole` projectile.
-   **When** rendered.
-   **Then** the trail particles are pulled **towards** the projectile center (Radial Gravity / Attractor).
-   **And** color is Inverted/Dark Purple.

### Requirement: Granular particle density
The system MUST emit particles at a high rate (e.g., 60-120 particles/second) to create a visual impression of a continuous stream or "body" of the projectile, rather than discrete puffs.

#### Scenario: Continous Stream
-   **Given** a projectile moving at 400 pixels/sec.
-   **When** it spawns particles at 60/sec.
-   **Then** particles spawn every ~6.6 pixels, creating a dense trail with overlaps.
-   **And** the particle texture is small (`2x2` pixels) to avoid screen fill issues.

### Requirement: Physical behavior
Particles MUST exhibit physical properties (Gravity, drag, initial velocity spread) appropriate to their element type.

#### Scenario: Spark Physics
-   **Given** a "Fire" or "Spark" projectile.
-   **When** it emits particles.
-   **Then** particles have gravity (`9.8`) and initial spread (`30 degrees`).
-   **And** particles MUST use collision (bounce) effectively with the world geometry, with a restitution of ~0.5.
-   **But** collision checking MUST be limited to a short radius or a subset of particles to maintain performance.

#### Scenario: Magic Turbulence
-   **Given** a "Magic" or "Plasma" projectile.
-   **When** it emits particles.
-   **Then** particles MUST exhibit **Smooth Swirl** noise (Simplex/Perlin-based force fields or Godot 4 Turbulence).
-   **And** they drift without gravity, creating a gaseous/fluid-like wake.

### Requirement: Material Color Ramps
All particle effects MUST use HDR color ramps that transition from a super-bright (White) core to the saturated element color, finally fading to transparent.

#### Scenario: Fire Color
-   **Given** a Fire projectile.
-   **When** a particle spawns.
-   **Then** its color starts effectively White (`Color(2, 2, 2)`).
-   **And** quickly transitions to Orange/Red (`Color(2, 0.5, 0)`).
-   **And** fades to transparent smoke color (`Color(0.2, 0.2, 0.2, 0)`).

## MODIFIED Requirements

### Requirement: Projectile Jitter
The main projectile sprite MUST jitter slightly perpendicular to its velocity vector each frame to simulate unstable energy.

#### Scenario: Bolt Instability
-   **Given** a moving Magic Bolt.
-   **When** `_process` runs.
-   **Then** the sprite's local Y position (relative to rotation) changes by `random(-1, 1)` pixels.
-   **And** this creates a "buzzing" or "vibrating" visual effect distinctive of high energy.

