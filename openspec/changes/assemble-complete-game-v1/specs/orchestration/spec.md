# Capability: Master Scene Orchestration

## ADDED Requirements

### Requirement: Unified Game Flow
The game must transition smoothly between main menu, gameplay, and reincarnation states.

#### Scenario: Starting the Game
- **Given**: The game is launched.
- **When**: The `Main` scene initializes.
- **Then**: It should show the `MainMenu` and wait for the "Start" signal.

#### Scenario: Player Reincarnation
- **Given**: The player's health or lifespan reaches zero.
- **When**: The `player_died` signal is emitted.
- **Then**: The `GameManager` should transition to `REINCARNATING` state and show the `ReincarnationWindow`.

### Requirement: Centralized UI Management
All UI windows must be managed by a single controller to prevent overlapping and input conflicts.

#### Scenario: Opening Inventory
- **Given**: The game is in `PLAYING` state.
- **When**: The player presses the "Inventory" key.
- **Then**: The `UIManager` should open the `InventoryWindow` and pause the game world if necessary.
