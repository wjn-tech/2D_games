# Proposal: Disable Fog of War

Temporarily disable the Fog of War system to allow for easier testing and development of other features without map obscuration.

## Problem
The Fog of War system obscures the map, which can make debugging world generation, NPC behavior, and POI placement difficult during the current development phase.

## Solution
- Hide the `FogOfWar` node in the `Main` scene.
- Add a toggle or early return in `FogOfWar.gd` to prevent it from filling the map with fog cells.
- Ensure POI discovery logic remains functional if possible, or acknowledge it will be disabled along with the fog.

## Scope
- `scenes/main.tscn`: Hide the node.
- `src/systems/world/fog_of_war.gd`: Add a disable flag.
