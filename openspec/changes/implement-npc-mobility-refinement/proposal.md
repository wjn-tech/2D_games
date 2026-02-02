# Proposal: NPC Mobility Refinement

Enable NPCs to pass through one another while maintaining solid collisions with the environment to prevent clogging in villages and narrow paths.

## Why
Currently, NPCs treat each other as rigid obstacles. In high-density areas like villages or 1-tile wide tunnels, this leads to permanent pathfinding "locks" where entities cannot move past each other.

## Proposed Changes
1.  **Bitmask Adjustment**: Define a dedicated physics layer for NPCs that allows them to ignore collisions with other members of the same layer.
2.  **Navigation Radius**: Adjust `NavigationAgent2D` avoidance radii to prefer spacing without enforcing hard physics blocks.

## Impact
- **Village Quality**: NPCs can move freely in crowded town squares.
- **Combat**: Prevents the player or enemies from being physically trapped by a pack of passive NPCs.

## Acceptance Criteria
- [ ] Two NPCs can walk through each other in a test corridor.
- [ ] NPCs still collide correctly with the ground and walls.
