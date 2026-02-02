# Tasks: Fix NPC Physics and Spawning

- [x] Adjust NPC spawn position in `world_generator.gd` to avoid ground clipping.
- [x] Add wall-hit cooldown/buffer in `base_npc.gd` to prevent jitter.
- [x] Verify `_handle_step_up` is active and functional in `base_npc.gd`.
- [x] Refine `_state_wander` to handle wall collisions more gracefully.
