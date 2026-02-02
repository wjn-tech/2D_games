# Capability: Attribute Growth

Define how character stats increase and how they affect game logic.

## ADDED Requirements

### Requirement: Growth Scaling
The character attributes SHALL follow defined growth curves provided by a Resource.
#### Scenario: Leveling up Strength
- GIVEN a character at level 1
- WHEN they gain enough EXP to reach level 2
- THEN their `Strength` MUST increase according to the `StrengthCurve` resource.

### Requirement: State Integrity
The character MUST always be in one of the predefined states (Idle, Moving, Attacking).
#### Scenario: State Transition
- GIVEN a character in `Idle` state
- WHEN the movement input is received
- THEN the state MUST change to `Moving`.
