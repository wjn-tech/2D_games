# Spec: NPC Spawning and Visuals

## MODIFIED Requirements: Visual Hostility
### Requirement: Telegraph Hostility
#### Scenario: Hostile NPC Spawned
- GIVEN a Hostile NPC is instance into the world
- WHEN the NPC's `_ready` is called
- THEN its `modulate` property MUST be set to a reddish tint (e.g., `Color(1.0, 0.4, 0.4)`).

## ADDED Requirements: Ecological Spawning
### Requirement: Valid Environment Check
#### Scenario: Attempting to Spawn NPC
- GIVEN a candidate spawn position in the world
- WHEN the `NPCSpawner` validates the location
- THEN it MUST verify the Foreground TileMapLayer (Layer 0) cell at that coordinate is empty.

### Requirement: Distance-Based Generation
#### Scenario: Player Explores World
- GIVEN the player is moving through the environment
- WHEN the distance traveled since the last spawn event exceeds the threshold
- THEN the `NPCSpawner` MUST trigger a new spawn attempt evaluation.
