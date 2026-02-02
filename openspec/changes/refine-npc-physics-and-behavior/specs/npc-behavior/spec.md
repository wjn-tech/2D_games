# Spec Delta: NPC Tethered Behavior

## MODIFIED Requirements

### Requirement: Spawn Tethering
Most NPCs must remain within a defined radius of their initial spawn point during their wander state.

#### Scenario: Wandering near limit
- **Given** an NPC is in the `WANDER` state.
- **When** the distance from `spawn_position` exceeds `wander_radius`.
- **Then** the NPC must choose a new wander direction that leads back towards the `spawn_position`.

### Requirement: Neutral Personality Behavior
NPCs with a "Neutral" personality (neither Brave nor Timid) must exhibit passive behavior.

#### Scenario: Encountering Player
- **Given** a Neutral NPC detects a player.
- **When** the player is not Hostile and has not attacked the NPC.
- **Then** the NPC must remain in its current state (WANDER/IDLE) and not initiate CHASE or FLEE.
