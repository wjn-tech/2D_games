# Proposal: Integrate Character Crafting System

## Metadata
- **Change ID**: `integrate-crafting-system`
- **Status**: Draft
- **Authors**: Copilot
- **Created**: 2026-02-08

## Summary
Implement a "Character Crafting" panel directly integrated into the player's inventory interface (accessible via 'I'). Based on user feedback, this will be a **side-by-side** view (enhancing the existing Inventory Window) geared towards **handcrafting** (items not requiring stations). The MVP will focus on **instant synthesis** that includes a depth-based **Quality System**, skipping time-based rituals for this specific portable interface.

## Background
Currently, the game has a basic `CraftingManager` and `CraftingRecipe` structure (implied by `crafting_manager.gd`). However, there is no integrated UI for crafting within the inventory, and the process is likely instant and purely formulaic. The goal is to elevate crafting to a core gameplay pillar where the process itself is engaging.

## Problem Statement
- **Lack of Immersion**: Crafting is currently a simple resource exchange without player agency or "ritual" feel.
- **UI Fragmentation**: Crafting might be separated from Inventory or non-existent in a consolidated view. The user specifically requests integration into the 'I' menu.
- **Missed Gameplay Depth**: Opportunities for material quality and player mastery are missing.

## Solution Overview
1.  **UI Integration**: Expand the `InventoryWindow` to a wide, two-panel layout.
    -   **Left/Center**: Existing Grid Inventory.
    -   **Right**: New "Handcrafting" Panel (Recipe List + Action).
2.  **Core Systems Update**: Expand `CraftingManager` to support:
    -   **Quality Generation**: Even instant crafting will roll for "Quality" (Common, Rare, etc.) based on a calculated success chance or skill.
    -   **Recipe Filtering**: Only show "Handcrafting" type recipes in this view.
3.  **Phased Implementation**:
    -   **Phase 1 (MVP)**: Side-by-side UI, Handcrafting Recipes, Instant Crafting with Quality Calculation.
    -   **Phase 2 (Depth)**: Minigames for specific stations (Alchemy/Forge), Discovery.

## Risks & Mitigations
-   **Screen Space**: A side-by-side layout might be too wide.
    -   *Mitigation*: Ensure the window size fits within 1024x600 safe zones.
-   **Quality Complexity**: Generating dynamic properties instantly might be complex.
    -   *Mitigation*: For Phase 1, "Quality" will simply represent a tier tag or slight stat variance.

## Dependencies
-   Existing `InventoryManager` and `CraftingManager` (need refactoring).
-   `UIManager` for window handling.
