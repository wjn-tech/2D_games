# Spec: Combat Basics Guidance

## ADDED Requirements

### Requirement: Combat Interaction
The tutorial system MUST teach the player basic combat mechanics (aiming and firing).

#### Scenario: Spawn Target
-   **Given** the tutorial state is `wait_shoot`.
-   **When** dialogue "Blast that loose panel!" finishes.
-   **Then** a **Target Dummy** (loose panel) MUST spawn at a predefined location.
-   **And** a **Red Reticle** or Bracket MUST highlight the target on screen.

#### Scenario: Aiming Prompt
-   **Given** the target is spawned.
-   **When** the player must engage.
-   **Then** a **Mouse Left Click** icon prompt MUST appear near the crosshair/player.
-   **And** update the prompt to "Fire!" when the player aims near (within 30 degrees) the target.

#### Scenario: Destruction Feedback
-   **Given** the target is active.
-   **When** the player successfully destroys the target with the Wand.
-   **Then** the tutorial manager should play a loud "Crash/Explosion" sound.
-   **And** immediately transition to the `crash_start` sequence.
