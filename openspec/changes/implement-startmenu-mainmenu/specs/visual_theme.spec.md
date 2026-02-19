## ADDED Requirements

### Requirement: Visual Parity with Startmenu Reference
- The `MainMenu` shall present a title, subtitle, magic circle, floating runes, and three primary action buttons arranged vertically and centered. The overall color mood shall match the reference screenshot (dark navy/charcoal with soft purple highlights).

#### Scenario: Title and subtitle
- Given the `MainMenu` is loaded, when the scene is visible, then the title label should display large uppercase text with a subtle vertical gradient from pale purple to saturated purple, and the subtitle should be smaller with increased letter spacing.

#### Scenario: Magic circle and runes
- Given the `MainMenu` is loaded, then a concentric magic circle should be present behind the title with slow rotation and intermittent rune particles that fade in/out.

#### Scenario: Buttons
- Given the `MainMenu` is visible, then three primary buttons (Start, Continue, Settings) appear stacked; hovering a button increases its glow and emits a few small spark particles, clicking triggers the existing button action.

#### Scenario: Time-driven background
- Given the system local time, when it is night (local hour between 20 and 6), then the background should be darker with stronger star sparkle intensity; when day (hour between 7 and 18), the background should be slightly brighter and warmer.

### Requirement: Resource Fallback
- If custom font or SVGs are missing at runtime, then the `MainMenu` must still load and present a functional layout using default fonts and placeholder icons.

#### Scenario: Missing font
- Given the project does not contain `res://assets/fonts/ui_font.ttf`, then the theme should fall back to a built-in font without causing errors.
