# Proposal: Enhance Tutorial Immersion

## Summary
Refine the tutorial to improve immersion and narrative depth, following the "Star Traveler: Day of the Fall" script, while retaining the core Wand Editor programming mechanics instead of the proposed Shield Crafting.

## Motivation
The current tutorial is functional but lacks emotional engagement. The "Star Traveler" script provides a strong hook, but needs adaptation to the existing 2D game mechanics and the "Wand Repair" core loop.

## Solution

### Narrative Adaptation (2D Top-Down)
- **Scene 1 (Wake Up)**: 
    - Instead of "First Person", use a **Character Animation** (waking up from cryo-pod).
    - "Looking Around": Use **Camera Pan** to show the planet outside the window, triggered by player movement or a bespoke cutscene trigger.
- **Scene 2 (First Magic)**:
    - Retain: "Collect Stardust" mechanics (needs implementation).
    - Retain: "Reveal Spell" to show enemies.
- **Scene 3 (Adaptation)**:
    - **Change**: Replace "Craft Shield" with **"Program Wand"**.
    - **Logic**: Seville gives a broken wand -> Player must insert "Generator" and "Projectile" -> This fixes the wand -> Player uses it to defend.
    - **UI**: Reuse the debugged `WandEditor` tutorial flow here.
- **Scene 4 (Emergency)**:
    - **Change**: "Charge Beam" becomes "Use Programmed Wand to clear debris/enemies".
    - **Finale**: The ship crash sequence (already partially in code) will be enhanced with visual effects and the new dialogue.

### Technical Changes
- **TutorialSequenceManager**: Update state machine to match the new 5-act structure.
- **Dialogue**: Replace current text with the new script (adapted for "Wand Repair" instead of "Shield").
- **Visuals**: Add "Cryo Pod", "Space Window", "Explosion Effects" to the tutorial scene.
- **Camera**: Implement "Camera Shake" and "Pan to Window" events.

## Risks
- **Asset Dependency**: The script asks for specific animations (Seville pulling player). We may need to use **Tweens** and **Dialogue Bubbles** as fallbacks if sprites are missing.
- **Complexity**: Blending cutscenes with gameplay in the existing `TutorialSequenceManager` might require refactoring the `_process` loop.
