# Spec: Combat Mechanics

**Status**: Draft
**Version**: 1.0

## ADDED Requirements

### `CM-001` - Stamina Management
#### Scenario: Player attacks repeatedly
- **Given** the player has `100` Max Stamina.
- **When** performing a "Light Attack".
- **Then** `10` Stamina is consumed immediately.
- **And** Stamina regeneration pauses for `0.5s` before recovering at `20/sec`.
- **But** if Stamina < `10`, the attack cannot be performed.

### `CM-002` - Stagger Threshold (Poise)
#### Scenario: Accumulating damage
- **Given** an Enemy has a predefined `Poise` meter (e.g., 50).
- **When** receiving hits, `Poise` damage is subtracted.
- **Then** if `Poise` drops to <= 0, the Entity enters `State_Stagger` (unable to act for 1-2s).
- **And** `Poise` resets to Max after the stagger ends.
- **And** `Poise` regenerates if no damage is taken for `3s`.
