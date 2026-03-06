# Tasks: Spaceship Visuals

## Asset Preparation
- [ ] **Create/Import Tileset**: Create a custom **Industrial Gritty** Sci-Fi tileset (Rust/Metal) using procedural generation or pixel art tools.
- [ ] **Create Prop Sprites**: Cryo Pod, Computer Console, Broken Pipe, Exposed Wire.
- [ ] **Create Particle Textures**: Spark (small jagged line), Steam (cloud puff), Debris (shards).

## Scene Construction (`spaceship2.tscn`)
- [ ] **Replace Geometry**: Remove `Polygon2D` structure and build the room using `TileMapLayer`.
- [ ] **Place Decor**: Add Cryo Pod (visuals only), Consoles, and Wires.
- [ ] **Setup Lighting**: 
    - [ ] Add `CanvasModulate` (Grey/Visible).
    - [ ] Add `PointLight2D` (Alarm - Rotating/Pulsing).
    - [ ] Add `PointLight2D` (Console Glow).
- [ ] **Setup Background**: Add `ParallaxBackground` with scrolling stars seen through window gaps.

## Scripting (`ShipEnvironmentController.gd`)
- [ ] **Update State Logic**: Ensure `set_alert_level()` creates distinct visual changes (Light color/energy, Background speed).
- [ ] **Implement `flicker_lights()`**: Randomly toggle light energy to simulate bad connection.
- [ ] **Implement `breach_hull()`**: Trigger specifically for the crash sequence (suction particles, fast background).
- [ ] **Implement `rotate_camera()`**: Add logic to `ShipEnvironmentController` or `CinematicDirector` to tween camera rotation during the crash sequence.

## Integration
- [ ] **Sync with Tutorial**: Ensure `TutorialSequenceManager` calls `set_alert_level` at appropriate phase transitions.
- [ ] **Test**: Verify performance and visual impact during the full tutorial run at 1920x1080.
