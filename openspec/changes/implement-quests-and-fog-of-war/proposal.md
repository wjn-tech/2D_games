# Proposal: Implement Quest System and Fog of War Integration

## 1. Problem Statement
The game currently lacks a structured quest system for NPC interaction and a functional Fog of War to encourage exploration. While basic NPC interaction and a Fog of War script exist, they are not integrated into the gameplay loop.

## 2. Proposed Solution
- **Quest System**: Create a `QuestManager` autoload and a `Quest` resource to handle quest tracking, rewards, and completion.
- **Fog of War Integration**: Add the `FogOfWar` node to the `Main` scene and ensure it correctly reveals tiles as the player moves.
- **Discovery System**: Implement a simple `DiscoveryManager` to track discovered POIs (camps, towns) and reward the player.
- **NPC Quest Givers**: Update `BaseNPC` to randomly assign quests to players.

## 3. Scope
- `src/systems/quest/quest_manager.gd`: New autoload for quest management.
- `src/systems/quest/quest_resource.gd`: New resource for quest data.
- `src/systems/world/fog_of_war.gd`: Update to handle initialization and player tracking.
- `scenes/main.tscn`: Add `FogOfWar` node.
- `src/systems/npc/base_npc.gd`: Add quest-giving logic.

## 4. Future Expansion: Complete Quest System
- **Quest Journal**: A dedicated UI window to view all active and completed quests with detailed descriptions.
- **Quest Markers**: Visual indicators on the map or over NPCs' heads to show quest availability and objectives.
- **Branching Quests**: Support for multiple outcomes and choices within a quest.
- **Quest Categories**: Main quests, side quests, and faction-specific tasks.
- **Persistence**: Saving and loading quest progress across game sessions.

## 5. Dependencies
- `UIManager` for quest notifications.
- `GameState` for reward distribution.
