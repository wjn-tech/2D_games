# Spec: Narrative Flow Adaptation

## Overview
Adapt the provided *Star Traveler* script to the game's mechanics and the "Wand Programming" core loop.

## ADDED Requirements

#### Scenario: The Awakening (Scene 1)
- **GIVEN** a new game starts
- **THEN** the screen should be black, playing "alarm" sound effects.
- **AND** a "Status Report" dialogue should appear (`Phase.WAKE_UP`).
- **WHEN** the player presses any key or after a timer
- **THEN** the camera should fade in, centered on a cryo-pod sprite.
- **AND** the player character should play a "stand up" animation (or simple sprite swap).
- **AND** Seville (NPC) should appear and initiate dialogue ("Wake up!").

#### Scenario: First Magic & Stardust (Scene 2)
- **GIVEN** the player has control
- **WHEN** Seville points to a "broken conduit"
- **THEN** an interaction prompt (E) should appear.
- **AND** collecting it should grant "Stardust" resource (simulated or real).
- **AND** trigger the next dialogue ("Good, now use it.").

#### Scenario: Wand Repair (Scene 3 - Replaces Shield Crafting)
- **GIVEN** the "Wand Repair" phase starts
- **WHEN** the player opens the Wand Editor
- **THEN** the dialogue should instruct to place a **Generator** (Source) and **Projectile** (Weapon).
- **AND** ghost indicators should guide this process (reusing existing system).
- **AND** closing the editor with a valid wand should trigger a "System Online" success message.

#### Scenario: The Charge Beam (Scene 4 - Climax)
- **GIVEN** enemies are defeated or specific time has passed
- **WHEN** Seville yells "Overcharge it!"
- **THEN** the player must hold the fire button.
- **AND** a `ChargeBar` UI element should appear and fill up.
- **AND** releasing at full charge should fire a massive beam (scripted visual) that destroys the obstruction.

#### Scenario: The Crash (Scene 5)
- **GIVEN** the obstruction is destroyed
- **THEN** a screen shake sequence should start (`_start_crash_sequence`).
- **AND** screens should fade to white/black.
- **AND** the "Title Card" or "Level 1" transition should occur.

## MODIFIED Requirements

#### Scenario: Dialogue Integration
- **GIVEN** the existing `dialogue_lines` array in `tutorial_sequence_manager.gd`
- **THEN** it must be replaced with the new script lines, adapted for the gameplay changes (e.g., "Craft Shield" lines changed to "Fix Wand").
- **AND** ensure existing `emit` tags (like `<emit:highlight:generator>`) are preserved or updated to match new flow.
