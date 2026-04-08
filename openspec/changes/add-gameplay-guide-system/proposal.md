# Proposal: Add Gameplay Guide System

- **Change ID**: `add-gameplay-guide-system`
- **Scope**: Implement an in-game help/guide window accessible from the gameplay HUD, separate from the tutorial sequence.
- **Status**: Proposed

## Problem

Players need an in-game reference system to understand game mechanics without interrupting gameplay. Currently:

- Game mechanics documentation exists only in dialogue/tutorials.
- Players cannot quickly reference game rules during gameplay.
- There is no persistent "Help" UI accessible from the HUD.
- No way to pause the game and read comprehensive gameplay information.

## Solution

Implement a **Gameplay Guide System** with:

1. **Guide Button**: A button in the top-left corner of the HUD labeled "?" or "Guide".
2. **Guide Window**: A modal panel that appears when clicked, displaying expandable guide sections.
3. **Pause Behavior**: When the guide window opens, the game pauses automatically.
4. **Guide Sections**: Organized help content covering:
   - Movement & Camera Controls
   - Inventory & Equipment Management
   - Combat Basics
   - Crafting & Forging
   - Mining & Resource Gathering
   - NPC Interactions & Trading
   - Building & City Planning
   - Magic/Wand System
   - World Mechanics & Progression
5. **Content Structure**: Each section is collapsible, with sub-sections for detailed information.
   - **Text Support**: Rich text formatting via BBCode (bold, italic, colors, alignment).
   - **Image Support**: Each subsection can include an optional image for visual explanation (PNG/JPG textures).
6. **Navigation**: Players can search/filter or scroll through sections.

## Scope

This change covers:

1. **UI Components**:
   - `GuideButton` scene/script: Small button in top-left HUD corner.
   - `GameplayGuideWindow` scene/script: Modal window with collapsible sections.
   - `GuideSectionItem` scene/script: Individual expandable guide entry.
   - `GuideSubsectionItem` scene/script: Content display with text + optional image support.

2. **Game Logic**:
   - Integration with Pause Manager to pause game when guide opens.
   - Guide content data structure (Resource-based guide data with image path support).
   - Open/close animations and state management.
   - Image loading and display management (with fallback for missing textures).

3. **Content**:
   - Framework for text + image guide content.
   - Schema for guide data (sections, subsections, descriptions, images, icons).
   - Content structure editable by user via Resource files (.tres) for easy updates.

## Not In Scope

- Advanced search or indexing system (can be added later).
- Localization (though guide content should support i18n structure).
- Voice narration or video tutorials.
- Context-sensitive hints during gameplay (handled separately by tutorial system).

## Risks & Mitigation

- **Risk**: Pause system conflicts with existing pause menu (ESC key).
  - **Mitigation**: Ensure Guide Window and Pause Menu share the same pause state; guide window can be closed via ESC.
- **Risk**: Guide content becomes outdated as game features change.
  - **Mitigation**: Use data-driven guide content (Resource files) to make updates decoupled from code.
- **Risk**: Modal window layout doesn't fit all screen resolutions.
  - **Mitigation**: Use responsive UI anchors and scrollable containers for long content.

## Architecture Decisions

1. **Pause Integration**: Reuse existing `PauseManager` (or `GameState`) to handle pause state for the guide window.
2. **Content Format**: Store guide sections in `.tres` Resource files or structured JSON for easy editing without code changes.
3. **UI Framework**: Use standard Godot UI nodes (VBoxContainer, TabContainer, or custom collapsible list items).
4. **Button Placement**: Fixed position in top-left HUD; can be repositioned via theme/layout settings.
