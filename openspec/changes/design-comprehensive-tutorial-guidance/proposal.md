# Proposal: Comprehensive Tutorial Guidance System

## Context
The current tutorial is a linear dialogue sequence with minimal visual support. Users report frustration with ambiguity ("where do I click?", "what key do I press?"), especially during inventory and logic programming tasks. The previous `improve-wand-tutorial-guidance` proposal addressed the Wand Editor specifically, but this proposal expands the scope to cover the **entire** new player experience from wake-up to first combat.

## Problem
-   **Silent Controls**: The game waits for inputs (WASD, I, K, Click) without ever showing them on screen.
-   **Ambiguous Instructions**: "Open your inventory" relies on prior knowledge of standard RPG keys (`I` or `Tab`).
-   **Static Highlights**: Highlighting a UI element is insufficient for drag-and-drop tasks; users need to see *source* and *destination*.
-   **Lack of Feedback**: When a user performs an action correctly (e.g., equips an item), there is often no immediate juice/feedback, just the next dialogue line.

## Solution
Implement a **Holistic Guidance Overlay** that supports:
1.  **Input Prompts**: Dynamic key icons (WASD, Space, Mouse) that appear in world-space or screen-space and react to presses.
2.  **Ghost Interactions**: Animated cursors showing complex mouse movements (Drag Item -> Slot, Drag Wire -> Port).
3.  **Contextual Highlighting**: Spotlight effects that dim the rest of the screen to focus attention on critical UI elements.
4.  **Step Validation**: Strict state tracking for every micro-action (e.g., "Opened Inventory" -> "Found Item" -> "Started Drag" -> "Equipped").

## Scope
This proposal covers 4 key tutorial phases:
1.  **Movement**: Basic locomotion and camera control.
2.  **Inventory & Equip**: Opening UI, identifying items, equipping to hotbar.
3.  **Wand Programming**: (Incorporating previous logic) Placing nodes, connecting logic.
4.  **Combat Basics**: Aiming, firing, destroying targets.

## Risks
-   **UI Clutter**: Overlaying too many prompts might obscure the game world. *Mitigation: Use "fade-on-press" logic.*
-   **Input Blocking**: Tutorial overlays must strictly NOT block input to the underlying game unless intentional (e.g., pausing during a modal explanation).
-   **State Desync**: If the user performs an action *before* the tutorial asks for it, the system must gracefully skip ahead.
