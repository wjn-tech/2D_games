# Spec: AudioManager Component

## Overview
Defines the core functionality and API for the centralized `AudioManager` singleton.

## MODIFIED Requirements

### 1. Global Audio Manager
The system must provide a globally accessible `AudioManager` Autoload to centralize all audio requests.
- **Requirement**: `AudioManager` must exist as a singleton.
- **Requirement**: `AudioManager` must manage dedicated buses for `Music`, `SFX`, and `Ambient` sounds.
- **Requirement**: `AudioManager` must implement a pool of `AudioStreamPlayer` nodes for non-blocking SFX playback.

#### Scenario: Playing an SFX Globally
- **Given** the game is running and `AudioManager` is initialized.
- **When** a script calls `AudioManager.play_sfx("ui_click")`.
- **Then** a free player in the SFX pool must playback the "ui_click" sound.
- **And** the sound must be played on the `SFX` audio bus.

#### Scenario: Music Transitions
- **Given** the music "MenuTheme" is currently playing.
- **When** the game calls `AudioManager.play_bgm("ForestTheme", 2.0)`.
- **Then** the "MenuTheme" must fade out over 2.0 seconds.
- **And** the "ForestTheme" must fade in over 2.0 seconds concurrently.

#### Scenario: Ambient Weather Audio
- **Given** the weather changes from `Clear` to `Rain`.
- **When** the `WeatherManager` signals a change.
- **Then** `AudioManager` must start the "RainLoop" in the `Ambient` stream.
- **And** the "RainLoop" should loop indefinitely until another ambience is called.

### 2. Audio Library Mapping
The `AudioManager` must map string identifiers to `AudioStream` resources for decoupled access.
- **Requirement**: An internal `Dictionary` must store `Key -> Resource` pairs.
- **Requirement**: Invalid sound keys must log a warning instead of crashing the game.
