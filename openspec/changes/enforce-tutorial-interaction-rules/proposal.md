# Proposal: Enforce Tutorial Interaction Rules & Enhance Scene Dynamics

## Summary
Enhance the tutorial to feature destructive environment changes, cinematic cutscenes (Cinematic Overlay), and rigorous validation checks (Both World & UI), ensuring a smooth, guided experience that adapts to the plot.

## Motivation
The current tutorial feels static and the checks are implicit. The "Star Traveler" script requires dramatic environmental shifts (walls breaking, fires spreading) and clear "Pass/Fail" states for complex actions like Wand Programming.

## Solution

### 1. Dynamic Environment (Destructive)
- **Concept**: The ship deteriorates physically.
- **Implementation**: 
    - **Tilemap Modification**: Scripted events will remove "Wall" tiles and replace them with "Rubble" or "Fire" tiles.
    - **Particles**: Add `Fire` and `Spark` particle systems at specific coordinates triggered by dialogue events.
    - **Screen Shake**: Intense shake during "Crash" sequences.

### 2. Cutscenes (Cinematic Overlay)
- **Concept**: Use overlay UI for key story moments (Waking up, The Crash).
- **Implementation**: 
    - **New UI**: `CinematicOverlay.tscn` with `TextureRect` (for images/videos) and `Label` (subtitles).
    - **Trigger**: `TutorialSequenceManager` pauses gameplay and shows this overlay during specific phases (`WAKE_UP`, `CRASH`).

### 3. Check System (Explicit Validation)
- **Concept**: Every "Action Phase" has a visual objective.
- **Implementation**:
    - **HUD Objective**: A new `ObjectiveTracker` UI listing current task (e.g., "Install Generator: [ ]").
    - **World Marker**: Existing `OverlayManager` ghosts/arrows pointing to the interactive element.
    - **Validation Logic**: `TutorialSequenceManager.gd` will have a strict `verify_action(phase)` function that must return `true` before proceeding.

### 4. Dialogue Flow
- **Non-Check**: Click-to-advance (Subtitle style).
- **Check**: Dialogue pauses, UI shows objective, waits for `verify_action() == true`.

## Risks
- **Asset Load**: Destructive environments require "Broken" tile variants. *Mitigation: Use existing assets or generic debris.*
- **Performance**: Many particles + screen shake might impact low-end devices. *Mitigation: Object pooling for particles.*
