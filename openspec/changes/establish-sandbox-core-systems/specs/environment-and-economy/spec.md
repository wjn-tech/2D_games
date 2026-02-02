# Specification: Environment and Economy Systems

## ADDED Requirements

### Requirement: Weather Impact on Gameplay
The system SHALL modify gameplay variables based on the current weather state.

#### Scenario: Rain affects fire
- **GIVEN** A "Rainy" weather state.
- **WHEN** The player tries to use a "Fire Arrow".
- **THEN** The fire damage is reduced or the fire effect is extinguished.

### Requirement: Ecological Food Chain
The system SHALL simulate simple predator-prey relationships between animals.

#### Scenario: Wolf hunting Rabbit
- **GIVEN** A "Wolf" NPC and a "Rabbit" NPC in the same area.
- **WHEN** The Wolf's "Hunger" stat is high.
- **THEN** The Wolf targets the Rabbit and initiates an attack.

### Requirement: Merchant Trading
The system SHALL allow buying and selling items with specific merchant NPCs.

#### Scenario: Selling raw materials
- **WHEN** The player opens the trade menu with a Merchant.
- **THEN** The player can exchange "Iron Ore" for "Gold Coins" based on the merchant's price list.
