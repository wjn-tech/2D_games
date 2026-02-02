# Capability: Inventory System

Core item management logic.

## ADDED Requirements

### Requirement: Transaction Handling
The system SHALL handle buying and selling with NPCs.
#### Scenario: Purchase
- GIVEN a merchant with a priced item
- WHEN the player confirms purchase
- THEN the player's currency MUST decrease by the item price.
