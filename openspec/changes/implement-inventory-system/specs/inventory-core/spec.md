# Spec: Inventory Core

**Status**: Draft
**Version**: 1.0

## ADDED Requirements

### `INV-001` - Item Storage (Backpack)
#### Scenario: Acquiring Items
- **Given** the Player steps over a "Loot Bag" containing `Iron Sword` x1.
- **When** the `_on_body_entered` signal triggers.
- **Then** the logic attempts to add `Iron Sword` to the **Hotbar** first.
- **And** if the Hotbar is full, it adds it to the **Backpack**.
- **And** if both are full, the Loot Bag remains on the ground.

### `INV-002` - Slot Management
#### Scenario: Dragging Items
- **Given** Slot A contains `Wand 1` and Slot B contains `Potion`.
- **When** the human player drags Slot A onto Slot B.
- **Then** the items in Slot A and Slot B are swapped.
- **And** the UI updates immediately to reflect the new positions.
