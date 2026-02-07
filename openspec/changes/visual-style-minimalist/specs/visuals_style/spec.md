# Visual Style Spec

## MODIFIED Requirements

### Requirement: Background Rendering
The background MUST render as a solid color gradient based on player depth, instead of parallax textures.

#### Scenario: Surface Level
Given the player is at Y=0 (Surface)
Then the background color is `Color(0.9, 0.9, 0.9)` (Off-White).

#### Scenario: Deep Underground
Given the player is at Y=1000 (Deep)
Then the background color is `Color(0.0, 0.0, 0.0)` (Black).

### Requirement: Tile Representation
Tiles MUST be rendered as solid color blocks representing their material properties.

#### Scenario: Dirt Tile
Given a generated Dirt tile
Then it appears as a solid Brown square.

#### Scenario: Tree Shape
Given a generated Tree
Then the canopy top row consists of 3 solid Green blocks.
And the middle/bottom rows are Green-Brown-Green.
