# Spec: Visual Style

## MODIFIED Requirements

### Requirement: Projectile Appearance
Projectiles MUST match the "Minimalist/Abstract" aesthetic.

#### Scenario: Pure Geometry
- **Given** a projectile is spawned
- **Then** it renders as a solid, pure-color rectangle (e.g., `ColorRect` or flat texture).
- **And** it does NOT use the default Godot icon or noisy sprites.

### Requirement: Elemental Feedback
Visuals MUST reflect logic modifiers.

#### Scenario: Fire Blast
- **Given** a spell with a "Fire Core" modifier
- **When** the projectile is fired
- **Then** it is colored Red/Orange.
- **And** emits simple square particles (if particles enabled).

#### Scenario: Ice Blast
- **Given** a spell with an "Ice Core" modifier
- **When** the projectile is fired
- **Then** it is colored Cyan/Blue.

#### Scenario: Multiple Blasts
- **Given** a spell with a Splitter or multiple Triggers
- **When** cast
- **Then** multiple distinct projectiles SHALL be visible (verified by slight spread or exact count).
