# Design: Sandbox Core Systems Architecture

## 1. Layered Combat & Physics
- **Mechanism**: Use Godot's `collision_layer` and `collision_mask`.
- **Implementation**: The world is divided into "Layer A" and "Layer B". Doors act as triggers that toggle the player's (and potentially enemies') collision bits.
- **AI**: Enemies will have a `target_layer` property. If the player is on a different layer, the AI will seek the nearest "Layer Door" to transition.

## 2. Lineage & Attributes
- **Data Structure**: `CharacterData` (Resource) stores all stats, including `lifespan`, `birth_date`, and `parents`.
- **Inheritance**: `child_stat = (parent_a_stat * 0.4) + (parent_b_stat * 0.4) + (random_variance * 0.2)`.
- **Training**: Minigames or time-based assignments for children to boost specific stats before adulthood.
- **Reincarnation**: On player death, the UI presents a "Succession" screen. The selected child's `CharacterData` becomes the new player data.

## 3. Industrial & Circuits
- **Grid System**: A hidden logic grid overlaying the TileMap.
- **Nodes**: Buildings like "Conveyor" or "Logic Gate" are nodes in a graph.
- **Energy**: A `PowerGridManager` tracks energy production (Generators) vs consumption (Machines).
- **Logic**: Simple signal propagation (0 or 1) between connected nodes.

## 4. Settlement & NPC Management
- **Recruitment**: NPCs have a `loyalty` stat. High loyalty allows "Recruit" action.
- **Jobs**: A `SettlementManager` assigns NPCs to `WorkStation` nodes (e.g., "Farmer" to "CropField").
- **Magnet Pickup**: An `Area2D` on the player with a "Magnet" script that applies a force to `LootItem` nodes within range.

## 5. Weather & Ecology
- **WeatherManager**: A global singleton that cycles through states (Sunny, Rainy, Stormy).
- **Effects**: Modifies `CanvasModulate` and triggers `GPUParticles2D`.
- **Ecology**: Simple state machines for animals: `Idle` -> `Hungry` -> `Hunt(Target)` -> `Eat`.

## 6. Crafting & Formations
- **Stations**: Crafting is only possible when near a `CraftingStation` node.
- **Formations**: 
    - **Mobile**: A `FormationArea` attached to the player that grants buffs to allies inside.
    - **Static**: A `FormationPillar` building that creates a defensive zone.
