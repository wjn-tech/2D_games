# Spell Differentiation

## MODIFIED Requirements

### Requirement: Spell Visual Variety
Spells MUST possess unique, identifiable visual profiles defined by distinct non-white color gradients, particle physical behaviors (e.g., gravity, scale curves over time, tangential acceleration), and spread architectures, ensuring no two spells look like identical clusters of generic white pixels.

#### Scenario: Firing dissimilar spells
- **Given** a player fires a `fireball` and then a `spark_bolt`
- **When** the projectiles travel across the screen
- **Then** the fireball leaves a rising, thick red-to-grey smoke trail that grows in size, while the spark bolt leaves a tight, erratic, spiraling blue electric trail.
