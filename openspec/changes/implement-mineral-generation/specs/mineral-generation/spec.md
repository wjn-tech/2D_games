# Mineral System Specs

## ADDED Requirements

### Requirement: [MIN-001] Mineral Resources
The system SHALL introduce 5 new specific mineral types (Iron, Copper, Magic Crystal, Staff Core, Magic Speed Stone) as distinct Item Resources with unique visual identifiers.

#### Scenario: Loot Table
Given a player mines a mineral block
When the block is broken
Then it must drop the specific `BaseItem` corresponding to that mineral (e.g., Iron Ore, Copper Ore).

#### Scenario: Visual Distinction
Given a mineral block is placed in the world
When viewed by the player
Then it must use a unique minimalist geometric icon from the palette, distinct from generic stone or dirt.

### Requirement: [MIN-002] Depth-Based Generation
The `WorldGenerator` SHALL use altitude (Y-level) as a primary factor for determining which minerals can spawn, creating distinct geological strata.

#### Scenario: Copper Distribution
Given the world generation at Shallow depth (Y < 100)
When a chunk is generated
Then Copper Ore should appear with moderate frequency.

#### Scenario: Magic Speed Stone Rarity
Given the world generation at Surface depth
When a chunk is generated
Then "Magic Speed Stone" should NOT appear (or be extremely rare).

Given the world generation at Deep depth (Y > 300)
When a chunk is generated
Then "Magic Speed Stone" should appear with very low frequency (Very Rare).

### Requirement: [MIN-003] Infinite Generation
The generation algorithm SHALL be deterministic based on world coordinates `(x, y)` and seed, ensuring continuity across chunk boundaries without generating global state maps.

#### Scenario: Chunk Boundaries
Given a vein of ore
When it crosses a chunk boundary (x=63 to x=64)
Then the vein should appear continuous and not cut off abruptly.

### Requirement: [MIN-004] Gameplay Integration
Minerals SHALL be fully integrated into the interaction system, having defined hardness (mining time) and correct dropper logic.

#### Scenario: Hardness (Future Proofing)
Given a "Magic Speed Stone" block
When the player attempts to mine it
Then it should ideally take longer to mine than plain Stone (handled by `hp` in logical tile data, or currently just visual).
*Note: Current digging system is simple 1-hit or time-based. We assume standard mining for now.*
