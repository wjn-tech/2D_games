# Cinematic Director Spec

## Summary
A system for sequencing and executing visual, audio, and gameplay events to create cutscenes.

## Requirements

### ADDED Cinematic Director Queue

#### Scenario: Queueing Actions and Executing
> **Given** a `CinematicDirector` instance
> **When** `play_sequence(actions)` is called with a list of action dictionaries
> **Then** the director processes each action sequentially, waiting for completion (e.g., duration or signal) before starting the next.

#### Scenario: Blocking Input During Cutscene
> **Given** a cutscene is playing
> **Then** player input should be disabled (`EventBus.player_input_enabled(false)`).
> **When** the cutscene ends
> **Then** player input is restored.

### ADDED Action Types

#### Scenario: Camera Control
> **Given** a `Camera2D` in the scene
> **When** action "pan_to" is executed with `target_pos` and `duration`
> **Then** the camera smoothly interpolates to the target position over the specified time.

#### Scenario: Screen Shake
> **Given** a shake action with `intensity` and `duration`
> **Then** the camera offset jitters randomly within the intensity range for the duration.

#### Scenario: Text Display
> **Given** a text action with `content` and `speed`
> **Then** the text appears character by character (typewriter effect) at the specified speed.
> **And** `[shake]` BBCode tags cause the text to jitter.

#### Scenario: Wait
> **Given** a wait action with `duration`
> **Then** the director pauses execution for the specified time.
