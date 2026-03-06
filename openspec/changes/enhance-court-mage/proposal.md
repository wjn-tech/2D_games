# Proposal: Enhance Court Mage Visuals and Movement

## Summary
Replace the placeholder geometric representation of the Court Mage with a polished character sprite, add a floating idle animation, and implement magical trail effects to improve the visual quality and "magical" feel of the character during the tutorial.

## Problem
The current Court Mage is represented by a simple `Polygon2D` and static particles. The character feels lifeless and lacks the visual fidelity expected of a key narrative NPC. The movement is a simple linear interpolation which feels robotic rather than magical.

## Proposed Solution
1.  **New Character Scene**: Create a dedicated `court_mage.tscn` with a proper sprite keyframed for idle floating.
2.  **Visual Overhaul**: Use a character sprite (wizard/robe style) instead of a colored polygon.
3.  **Dynamic Movement**: Add a script to handle a sine-wave "floating" idle motion and a particle trail that activates when moving.
4.  **Integration**: Update `spaceship2.tscn` to use this new scene.

## Risks
-   **Asset dependency**: Requires a suitable sprite asset. (We will use a placeholder or generate one if needed, but the spec focuses on the implementation structure).
-   **Cinematic Compatibility**: The `CinematicDirector` moves the node directly. The new script needs to handle local visual offsets (floating) without fighting the global position tweening.

## Estimated Impact
-   Isolates the Mage logic into its own scene/script.
-   Improves the initial "hook" of the game during the tutorial.
