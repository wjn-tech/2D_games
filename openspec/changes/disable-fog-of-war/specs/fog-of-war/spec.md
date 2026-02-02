# Spec Delta: Disable Fog of War

## MODIFIED Requirements

### Requirement: Fog of War Visibility
The Fog of War system must support being toggled on or off for development and debugging purposes.

#### Scenario: Disabling Fog of War
- **Given** the `FogOfWar` node is present in the scene.
- **When** the `enabled` property is set to `false`.
- **Then** the map should not be filled with fog tiles.
- **And** the `FogOfWar` layer should be invisible.
- **And** POI discovery logic should be suspended.
