# Spec: Attribute System Refactor

## MODIFIED Requirements

### Attribute Calculation
The value of an attribute is no longer a simple float. It is derived from a base value, wild levels (genetics), tamed levels (progression), and mutation bonuses.

#### Scenario: Calculating Final Strength
- **Given** a creature with Base Strength 10.
- **And** it has 5 Wild Levels in Strength (each adds 5%).
- **And** it has 2 Tamed Levels in Strength (each adds 2%).
- **And** it has 1 Mutation (+2 Wild Levels effective).
- **When** `get_strength()` is called.
- **Then** the result should be: `10 * (1 + (5+2)*0.05) * (1 + 2*0.02)`.

### Persistence
Attribute structure must be serializable to JSON/Dictionary for saving.

#### Scenario: Saving Character Data
- **Given** a character with split attribute levels.
- **When** `save_game()` is called.
- **Then** the JSON should contain nested objects for stats: `stats: { strength: { wild: 7, tamed: 2 }, ... }`.
