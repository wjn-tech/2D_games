# Proposal: NPC Behavior and Factions

Implement a state-machine driven AI and faction relation system.

## Proposed Changes
1. AI States: Patrol, Chase, Attack, Flee. (COMPLETE: Refactored FSM)
2. Faction Grid: Defines how NPCs feel about each other and the player. (COMPLETE: Faction relation logic added)
3. Schedule System: NPCs react to day/night cycles. (COMPLETE: Routine behaviors added)

## Acceptance Criteria
- [x] NPC switches to hostile when player of enemy faction approaches.
- [x] NPC returns home or seeks shelter at night.
- [x] FSM code is organized and maintainable.
