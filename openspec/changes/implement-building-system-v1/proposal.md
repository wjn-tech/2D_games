# Proposal: Implement Building System and Player Settlements

## 1. Problem Statement
The game currently has a basic `BuildingManager` and `SettlementManager`, but they are not integrated into a functional gameplay loop. Players cannot yet build structures, manage resources for construction, or establish a "city-state" with functional buildings and recruited NPCs.

## 2. Proposed Solution
- **Dual Building Mode**: Support both individual tile placement (for custom structures) and large pre-built structure placement (for functional buildings).
- **Building System Overhaul**: Enhance `BuildingManager` to support a UI-based building menu, resource costs, and strict grid-based placement validation matching the world's tile size.
- **Dynamic Territory**: Implement a system where buildings generate a "settlement influence" area. Players can build anywhere, and the city-state's range expands as more structures are added.
- **Settlement Integration**: Connect buildings to the `SettlementManager`. Certain buildings (e.g., Houses, Farms, Workshops) will provide benefits like housing capacity, food production, or crafting stations.
- **City-State Progression**: Implement a level-based progression system for the settlement, allowing players to define and upgrade their city-state's scope and capabilities.
- **Resource Management**: Integrate with the existing `InventoryManager` to consume materials directly from the player's backpack during construction.

## 3. Scope
- `src/systems/building/building_manager.gd`: Update to handle UI integration and resource costs.
- `src/systems/settlement/settlement_manager.gd`: Add logic for settlement stats (population, food, defense).
- `res://scenes/ui/BuildingMenu.tscn`: New UI for selecting buildings.
- `res://data/buildings/`: New directory for building definitions (Resources).
- `res://scenes/buildings/`: Base scenes for various building types.

## 4. Dependencies
- `InventoryManager` for resource tracking.
- `UIManager` for the building interface.
- `GameState` for global settlement data.

## 5. Architectural Reasoning
We will use a data-driven approach where each building is defined by a `BuildingResource`. This resource will contain the building's scene, cost, and functional properties. The `BuildingManager` will act as the controller for the placement phase, while the `SettlementManager` will track the global state of the player's city-state.
