# Spec: Check Validation System

## Overview
Implement strict validation for tutorial tasks with explicit UI feedback.

## ADDED Requirements

#### Scenario: Objective Tracking (HUD)
- **GIVEN** `Phase` change
- **THEN** display `ObjectiveTracker` UI (CanvasLayer/VBoxContainer in HUD).
- **AND** show text for the active "Quest" (e.g., "Install Generator [ ]").
- **AND** checkmark [✓] when `verify_action` returns true.

#### Scenario: World Markers
- **GIVEN** `ObjectiveTracker` is active
- **AND** interactive object exists
- **THEN** show `ArrowIndicator` or `GhostHand` pointing to it.
- **AND** blink or animate the indicator to grab attention.

#### Scenario: Strict Phase Validation
- **GIVEN** `check_step(phase)` function
- **THEN** logic must prevent progression until ALL conditions are met:
    1.  `Interactive` object state (e.g., Wand programmed correctly). 
    2.  `Trigger` event fired (e.g., "Connect" button pressed).
- **AND** if player fails or mis-clicks
    - **THEN** show localized tooltip ("Missing Generator!" or "Wrong Connection!").
    - **AND** do NOT advance `_wait_condition`.

## MODIFIED Requirements

#### Scenario: Check Indicators
- **GIVEN** existing overlay system (`OverlayManager`)
- **THEN** expand it to track multiple simultaneous tasks (e.g., "Generator" AND "Projectile").
- **AND** verify both are placed before showing "Connect" arrow.
