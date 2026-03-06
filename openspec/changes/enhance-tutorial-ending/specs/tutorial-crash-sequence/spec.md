# Tutorial Crash Sequence (Enhanced)

This spec defines the enhanced behavior for the "Crash Sequence" phase of the tutorial, replacing the static text overlay with a dynamic in-engine cutscene.

## MODIFIED Requirements

### Requirement: Seamless Transition
The tutorial end sequence MUST NOT invoke `get_tree().change_scene*` or reload the `Main` scene.
#### Scenario: Crash Event
Given the player completes the final tutorial step (destroying the target),
When the "Crash Sequence" begins,
Then the game transitions to the crash cutscene without a loading screen,
And the player remains in the same scene instance but experiences visual and state changes.

### Requirement: Ship Disintegration
The spaceship visual elements (walls, props, floor) MUST disappear or break apart to simulate destruction.
#### Scenario: Breakup
Given the countdown timer reaches zero (or sequence trigger),
When the ship "breaks apart",
Then the `TutorialSpaceship` node's visual children (Sprite2D, TileMapLayer) become invisible or free,
And particles representing purely mechanical debris (metal shards, sparks, wires, no magical corruption) spawn around the player's last known position.

### Requirement: Player Falling
The player character MUST appear to be falling through the atmosphere after the ship breaks for a sustained duration (approx. 8-10 seconds).
#### Scenario: Freefall
Given the ship has disintegrated,
When the player is unsupported in the air,
Then the player's physics processing (gravity) is enabled or simulated downwards,
And a "falling" visual effect (wind lines, blur) is applied to the camera or screen,
And the player sprite rotates or plays a falling animation for at least 8 seconds to allow for a smooth transition.

### Requirement: Mage Protection (Visual)
A visible energy shield MUST appear around the player during the fall, implying magical protection, while the Mage NPC itself is not shown.
#### Scenario: Shield Activation
Given the player is falling,
When the fall sequence is active,
Then a blue/magical circular aura surrounds the player character,
And the Court Mage NPC model is hidden or removed (implying separation).

### Requirement: Waking Up
The sequence MUST conclude with the player waking up on the planet surface with their inventory intact.
#### Scenario: Impact & Wake
Given the player has "fallen" for the duration,
When the impact moment occurs,
Then the screen fades to white or blurs heavily,
And the player is teleported to a valid spawn point on the ground,
And the player retains all items (Wand, etc.) gathered during the tutorial,
And the player sprite is set to a "lying down" rotation (-90 degrees),
And after a short delay (2-3 seconds), the player stands up (rotation 0) and regains control.
