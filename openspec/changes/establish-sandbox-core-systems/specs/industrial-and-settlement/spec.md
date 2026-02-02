# Specification: Industrial and Settlement Systems

## ADDED Requirements

### Requirement: NPC Job Assignment
The system SHALL allow assigning recruited NPCs to specific functional buildings.

#### Scenario: Assigning a Farmer
- **GIVEN** A recruited NPC and a "Farm" building.
- **WHEN** The player assigns the NPC to the "Farm" via the Settlement UI.
- **THEN** The NPC moves to the farm and begins producing "Food" resources over time.

### Requirement: Industrial Logic and Energy
The system SHALL support logic-based automation and energy consumption.

#### Scenario: Powering a machine
- **GIVEN** A "Generator" and a "Crusher" connected by a "Wire".
- **WHEN** The Generator has fuel and is running.
- **THEN** The Crusher receives energy and can process raw ores into dust.

### Requirement: Formation Buffs
The system SHALL support tactical zones that provide combat or defensive bonuses.

#### Scenario: Activating a Defensive Formation
- **GIVEN** A "Formation Pillar" and required "Spirit Stones".
- **WHEN** The player inserts the stones into the pillar.
- **THEN** A zone is created that reduces incoming damage for all allies inside.
