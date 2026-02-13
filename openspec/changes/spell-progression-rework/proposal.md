# Proposal: Spell Progression & Monster Execution System

## Problem Statement
Currently, all spells (logic components) in the Wand Editor are hardcoded and available by default. There is no progression or incentive to engage in combat beyond gaining experience. Monsters lack specific loot drops and meaningful death mechanics.

## Proposed Changes
1.  **Spell Locking**: Spells in the Wand Editor will be locked by default.
2.  **Spell Registry**: Implement a registry in `GameState` to track unlocked spells.
3.  **Loot Drops**:
    *   Fix monsters to drop inherent materials on death (probability: 100%).
    *   Add a rare chance for monsters to drop "Spell Items" (e.g., Crystallized Magic) that unlock specific spells upon pickup.
4.  **Execution Mechanic (Finishers)**:
    *   When a monster's health is below **20%**, a "Execute" prompt appears.
    *   Pressing the **`F`** key triggers an execution sequence:
        *   The monster is bound (stunned).
        *   The monster is pulled towards the player.
        *   The monster explodes (no damage to others), dropping guaranteed loot and a high-probability spell item.
5.  **UI Feedback**:
    *   Execution prompt above targeted monsters.
    *   Notifications when a new spell is unlocked.
    *   Wand Editor UI updates to **completely hide** locked spells until discovered.
6.  **New Materials**: Create a batch of basic monster materials (e.g., Slime Essence, Bone Fragment, etc.) for guaranteed drops.

## Expected Outcome
A rewarding progression loop where players explore the world and engage in combat to expand their magical arsenal. The execution mechanic provides a skill-based way to farm rare spells.
