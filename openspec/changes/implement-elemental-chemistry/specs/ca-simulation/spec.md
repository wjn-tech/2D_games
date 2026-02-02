# Capability: CA Simulation

The cellular automata engine for elements.

## ADDED Requirements

### Requirement: Gravity for Liquids
Liquid tiles SHALL move down if the tile below is empty.
#### Scenario: Water falling
- GIVEN a water tile suspended in air
- WHEN the simulation ticks
- THEN the water MUST move to the tile below.

### Requirement: Horizontal Displacement
Liquids SHALL spread sideways if they cannot move down.
#### Scenario: Filling a basin
- GIVEN a water tile on a solid floor
- WHEN more water is added
- THEN it MUST spread to adjacent empty tiles.
