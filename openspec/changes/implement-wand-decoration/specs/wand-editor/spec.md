# Spec: Wand Editor (Pixel Paint)

## ADDED Requirements

### Requirement: 16x16 Grid Canvas
The editor SHALL provide a 16x16 interactive grid. The left edge of the grid represents the "Tail" (User Hand connection), and the right edge represents the "Head" (Spell Output).

#### Scenario: Visual Layout
The user opens the Wand Editor. The "Visual" tab displays a 16x16 grid of empty cells. The UI shows markers for "Hand" (Left) and "Tip" (Right).

### Requirement: Painting Interaction
Dragging a Material Item from the palette onto the grid SHALL color the grid cell with the item's `wand_visual_color`. Right-clicking SHALL clear the cell.

#### Scenario: Painting a pixel
User drags "Wood (Brown)" onto Grid(0,0). The cell turns solid Brown. The internal data updates to reference the Wood item at (0,0).

### Requirement: Visual Preview
The editor SHALL display a life-size (1:1 scale) and magnified (e.g., 4:1) preview of the final generated texture.

#### Scenario: Real-time update
As the user paints pixels, a small preview image updates in real-time to show what it looks like as an icon.
