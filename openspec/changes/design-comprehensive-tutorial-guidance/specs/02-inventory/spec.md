# Spec: Inventory Guidance

## ADDED Requirements

### Requirement: Inventory Highlighting
The tutorial MUST clearly visually indicate which exact UI elements need to be interacted with.

#### Scenario: Open Inventory Prompt
-   **Given** the tutorial state is `wait_inventory`.
-   **When** the dialogue "Open your inventory" finishes.
-   **Then** a **Key Prompt** ("I" or "Tab") should pulse on screen.
-   **And** the "Backpack" button on the HUD (if visible) should be highlighted.

#### Scenario: Equip Wand Guidance
-   **Given** the inventory window is open.
-   **When** the player must equip the Wand.
-   **Then** the **Slot 0** (Backpack, containing the Wand) MUST be highlighted with a focused spotlight/ring.
-   **And** a **Ghost Cursor** animation MUST initiate from Slot 0 to **Hotbar Slot 1** (or first empty hotbar slot).
-   **And** a text tooltip "Drag to Hotbar" MUST appear near the starting slot.

#### Scenario: Equipment Validation
-   **Given** the ghost animation is playing.
-   **When** the player successfully drags the Wand from Slot 0 to Hotbar Slot 1.
-   **Then** the tutorial manager should immediately emit a success sound/effect.
-   **And** hide all ghost/overlay elements.
-   **And** advance to `wait_equip` step.
