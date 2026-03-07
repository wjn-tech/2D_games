# Design: Global Audio System Architecture

## Architecture Overview
The system centers on a singleton `AudioManager` that manages node pools for concurrent SFX playback and dedicated streams for looping Ambience and Music.

## Key Components

### 1. AudioManager Singleton
- **Responsibility**: Global playback entry point for UI, Scripts, and Signals.
- **Node Structure**:
    - `MusicStreamPlayer` (BGM bus): Dedicated player for music. Supports cross-fading.
    - `AmbientStreamPlayer` (Ambient bus): Dedicated player for weather/biome loops. Includes a `AudioEffectLowPassFilter` for muffled effects.
    - `SFXPool` (SFX bus): A dynamic or pre-allocated pool of `AudioStreamPlayer` nodes to handle overlapping sounds without interruption.
    - `SFXPool2D` (SFX bus): A pool of `AudioStreamPlayer2D` for world-positioned sounds (NPCs, Breakables).

### 2. Audio Bus Layout
- **Master**: Overall project volume.
- **Music (L-R)**: Background melodies.
- **SFX**: Player actions, UI clicks, small events.
- **Ambient**: Wind, Rain, Biome loops.
- **Underground Filter**: A secondary bus or effect applied to `Ambient` when the player is below `surface_height`.

### 3. Integrated Playback API
```gdscript
# Trigger a one-shot SFX at any position or globally
AudioManager.play_sfx("ui_click")
AudioManager.play_sfx_2d(global_pos, "impact_metal")

# Transitions for looping audio
AudioManager.play_bgm("forest_theme", fade_time = 2.0)
AudioManager.play_ambience("rain_loop", fade_time = 1.0)

# Settings integration
AudioManager.update_bus_volume("SFX", 0.8) # 0.0 to 1.0
```

## System Behaviors
- **Pitch Randomization**: Automatically applied (default +/- 0.1) to SFX calls unless specified otherwise.
- **Attenuation**: `AudioStreamPlayer2D` nodes configured with `MAX_DISTANCE` to prevent global bleed of localized sounds.
- **Occlusion/Muffling**: Simple check against `GameState` surface data to toggle LPF on the `Ambient` bus.


## Data Management
Audio assets are managed via a centralized `Dictionary` mapping string keys to `AudioStream` resources (Ogg, MP3, Wav). This avoids hardcoded paths in system scripts.

## Performance Optimization
- **Node Pooling**: Prevents excessive node creation/deletion; reuses inactive players.
- **Volume Control**: Direct control over `AudioServer` buses for real-time responsiveness.
- **Format Choices**: Use `Wav` for short, frequent SFX (low CPU impact). Use `Ogg` or `MP3` for long, looping Music (compressed).

## Cross-System Integration
- **EventBus Connections**: The `AudioManager` will listen for generic events like `player_jumped`, `item_crafted`, or `weather_changed` to automatically trigger corresponding sounds.
- **UI Hooks**: Use `get_tree().node_added` or manual hookups to automatically add SFX to standard Button clicks across all menus.
