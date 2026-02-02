# Design: Ground-Aware NPC Spawning

## Architectural Reasoning
To prevent NPCs from spawning in invalid locations, we need to move away from coordinate-based spawning to "surface-finding" spawning. 

### Surface Finding Logic
Instead of spawning an NPC at `(x, y)` when a noise condition is met, we will:
1. Identify the X coordinate where an NPC *should* spawn.
2. Iterate through the Y coordinates for that X to find the first solid tile (the "ground").
3. Place the NPC at `(x, ground_y - 1)`.

### Spawn Rate Reduction
The current rate of `0.005` per tile in `generate_layer` is applied to every tile in the grid. Since we only want NPCs on the surface, we should move the spawn check to a per-column basis or significantly reduce the probability.

### Camp Safety
In `_create_camp`, the horizontal offset should be validated. If `pos + offset` results in a position that is in the air or inside a wall, the NPC should be snapped to the nearest ground or the spawn should be skipped.

## Trade-offs
- **Generation Time**: Finding the ground for each NPC spawn adds a small amount of iteration, but since the number of NPCs is being reduced, the overall impact on world generation time will be negligible.
