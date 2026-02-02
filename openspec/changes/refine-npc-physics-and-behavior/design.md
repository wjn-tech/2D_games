# Design: NPC Physics and Tethered AI

## Architectural Reasoning
To make the world feel grounded, NPCs must obey the same physical rules as the player (gravity, collisions). By inheriting from `CharacterBody2D` and applying a constant gravity force when not on the floor, we achieve this consistency.

For world stability, NPCs shouldn't drift infinitely. Storing a `spawn_position` on `_ready()` allows us to calculate a "return to home" vector if the NPC wanders too far. This is especially important for "Neutral" NPCs who represent the general population of the world.

## AI State Machine Updates
- **WANDER**: Now checks distance from `spawn_position`. If `distance > wander_radius`, the next wander direction will be biased towards the spawn point.
- **IDLE**: Standard idle behavior.
- **NEUTRAL Personality**: In `_check_for_targets`, Neutral NPCs will ignore the player unless the player's alignment is Hostile or the NPC has been attacked.

## Trade-offs
- **Performance**: Adding gravity calculations to many NPCs might have a small performance hit, but `move_and_slide()` is already optimized in Godot.
- **Complexity**: Tethering adds a bit more math to the wander logic but significantly improves the "lived-in" feel of camps and towns.
