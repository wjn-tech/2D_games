# Solution Architecture: Wand Programming Guidance

This design focuses on adding a dedicated "Guidance Layer" (CanvasLayer) specifically for interactions within complex UIs like the Wand Editor. This layer can visualize abstract instructions like "drag item to X" and "connect A to B" without relying solely on text or static highlights.

## Core Components
-   **TutorialSystem** (`TutorialManager`): Coordinates the flow.
    -   Holds state: `current_step` (Enum: PLACE_TRIGGER, PLACE_PROJ, CONNECT).
    -   Connects to `WandEditor` signals: `nodes_changed`, `connection_request`.
-   **VisualOverlay** (`TutorialOverlay`): Renders guidance visuals.
    -   `GhostCursor`: Animated sprite showing movement.
    -   `GhostItem`: Faded preview of the item in the target slot.
    -   `GhostWire`: Pulsating Bezier curve showing connection path.
-   **Helpers**:
    -   `WandEditor.get_grid_rect(grid_pos)`: Returns screen-space rect for target logic grid cell.
    -   `WandEditor.get_port_rect(node, port_index, is_output)`: Returns screen-space rect for connection ports.

## Flow
1.  **Step 1: Place Trigger**
    -   `TutorialManager` calls `Highlight(TriggerButton)`.
    -   `TutorialManager` calls `ShowDraggableGhost(TriggerButton -> Grid(2, 2))`.
    -   User drags Trigger to grid.
    -   `WandEditor` emits `nodes_changed`.
    -   `TutorialManager` verifies `has_node("trigger")`. If true -> Advance.

2.  **Step 2: Place Projectile**
    -   `TutorialManager` calls `Highlight(ProjectileButton)`.
    -   `TutorialManager` calls `ShowDraggableGhost(ProjectileButton -> Grid(5, 2))`.
    -   User drags Projectile to grid.
    -   `WandEditor` emits `nodes_changed`.
    -   `TutorialManager` verifies `has_node("action_projectile")`. If true -> Advance.

3.  **Step 3: Connect**
    -   `TutorialManager` calls `ShowConnectGhost(TriggerNode.Output -> ProjectileNode.Input)`.
    -   User drags connection line.
    -   `WandEditor` emits `connection_request` -> `connect_node`.
    -   `TutorialManager` verifies 1 connection. If true -> Complete.

## Considerations
-   **Coordinate Space**: Ensure `get_global_rect()` works correctly across different CanvasLayers (Tutorial Layer vs WandEditor Layer).
-   **GraphEdit Nodes**: `GraphNode` positions are relative to `GraphEdit`'s scroll offset. Need to convert to global screen coordinates.
-   **Flexibility**: If the user places the projectile at (2, 5) instead of (5, 2), the ghost connection should adapt dynamically to the *actual* node positions, not the suggested ones.
