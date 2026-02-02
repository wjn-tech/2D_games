# Capability: Wand System

The logic for interpreting and casting spell sequences.

## ADDED Requirements

### Requirement: Sequence Execution
The wand SHALL iterate through its spell slots and execute effects in order.
#### Scenario: Basic Combo
- GIVEN a wand with [Splitter, Spark]
- WHEN the player fires
- THEN two Spark projectiles MUST be emitted simultaneously.

### Requirement: Resource Management
Wands MUST consume mana per cast and recharge over time.
#### Scenario: Mana Depletion
- GIVEN a wand with 10 mana and a spell costing 15
- WHEN the player attempts to fire
- THEN no projectile SHALL be emitted until mana recharges.
