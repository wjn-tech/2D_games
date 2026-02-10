# Spec: Crafting System Core

## ADDED Requirements

### 1. Instant Synthesis with Quality
-   **Requirement**: The system MUST generate items instantly upon request, but with variable Quality attributes.
-   **Scenario**:
    -   `CraftingManager.craft(recipe)` is the atomic operation.
    -   It calculates a `quality_score` (0-100) based on base RNG.
    -   It returns the `ItemData` with the `quality` property set.

### 2. Quality Attributes
-   **Requirement**: The system MUST assign a quality tier string to the item based on the score.
-   **Scenario**:
    -   Attributes: `quality_grade` (Common/Good/Excellent/Masterwork).
    -   This data is persisted in the item's dictionary/resource.

### 3. Discovery Logic
-   **Requirement**: Recipes MUST be lockable/unlockable based on Player Knowledge.
-   **Scenario**:
    -   `CraftingManager` checks `unlocked_recipes` set before returning the list to UI.
    -   Debug/Cheat command `unlock_all_recipes` is available.

## MODIFIED Requirements

### 1. Crafting Manager Scope
-   **Requirement**: `CraftingManager` functionality moves from simple boolean checks to data-rich item generation.
-   **Impact**:
    -   Existing `craft(recipe)` function is expanded to handle Quality generation and Ingredient consumption logic.
