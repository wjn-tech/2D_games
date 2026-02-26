# Visual Requirements

## ADDED Requirements

### Requirement: Rarity Visualization
The interface MUST visually distinguish items based on their rarity tier (Common, Uncommon, Rare, Epic, Legendary) using color-coded borders and glowing effects.

#### Scenario: Displaying a Legendary Item
*   **Given** an item with `rarity="legendary"` is in the inventory.
*   **When** the inventory is opened.
*   **Then** the item slot should have a **Gold/Orange** border.
*   **And** a faint gold background glow/gradient.
*   **And** the item icon should be centered.

### Requirement: Interactive Atmosphere
The interface MUST provide tactile feedback through animations and sound effects when interacting with elements, including Drag-and-Drop operations.

#### Scenario: Hovering an Item
*   **Given** the mouse cursor moves over an item slot.
*   **When** the hover state triggers.
*   **Then** the slot should scale up by **1.05x** within 0.1s.
*   **And** the border brightness should increase.

#### Scenario: Dragging an Item
*   **Given** the player clicks and holds an item.
*   **When** dragging begins.
*   **Then** a semi-transparent "ghost" texture of the item icon should follow the cursor.
*   **And** the original slot should dim.

#### Scenario: Dropping an Item
*   **Given** the player is dragging an item over another valid slot.
*   **When** the player releases the mouse button.
*   **Then** the items in the source and target slots should swap positions.
*   **And** a "place" sound/particle effect should play.

#### Scenario: Opening Inventory
*   **Given** the player presses the inventory key (I).
*   **When** the window opens.
*   **Then** the background should be a dark, semi-transparent pane (Glassmorphism).
*   **And** the window content should fade in.

## MODIFIED Requirements

### Requirement: Expanded Layout
The layout MUST move from a simple grid to a three-column structure (Navigation, Grid, Details) to support better item management.

#### Scenario: Viewing Details
*   **Given** an inventory with items.
*   **When** the player clicks an item.
*   **Then** the **Details Panel** on the right should update to show:
    *   Large Item Icon.
    *   Item Name in Rarity Color.
    *   Description.
    *   Stats (if available).



