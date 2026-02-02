# Spec Delta: NPC Spawning Logic

## MODIFIED Requirements

### Requirement: Ground-Only Spawning
NPCs must only be spawned on top of solid tiles and in empty space.

#### Scenario: Scattered NPC Generation
- **Given** the world generator decides to spawn a scattered NPC at X coordinate.
- **When** searching for a spawn Y.
- **Then** it must find the highest solid tile at X and place the NPC exactly one tile above it.

### Requirement: Reduced Spawn Density
The frequency of NPC encounters in the open world must be reduced.

#### Scenario: World Generation
- **Given** a world of size 200x100.
- **When** generation completes.
- **Then** the number of scattered (non-camp) NPCs should be significantly lower than the previous implementation (e.g., 5-10 total instead of dozens).

### Requirement: Camp Placement Safety
NPCs within a camp must be placed on valid ground even when offset from the camp center.

#### Scenario: Spawning Camp NPC with Offset
- **Given** a camp center at `(x, y)`.
- **When** an NPC is spawned with a horizontal offset.
- **Then** the generator must re-verify the ground level at the offset X to prevent the NPC from being stuck or floating.
