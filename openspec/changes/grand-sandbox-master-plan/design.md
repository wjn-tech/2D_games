# Design: Grand Sandbox Master Plan

## Architectural Pillars

### 1. The Decoupled Core (EventBus)
All systems (Weather, Combat, Trading, Lineage) will communicate via a global `EventBus.gd`. For example, `WeatherManager` emits `storm_started`, which `NpcManager` receives to make NPCs seek shelter.

### 2. Physical Depths (The Layer System)
The world is composed of 3 distinct TileMap layers (Depth 0, -1, -2). 
- Combat shifts between these layers via "Layer Switches" (Doors).
- Entities can only interact with others on the same depth unless using ranged "formation" effects.

### 3. Data-Driven NPCs and Stats
- **Stats**: Strength, Dexterity, Lifespan, and Heritage.
- **Inheritance**: A child's stats = `(Parent1.Stat + Parent2.Stat) / 2 * RandomFactor`.
- **Items**: Retention of previous gear is handled by a `DynastyVault` that transfers inventory data to the new successor.

### 4. Logic & Industry
- Tiles are tagged with `LogicComponent` metadata.
- Updates occur on a fixed `TickRate` (e.g., 0.1s) to prevent FPS drops during complex industrial simulations.

## Global Directory Structure
- `res://src/core/`: Global managers (Time, Events, Layers).
- `res://src/systems/world/`: Exploration, Building, Weather.
- `res://src/systems/actors/`: NPC AI, Stats, Social, Breeding.
- `res://src/systems/economy/`: Trading, Crafting, Gathering.
- `res://src/systems/tech/`: Formations, Circuits, Industry.
