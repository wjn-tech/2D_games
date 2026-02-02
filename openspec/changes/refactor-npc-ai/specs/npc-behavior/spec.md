# Spec: NPC Behavior Roles

## ADDED Requirements

### Req: Fighter AI Routine
Hostile NPCs must actively search for and engage targets.

#### Scenario: Aggressive Pursuit
- **GIVEN** a `Fighter` NPC in `Wander` state.
- **WHEN** a player enters `detection_range` on the same layer.
- **THEN** the BT switches to the `Chase` branch.

### Req: Passive Schedule
Passive NPCs should return home during night time.

#### Scenario: Go Home at Night
- **GIVEN** a `Passive` NPC wandering in the village.
- **WHEN** `SettlementManager.is_night` becomes true.
- **THEN** the BT triggers the `ReturnToHome` sequence.
