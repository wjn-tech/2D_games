# Proposal: Generate Villages and Ruins

## Problem
The current world generation produces a vast but empty landscape. While there are trees and a few scattered NPCs, there are no permanent structures, ruins, or organized settlements. This lacks the "sandbox exploration" feel where players discover interesting locations, loot, and established communities.

## Proposed Change
1.  **Preset Building Scenes**: Create a set of reusable building scenes (`House.tscn`, `Ruins.tscn`, `Workshop.tscn`) that can be instantiated by the world generator.
2.  **Village Clustering**: Implement logic in `WorldGenerator` to group buildings together on flat terrain to form villages or towns.
3.  **Isolated Ruins**: Spawn abandoned ruins in remote areas or underground to encourage exploration.
4.  **NPC Integration**: Assign NPCs to specific buildings (e.g., a Merchant in a Workshop, Villagers in Houses).
5.  **Lootable Chests**: Add chests with randomized loot to ruins and some village buildings.
6.  **Destructibility**: Ensure these buildings are made of tiles or destructible nodes so players can dismantle them for resources.

## Impact
- **Exploration**: Gives players a reason to travel across the 1000x500 world.
- **Progression**: Provides early-game resources and equipment through looting.
- **Immersion**: Makes the world feel inhabited and historically rich.
- **Gameplay**: Introduces "town" hubs where players can trade and interact with NPCs in a structured environment.

## Verification Plan
- **Manual Verification**:
    - Run the world generator and fly around to find generated villages.
    - Check if NPCs are correctly positioned inside or near buildings.
    - Verify that chests contain items and can be opened.
    - Confirm that buildings can be destroyed using tools.
