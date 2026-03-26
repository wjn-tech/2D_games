# Capability: Liquid Interactions

Gameplay and terrain rules for liquids, materials, and elemental reactions.

## ADDED Requirements

### Requirement: Liquids SHALL Respect Tile Openness Metadata
Liquid movement SHALL consult explicit tile or material metadata describing whether a cell blocks liquid, permits fallthrough, or supports partial occupancy.

#### Scenario: Grated opening passes liquid but not solid fill
- GIVEN a tile that is marked as allowing liquid fallthrough
- WHEN water reaches that tile boundary
- THEN the water MUST be allowed to continue through according to the metadata instead of treating the tile as a fully solid wall.

### Requirement: Liquids SHALL Apply Type-Specific Entity Effects
Each liquid type SHALL be able to impose distinct movement, survival, or status effects on entities.

#### Scenario: Lava harms while water does not
- GIVEN an entity entering water and another entering lava under comparable conditions
- WHEN immersion is processed
- THEN the lava case MUST apply damaging or burning consequences while the water case MUST not reuse the same damage behavior by default.

### Requirement: Liquids SHALL Support Stable Reaction Rules
The system SHALL support a deterministic reaction table for liquid-liquid and liquid-element interactions.

#### Scenario: Water and lava solidify into a block result
- GIVEN water and lava become adjacent under a valid reaction rule
- WHEN the reaction resolves
- THEN the system MUST replace the affected interaction site with the configured solid result and update nearby liquid state accordingly.

#### Scenario: Water extinguishes fire
- GIVEN an ignited flammable cell or fire state that is configured to be suppressible by water
- WHEN water reaches that location
- THEN the fire state MUST be reduced or removed by the shared reaction system.

### Requirement: Liquid Placement and Removal SHALL Use Shared Interfaces
Gameplay tools and scripted events SHALL use common fill and drain interfaces instead of bypassing the simulation with one-off tile edits.

#### Scenario: Bucket-like placement wakes nearby simulation
- GIVEN a tool action that deposits liquid into the world
- WHEN the placement succeeds
- THEN the affected cells MUST receive liquid fill through the shared interface and the nearby region MUST wake for simulation.