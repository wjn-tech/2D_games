# Spec: Role Interactions

## MODIFIED Requirements

### Req: Contextual Interaction Options
The player must be presented with relevant options when interacting with an NPC based on the NPC's role.

#### Scenario: Interacting with a Merchant
- **Given** The player interacts with a "villager_merchant".
- **When** The dialogue window opens.
- **Then** "Trade" should be one of the selectable options.
- **And** Selecting "Trade" should open the trading UI.

#### Scenario: Interacting with a Wizard
- **Given** The player interacts with a "villager_wizard".
- **When** The dialogue window opens.
- **Then** "Inscribe Spell" or "Identify Item" should be available options (if applicable).

#### Scenario: Gifting for Relationship
- **Given** The player selects the "Gift" option.
- **When** The player provides a valuable item.
- **Then** The NPC's `relationship` value increases.
- **And** The NPC says a "Thank you" line from their specific dialogue table.
