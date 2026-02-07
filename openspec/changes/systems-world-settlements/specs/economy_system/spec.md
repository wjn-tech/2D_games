# Economy & Jobs Spec

## ADDED Requirements

### Requirement: Merchant Interaction
Players MUST be able to buy and sell items with Merchant NPCs.

#### Scenario: Buying a Potion
Given a Merchant with `HealthPotion` in stock (Price: 50g)
And a Player with 100g
When the Player clicks "Buy" on the Potion
Then the Player loses 50g
And creates/receives 1 `HealthPotion` item.

### Requirement: Gold Currency
The `GameState` MUST manage a persistent `gold` integer.

#### Scenario: Starting Gold
Given a new game
Then `GameState.gold` should be 0 (or a starting amount).

### Requirement: Blacksmith Crafting
Players MUST be able to interact with the Anvil (Placeholder).

#### Scenario: Anvil Placeholder
Given an Anvil object in the world
When the player interacts
Then a placeholder message or empty UI is shown (functionality TBD).
