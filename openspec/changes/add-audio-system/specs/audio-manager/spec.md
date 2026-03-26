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

#### Scenario: Muffled Underground Audio
- **Given** the player is moving below the `surface_height`.
- **When** the player's Y position exceeds the biome surface threshold.
- **Then** `AudioManager` must enable the Low-Pass Filter (LPF) on the `Ambient` bus.
- **And** when returning to the surface, the LPF must be disabled.

### 2. Audio settings
The system must expose volume control for each audio bus to the settings menu.
- **Requirement**: `AudioManager` must provide methods to set volume in decibels or percentage (0-100).
- **Requirement**: Volume settings must persist via `SettingsManager`.

