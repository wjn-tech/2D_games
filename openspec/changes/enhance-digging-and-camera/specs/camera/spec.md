# Spec: Camera Zoom and Focus

## MODIFIED Requirements

### Requirement: Dynamic Camera Zoom
#### Scenario: Using the mouse wheel
- **Given** the player is in the game world.
- **When** the player scrolls the mouse wheel up.
- **Then** the camera zoom should increase (zoom in), clamped at `4.0`.
- **When** the player scrolls the mouse wheel down.
- **Then** the camera zoom should decrease (zoom out), clamped at `1.5`.

### Requirement: Character Prominence
#### Scenario: Zooming in
- **When** the camera is zoomed in to `4.0`.
- **Then** the player character should appear significantly larger on screen, occupying a major portion of the vertical space.
