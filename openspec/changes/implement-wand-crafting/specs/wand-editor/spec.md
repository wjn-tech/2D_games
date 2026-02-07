# Spec: Wand Editor UI

## ADDED Requirements

#### Requirement: Visual Decoration Grid
A simplified "Pixel Art" or "Block" editor grid must be available to customize wand appearance. The grid resolution scales with the Wand Embryo tier.

#### Scenario: Drawing and Consumption
- **Given** the Wand Editor is open in "Decoration Mode" with a Tier 1 Embryo (4x4 grid)
- **When** the player selects a [Gold Nugget] material and clicks a cell
- **Then** one [Gold Nugget] is removed from the inventory.
- **And** a Gold Block sprite appears in the grid.
- **And** the logic calculates the stat increase from this new block.

#### Scenario: Scaling Grid
- **Given** a Tier 10 Embryo
- **Then** the visual editor grid should present a higher resolution (e.g., 16x16) within the same UI area.
- **And** the player can place more materials for finer detail.

#### Requirement: Logic Connection Interface
A UI representing the "Circuit" must allow placing and wiring items in a free graph.

#### Scenario: Wiring the Circuit
- **Given** the "Logic Mode" is active
- **When** the player drags a [Crystal] into the workspace
- **Then** it becomes a Node.
- **When** the player drags a line from Node A to Node B
- **Then** a logical connection is formed.
