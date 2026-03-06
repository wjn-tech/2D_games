# Spec: Cutscene Integration

## Overview
Replaces standard in-game cutscenes with Cinematic Overlays for key moments (Waking Up, Crash).

## ADDED Requirements

#### Scenario: Full-Screen Cutscene (Wake Up)
- **GIVEN** tutorial start (`Phase.WAKE_UP`)
- **THEN** display a `CinematicOverlay.tscn` full-screen control node.
- **AND** render blurred, first-person style images (`wake_up.png`).
- **AND** show subtitles overlaying the visual.
- **WHEN** user interacts or time passes
- **THEN** fade out the overlay to `0` alpha, returning control to gameplay (`Phase.TUTORIAL_START`).

#### Scenario: Crash Sequence (Cutscene)
- **GIVEN** tutorial end (`Phase.CRASH`)
- **THEN** fade in `CinematicOverlay.tscn`.
- **AND** play "Crash" sound effect and intense screen shake (`overlay.shake`).
- **AND** display final text ("IMPACT IMMINENT").
- **THEN** transition scene to `MainGame` or `TitleScreen` after delay.

## MODIFIED Requirements

#### Scenario: Dialogue Management
- **GIVEN** `DialogueManager`
- **THEN** ensure it can pause *gameplay* dialogue while *cinematic* dialogue is running (or share the overlay).
