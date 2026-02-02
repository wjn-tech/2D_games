# Capability: Physics Bitmask Configuration

Define and verify the collision rules for the new project structure.

## ADDED Requirements

### Requirement: Layer Definition
The project SHALL define 16 physics layers, with specific labels for 1-6.
#### Scenario: Settings Inspection
- GIVEN the Godot project settings
- WHEN inspecting 2D Physics layers
- THEN Layer 4 MUST be named "Entities_Soft".

### Requirement: Phasing Collision Rule
Entities on the "Entities_Soft" layer MUST NOT hard-collide with other objects on the same layer.
#### Scenario: NPC overlap
- GIVEN two NPCs on Layer 4
- WHEN their Hitboxes overlap
- THEN no physical displacement SHALL occur.
