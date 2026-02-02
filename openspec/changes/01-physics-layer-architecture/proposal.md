# Proposal: Physics Layer Architecture

Establish a rigid and optimized physics layer matrix to support NPC phasing, redstone logic, and destruction debris.

## Why
Current physics layers are broad. To implement specific features like "NPCs passing through each other" or "Logic signals ignoring player collision," we need a dedicated layer assignment strategy.

## Proposed Changes
1.  **Define Layers**:
    *   Layer 1: World (Solid Terrain)
    *   Layer 2: Player
    *   Layer 3: Entities_Hard (NPCs that block, Enemies)
    *   Layer 4: Entities_Soft (NPCs that phase)
    *   Layer 5: Debris (Building fragments)
    *   Layer 6: Logic (Redstone signals)
2.  **Bitmask Strategy**: Configure the collision matrix so Entities_Soft ignore other Entities_Soft but collide with World.

## Impact
- **Mobility**: Foundation for NPCs moving through each other.
- **Performance**: Prevents unnecessary collision checks between static logic and physical actors.

## Acceptance Criteria
- [ ] Physics layers are named in Project Settings.
- [ ] Collision matrix allows Layer 4 to ignore Layer 4.
