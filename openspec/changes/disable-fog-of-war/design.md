# Design: Disable Fog of War

## Approach
We will implement a simple toggle in the `FogOfWar` script and update the main scene to hide the visual layer.

### 1. Script Modification
Add an `@export var enabled: bool = true` to `FogOfWar.gd`.
In `_ready()` and `_process()`, check this flag. If `false`, do nothing.

### 2. Scene Modification
In `Main.tscn`, set the `FogOfWar` node's `visible` property to `false` and set its `enabled` property (once added) to `false`.

## Impact on Other Systems
- **Quest System**: Quests that rely on `DISCOVER` objectives (POI discovery) will not progress because the discovery logic is tied to the fog revelation process. This is acceptable for a temporary disablement.
- **Performance**: Disabling the fog will slightly improve performance as it removes the per-frame tile calculations and the initial map filling.
