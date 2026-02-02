# Specification: World and Combat Systems

## ADDED Requirements

### Requirement: Layered Combat Planes
The system SHALL support multiple physical planes (layers) that characters can transition between.

#### Scenario: Transitioning layers via door
- **WHEN** A player interacts with a "Layer Door".
- **THEN** The player's collision layer and mask are updated to the target layer.
- **AND** The player can now only interact with objects and enemies on that specific layer.

### Requirement: Cross-Layer AI Pursuit
Enemies SHALL be able to follow the player across layers if a path exists.

#### Scenario: Enemy chasing player through a door
- **GIVEN** An enemy on Layer A and a player who just moved to Layer B.
- **WHEN** The enemy loses direct contact.
- **THEN** The enemy AI searches for the nearest "Layer Door" to reach Layer B.

### Requirement: Magnet Item Pickup
The system SHALL automatically pull nearby loot items toward the player.

#### Scenario: Mining a block
- **WHEN** A block is destroyed and drops an item.
- **THEN** If the item is within the player's "Magnet Range", it moves toward the player until collected.
