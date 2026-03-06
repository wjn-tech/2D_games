# Design: Enforce Interaction Rules & Scene Dynamics (Detailed)

## Architecture Overview

This change integrates strict state enforcement into the existing `TutorialSequenceManager` (TSM) while adding two new subsystems: `CinematicOverlay` (for narrative) and `ObjectiveTracker` (for validation).

### 1. Class Structure & Relationships

```mermaid
graph TD
    TSM[TutorialSequenceManager] -->|Manage Phrases| STATE{State Machine}
    TSM -->|Updates| OT[ObjectiveTracker (UI)]
    TSM -->|Controls| CO[CinematicOverlay (UI)]
    TSM -->|Triggers| EC[EnvironmentController]
    
    TSM -- Listen --> EB[EventBus]
    wand[WandEditor] -- Signal: logic_updated --> EB
    inv[Inventory] -- Signal: item_equipped --> EB
```

## 2. Component Design

### A. TutorialSequenceManager (Refactor)
*   **State Machine**: Extend `Phase` enum.
    *   `Phase.CINEMATIC_INTRO` (New): Blocks input, shows overlay.
    *   `Phase.WAND_REPAIR` (Refined): Combines LogicTab + Gen + Proj + Connect.
    *   `Phase.DESTRUCTION` (Parallel): TSM monitors time/steps to trigger `break_wall()` events.
*   **Validation Logic**:
    *   Replace string-based `_wait_condition` with typed `ActionRequirement`:
        ```gdscript
        class ActionRequirement:
            var text: String # HUD Text
            var function_name: String # EventBus signal to listen for (via `call` or `connect`)
            var validator: Callable # Function to check specific data
        ```
    *   **Flow**:
        1.  `_start_phase(Phase)` sets `current_requirement`.
        2.  `ObjectiveTracker.update(text)` is called.
        3.  TSM listens to `EventBus` or polls `process`.
        4.  On check, run `validator.call()`.
        5.  If true -> `ObjectiveTracker.complete()` -> Advance Dialogue.

### B. CinematicOverlay (New Scene)
*   **Path**: `scenes/ui/tutorial/CinematicOverlay.tscn`
*   **Node Tree**:
    ```
    CanvasLayer (Layer=120)
      ColorRect (Black Background)
      TextureRect (Image, Full Rect, Expand)
      MarginContainer (Bottom)
        PanelContainer (Dialogue Box)
          RichTextLabel (Subtitle)
    ```
*   **API**:
    *   `play_sequence(data: Array[Dictionary])`
    *   `data` structure: `[{ text: "...", image: Texture, duration: 3.0 }, ...]`

### C. ObjectiveTracker (New UI Component)
*   **Path**: `scenes/ui/hud/ObjectiveTracker.tscn`
*   **Visuals**: Simple, high-contrast box in Top-Left.
*   **States**:
    *   `Idle` (Hidden)
    *   `Active` (Show Box + Text + Empty Checkbox)
    *   `Success` (Play "Ding" sound + Checkbox Checked + Green Text) -> Fade out after 2s.

### D. EnvironmentController (Enhanced)
*   **Destruction Map**:
    *   Dictionary `destruction_events = { 2: [Vector2i(5,5)], 4: [Vector2i(8,8)] }` mapping `Phase` to `TileCoords`.
*   **Methods**:
    *   `trigger_destruction(phase_index: int)`: Iterates coords, sets TileMap cell to `rubble_id`, spawns `ExplosionParticles`.

## 3. Data Flow (Example: Wand Repair)

1.  **Dialogue**: "You need to fix the wand." -> `<emit:objective:repair_wand>`
2.  **TSM**:
    *   Parses tag.
    *   Sets Objective: "Install Generator & Projectile".
    *   Calls `ObjectiveTracker.show("Install Components")`.
    *   Highlights: `OverlayManager` points to Generator in Palette.
3.  **Player**: Drags Generator to Grid.
4.  **Signal**: `EventBus.spell_logic_updated` fires.
5.  **TSM Validator**:
    *   Checks `wand.has_node("generator")` -> True.
    *   Checks `wand.has_node("projectile")` -> False.
    *   Result: *Incomplete*. Update Text: "Now add Projectile".
6.  **Player**: Drags Projectile.
7.  **TSM Validator**:
    *   Checks both -> True.
    *   Result: *Phase Complete*.
    *   `ObjectiveTracker.success()`.
    *   `DialogueManager.resume()`.

## 4. Asset Requirements
*   **Images**: `intro_cryobod_1.png`, `intro_cryobod_open.png`, `ship_crash_external.png`.
*   **Audio**: `ui_objective_update.wav`, `ui_objective_complete.wav`, `structure_break.wav`.
*   **Particles**: `Sparks.tscn` (GPU Particles), `Debris.tscn`.
