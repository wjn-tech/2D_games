# Proposal: City-State and Settlement Expansion

## 1. Problem Statement
The current settlement system tracks stats but lacks a visual interface for the player to manage their city-state. NPCs are recruited but don't have a physical "home" or daily routine tied to the buildings. The "city-state" concept needs more depth to feel like a growing community.

## 2. Proposed Solution
- **Settlement UI**: A dedicated panel to view population, food, prosperity, and recruited NPCs.
- **Territory System**: Buildings will project an "Influence Area". The player can only build certain structures within their territory.
- **NPC Housing**: Recruited NPCs will be assigned to a `House` building.
- **New Buildings**:
    - **Storage**: Provides a shared chest for the settlement.
    - **Wall/Gate**: Defensive structures.
    - **Well**: Required for production buildings.
- **Prosperity Levels**: Unlocks new building types as the settlement grows.

## 3. Scope
- `src/systems/settlement/settlement_manager.gd`: Update to handle territory and NPC housing.
- `src/ui/settlement_ui.gd`: New UI for settlement management.
- `src/systems/building/building_manager.gd`: Implement territory checks and influence visualization.
- `data/buildings/`: Add new building resources.

## 4. Dependencies
- `GameState` for global access.
- `UIManager` for displaying the new UI.
