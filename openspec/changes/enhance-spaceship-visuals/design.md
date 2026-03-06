# Design: Dynamic Spaceship Environment

## Overview
This design details the visual and technical implementation for the enhanced spaceship environment, focusing on the `ShipEnvironmentController` and asset integration.

## System Components

### 1. **Visual Layer (TileMap & Decor)**
-   **Structure**: Use a `TileMapLayer` for the hull, floor, and ceiling.
    -   *Style*: **Industrial Gritty**. Deep grey metal, rust stains, oil leaks, heavy bolting, and yellow hazard stripes.
-   **Decor**: `Sprite2D` props for:
    -   **Cryo Pod**: The player's start point.
    -   **Main Console**: Where the Mage stands.
    -   **Exposed Wiring**: Spark emission points.
    -   **Pipes**: Steam vent points.

### 2. **Lighting System (Godot 2D Lights)**
-   **Global Illumination**: `CanvasModulate` set to **Industrial Grey** (`#808080`) to ensure visibility while allowing lights to pop. NOT pitch black.
-   **Emergency Lights**: `PointLight2D` (Red) rotating or flashing. High contrast against the grey walls.
-   **Sparks**: Light transiently enabled when particles emit.
-   **Console Glow**: Static `TextureLight2D` on key interactive areas.

### 3. **Environment Controller (State Machine)**
The `ShipEnvironmentController` will be expanded to manage these visual layers based on `AlertLevel`.

| State | Lighting | Particles | Background | Sound |
| :--- | :--- | :--- | :--- | :--- |
| **WAKE_UP** | Bright grey ambient. Slow red pulse. | Minor steam. | Slow drift. | Low hum + Alarm. |
| **MAGE_TALK** | Spotlights active. | Occasional spark. | Slow drift. | Muted alarm. |
| **REPAIR** | Flicker on input (Player interaction). | Steam increases. | Medium drift. | Spark zaps. |
| **COMBAT** | Aggressive strobing red. | Heavy sparks. | Fast spin (loss of control). | Structural creaking. |
| **BREACH** | Momentary blackouts -> Bright flash. | Debris suction. | Streaking stars + **Camera Rotation**. | Wind roar. |


### 4. **Parallax Background**
-   **Layer 1**: Distant stars (Slow scroll).
-   **Layer 2**: Nearby debris/dust (Fast scroll + Parallax).
-   **Window View**: A `SubViewport` or `Stencil` mask to rendering the stars only through the ship's windows.

## Technical Implementation
-   **Resource**: `ShipState` resource or Enum in `ShipEnvironmentController`.
-   **Signals**: `TutorialSequenceManager` emits state changes -> `ShipEnvironmentController` applies visual transitions (Tweens).
-   **Performance**: Batch particles where possible. Use `VisibleOnScreenNotifier2D` for expensive effects.
