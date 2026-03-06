# Enhance Tutorial Visual Guidance

- **Change ID**: `enhance-tutorial-guidance`
- **Scope**: Adding visual overlays, highlighting, and contextual tooltips to the tutorial sequence.
- **Status**: Proposed

## Problem
The current tutorial sequence (implemented in `improve-tutorial-interactivity` and `TutorialSequenceManager`) relies heavily on dialogue text and basic state checks. Players often struggle to locate specific buttons or understand abstract instructions like "Drag the Trigger into the grid" without direct visual cues pointing to the relevant UI elements.

## Solution
Implement a **Visual Guidance System** that can:
1.  **Spotlight UI Elements**: Dim the rest of the screen and highlight a specific control (Inventory Slot, Wand Editor Palette Item).
2.  **Dynamic Arrows**: Position animated arrows pointing to specific screen coordinates or UI controls dynamically.
3.  **Contextual Hints**: Display small popup hints near the cursor when hovering over correct/incorrect elements during a tutorial step.

## Risks
- **UI Dependency**: The guidance system needs references to internal UI components (buttons, slots) that might change. We need a robust way to traverse or tag these elements.
- **Visual Clutter**: Too many overlays can be distracting.
- **Input Blocking**: Ensure the "Spotlight" doesn't accidentally block input to the highlighted element.
