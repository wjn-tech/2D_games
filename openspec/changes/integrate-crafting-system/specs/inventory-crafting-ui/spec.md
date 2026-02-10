# Spec: Inventory Crafting UI (MVP)

## ADDED Requirements

### 1. Unified Side-by-Side Layout
-   **Requirement**: The 'I' key MUST open a widened window containing the Inventory (Left) and Crafting Panel (Right) simultaneously.
-   **Scenario**:
    -   Given the player is in the world.
    -   When they press 'I'.
    -   Then the window opens showing the Bag Grid on the left and the Crafting Recipe List on the right.

### 2. Interaction Flow
-   **Requirement**: Selecting a valid recipe in the right panel updates the "Craft" button state.
-   **Scenario**:
    -   Clicking a recipe shows its details in the detail pane (below the list).
    -   If materials are missing, the "Craft" button is disabled/greyed out.

### 3. Instant Crafting
-   **Requirement**: Clicking "Craft" MUST instantly deduce materials and add the result, providing Quality feedback.
-   **Scenario**:
    -   When "Craft" is clicked.
    -   Materials are removed.
    -   Result item (with random Quality) is added to Inventory.
    -   A floating text "Crafted [Item] (Quality: Rare!)" appears.

## MODIFIED Requirements

### 1. Inventory Window Structure
-   **Requirement**: The existing `InventoryWindow` layout MUST be refactored to use an HBox container for split-view.
-   **Impact**:
    -   Current independent GridContainer needs to be wrapped in a Left-Side container.

### 2. Player Input
-   **Requirement**: 'I' key toggles the combined window.
-   **Scenario**:
    -   Pressing 'I' while open closes the window.
    -   Pressing 'Esc' also closes the window.
