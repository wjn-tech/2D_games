# Specification: Lighting System

## ADDED Requirements

### Requirement: Ambient and Local Lighting
The system SHALL provide a way to darken the world and allow local light sources to illuminate areas.

#### Scenario: Entering a cave
- **WHEN** The player moves deep underground.
- **THEN** The `CanvasModulate` darkens the screen.
- **AND** A torch held by the player (or placed on a wall) provides a radius of light.

### Requirement: Multi-layer Backgrounds
The system SHALL support background layers that provide depth and visual context.

#### Scenario: Parallax background
- **WHEN** The player moves horizontally.
- **THEN** Distant mountains or forest layers move at different speeds to create a 3D effect.
