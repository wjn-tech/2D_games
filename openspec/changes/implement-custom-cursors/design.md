# Design: Implement Custom Dynamic Cursors

## Architectural Reasoning
The goal is to provide high-quality visual feedback through the mouse cursor by replacing system cursors with custom textures that adapt to the context (UI hover, world interaction, combat, etc.).

### System Components

#### 1. CursorManager (Autoload)
- **Shared Access**: Central singleton to manage cursor state globally.
- **Hotspot Management**: Different textures have different "Click points" (the hotspot). For an arrow, it's (0,0); for a crosshair, it's the center (e.g., 16,16). This must be defined per texture.
- **Redundancy Filter**: Avoid triggering a system cursor update on every frame if the cursor type hasn't changed.

#### 2. Interaction Layer integration
- **Raycast/Area2D signals**: Objects in the world (NPCs, Gatherable wood) will emit mouse hover signals. The `CursorManager` will listen or be called to change the cursor (e.g., to a "Hand" or "Magnifying Glass").
- **UI Focus**: When the `UIManager` reports that UI is focused, the cursor should default to the menu-style ARROW.

### Technical Implementation details
- **Godot API**: Primarily uses `Input.set_custom_mouse_cursor(image, shape, hotspot)`.
- **Image Scaling**: Godot handles scaling if the texture is a fixed size (e.g., 32x32). Using `.svg` source assets is preferred for clarity on high-DPI displays if exported as `.png` at multiple common sizes.

### Trade-off Discussion
- **Hardware Cursor vs Sprite Cursor**:
  - *Hardware Cursor (Chosen)*: Uses the OS mouse driver. Lower latency, matches system cursor speed, but limited in complex animations.
  - *Sprite/UI Cursor*: A custom `Sprite2D` following `get_local_mouse_position()`. Can be fully animated and scaled freely, but feels "floaty" if FPS is low.
  - **Decision**: We use Hardware Cursors for the best feel and lowest input latency, as is standard for 2D RPGs.
