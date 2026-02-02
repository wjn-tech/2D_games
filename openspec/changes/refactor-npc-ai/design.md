# Design: NPC AI Refactor with LimboAI (HSM + BT)

## Overview
The new system separates the NPC into three distinct layers: Data (`CharacterData`), Pawn/Actor (`BaseNPC`), and Controller (`LimboHSM` + `BTPlayer`).

## Architecture

### 1. Hierarchical Architecture (HSM -> BT)
We will use a **LimboHSM** as the top-level executor to manage context-switching:
*   **WanderState**: Active during non-work hours in safe biomes. Tree: `common_wander.bt`.
*   **CombatState**: Triggered by danger/threats. Tree: `flee_or_defend.bt`.
*   **HomeState**: Active during night/rain or when "Happiness" is low. Tree: `return_and_rest.bt`.
*   **SocialState**: Triggered when compatible neighbors are nearby. Tree: `social_interaction.bt`.

### 2. Social Affinity & Happiness System
Inspired by Terraria, NPCs will have preferred neighbors and biomes.
*   **Happiness Score**: Calculated based on (Neighbor Match + Biome Match + Crowding).
*   **Economic Impact**: Happiness influences store prices (via the `BaseNPC.inventory` service).
*   **Blackboard Data**: `preferred_biomes: Array`, `liked_neighbours: Array`, `disliked_neighbours: Array`.

### 3. Perception & Environment Sensing
A dedicated `SensorComponent` (attached to `BaseNPC`) will feed the Blackboard:
*   **Time/Weather**: Synced from `SettlementManager` or `DayNightCycle`.
*   **Local Entities**: Scans for player, enemies, and other NPCs within detection range.
*   **Contextual Dialogue**: The BT will select `dialogue_pool` keys based on blackboard flags (e.g., `is_raining`, `is_near_friend`, `killed_boss_1`).

## Key Interactions

### Seamless State Transition
When a `Fighter` NPC in `IdleState` detects an enemy, the `BTPlayer` triggers a transition on the `LimboHSM` to `CombatState`. The `CombatState` then swaps the active Behavior Tree to a specialized tactical one.

### Dynamic Navigation
The `NavigationAgent2D` will be updated per frame within the `Move` tasks. The `Actor` handles the actual `move_and_slide()` call using the velocity calculated by the navigation system.
