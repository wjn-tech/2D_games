# Tasks

1.  **Define Guidance Types**:
    -   `Highlight(control_node)`: Existing.
    -   `GhostDrag(source_node, target_grid_rect)`: New. Show an animated ghost item dragging from source to target.
    -   `GhostConnect(source_port_rect, target_port_rect)`: New. Show an animated line drawing connection between two ports.
    -   `StepTracker`: A simple panel showing "Task X/Y: [Description]".

2.  **Extend WandEditor**:
    -   Add `get_grid_cell_rect(x, y) -> Rec2` helper.
    -   Add `get_palette_item_rect(item_id) -> Rec2` helper.
    -   Add `get_node_port_rect(node, port_idx, is_output=true) -> Rec2` helper.

3.  **Implement `TutorialSteps` Script**:
    -   Create `res://scenes/tutorial/wand_programming_steps.gd` (or similar).
    -   Implement the state machine:
        -   `_step_place_trigger()`: Highlight "Trigger" in palette + show ghost at (2, 2) in grid. Wait for `nodes_changed` signal with 1 node.
        -   `_step_place_projectile()`: Highlight "Action: Projectile" in palette + show ghost at (5, 2) in grid. Wait for `nodes_changed` signal with 2 nodes.
        -   `_step_connect()`: Highlight Trigger's output port + Projectile's input port. Draw animated line between them. Wait for `logic_board.connection_request` or `nodes_changed` with active connection.

4.  **Polish UI**:
    -   Ensure the `GhostItem` and `GhostConnection` are clearly visible above the `WandEditor`.
    -   Add audible cues for correct/incorrect placement (simple click vs error sound).

5.  **Integrate**:
    -   Hook this into `tutorial_sequence_manager.gd` under the `wait_program` case.
