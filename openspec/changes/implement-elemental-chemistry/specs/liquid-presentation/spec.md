# Capability: Liquid Presentation

Rendering and non-authoritative visual effects for liquids.

## ADDED Requirements

### Requirement: Functional Liquid Bodies SHALL Render from Authoritative Fill Data
Visible liquid surfaces SHALL derive their baseline height and occupancy from the authoritative liquid state.

#### Scenario: Half-filled cell renders lower than full cell
- GIVEN two adjacent water cells where one has a smaller fill amount than the other
- WHEN the liquid surface is rendered
- THEN the less filled cell MUST visually read as a lower or thinner liquid state.

### Requirement: Liquid Types SHALL Expose Distinct Visual Identity
Different liquid types SHALL be able to provide separate color, opacity, emissive, or surface treatment cues.

#### Scenario: Lava emits a different presentation profile
- GIVEN a water pool and a lava pool rendered in comparable darkness
- WHEN the scene is displayed
- THEN the lava MUST be able to appear more emissive or visually dangerous than the water.

### Requirement: Decorative Liquidfalls SHALL Be Non-Authoritative
The presentation layer SHALL support decorative liquidfalls, drips, or seep effects that do not act as authoritative liquid volumes.

#### Scenario: Liquidfall remains visual-only
- GIVEN a decorative fall effect attached to level geometry
- WHEN the effect is visible on screen
- THEN it MAY animate independently without draining a full upstream reservoir from the authoritative simulation.

### Requirement: High-Fidelity Local Effects SHALL Remain Optional
Any metaball-like, droplet-based, or shader-fused local liquid enhancement SHALL remain an optional presentation layer rather than the required world simulation backend.

#### Scenario: Splash enhancement can be disabled without breaking liquid logic
- GIVEN optional near-camera splash or blob rendering inspired by a particle or shader technique
- WHEN that enhancement is disabled
- THEN liquid gameplay behavior and world-state correctness MUST remain intact.