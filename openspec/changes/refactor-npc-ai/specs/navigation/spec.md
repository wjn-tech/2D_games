# Spec: NPC Navigation

## ADDED Requirements

### Req: Procedural Pathfinding
NPCs must use the navigation system to reach destinations in the procedurally generated world.

#### Scenario: Navigate to Target
- **GIVEN** an active `NavigationRegion2D` in the current chunk.
- **AND** a `BaseNPC` with a `NavigationAgent2D`.
- **WHEN** the `BTNavigateTo` task sets a target position.
- **THEN** the NPC calculates a valid path and moves towards it, avoiding obstacles.

### Req: Navigation Staleness Check
NPCs must re-calculate paths if the environment (chunks) changes.

#### Scenario: Handle Chunk Load
- **GIVEN** an NPC moving towards a destination.
- **WHEN** a new chunk is loaded that alters the navigation mesh.
- **THEN** the `NavigationAgent2D` emits a recalculation signal.
