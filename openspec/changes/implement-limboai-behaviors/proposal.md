# Implement LimboAI Behaviors

## Summary
 Establish a standardized workflow and component library for creating NPC behaviors using LimboAI. This proposal defines the specific Behavior Tree (BT) structures and State Machine (HSM) logic required for Friendly (Villager) and Hostile (Zombie, Slime) NPCs, and specifies the custom `BTTask` scripts needed to support them.

## Problem
Currently, NPC logic relies on hardcoded checks in `_physics_process` or rudimentary state scripts. This makes adding complex behaviors (like Slime jumping or Villager fleeing) difficult and decoupled from the LimboAI plugin's visual editor capabilities. The user requires guidance on how to construct these trees using the plugin.

## Proposed Solution
1.  **Dual-Layer Architecture**: Use `LimboHSM` for high-level State retrieval (Peace/Combat) and `BTPlayer` to execute the logic within those states.
2.  **Custom Task Library**: Implement reusable `BTTask` and `BTCondition` scripts specific to our 2D platformer physics (e.g., `TargetInRange`, `JumpToTarget`).
3.  **Standardized Tree Templates**: Define "Reference Trees" for common archetypes ensuring consistently high-quality AI.

## Value
*   **Editor Integration**: Allows tuning AI (sight range, jump frequency) without code changes.
*   **Reusability**: `BTMoveToTarget` can be used by both Zombies and Villagers.
*   **Scalability**: Easy to add new "Boss" behaviors by combining existing leaf nodes.
