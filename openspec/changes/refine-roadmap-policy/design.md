# Design: Refine Roadmap Policy

## Strategic Pillars

### 1. Leverage "Low Hanging Fruit"
Since `WeatherManager` and `LayerManager` are nearly done, we finalize them first. This gives the project a "finished" feel and provides environmental context for other systems.

### 2. Connect the Autoloads
The existing Autoloads (`GameState`, `EventBus`, `LayerManager`, `WeatherManager`) are currently "islands". The priority shift focuses on making them talk. 
- Example: `WeatherManager` (Rain) -> `EventBus` -> `TileMapLayer` (Wet surface) -> `Player` (Slippery movement).

### 3. Data-Driven Standardization
We will move away from placeholder variables in `base_npc.gd` and `player.gd` and unify them into a single `AttributeComponent`.

## Re-prioritized Sequence Table

| Rank | Change ID | Baseline % | Focus |
| :--- | :--- | :--- | :--- |
| 1 | 03-world-chronometer-and-weather | 90% | UI Integration, VFX |
| 2 | 01-physics-layer-architecture | 70% | Bitmasking, Portal cleanup |
| 3 | 02-character-attribute-engine | 70% | UI, Componentization |
| 4 | 09-layer-combat-mechanics | 70% | Cross-layer AI behavior |
| 5 | 04-npc-behavior-and-factions | 50% | Behavior Tree cleanup |
| 6 | 12-succession-and-legacy | 30% | Transmigration UI |
