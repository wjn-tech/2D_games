# Capability: Gathering Logic

Logic for harvesting resources.

## ADDED Requirements

### Requirement: Drop Generation
Harvestable objects SHALL spawn item drops upon destruction.
#### Scenario: Mining Ore
- GIVEN a rock node with 1 HP
- WHEN it receives mining damage
- THEN it MUST spawn an "Iron Ore" item.
