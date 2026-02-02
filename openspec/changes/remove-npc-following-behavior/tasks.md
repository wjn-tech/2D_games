# Tasks: Remove NPC Following Behavior

- [x] Modify `_check_for_targets` in `base_npc.gd` to restrict `State.CHASE` to "Hostile" NPCs only.
- [x] Ensure "Friendly" and "Neutral" NPCs remain in `State.WANDER` or `State.IDLE` when near the player.
- [x] Verify that "Timid" NPCs still flee from the player if intended.
