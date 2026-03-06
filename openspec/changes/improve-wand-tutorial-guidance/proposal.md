# Proposal: Step-by-Step Wand Programming Guidance System

## Context
The current wand programming tutorial relies entirely on dialogue text and a simple "highlight" (which highlights the component in the palette but not the destination on the grid). Users find this confusing and "shitty" because it lacks explicit, visual instructions on *where* to place components and *how* to connect them.

## Problem
- **Ambiguous Placement**: The user is told to "Drag the TRIGGER component into the grid" but not *where* in the grid.
- **No Connection Guidance**: The instruction "Connect them: TRIGGER -> PROJECTILE" is purely text-based. Users may not know how to drag connections between ports.
- **Silent Failure**: If the user places components but doesn't connect them, nothing happens until a hidden timer checks for success, leading to frustration.
- **Input Blocking**: Previous iterations had issues where tutorial text blocked input or didn't allow interaction.

## Solution
Implement a **Dedicated Guidance Overlay** system specifically for complex UI interactions like the Wand Editor. This system will:
1.  **Ghosting**: Show a semi-transparent "ghost" of the required component at the *exact* target grid cell.
2.  **Pointer Animation**: An animated hand/cursor showing the drag action from Palette -> specific Grid Slot.
3.  **Connection Preview**: A pulsating line connecting the specific output port of the Trigger node to the specific input port of the Projectile node.
4.  **Step-by-Step State Machine**: A rigid state machine that advances *only* when the specific action is performed correctly.
    - State 1: WAITING_FOR_TRIGGER_PLACEMENT
    - State 2: WAITING_FOR_PROJECTILE_PLACEMENT
    - State 3: WAITING_FOR_CONNECTION
5.  **Immediate Feedback**: If a user places a component in the wrong slot during the tutorial, gently nudge them or automatically move it to the correct slot (or just allow it but update the ghost). *Decision: For this tutorial, we will allow placement anywhere but highlight the 'suggested' slots to keep it clean.*

## Scope
-   **New System**: `TutorialOverlay` (extended from current simple arrow) to support `GhostItem`, `DragPath`, and `ConnectionPath`.
-   **WandEditor Integration**: Expose `get_grid_cell_rect(x, y)` and `get_node_port_rect(node, port_index)` to the tutorial system.
-   **Content**: A specific `WandProgrammingTutorial` script or data resource that defines the steps.

## Risks
-   **Complexity**: Implementing a robust overlay that tracks moving UI elements (scrollable grids, graph nodes) can be tricky with coordinate spaces.
-   **Rigidity**: If we force the user to place items in *specific* slots, it might feel too restrictive. We should frame it as "suggested" placement but accept any valid placement.
