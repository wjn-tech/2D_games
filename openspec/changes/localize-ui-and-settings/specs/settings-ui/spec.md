# Delta Spec: Settings UI

## MODIFIED Requirements

### Requirement: General Settings Panel
The `GeneralPanel` (`res://scenes/ui/settings/panels/GeneralPanel.tscn`) MUST provide a language selection interface.

#### Scenario: Language Dropdown
Given the Settings Window is open on the "General" tab
When the user views the panel
Then they see a "Language" (语言) dropdown
And the dropdown shows "简体中文" and "English"
And the current selection matches `SettingsManager` state

#### Scenario: Applying Language Change
Given the user changes the dropdown from "简体中文" to "English"
When the selection is confirmed (or immediately)
Then `SettingsManager.set_value("General", "language", "en")` is called
And the UI text updates to English
