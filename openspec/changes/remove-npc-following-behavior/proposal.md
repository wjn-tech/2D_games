# Proposal: Remove NPC Following Behavior

## 1. Problem Statement
Currently, NPCs with the "Brave" personality or "Hostile" alignment will chase the player when they enter detection range. This results in friendly NPCs "following" the player around, which is unintended and annoying for the user.

## 2. Proposed Solution
- **Refine Target Detection**: Update `_check_for_targets` in `base_npc.gd` to ensure that only "Hostile" NPCs chase the player.
- **Personality Adjustment**: "Brave" NPCs should not chase the player unless they are also "Hostile". They might still chase other hostile entities in the future, but for now, we will disable the player-chasing behavior for non-hostile NPCs.

## 3. Scope
- `src/systems/npc/base_npc.gd`: Modify `_check_for_targets` logic.

## 4. Dependencies
- `BaseNPC` AI state machine.
