# Tasks: Implement Tabbed Settings

## Phase 1: Core System (SettingsManager)
- [ ] Implement `src/core/settings_manager.gd` (Autoload) with `ConfigFile` persistence.
- [ ] Implement `load_settings()` and `save_settings()` using `ConfigFile`.
- [ ] Add application logic for Graphics (Fullscreen, Vsync) and Audio (Bus Volume).

## Phase 2: UI Structure
- [ ] Create `scenes/ui/SettingsWindow.tscn` with a custom Tab layout (Buttons + Content Area).
- [ ] Style the UI to match pixel-art references (Dark bg, Gold borders).
- [ ] Implement `GraphicsPanel` with checkboxes/sliders for `WindowMode`, `Vsync`, `Particles`.
- [ ] Implement `AudioPanel` with sliders for Master/Music/SFX.

## Phase 3: Input Remapping
- [ ] Implement `InputPanel` that lists defined Actions (Up, Down, Inventory, etc.).
- [ ] Create a `KeybindButton` component that listens for input event when clicked.
- [ ] wire up `SettingsManager` to save/load input overrides into `settings.cfg`.

## Phase 4: Integration
- [ ] Register `SettingsManager` as Autoload in `project.godot`.
- [ ] Update `MainMenu` -> `Settings` button to open this window.
- [ ] Ensure settings are applied on game startup.
