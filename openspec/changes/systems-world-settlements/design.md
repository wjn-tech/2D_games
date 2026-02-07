# Design: Settlement Generation & Economy

## 1. Blueprint System Refactor
We will leverage the existing pattern in `InfiniteChunkManager._generate_tile_house` but move the data out of code.

### 1.1 `BlueprintResource`
Mirrors current `MY_CUSTOM_HOUSE_DESIGN` and `palette` structure.
```gdscript
class_name BlueprintResource extends Resource

@export_multiline var layout: String = "..." # The char grid
@export var palette: Dictionary = {
    "#": {"type": "tile", ...}, # Existing palette structure
    "D": {"type": "special", "tag": "door", ...}
}
```

### 1.2 Construction Logic
Refactor `InfiniteChunkManager._generate_tile_house` to accept `BlueprintResource` input instead of using constants.
- The entry function `_apply_structures` will select random blueprints based on biome/hash.

## 2. Settlement Generation Strategy
The `WorldGenerator` (or `InfiniteChunkManager` via structure pass) will determine settlement locations.
- **Cluster Gen**: When a chunk triggers a settlement spawn (based on hash), it prepares a list of `BlueprintResource`s to spawn in that and adjacent chunks.
- **Layout**: Center building + satellite houses/shops.

## 3. Economy & Jobs
### 3.1 Currency
Add `var gold: int = 0` to `GameState`.
Persistence is handled by existing `SaveManager` (needs verification that it saves GameState properties).

### 3.2 Merchant
- **Interaction**: Opens `TradeWindow` UI.
- **Logic**: Simple Buy/Sell modifying `GameState.gold` and inventory.

### 3.3 Blacksmith & Anvil
- **Blacksmith**: NPC with "Blacksmith" visual role.
- **Anvil**: New interactable Scene (`Anvil.tscn`).
- **Interaction**: Initially just a placeholder print or empty UI. Future extensibility: Upgrade interface.

## 4. NPC Lifecycle
- **Spawn**: Blueprints define spawn points (`NPCSpawn` markers or specific palette chars e.g. 'N').
- **Persistence**: Handled by `InfiniteChunkManager` entity system.
