# Tasks: Expand World and Background

- [x] Update `WorldGenerator.gd` default dimensions to 1000x500.
- [x] Create `res://scenes/world/background.tscn` using `ParallaxBackground`.
- [x] Configure at least 3 layers in `background.tscn`:
    - Sky (Static/Slowest)
    - Distant Mountains (Slow)
    - Mid-ground (Medium)
- [x] Add the `background.tscn` to the `test.tscn` scene.
- [x] Add the `background.tscn` to the `main.tscn` scene.
- [x] Implement a simple script `background_controller.gd` to handle vertical transitions (Surface to Underground).
- [x] Verify that the camera limits are updated to match the new 1000x500 world size.
- [x] Test generation time and ensure it doesn't exceed acceptable limits (e.g., < 5 seconds).
- [x] Fix grass blocks dropping dirt instead of grass items.
- [x] Implement `GrassGrowthManager` for dirt-to-grass conversion.
