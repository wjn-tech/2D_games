# Spec: Physical Loot Drops

## MODIFIED Requirements

### Requirement: Continuous Mining
#### Scenario: Holding mouse over a tile
- **Given** a tile has a `hardness` value of `2.0` seconds.
- **When** the player holds the left mouse button over the tile.
- **Then** the tile should display increasingly intense cracking visuals.
- **And** if the mouse is moved away before `2.0` seconds, the cracking should disappear and progress reset.
- **And** if held for `2.0` seconds, the tile should break and spawn a `LootItem`.

### Requirement: Physical Loot Spawning
#### Scenario: Breaking a tile
- **Given** a tile is broken.
- **Then** a small block-shaped `LootItem` should spawn at the tile's location.
- **And** it should have a 100% drop rate for the configured item.

### Requirement: Loot Collection Feedback
#### Scenario: Picking up a loot item
- **Given** the player walks over a `LootItem`.
- **Then** a floating "+1 [Item Name]" text should appear above the player.
- **And** a collection sound effect should play.
