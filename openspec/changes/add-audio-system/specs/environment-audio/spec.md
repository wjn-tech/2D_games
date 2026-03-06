# Spec: Environment Audio Feedback

## Overview
Implement ambient audio feedback for biomes, weather, and environmental events.

## ADDED Requirements

### 1. Dynamic Ambient Loops
The `AudioManager` must transition between ambient loops based on player location.
- **Requirement**: `AudioManager` must support background looping "Ambience" tracks.
- **Requirement**: Biome components/managers must signal a biome change to cross-fade background loops.
- **Requirement**: Weather systems must trigger specific ambient overlays for `Rain`, `Storm`, and `Snow`.

#### Scenario: Biome Transition
- **Given** the player is in the `Forest` biome.
- **When** the player moves into the `Plains` biome.
- **Then** the "ForestAmbient" loop should fade out over 2.0 seconds.
- **And** the "PlainsAmbient" loop should fade in over 2.0 seconds concurrently.

#### Scenario: Rainy Weather
- **Given** the `WeatherManager` starts a `Rain` event.
- **When** the `Rain` state is triggered.
- **Then** `AudioManager` must play a "RainLoop" in the `Ambient` channel.
- **And** the "RainLoop" volume must adjust if the player moves `Underground` (muffled effect).

### 2. Environmental Event One-Shots
Feedback for specific environmental world-state changes.
- **Requirement**: Tree falling or being chopped must have specific "WoodCrunch" and "Fall" SFX.
- **Requirement**: Mining/Gathering must have "Ping" or "Chisel" SFX.
- **Requirement**: Time signals (Dawn/Dusk) must play a subtle thematic chime or sound (e.g. Roosters/Birds for Dawn).

#### Scenario: Mining a Stone
- **Given** the player is mining a `Stone` node.
- **When** the player's tool impacts the stone.
- **Then** `AudioManager` must play a randomized "StoneClink" SFX.
- **And** the final impact that breaks the stone must play a "StoneBreak" SFX.
