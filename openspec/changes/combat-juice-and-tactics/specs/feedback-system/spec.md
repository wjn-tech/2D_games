# Spec: Feedback System

**Status**: Draft
**Version**: 1.0

## ADDED Requirements

### `FB-001` - Hit Stop Handling
#### Scenario: Player lands a heavy hit
- **Given** the player strikes an enemy with a generic "Heavy Attack".
- **When** the damage is applied.
- **Then** the `Engine.time_scale` freezes at `0.05` for `0.1s`.
- **And** immediately transitions back to `1.0` linearly over `0.05s`.
- **And** audio continues playing (Music bus unaffected, specialized SFX bus whitelist).

### `FB-002` - Visual Hit Confirm
#### Scenario: Projectile hits Enemy
- **Given** a projectile hits an enemy.
- **When** the collision event triggers.
- **Then** the enemy sprite shader parameter `flash_intensity` is set to `1.0` (White) for `0.1s`.
- **And** `BloodParticles` span at the impact point, oriented along the reflection vector of the bullet velocity.
- **And** a floating text number appears, drifting upwards and fading out over `0.8s`.

### `FB-003` - Screen Shake
#### Scenario: Explosion
- **Given** a bomb explodes near the camera.
- **When** the explosion deals damage.
- **Then** the camera offset shakes using a Perlin noise pattern with `trauma` value of `0.8`.
- **And** the `trauma` decays linearly to `0` over `0.5s`.
