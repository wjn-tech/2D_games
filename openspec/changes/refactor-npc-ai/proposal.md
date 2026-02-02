# Proposal: Deep Refactor of NPC AI with LimboAI (HSM + BT)

## 1. Problem Statement
The current NPC implementation in `base_npc.gd` is highly monolithic, mixing data (`CharacterData`), physics management, and AI logic (FSM) in a single script. This makes it:
- **Fragile**: Changes to movement physics often break state logic.
- **Limited**: Simple FSM cannot handle complex, multi-goal behaviors required for a living world (e.g., job routines, combat tactics, social interactions).
- **Hard to Maintain**: Overlapping states lead to "buggy" transitions, such as NPCs jittering between wandering and chasing.

## 2. Proposed Solution
Implement a **Hierarchical AI Architecture** using **LimboAI**, and perform a **total decoupling** of data and control. Inspired by *Terraria*'s ecological sandbox, the NPCs will not just be static sellers but "living" participants in the environment.

### Key Architectural Shifts:
1.  **Orchestration (LimboHSM)**: A top-level State Machine will manage high-level "Life Modes" (e.g., `IdleState`, `CombatState`, `HomeState`, `SocialState`).
2.  **Execution (Behavior Trees)**: Each HSM state will host a specific Behavior Tree (`BTPlayer`) to handle granular, rule-based decision-making.
3.  **Pathfinding (NavigationAgent2D)**: Robust pathing for traversing player-built houses, platforms, and varying biomes.
4.  **Ecological Sensing**: NPCs will monitor environmental variables (Time, Weather, Biometype, Neighbors) to drive dialogue and happiness.
5.  **Decoupled Controller**: Separate `BaseNPC` into a "Pawn" (Physics body) and a "Controller" (AI/HSM).

## 3. Scope
- Full refactor of `base_npc.gd` into a cleaner "Actor" class.
- Integration of `LimboHSM` and `BTPlayer`.
- Setup of `NavigationAgent2D` and `NavigationRegion2D` within chunks.
- Implementation of a data-to-blackboard synchronization layer for `CharacterData`.

## 4. Impact
- **Flexibility**: Define job routines and combat strategies purely in the editor.
- **Robustness**: Pathfinding handles complex terrain that manual checks miss.
- **Performance**: Leverages LimboAI's optimized C++ backend for complex logic trees.
