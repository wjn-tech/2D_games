# Proposal: Localize UI and Settings

## Background
Currently, the game has a `language` setting in `SettingsManager` (defaulting to "zh"), but it has no effect. The UI (e.g., `MainMenu`, `SettingsWindow`) contains hardcoded Chinese strings. Game content like item names and NPC dialogues also use hardcoded strings. The `GeneralPanel` in the settings menu is empty.

## Goal
Implement a functional localization system and expose language selection in the Settings UI. Ensure all hardcoded text (UI, Items, NPC Dialogues) is moved to a translation system to support bilingual switching (zh-CN <-> en-US).

## Components
1.  **Localization System**: Use Godot's built-in CSV translation server.
2.  **Settings UI**: Populate `GeneralPanel` with a language dropdown.
3.  **UI Updates**: Refactor `MainMenu` and `SettingsWindow` to use `tr()` keys instead of hardcoded text.
4.  **Content Updates**: Update Items and NPC data to use translation keys (e.g., `ITEM_SWORD_NAME`) for their display names and descriptions.

## Impact
- **SettingsManager**: Will need to apply locale changes to `TranslationServer`.
- **UI Scenes**: Will need updates to remove hardcoded strings.
- **Game Data**: Resource files (Items, NPCs) will need to store keys instead of raw text, or use `tr()` on display.
- **New Assets**: `translations.csv`.

## Risks
- Existing hardcoded strings might be missed during migration.
- Dynamic strings in code (e.g., string concatenation) need careful handling.
- Large volume of content text might require efficient CSV management.
