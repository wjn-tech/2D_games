# Capability: NPC Phasing

Improve NPC movement by allowing them to pass through each other while maintaining environmental collisions.

## MODIFIED Requirements

### Requirement: NPC-to-NPC Phasing
NPCs SHALL be able to pass through other NPCs to prevent blocking movement in tight spaces.
#### Scenario: Crossing paths in narrow tunnel
- GIVEN NPC A and NPC B are in a 1-tile wide hallway
- WHEN they move toward each other
- THEN they MUST overlap and continue to their destinations without stopping.

### Requirement: Environmental Collision
NPCs SHALL maintain physical collision with solid terrain.
#### Scenario: Walking into a wall
- GIVEN an NPC moves toward a solid tile
- WHEN the collision occurs
- THEN the NPC MUST be blocked by the terrain.
