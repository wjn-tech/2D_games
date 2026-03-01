# Spec: Spell Visual Effects Optimization

## Overview
This spec defines the visual effect requirements for magic projectiles, aiming to match the dynamic particle behaviors of the reference implementation while adhering to the project's minimalist sci-fi pixel art style.

## ADDED Requirements

### Requirement: Fireball Trail
The fireball spell MUST emit a continuous trail of particles while traveling.
#### Scenario: Player casts Fireball
-   **Given** the player casts a Fireball spell
-   **When** the projectile is in flight
-   **Then** it should emit orange and red particles backwards relative to its flight path.
-   **And** the particles should scale down over time (lifetime ~0.5s).

### Requirement: Fireball Impact
The fireball spell MUST spawn an explosion effect upon impact.
#### Scenario: Fireball hits enemy
-   **Given** a Fireball projectile collides with an enemy or wall
-   **When** the projectile is destroyed
-   **Then** it should spawn a one-shot particle system (fx_fireball_impact) emitting rapidly expanding orange/yellow particles.-   **And** it should instantiate a `PointLight2D` (Orange) that fades out over ~0.5s.-   **And** the particles should fade out quickly (lifetime < 1.0s).

### Requirement: Magic Bolt Spiral Trail
The magic bolt spell MUST emit a spiraling trail of particles.
#### Scenario: Player casts Magic Bolt
-   **Given** the player casts a Magic Bolt
-   **When** the projectile is in flight
-   **Then** it should emit purple/pink particles that follow a spiral or orbital path around the projectile center.
-   **And** the particles should have a glowing additive blend mode.

### Requirement: Magic Bolt Impact
The magic bolt spell MUST spawn a magical burst upon impact.
#### Scenario: Magic Bolt hits wall
-   **Given** a Magic Bolt projectile collides
-   **When** impact occurs
-   **Then** it should spawn a burst of purple/white particles (fx_magic_impact) radiating outward.
-   **And** emit a `PointLight2D` (Purple) flash that quickly fades.

### Requirement: Blackhole Implosion Core
The blackhole spell MUST visualize a gravitational core effect.
#### Scenario: Player casts Blackhole
-   **Given** a Blackhole projectile is active
-   **When** it moves
-   **Then** it should emit dark purple/black particles that accelerate *inward* towards the center (negative radial acceleration).
-   **And** it should distort or darken the area behind it (using separation shader or dark sprite).
-   **And** maintain a constant active `PointLight2D` (Purple/Dark) at the center.

### Requirement: Blackhole Event Horizon
The blackhole spell MUST show a distinct event horizon boundary.
#### Scenario: Blackhole exists
-   **Given** the Blackhole projectile
-   **When** rendering
-   **Then** a ring of glowing particles (purple/indigo) should outline the pull radius.

### Requirement: Chainsaw Spark Emission
The chainsaw spell MUST emit rapid sparks.
#### Scenario: Player uses Chainsaw
-   **Given** the Chainsaw projectile is active (short range)
-   **When** it exists
-   **Then** it should emit high-velocity yellow/white spark particles in random directions from the tip.
-   **And** emit a flickering `PointLight2D` (Yellow/White) synced with the sparks.
-   **And** the particles should have very short lifetime (< 0.2s) and high damping.

### Requirement: VFX Auto-Cleanup
VFX scenes spawned on impact MUST automatically free themselves.
#### Scenario: Impact VFX finishes
-   **Given** an impact VFX scene (fx_fireball_impact) instantiated in the world
-   **When** its emitting stops and all particles expire
-   **Then** it should queue_free() itself (via script or animation signal).

### Requirement: VFX Visibility
VFX particles MUST be visible above the game world layers but below UI.
#### Scenario: Projectile renders
-   **Given** a projectile with attached GPUParticles2D
-   **When** rendered
-   **Then** the particles should be on z_index relative to the projectile or world layer (e.g., z_index = 0 or higher if flying).
-   **And** use additive properties (CanvasItemMaterial with Blend Mode: Add) for glowing effects where appropriate (Fire, Magic, Lightning).
