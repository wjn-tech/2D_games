# Spec Delta: NPC Trade Window Fix

## MODIFIED Requirements

### Requirement: Trade Window Initialization
The `BaseNPC` must correctly initialize the trade window using the `UIManager`.

#### Scenario: Opening Trade
- **Given** the player selects the "Trade" option in an NPC dialogue.
- **When** `BaseNPC._open_trade()` is called.
- **Then** it must call `UIManager.open_window` with "TradeWindow" and "res://scenes/ui/TradeWindow.tscn".
