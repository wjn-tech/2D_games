## ADDED Requirements

1. Requirement: Add non-intrusive decorative elements to frame the menu

#### Scenario: Decorative ring and starfield
- Given the background supports rings and stars via `MenuDynamicBackground`
- When the menu is visible
- Then a faint concentric ring and starfield are visible around the central UI area; their opacity must not reduce button readability.

2. Requirement: Subtle vignette and depth

#### Scenario: Readability with vignette
- Given a darkened vignette is applied
- When text and buttons render on top
- Then central content remains comfortably readable while edges subtly darken for focus.
