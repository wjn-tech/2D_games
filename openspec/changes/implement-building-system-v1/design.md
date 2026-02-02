# Design: Building System and Player Settlements

## 1. Building Data Structure
Buildings will be defined using a custom `BuildingResource` (extending `Resource`).
- `id`: String
- `display_name`: String
- `description`: String
- `icon`: Texture2D
- `scene`: PackedScene (The actual building node)
- `cost`: Dictionary (e.g., `{"wood": 10, "stone": 5}`)
- `requirements`: Array (e.g., "Town Hall Level 1")
- `category`: String (Housing, Production, Defense, Utility)

## 2. Grid and Placement
- **Strict Grid Alignment**: All placements (tiles and structures) must align with the world's `TileMap` grid.
- **Collision & Terrain Validation**: 
    - Buildings cannot overlap with existing structures.
    - Certain buildings have terrain requirements (e.g., must be on flat ground, near water, etc.).
- **Territory Influence**: 
    - Players can build anywhere.
    - Each functional building generates an "Influence Radius".
    - The union of these radii defines the "Settlement Territory".
- **Visual Feedback**: 
    - Valid placement: Green translucent preview.
    - Invalid placement: Red translucent preview.

## 3. Settlement Progression & NPCs
- **Settlement Level**: Increased by total prosperity and specific "milestone" buildings.
- **NPC Housing**: NPCs automatically seek out available "House" buildings to reside in.
- **Job Assignment**: Players can manually assign recruited NPCs to specific production buildings (Farms, Workshops).
- **Stats Tracking**:
    - **Population**: Current / Max (increased by Houses).
    - **Food**: Production vs Consumption.
    - **Defense**: Security level (increased by Walls/Towers).
    - **Prosperity**: Affects recruitment and trade.

## 4. Building Operations
- **Demolition**: Players can dismantle buildings to reclaim a portion of the resources.
- **Moving**: Pre-built structures (PackedScenes) can be moved as a whole without dismantling.
- **Tile Building**: A "Brush" tool for placing individual tiles (walls, floors) using backpack resources.

## 5. UI Flow
1. Player opens `BuildingMenu` (Hotkey: B).
2. Selects a building category and then a specific building.
3. `BuildingManager` enters "Preview Mode".
4. Player moves mouse to position the building.
5. Left-click to place (if affordable and valid).
6. Right-click or ESC to cancel.
