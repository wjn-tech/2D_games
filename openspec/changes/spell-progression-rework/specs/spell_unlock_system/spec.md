# Spec: Spell Unlock System

## MODIFIED Requirements

### Req: Wand Component Discovery
Spells and logic components used in the wand editor must be discovered before they can be used.

#### Scenario: Locked Editor Components
- **Given** The player has not discovered "Fire Core".
- **When** The player opens the Wand Editor.
- **Then** "Fire Core" is completely hidden from the palette.

#### Scenario: Unlocking via Item Pickup
- **Given** The player picks up a "Spell Scroll: Fire Core".
- **When** The item is added to the inventory.
- **Then** "Fire Core" is added to `GameState.unlocked_spells`.
- **And** A notification displays: "Spell Unlocked: Fire Core".
