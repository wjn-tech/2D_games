# Magic Muzzle Flash

## MODIFIED Requirements

### Requirement: Spell Casting Muzzle Flash
The visual effect played immediately upon spawning a projectile (the muzzle flash) MUST consist exclusively of a burst of pixel particles (`GPUParticles2D`) that dissipate quickly, and MUST NOT use scaled planar textures (like `Sprite2D` tweening).

#### Scenario: Firing a magic wand
- **Given** a player has a wand and fires a `magic_bolt`
- **When** the `play_muzzle_flash()` function is called
- **Then** a dense puff of 20-50 localized, rapidly decelerating 1x1 pixels erupts at the barrel of the wand, instantly replacing the massive flat sprite gradient of previous iterations.