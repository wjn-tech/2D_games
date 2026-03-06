# Spec: Wand Programming Guidance

## OVERVIEW
The current wand programming tutorial is a simple text prompt sequence. Users find it confusing and lacking direction.
This spec introduces a detailed, interactive guidance system specifically for the Wand Editor. It adds:
-   **Step-by-Step State Machine**: For tracking progress.
-   **Visual Guidance**: "Ghost" cursors showing drag-and-drop actions.
-   **Connection Guidance**: Animated lines showing required connections.
-   **Success Feedback**: Immediate response when a step is completed correctly.

## ADDED Requirements

### Requirement: Wand Interface Highlighting
The tutorial system MUST clearly highlight the palette item that needs to be interacted with.

#### Scenario: Highlight Component in Palette
-   **Given** the tutorial state is `PLACE_TRIGGER`.
-   **When** the step begins.
-   **Then** the "TRIGGER" component in the palette (left sidebar) should be visually highlighted (e.g., pulsating border or spotlight).
-   **And** a floating text prompt "Drag Trigger Here" should appear near the target grid slot (2, 2).

### Requirement: Wand Interface Ghosting
The tutorial system MUST provide animated visual cues ("ghosts") showing drag-and-drop actions.

#### Scenario: Ghost Drag Action
-   **Given** the tutorial state is `PLACE_TRIGGER`.
-   **When** the step is active and no item is being dragged.
-   **Then** a semi-transparent "ghost" of the Trigger item should appear and animate from the palette button to the target grid slot (2, 2).
-   **And** this animation should loop every 2 seconds until the user starts dragging.

#### Scenario: Ghost Connection Action
-   **Given** the tutorial state is `CONNECT_NODES`.
-   **When** both Trigger and Projectile nodes are on the board.
-   **Then** an animated line (e.g., dashed or glowing) should draw repeatedly from the output port of the Trigger node to the input port of the Projectile node.
-   **And** a floating label "Connect Ports" should appear near the connection line center.

### Requirement: Wand Interface Validation
The system MUST provide immediate feedback on whether the user's action was correct or incorrect.

#### Scenario: Validate Connection
-   **Given** the tutorial state is `CONNECT_NODES`.
-   **When** the user drags a connection from Trigger -> Projectile.
-   **Then** the tutorial logic should verify the connection is valid (Trigger Output -> Projectile Input).
-   **And** if valid, immediately show a "Success!" notification and advance the tutorial.
-   **But** if invalid (e.g., Trigger -> Trigger), show a brief "Invalid Connection" tooltip and do not advance.

## MODIFIED Requirements

### Requirement: Tutorial Sequence Manager Logic
The tutorial manager MUST implement a strict state machine for the wand programming sequence.

#### Scenario: Wand Programming Step
-   **But** modify the `wait_program` case in `TutorialSequenceManager`.
-   **Instead of** simply waiting for *any* connection.
-   **It MUST** execute the 3 specific sub-steps:
    1.  `Highlight(Trigger)` + `Ghost(Trigger -> Grid)`. Wait for `has_node("trigger")`.
    2.  `Highlight(Projectile)` + `Ghost(Projectile -> Grid)`. Wait for `has_node("action_projectile")`.
    3.  `Ghost(Trigger.Out -> Projectile.In)`. Wait for `connections > 0`.

### Requirement: Wand Editor Helper API
The Wand Editor MUST expose helper methods for the tutorial overlay to locate UI elements in screen space.

#### Scenario: Get UI Rects
-   **Add** `get_grid_cell_rect(grid_pos)`: Returns global screen rect for logic grid cell.
-   **Add** `get_node_port_rect(node, port_index, is_output)`: Returns global screen rect for graph node connection ports.
