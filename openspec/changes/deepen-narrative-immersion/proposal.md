# Deepen Narrative Immersion

- **Change ID**: `deepen-narrative-immersion`
- **Scope**: Tutorial Scene (`intro/spaceship2.tscn`), `TutorialSequenceManager`, Court Mage NPC behavior, Environmental FX (Sound, Lighting, Particles).
- **Status**: Proposed

## Problem
The current tutorial sequence is functional but emotionally flat. The player is taught mechanics in a sterile vacuum.
- **Lack of Urgency**: The player is told the ship is "crashing" via text, but nothing *feels* like a crash. No debris, no alarms, no visual struggle.
- **Static NPC**: The Court Mage is a static sprite delivering monologue. It doesn't convey the effort of holding the ship together.
- **Missing Motivation**: The player is given a wand "because magic," not because survival demands it.

## Solution
Transform the tutorial from a "lesson" into a **Survival Sequence**.
1.  **Reactive Environment**: Implement a `ShipStateController` that triggers alarms, red emergency lighting, steam leaks, and sparks based on tutorial progression.
2.  **Cinematic Framing**: Use dynamic camera (screenshake intensity layers, zoom-ins on the Mage) and UI Letterboxing to focus attention during key dialogue.
3.  **Active NPC**: The Court Mage should be actively casting a "Barrier Spell" to hold a hull breach closed. The player fixes the wand *to help the Mage*.
4.  **Audio Design**: Layered soundscape (low rumbles, high-pitch magical strain, metal groaning).

## Risks
- **Performance**: High particle counts (sparks/steam) could impact low-end devices during the intro. Need to optimize or use simple sprites.
- **Clarity vs. Chaos**: Too much screen shake/flashing lights might make the Wand Editor (a precise UI task) frustrating to use. The chaos must *pause* or *dampen* when the UI is open.
