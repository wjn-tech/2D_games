# Spec: Implement Custom Dynamic Cursors

## Capability: cursor-management

### MODIFIED Requirements

#### Requirement: Dynamic Mouse Cursors
Provide visual feedback by automatically changing the mouse cursor icon based on what the player is currently hovering or the game's current context.

#### Scenario: Hovering Over Interactive NPCs
- **Given** the player is in the game world
- **When** the mouse cursor hovers over an interactive NPC (e.g., Court Mage)
- **Then** the cursor icon should change from the default arrow to a "talk" or "interact" hand icon.

#### Scenario: Hovering Over Inventory Items
- **Given** the Inventory UI is open
- **When** the mouse cursor is hovered over an item slot with an item inside
- **Then** the cursor icon should change to a "grab" hand icon to indicate that the item can be dragged.

#### Scenario: Combat Mode Targeting
- **Given** the player has a staff equipped and is in a combat-ready state
- **When** the cursor is positioned in the world and no UI is blocking it
- **Then** the cursor icon should change to a crosshair or target icon to assist aim.

#### Scenario: Resetting to Menu Cursor
- **Given** the player opens the Pause Menu or Main Menu
- **When** the UI is focused and blocking world input
- **Then** the cursor icon should reset to the default menu arrow icon.
