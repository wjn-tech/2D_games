# Spec Delta: NPC Physics Consistency

## MODIFIED Requirements

### Requirement: NPC Gravity
NPCs must be affected by gravity in a way that is consistent with the player's physics.

#### Scenario: NPC in the air
- **Given** an NPC is spawned or moved into the air.
- **When** `_physics_process` runs.
- **Then** the NPC must fall towards the floor using a gravity constant (default 1400).

### Requirement: Floor Detection
NPCs must stop falling when they hit a floor tile.

#### Scenario: NPC landing
- **Given** an NPC is falling.
- **When** `is_on_floor()` becomes true.
- **Then** the vertical velocity must be reset.
