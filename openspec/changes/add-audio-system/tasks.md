# Tasks: Add Global Audio System and Core Sound Effects

## Overview
Implement a centralized `AudioManager` and integrate SFX across Player, UI, and Environment systems.

## Prerequisites
- [ ] Research and confirm initial audio assets (Ogg/MP3 for music, Wav for SFX).

## Phase 1: Core Audio Framework
- [ ] Task 1: Create `res://src/core/audio_manager.gd` singleton.
- [ ] Task 2: Configure Global Audio Buses (Master, BGM, SFX, Ambient) in `default_bus_layout.tres`.
- [ ] Task 3: Initialize `AudioManager` in `project.godot` Autoload.
- [ ] Task 4: Implement Sound Pooling in `AudioManager` for SFX.
- [ ] Task 5: Setup global SFX and BGM play API in `AudioManager`.

## Phase 2: User Interface Audio
- [ ] Task 6: Hook into `EventBus` or individual UI nodes to play hover/click sounds.
- [ ] Task 7: Integrate feedback sounds for Inventory actions (open, close, drag, equip).
- [ ] Task 8: Add volume sliders (Master, Music, SFX, Ambient) to `SettingsWindow` and bind to `AudioManager`.


## Phase 3: Player Actions SFX
- [ ] Task 8: Implement Step detection and playback in `player.gd`.
- [ ] Task 9: Implement Jump, Double Jump, and Landing SFX.
- [ ] Task 10: Implement Combat SFX (swing, hit, miss).

## Phase 4: Environment and Ambience
- [ ] Task 11: Implement Weather-based ambient looping sounds (Rain, Storm, Snow).
- [ ] Task 12: Implement Biome-based background music transitions.
- [ ] Task 13: Implement Low-Pass Filter (LPF) toggle logic in `AudioManager` based on altitude/depth.


## Phase 5: Testing and Polish
- [ ] Task 13: Audit all systems to ensure no missing audio events.
- [ ] Task 14: Implement Pitch randomization for repetitive sounds (Steps, Hits).
- [ ] Task 15: Create Volume slider integration for settings.
