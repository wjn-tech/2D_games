# Blueprint System Spec

## ADDED Requirements

### Requirement: Blueprint Resource Extraction
The system MUST support defining blueprints in Resources, replacing hardcoded arrays.

#### Scenario: Loading a House
Given a `BlueprintResource` with layout and palette
When `InfiniteChunkManager` generates a structure
Then it should use the Resource data instead of `MY_CUSTOM_HOUSE_DESIGN`.

### Requirement: Mixed Content Support
Blueprints MUST support mixing Tiles, Scenes, and Entities (NPCs) in the same grid.

#### Scenario: Blacksmith Shop
Given a Blueprint with symbols `A` (Anvil Scene) and `B` (Blacksmith NPC)
When the building is generated
Then a `TileMap` structure is built for walls/floor
And an `Anvil` node is instantiated at the `A` position
And a `Blacksmith` NPC is spawned at the `B` position.
