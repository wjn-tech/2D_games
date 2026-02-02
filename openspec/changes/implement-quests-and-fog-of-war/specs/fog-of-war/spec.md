# Spec Delta: Fog of War

## ADDED Requirements

### Requirement: Map Obscuration
The world must be initially obscured by a Fog of War.

#### Scenario: Starting the Game
- **Given** the game has started and the world is generated.
- **When** the player looks at the map.
- **Then** areas outside the player's immediate vicinity must be covered by black tiles.

### Requirement: Dynamic Revelation
The Fog of War must reveal areas as the player explores.

#### Scenario: Moving the Player
- **Given** the player is moving across the map.
- **When** the player enters a new tile.
- **Then** tiles within a defined radius (e.g., 8 tiles) must be permanently revealed.
