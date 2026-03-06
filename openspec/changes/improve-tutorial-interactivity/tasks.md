# Interactive Tutorial Tasks

## Tasks

### System & Input
- [ ] Add `player_movement_locked` signal to `src/core/event_bus.gd`.
- [ ] Update `scenes/player.gd` to stop movement/jump when `movement_locked` is true, but allow UI inputs.

### Scene & Content
- [ ] Create `scenes/tutorial/breakable_wall.gd` and add it to `spaceship2.tscn`.
- [ ] Add `TutorialArrow` (simple Control scene with animation) to `scenes/ui/tutorial_arrow.tscn`.
- [ ] Verify `test_wand.tres`, `wood.tres`, `stone.tres` load correctly in `TutorialSequenceManager`.

### Logic Implementation
- [ ] Connect `EventBus` signals (`inventory_opened`, `item_equipped`) in `tutorial_sequence_manager.gd`.
- [ ] Implement `process_step` function in `TutorialSequenceManager` to handle waiting.
- [ ] Implement `<emit:wait_move>`, `<emit:wait_inventory>`, `<emit:wait_equip>`, `<emit:wait_craft>`.
- [ ] Implement `<emit:highlight>` to spawn `TutorialArrow`.

### Validation
- [ ] Test loop: Intro -> Dialogue -> Move Lock -> Inventory Open -> Equip -> Craft -> Shoot Wall -> Crash.
