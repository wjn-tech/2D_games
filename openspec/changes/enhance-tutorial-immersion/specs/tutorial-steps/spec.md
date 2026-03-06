# Spec: Technical Steps & Changes

## Overview
Implement the narrative changes by updating the `TutorialSequenceManager` and scene assets.

## ADDED Requirements

#### Scenario: Phase Updates
- **GIVEN** `Phase` enum in `tutorial_sequence_manager.gd`
- **THEN** it should include: `WAKE_UP`, `STARDUST`, `WAND_REPAIR`, `COMBAT_CHARGE`, `CRASH_SEQUENCE`.
- **AND** remove or repurpose `INVENTORY` and `EQUIP` phases (now implicit in Wand Repair).

#### Scenario: Visual Assets
- **GIVEN** `Tutorial` scene
- **THEN** add valid placeholders for:
    - `CryoPod` (`Sprite2D` or `Polygon2D`)
    - `Stardust` (`Particles2D` or `Area2D` pickup)
    - `BrokenConduit` (`Sprite2D` interactable)
    - `Window` (Area showing space background)

#### Scenario: Camera Events
- **GIVEN** `Camera2D` in `Tutorial` scene
- **WHEN** phase is `WAKE_UP` or `CRASH`
- **THEN** allow targeted camera panning via `Tween` (avoid abrupt jumps).
- **AND** maintain `shake` logic for explosions.

#### Scenario: Wand Editor Validation
- **GIVEN** `_check_step` function
- **THEN** ensure it accepts `Phase.WAND_REPAIR` (new name for `Phase.PROGRAM` + `Phase.GENERATOR` combined) correctly.
- **AND** validates `generator` and `projectile` presence before completion.

## MODIFIED Requirements

#### Scenario: Dialogue Management
- **GIVEN** `dialogue_event.emit` calls in `tutorial_sequence_manager.gd`
- **THEN** align these with the new script lines (e.g., `<emit:wait_editor>`, `<emit:wait_generator>`).
- **AND** ensure existing `highlight` logic (`_handle_highlight_event`) still works with the new tags if needed.
