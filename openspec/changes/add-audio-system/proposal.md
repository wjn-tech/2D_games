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
- **Audio Buses**: Define "Master", "BGM", "SFX", and "Ambient" buses for volume control.
- **Decoupling**: Systems trigger sounds via `AudioManager` global calls or signals via `EventBus`.

## Impact
- **Performance**: Negligible if using pooling and compressed audio formats (Ogg/MP3 for music, Wav for SFX).
- **Architecture**: Enhances the existing modular pattern by centralizing audio logic.

## Questions for Clarification
1. **Asset Source**: Do we have existing audio assets, or should placeholders/generated sounds be used initially?
2. **Dynamic Music**: Does the music need to change dynamically based on combat state or biome intensity?
3. **Spatial Audio**: Do we need 2D spatial audio (e.g., sounds getting quieter as they move off-screen) for NPCs and environment?
4. **Volume Settings**: Should UI controls for Volume be part of this proposal or a separate settings-window update?
5. **Pitch Randomization**: Should the system automatically apply pitch variation to repeated sounds (like footsteps) to prevent fatigue?
6. **Voice Overs**: Is there any plan for NPC voice-overs or grunts that require special handling?
7. **Transition Duration**: What are the preferred fade-in/out durations for BGM transitions?
