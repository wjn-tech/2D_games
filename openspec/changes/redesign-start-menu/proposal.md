# Proposal: Redesign Start Menu

## Goal
Transform the Start Menu from a functional entry point into an immersive "Dynamic Experience" that establishes the game's atmosphere, builds emotional connection, and provides smart, context-aware navigation.

## Context
The current `MainMenu.tscn` is a standard static interface with basic buttons (`Start`, `Load`, `Exit`) and minimal animation. It lacks world coherence and does not leverage the game's rich environment (time of day, weather) or the player's progress history.

## Solution
We will implement a layered `MainMenuSystem` that includes:
1.  **Immersive Background**: A dynamic scene reflecting real-time (System Time) or game-state conditions (Time/Weather), utilizing parallax layers.
2.  **Smart Navigation**: Context-sensitive options like "Continue [Location] ([Time])" instead of a generic "Load Game".
3.  **Atmospheric Audio**: Layered music tracks (Ambient, Melody) that react to player activity.
4.  **Polished UX**: Smooth transitions (Entrance/Exit animations), particle effects, and preview-enabled settings.

## Risks
*   **Performance**: Loading heavy assets (scenes/weather) for the menu might increase startup time. We will mitigate this with a progressive loading strategy.
*   **Complexity**: Managing state (game progression) inside the menu requires access to `SaveSystem` data without fully loading the game world.

## Success Criteria
*   The menu displays a dynamic background corresponding to the time of day.
*   "Continue" button shows specific save details (Location, Time ago).
*   Transitions between menu states (Title -> Settings -> Game) are animated and seamless.
