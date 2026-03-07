# Proposal: Add Global Audio System and Core Sound Effects

## Overview
Currently, the project lacks an integrated audio system. This proposal introduces a centralized `AudioManager` singleton to manage background music (BGM) and sound effects (SFX), and implements initial sound effects for the player, UI, and environment to enhance immersion.

## Problem
- No auditory feedback for player actions (steps, jumping, landing).
- UI interactions (buttons, inventory) are silent.
- Environmental events (weather, biome transitions) lack ambient sound.
- No existing framework for managing audio buses, volume settings, or spatial audio.

## Objectives
1. Create a centralized `AudioManager` singleton.
2. Implement SFX for core player movements and combat.
3. Implement SFX for UI interactions.
4. Implement ambient audio for environment and weather.
5. Provide a foundation for future spatial audio and dynamic music systems.

## Proposed Changes
- **AudioManager**: A new Autoload to handle global play requests, cross-fading, and audio bus management.
- **Spec Deltas**:
    - `audio-manager`: General requirements for the audio framework.
    - `player-sfx`: SFX triggered by player states.
    - `ui-sfx`: Global UI sound feedback.
    - `environment-audio`: Ambient loops and weather-based sounds.

## Design Decisions
- **Pool Management**: Use an internal pool of `AudioStreamPlayer` nodes to allow overlapping SFX without performance hits.
- **2D Spatial Audio**: Use `AudioStreamPlayer2D` for world-based emitters (NPCs, Environment) to support distance-based attenuation.
- **Audio Buses**: Define "Master", "BGM", "SFX", and "Ambient" buses for volume control.
- **Volume Integration**: Volume sliders will be integrated into the existing `SettingsWindow`.
- **Dynamic Behavior**: BGM and Ambience will support smooth cross-fading. Ambient sounds will include a Low-Pass Filter (LPF) for "muffled" effects when the player is underground.
- **Decoupling**: Systems trigger sounds via `AudioManager` global calls or signals via `EventBus`.

## Impact
- **Performance**: Negligible if using pooling and compressed audio formats (Ogg/MP3 for music, Wav for SFX).
- **Architecture**: Enhances the existing modular pattern by centralizing audio logic.

## Implementation Details (Confirmed)
- **SFX Assets**: Will be generated/provided as high-quality Wav files.
- **BGM/Ambience**: Provided by the user; placed in `assets/audio/bgm/` and `assets/audio/ambient/`.
- **Pitch Randomization**: Enabled for repetitive SFX.
- **Spatial Audio**: Enabled for world-based events.
- **Settings**: Integrated into current global settings.
- **Environment**: Muffled effect (LPF) enabled for interiors/underground.

