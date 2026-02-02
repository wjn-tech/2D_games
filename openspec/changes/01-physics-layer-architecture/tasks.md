# Tasks: Physics Layer Architecture

- [x] **Layer Configuration**
    - [x] Update `project.godot` with named physics layers 1-6.
    - [x] Adjust collision matrix settings to allow Soft Entities to phase.
- [x] **Infrastructure Update**
    - [x] Update `LayerManager.gd` or similar globals to reflect new layer IDs.
- [x] **Optimization**
    - [x] Implement raycast filtering for multi-depth interaction (ignoring inactive layers).
- [x] **Verification**
    - [x] Validate new layers in `test.tscn` using debug collision shapes.
