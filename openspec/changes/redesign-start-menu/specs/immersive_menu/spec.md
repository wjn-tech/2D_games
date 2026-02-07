# Spec: Immersive Menu Capabilities

## ADDED Requirements

### Dynamic Background environment
The main menu MUST render a background scene that visually corresponds to the player's real-world time of day.

#### Scenario: Evening Login
When the player opens the game at 20:00 (8 PM):
*   The background sky uses dark blue/purple tones (`sky_night` colors).
*   Particle effects display "Fireflies" or "Stars".
*   Lighting simulates moonlight.

#### Scenario: Morning Login
When the player opens the game at 08:00 (8 AM):
*   The background sky uses light blue/cyan tones (`sky_day` colors).
*   Particle effects are subtle (e.g., floating dust or leaves).
*   Lighting simulates bright sunlight.

### Smart "Continue" Action
The menu primary action button MUST adapt based on the presence of save data.

#### Scenario: Existing Save
Given a save file exists with metadata `{"location": "Forest Camp", "timestamp": "2023-10-27 10:00"}`:
*   The first menu button reads "Continue - Forest Camp".
*   A secondary subtitle might show "Last played: 2 hours ago".
*   Clicking it immediately loads that save.

#### Scenario: No Save
Given no valid save file exists:
*   The first menu button reads "Start Journey".
*   Clicking it triggers the `New Game` sequence.

### Personalized Greeting
The menu MUST display a text greeting that acknowledges the real-world time and the player (if name is known).

#### Scenario: Late Night
*   Text displays: "Late night adventure, Traveler?" or "Good evening."

### Transitions
Menu state changes MUST be accompanied by visual transitions.

#### Scenario: Start Game
When "Start Journey" is clicked:
*   The UI elements fade out (Opacity 1.0 -> 0.0) over 0.5s.
*   The background blurs or zooms in.
*   A "Flash" or "Fade to Black" covers the screen before the game scene loads.

## MODIFIED Requirements

### MainMenu Scene Structure
*   **Old**: Single `Control` node with direct `Button` children.
*   **New**: A `Node` root containing `BackgroundController`, `CanvasLayer` (UI), and `AudioStreamPlayer` nodes.
