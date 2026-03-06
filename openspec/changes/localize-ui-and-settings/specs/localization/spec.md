# Delta Spec: Localization System

## ADDED Requirements

### Requirement: CSV-Based Translation
The system MUST load translation data from a CSV file (`assets/translations.csv`).
- **Keys**: Unique identifiers (e.g., `UI_MAIN_START`, `ITEM_IRON_ORE`).
- **Locales**: `zh` (Chinese), `en` (English).

#### Scenario: Loading Translations
Given the game starts
When the translation system initializes
Then `TranslationServer` should contain keys from `translations.csv`

### Requirement: Runtime Locale Switching
The system MUST allow changing the locale at runtime via `SettingsManager`.

#### Scenario: Switching from Chinese to English
Given the current locale is "zh"
When the user selects "English" in settings
Then `TranslationServer.set_locale("en")` is called
And all UI elements using `tr()` or `text` keys update immediately to English

### Requirement: Content Translation
Game content (Items, NPCs, Dialogues) MUST use translation keys for user-visible text.

#### Scenario: Item Name Translation
Given an item with key `ITEM_SWORD`
When the player looks at the item tooltip in "en" locale
Then the name displays as "Iron Sword" (value for `ITEM_SWORD` in en column)

#### Scenario: NPC Dialogue
Given an NPC dialogue line using key `NPC_GREET_MERCHANT`
When the dialogue window opens in "zh" locale
Then the text displays as "你好，想要买点什么吗？" (value in zh column)
