# Spec: Hotbar Mechanics

**Status**: Draft
**Version**: 1.0

## ADDED Requirements

### `HOT-001` - Selection Input
#### Scenario: Switching Weapons
- **Given** the Hotbar has `Sword` in Slot 1 and `Wand` in Slot 2.
- **And** the currently active slot is 1 (Sword).
- **When** the player presses the `2` key.
- **Then** the Active Slot becomes 2.
- **And** the `Sword` visual is despawned from the Player's hand.
- **And** the `Wand` visual is spawned in the Player's hand.

### `HOT-002` - Empty Slot Selection
#### Scenario: Selecting empty hand
- **Given** Slot 3 is empty.
- **When** the player presses `3`.
- **Then** the Player enters "Unarmed" state.
- **And** any held item is despawned.
