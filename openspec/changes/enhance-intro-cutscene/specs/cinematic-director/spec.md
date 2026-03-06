# Spec: CinematicDirector (Enhancement)

## Goal
Extend `CinematicDirector` to handle node-based transforms (move, rotate, scale) dynamically, allowing for scripted cutscenes without needing dedicated AnimationPlayers for every sequence.

## Added Requirements

#### Requirement: Move Actor
The system must be able to move a `Node2D` from its current position to a target position over a specified duration.

#### Scenario: Running
Given a cutscene where an NPC needs to run from A to B:
When the director executes `{"type": "move_actor", "target": npc_node, "destination": Vector2(100, 0), "duration": 2.0}`:
Then the `npc_node` should smoothly translate to `(100, 0)` over 2 seconds.

#### Requirement: Rotate Actor
The system must be able to rotate a `Node2D` to a target angle over a duration.

#### Scenario: Falling Down / Clean Get Up
Given a cutscene where the player is knocked down:
When the director executes `{"type": "rotate_actor", "target": player_sprite, "angle": -90.0, "duration": 0.5}`:
Then the `player_sprite` should rotate to -90 degrees over 0.5 seconds.

#### Requirement: Scale Actor
The system must be able to scale a `Node2D` to a target size over a duration.

#### Scenario: Squash and Stretch
Given a cutscene where an NPC jumps or kneels:
When the director executes `{"type": "scale_actor", "target": npc_node, "scale": Vector2(1.0, 0.8), "duration": 0.2}`:
Then the `npc_node` should scale its Y axis to 0.8 over 0.2 seconds.
