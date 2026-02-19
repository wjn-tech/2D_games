## ADDED Requirements

1. Requirement: Promote a single primary CTA (call-to-action) and visually de-emphasize secondary options.

#### Scenario: Player opens the game at default resolution
- Given the game starts and the main menu is visible
- When the player looks at the screen without interacting
- Then the primary CTA (`New Game` or `Start`) occupies greater visual weight (larger size, filled background, glow), and the three secondary buttons are visibly subordinate (outline or lower opacity).

Additional visual matching requirements (from reference):

- Title scale & spacing

#### Scenario: Title prominence
- Given default 1920x1200 resolution
- When the menu loads
- Then the title occupies approximately 40% of the UI column width; letter-spacing of title should be between 2-6 px; a subtle radial highlight behind the title should be present (soft bloom radius ~120px, intensity ~0.6 relative).

- Button styling and glow

#### Scenario: Button glow and layout
- Given buttons stacked vertically under the title
- When the buttons render
- Then primary CTA uses a rounded rectangle with corner radius 12 px, a soft gradient fill from `grad_top` -> `grad_bottom`, and a rear blurred glow of color `glow` with blur radius 24 px and intensity 0.9; secondary buttons use darker panel color with accent-outline and low-opacity glow (0.18).

- Concentric rings and starfield framing

#### Scenario: Ring framing
- Given the background shader is active
- When rendering
- Then at least two concentric rings are visible centered on UI column; ring stroke thickness is small (<= 3 px) and opacity between 0.03 and 0.08; rings must not obstruct text readability.


2. Requirement: Reduce redundant greeting and improve spacing

#### Scenario: Greeting placement
- Given the title and buttons are stacked vertically
- When layout is rendered
- Then any greeting text should be smaller and placed below the title or hidden behind an option in Settings; spacing between title and primary CTA must be >= 1.2x standard vertical unit.
