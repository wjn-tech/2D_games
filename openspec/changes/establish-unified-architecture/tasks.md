# Tasks: Establish Unified Architecture

- [ ] Audit `EventBus.gd`:
    - [ ] Add missing global signals for `elemental_reaction_triggered`.
    - [ ] Add missing global signals for `building_shattered`.
- [ ] Refactor `LayerManager` Registration:
    - [ ] Ensure `WorldGenerator` calls a standardized `LM.register_world()` method instead of manual registration.
- [ ] Define "Simulation Window" Constants:
    - [ ] Set global constants in `GameState` for chunk loading and simulation radii.
- [ ] Implement Unified "Take Damage" Interface:
    - [ ] Ensure `BaseNPC`, `DestructibleBuilding`, and `Player` all respond to a standardized damage signal.

## Clarification Tasks
- [ ] Resolve Simulation Consistency Question: Decide if offline layers process chemistry.
- [ ] Resolve Building Granularity Question: Decide if buildings are `tscn` or `TileMap` baked.
