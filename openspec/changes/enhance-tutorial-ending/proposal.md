# Enhance Tutorial Ending Sequence

Replaces the abrupt black-screen-with-text ending of the tutorial with a seamless, cinematic crash sequence. The player will experience the ship disintegrating around them, falling through the atmosphere protected by the Court Mage's shield, and waking up on the planet surface to begin the game proper.

## Context
Currently, when the tutorial ends (after the "Critical Failure" event), the screen fades to black, displays text "TOO LATE! BRACE FOR IMPACT!", and then reloads the Main scene. This breaks immersion and feels outdated compared to modern game standards.

## Why
- **Immersion Breaking:** The black screen transition disconnects the player from the urgent narrative of the ship crashing.
- **Lack of Visual Feedback:** The "crash" is purely textual.
- **Jarring Reset:** Reloading the scene resets the world state unnecessarily when the tutorial already occurs within the main game context.

## Solution
Implement a continuous, in-engine cutscene sequence:
1.  **Ship Destruction:** The spaceship visuals (walls, props) disappear or fly apart, spawning debris/explosion particles.
2.  **Ejection & Fall:** The player character is launched out of the ship area and begins falling downward.
3.  **Protective Shield:** A magical barrier (referencing the Court Mage) visual appears around the falling player.
4.  **Atmospheric Entry:** Screen blur, wind lines, and camera shake simulate high-speed entry.
5.  **Impact & Wake Up:** The screen fades to white/blur near the ground. The player is teleported to a safe spawn point on the surface, starts in a "lying down" state, and stands up after a moment to begin gameplay.

## Scope
-   **Tutorial Logic:** Update `TutorialSequenceManager` to execute the new sequence instead of scene reload.
-   **Visual Effects:** Add particles for debris, wind lines, and the protective bubble.
-   **Camera Control:** Enhance `CinematicDirector` or script custom camera behavior for the fall.
-   **Player State:** Add a "Unconscious/Waking Up" state to the player (or simulate it).
