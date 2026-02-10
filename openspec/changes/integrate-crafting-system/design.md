# Design: Character Crafting Table System

## Architectural Principles
1.  **"Crafting is a Ritual"**: The system is not just `Input -> Output`. It manages a *Stateful Session* (`CraftingSession`) that tracks the progress through stages (Prep, Combine, Refine).
2.  **Visual-First**: The UI must show materials moving, mixing, or being struck, rather than just updating numbers.
3.  **Extensibility**: The system differentiates between `StationType` (Alchemy, Forge, etc.), allowing unique minigames and interaction patterns for each, even if accessed via the same Player Inventory "Character Crafting" interface (representing portable/personal techniques).

## System Components

### 1. `CraftingManager` (Singleton/Autoload)
-   **Responsibility**: Orchestrates global crafting logic, recipe database access, and player unlock progression.
-   **State**: `unlocked_recipes`, `crafting_skill_levels`.

### 2. `SynthesisSystem` (New Class)
-   **Responsibility**: Manages the active crafting session.
-   **Components**:
    -   `layers`: Discovery, Interaction, Process, Quality.
    -   `stages`: PREPARATION, COMBINATION, REFINEMENT, FINISHING.

### 3. `CraftingInterface` (UI)
-   **Input**: Player Inventory 'I'.
-   **Structure**:
    -   **Combined View**: A persistent split-view. Inventory Grid on Left, Crafting Panel on Right.
    -   **Toggle**: Crafting panel visibility might be toggleable, or always present.
-   **Layout**:
    -   **Recipe List**: Scrollable list of "Handcrafting" recipes.
    -   **Details Panel**: Shows selected recipe requirements and potential Quality range.
    -   **Action**: "Craft" button (Instant execution).

## Data Structures

### Quality & Properties
Items will need extended data structures to support:
-   `quality_grade`: common, rare, epic...
-   `crafted_properties`: Dynamic stats generated during synthesis.
-   `creator_signature`: "Crafted by [PlayerName]".

## Integration Strategy
-   Modify `InventoryWindow` to increase its default width.
-   Add an `HSplitContainer` or `HBoxContainer` to hold the existing Inventory Grid (Left) and new Crafting Panel (Right).
-   Data flow: `CraftingPanel` checks `InventoryManager` for materials -> `CraftingManager` executes instant craft with Quality calculation -> `InventoryManager` receives result.
