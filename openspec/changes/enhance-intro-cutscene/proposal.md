# Proposal: Enhance Intro Cinematic (Brother's Entrance)

## Summary
Transform the opening tutorial sequence from a static camera pan into a dynamic, character-driven event. Instead of the "Court Mage" (Brother) standing idle while the player wakes, he will actively rush to the player's aid amidst a chaotic, crumbling ship environment.

## Motivation
Current feedback indicates the intro feels "static" and "lacks immersion," specifically citing that characters seem to "hang on the wall" (idle) for too long. By adding scripted movement, environmental storytelling (screen shake, sparks, red alert lighting), and character acting (running, helping up), we will deliver the desired "epic" and urgent feel.

## Proposed Changes

### 1. Dynamic Character Acting
*   **The Brother (Court Mage)**: Will start at a control console, react to the explosion, and physically **run** to the player's position.
*   **The Player**: Will start in a "knocked down" state (rotated/lying on floor) and be "helped up" during the sequence.

### 2. Environmental Chaos
*   **Red Alert**: The ship's lighting should pulse red.
*   **Debris**: Sparks and smoke particles will spawn during the "impact" moments.
*   **Camera Work**: The camera will track the Brother as he runs to the player, creating a sense of urgency.

### 3. Seamless Transition
*   The "Terminal Boot" sequence (already implemented) will transition directly into the "Brother Running" sequence, eliminating the static pause where the player just stares at a wall.

## Deliverables
1.  **Enhanced CinematicDirector**: Add support for `move_to`, `rotate_to`, and `play_anim` actions.
2.  **Scripted Sequence**: A revised `start_intro` in `TutorialSequenceManager`.
3.  **VFX Polish**: Integration of `Sparks` and `RedAlert` lighting states.
