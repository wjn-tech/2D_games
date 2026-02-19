## ADDED Requirements

1. Requirement: Use Poppins (or close metric match) for title and UI

#### Scenario: Font assets and fallback
- Given `Poppins` font files are added to `assets/fonts/` and referenced in Theme
- When the MainMenu loads
- Then title uses Poppins Bold at recommended size, buttons use Poppins Medium, and fallbacks exist if font missing.

2. Requirement: Improve typographic hierarchy

#### Scenario: Size and weight
- Given the title, greeting, and buttons
- When rendered
- Then title > greeting > primary CTA > secondary CTA in visual weight (size/weight) with spacing consistent across resolutions.
