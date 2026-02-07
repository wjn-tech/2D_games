# Spec: Wand Editor Integration

**Status**: Draft
**Version**: 1.0

## ADDED Requirements

### `WAND-001` - Wand Selection
#### Scenario: Choosing a wand to edit
- **Given** the player has `Fire Wand` in Hotbar and `Ice Wand` in Backpack.
- **When** the **Wand Editor** interface is opened.
- **Then** a "Wand Selector" panel is displayed on the side.
- **And** it lists both `Fire Wand` and `Ice Wand` with their icons.
- **When** the player clicks `Ice Wand` in the list.
- **Then** the Logic Board loads the graph data for `Ice Wand`.

### `WAND-002` - Data Persistence
#### Scenario: Saving changes
- **Given** the user modifies the logic of `Ice Wand`.
- **When** the Editor runs "Compile" or "Close".
- **Then** the modified `WandData` is written back to the `WandItem` resource residing in the Backpack.
- **And** if the player later equips the `Ice Wand`, it uses the new logic program.
