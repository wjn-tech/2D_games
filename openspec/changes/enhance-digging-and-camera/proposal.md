# Proposal: Enhance Digging System and Camera Focus

## 1. Problem Statement
The current digging system is functional but lacks visual and mechanical depth. Items are added directly to the inventory without physical representation, and the camera zoom level makes the character feel small and disconnected from the world.

## 2. Proposed Solution
- **Physical Loot Drops**: Update `DiggingManager` to spawn physical `LootItem` entities (small blocks) in the world when a tile is broken (100% drop rate).
- **Continuous Mining Mechanic**: Implement a "hold-to-mine" system where tiles gradually crack while focused/held, resetting if focus is lost.
- **Dynamic Camera Zoom**: Allow players to adjust camera zoom using the mouse wheel for fine-tuning.
- **Visual Feedback**: Add a "block cracking" overlay effect during the mining process and floating "+1" text popups upon collection.
- **Tool Progression**: Enforce tool power requirements for different tile types.

## 3. Scope
- `src/systems/world/digging_manager.gd`: Update loot spawning and implement continuous mining logic.
- `scenes/world/loot_item.tscn`: New scene for physical items on the ground.
- `scenes/player.gd`: Implement mouse wheel zoom and mining focus logic.
- `assets/world/default_tileset.tres`: Update tile metadata for drops and hardness.
- `src/ui/floating_text.gd`: New utility for "+1" popups.

## 4. Dependencies
- `GameState` for inventory management.
- `EventBus` for collection signals.
