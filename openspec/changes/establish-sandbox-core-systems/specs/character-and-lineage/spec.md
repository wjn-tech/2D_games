# Specification: Character and Lineage Systems

## ADDED Requirements

### Requirement: Comprehensive Attribute System
The system SHALL track Strength, Agility, Intelligence, and Constitution for all characters.

#### Scenario: High-intensity action affects lifespan
- **GIVEN** A player with 100 days of lifespan.
- **WHEN** The player performs a "Heavy Forge" action.
- **THEN** The lifespan decreases by an additional amount (e.g., 0.5 days) beyond natural aging.

### Requirement: Weighted Inheritance
The system SHALL calculate offspring attributes based on a weighted average of parental stats.

#### Scenario: Child born to strong parents
- **GIVEN** Parent A (Str: 20) and Parent B (Str: 10).
- **WHEN** A child is born.
- **THEN** The child's base Strength is calculated as `(20*0.4 + 10*0.4) + random_offset`.

### Requirement: Reincarnation with Equipment
The system SHALL allow the player to take control of an offspring upon death, retaining their previous equipment.

#### Scenario: Succession after death
- **WHEN** The current character's lifespan reaches zero.
- **THEN** The player selects a child from the "Succession" menu.
- **AND** The new character starts with the selected child's stats but inherits the parent's inventory and equipped items.
