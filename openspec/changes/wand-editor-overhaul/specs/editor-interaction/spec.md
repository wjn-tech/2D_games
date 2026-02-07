# Spec: Editor Interaction

## MODIFIED Requirements

### Requirement: Zoom and Pan
The Logic Board MUST support standard infinite canvas navigation including scrolling and zooming.

#### Scenario: User navigates large graph
- **Given** the Wand Editor is open
- **When** the user holds Middle Mouse and drags
- **Then** the canvas pans smoothly.
- **When** the user scrolls the mouse wheel
- **Then** the canvas zooms in/out (Range 0.5x to 2.0x).

#### Scenario: Components stay put
- **Given** a graph with nodes at specific coordinates
- **When** the wand is saved and reloaded
- **Then** the nodes SHALL appear at the exact same visual positions relative to each other.
- **And** they do not stack in the corner.

### Requirement: Node Interaction
The system MUST improve usability of selecting and connecting nodes compared to the baseline.

#### Scenario: Hover Highlight
- **Given** the mouse cursor moves over a Logic Node
- **Then** the node scales up by 10% (1.1x) to indicate focus.
- **When** the mouse leaves
- **Then** it returns to normal scale.

#### Scenario: Valid Connection
- **Given** a hovered node
- **When** the user clicks the output port area
- **Then** a connection wire SHALL begin dragging consistently (no "node drag" misclick).
