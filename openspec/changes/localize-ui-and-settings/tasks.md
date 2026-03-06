# Implementation Tasks

- [ ] Create `assets/translations.csv` with initial keys for Main Menu, Settings, and sample Item/NPC. <!-- id: 1 -->
- [ ] Import the CSV in Godot (ensure `.translation` files are generated). <!-- id: 2 -->
- [ ] Update `SettingsManager.gd` to apply the saved language setting to `TranslationServer` on startup and change. <!-- id: 3 -->
- [ ] Implement `GeneralPanel` scene with an `OptionButton` for language selection. <!-- id: 4 -->
- [ ] Connect `GeneralPanel` to `SettingsManager` to read/write the language setting. <!-- id: 5 -->
- [ ] Refactor `MainMenu.tscn` to use translation keys (e.g., set text to `UI_MAIN_START`). <!-- id: 6 -->
- [ ] Refactor `SettingsWindow.tscn` to use translation keys. <!-- id: 7 -->
- [ ] Identify key Items and NPCs (e.g., `test_wand.tres`, `NPC.tscn`) and replace hardcoded names with keys. <!-- id: 9 -->
- [ ] Update `DialogueManager` or relevant UI to call `tr()` on content text if not automatically handled. <!-- id: 10 -->
- [ ] Verify runtime language switching works for both UI and Game Content. <!-- id: 8 -->
