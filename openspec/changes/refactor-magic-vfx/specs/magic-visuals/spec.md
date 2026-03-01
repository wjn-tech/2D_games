# Spec: Magic Visual System

## ADDED Requirements

### Requirement: Preservation of Functional Logic
The refactoring MUST NOT alter any gameplay logic, damage calculations, element applications, or movement physics. Code related to stats, collision detection, and modifiers must remain identical to the original implementation.

#### Scenario: Logic Integrity
- GIVEN the original `projectile_base.gd` had a specific damage multiplier for "mana_to_damage"
- WHEN the refactor is applied
- THEN the calculation remains `damage *= float(m_params.get("damage_multiplier", 1.0))` exactly.

### Requirement: Preservation of Color Identity
The refactor MUST preserve the specific RGB color values used for each element (e.g., Fire = `Color(10.0, 2.0, 0.1)`) to maintain the existing artistic intent, only applying them through the new Visualizer.

#### Scenario: Color Match
- GIVEN the "Slime" element used `Color(0.2, 8.0, 0.2)`
- WHEN rendered by the new Visualizer
- THEN the pixel sprite is modulated by that exact HDR color.

### Requirement: Visual Hierarchy & Juice
Every projectile MUST have three distinct visual components: A solid Core (Sprite), a Trail (Particles), and a Glow (Light).

#### Scenario: Visual Readability
- GIVEN a projectile in flight
- WHEN viewed against a similar-colored background
- THEN the Core is still visible due to high opacity or outline.
- AND the Trail indicates the direction of travel.

### Requirement: Feedback Lifecycle
Projectiles MUST generate visual feedback at Spawn (Flash) and Death (Explosion).

#### Scenario: Impact Feedback
- GIVEN a projectile hitting a wall
- WHEN it is destroyed
- THEN a visual "Explosion" or "Dissipation" effect plays at the contact point.
- AND it is NOT just instantly removed from the screen.

## MODIFIED Requirements

### Requirement: Refactored ProjectileBase
`ProjectileBase` visually MUST appear unchanged in behavior/stats, delegating *only* the rendering responsibility to `MagicProjectileVisualizer`.
The logic MUST invoke `visualizer.on_hit()` or `visualizer.on_spawn()` hooks to trigger feedback effects without altering physics or damage.

#### Scenario: Non-Intrusive Integration
- GIVEN the `projectile_base.gd`
- WHEN the visualizer is attached
- THEN the projectile's velocity, damage, and collision logic remain EXACTLY the same.
- AND the visualizer reads the *existing* `element` and `damage` variables to determine color/size.
