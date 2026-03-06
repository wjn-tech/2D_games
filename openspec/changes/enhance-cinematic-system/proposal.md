# Proposal: Hybrid Cinematic System (Terminal + In-Engine)

## Summary
Implement a high-fidelity "Hybrid" cinematic system for the game's introduction. The sequence begins with a **diegetic Terminal Boot UI** (Scheme C) simulating the ship's computer coming online, then transitions via a glitch effect into an **In-Engine** cutscene (Scheme B) showing the player waking up amidst the chaos of the crash.

## Motivation
The current static black screen lacks immersion and urgency. By using a terminal interface, we immediately establish the sci-fi/tech setting without needing expensive 3D assets or character portraits. The seamless transition to the in-game view grounds the player in the actual environment they will explore.

## Selected Approach: Hybrid (Scheme B + C)

### Part 1: The Terminal (UI Overlay)
*   **Visual Style**: CRT monitor aesthetic (scanlines, curvature, chromatic aberration).
*   **Narrative**: "System Rebooting...", "Hull Critical", "Life Support Failing".
*   **Audio**: Computer hums, hard drive clicks, alarm klaxons.

### Part 2: The Awakening (In-Engine)
*   **Visual Style**: Game camera zooms and pans dynamically.
*   **Action**: Camera focuses on burning wreckage (Mana Drive), then pans to the unconscious player.
*   **FX**: Screen shake, smoke particles, sparks.

## Benefits
1.  **Asset Efficient**: Uses text shaders and existing game sprites.
2.  **Immersive**: No break in "presence" (everything happens "in world" or "on screen").
3.  **Extensible**: The underlying `CinematicDirector` can be reused for boss intros or area reveals.

## Deliverables
1.  `CinematicDirector`: A singleton to manage the sequence queue.
2.  `TerminalOverlay`: A robust UI scene with CRT shaders and typewriter text effects.
3.  `IntroSequence`: The specific script orchestrating the tutorial start.
