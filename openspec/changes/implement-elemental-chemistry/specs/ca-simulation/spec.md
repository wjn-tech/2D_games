# Capability: CA Simulation

The authoritative cellular liquid simulation used by the world.

## ADDED Requirements

### Requirement: Liquid Cells SHALL Track Partial Fill and Type
The simulation SHALL represent functional liquid as authoritative cells with a liquid type and a bounded fill amount, rather than as only binary occupied or empty state.

#### Scenario: Partial reservoir cell
- GIVEN a world cell that contains only part of a bucket-equivalent of water
- WHEN gameplay or rendering queries inspect that cell
- THEN the system MUST report both the water type and a partial fill state instead of only occupied or empty.

### Requirement: Liquids SHALL Resolve Vertical Fall Before Lateral Spread
Functional liquids SHALL attempt to move downward into valid space before attempting lateral equalization.

#### Scenario: Water falling through an opening
- GIVEN a water cell above an open cell
- WHEN the simulation ticks
- THEN the water MUST move downward before considering sideways flow.

### Requirement: Liquids SHALL Equalize Sideways When Blocked Vertically
Liquids SHALL spread laterally into valid neighboring space when downward movement is blocked and excess fill remains.

#### Scenario: Filling a basin
- GIVEN water on top of a solid floor with open space to the left or right
- WHEN additional water enters the basin
- THEN the liquid MUST redistribute into adjacent valid cells until it reaches a more stable level.

### Requirement: Liquid Types SHALL Use Distinct Flow Profiles
The simulation SHALL support per-liquid flow profiles so different liquid types can move, settle, evaporate, or linger differently.

#### Scenario: Water moves faster than lava
- GIVEN equal amounts of water and lava placed in equivalent terrain
- WHEN both are simulated for the same number of ticks
- THEN the water MUST advance or equalize faster than the lava according to their profiles.

### Requirement: Simulation SHALL Run Deterministically in Active Regions
The liquid solver SHALL update only relevant active regions while remaining deterministic for a given seed and gameplay history.

#### Scenario: Chunk reload preserves liquid outcome
- GIVEN a partially settled water pool in a modified chunk
- WHEN the chunk unloads and later reloads without additional interaction
- THEN the liquid state MUST match the previously persisted result and continue simulating from that state.

### Requirement: Settled Liquid SHALL Become Cheap to Skip
The simulation SHALL be able to mark sufficiently stable liquid cells or regions as sleeping until new nearby changes wake them again.

#### Scenario: Sleeping pool wakes after disturbance
- GIVEN a settled pool that has been marked as sleeping
- WHEN a new source is added nearby or terrain opens below it
- THEN the affected cells MUST wake and resume simulation.
