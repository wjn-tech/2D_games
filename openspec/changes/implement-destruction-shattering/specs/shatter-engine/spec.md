# Capability: Shatter Engine

The system for generating and managing physical debris.

## ADDED Requirements

### Requirement: Fragment Generation
When a destructible building reaches 0 HP, it MUST spawn physics fragments.
#### Scenario: House Collapse
- GIVEN a house at 1 HP
- WHEN it receives 1 damage
- THEN it SHALL be removed from the tilemap.
- AND multiple `RigidBody2D` fragments MUST be instantiated at its location.

### Requirement: Interaction
Fragments SHALL collide with the ground and other entities.
#### Scenario: Pile of rubble
- GIVEN fragments falling on the floor
- WHEN they land
- THEN they MUST stack or bounce according to physics properties.
