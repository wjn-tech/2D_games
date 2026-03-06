# Spec: Movement Core

## ADDED Requirements

### Requirement: Movement Input Prompts
The game MUST display visual cues for movement controls during the tutorial introduction.

#### Scenario: Display WASD Inputs
-   **Given** the player has just woken up in the tutorial sequence.
-   **When** the dialogue "The Mana Drive is unstable. Come here, quickly!" finishes.
-   **Then** a set of 4 semi-transparent key icons ("W", "A", "S", "D") should appear in screen space near the player character.
-   **And** these icons should pulse gently to attract attention.

#### Scenario: Fade out on Input
-   **Given** the "W", "A", "S", "D" icons are visible.
-   **When** the player presses the `move_right` action ("D").
-   **Then** the "D" icon should play a "pressed" animation and fade out permanently.
-   **And** the "W", "A", "S" icons should remain visible until their respective actions are performed.

#### Scenario: Advance Tutorial on Movement
-   **Given** the movement prompts are active.
-   **When** the player has successfully moved a total distance of 200 pixels from the spawn point.
-   **Then** the tutorial manager should consider the "Movement Phase" complete.
-   **And** any remaining movement prompts should fade out.
